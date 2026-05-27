ActiveAdmin.register PodcastEpisode do
  menu priority: 3, label: "Podcast"

  permit_params :title, :season, :episode_number, :description, :audio_url, :video_url,
                :duration_seconds, :transcript, :scheduled_for, :published_at,
                :cover_photo_slug, guest_names: []

  filter :season
  filter :episode_number
  filter :published_at
  filter :scheduled_for

  scope :all
  scope :published
  scope :scheduled, default: true

  index do
    selectable_column
    column :season
    column :episode_number
    column :title do |ep|
      link_to ep.title, admin_podcast_episode_path(ep)
    end
    column "Guests" do |ep|
      ep.guest_names.to_sentence
    end
    column "Duration", &:duration_label
    column :scheduled_for
    column "Live" do |ep|
      status_tag(ep.published_at ? "Published" : "Scheduled", class: ep.published_at ? "ok" : "warning")
    end
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs "Episode" do
      f.input :season
      f.input :episode_number
      f.input :title
      f.input :description, as: :text, input_html: { rows: 6 }
      f.input :guest_names, as: :string,
              hint: "Comma-separated. e.g. 'Reuben Hollis, Anita Keys'",
              input_html: { value: f.object.guest_names.join(", ") }
      f.input :duration_seconds, hint: "Total runtime in seconds"
      f.input :audio_url, hint: "Direct MP3/M4A URL (CDN or Postmark-friendly host)"
      f.input :video_url, hint: "Optional — YouTube or Vimeo URL"
      f.input :cover_photo_slug, as: :select,
              collection: PhotoHelper::PHOTO_IDS.keys,
              include_blank: "(default — microphone)",
              hint: "Choose from the seeded PhotoHelper set; Phase 2 will swap to direct upload."
      f.input :transcript, as: :text, input_html: { rows: 12 }
      f.input :scheduled_for, as: :datepicker
      f.input :published_at, as: :datetime_picker, hint: "Leave blank to keep as draft."
    end
    f.actions
  end

  controller do
    def create
      coerce_guest_names!
      super
    end

    def update
      coerce_guest_names!
      super
    end

    private

    def coerce_guest_names!
      raw = params.dig(:podcast_episode, :guest_names)
      return unless raw.is_a?(String)
      params[:podcast_episode][:guest_names] = raw.split(",").map(&:strip).reject(&:blank?)
    end
  end

  action_item :publish_now, only: :show do
    unless resource.published?
      link_to "Publish now",
              publish_now_admin_podcast_episode_path(resource),
              method: :put,
              data: { turbo_method: :put, turbo_confirm: "Publish #{resource.title}?" }
    end
  end

  member_action :publish_now, method: :put do
    resource.publish!
    redirect_to admin_podcast_episode_path(resource), notice: "Published."
  end
end
