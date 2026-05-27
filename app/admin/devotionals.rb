# frozen_string_literal: true

ActiveAdmin.register Devotional do
  menu priority: 2, label: "Devotionals"

  permit_params :title, :scripture_reference, :excerpt, :scheduled_for,
                :published_at, :author_id, :body, :featured_image, :audio,
                tags: []

  filter :title
  filter :scripture_reference
  filter :scheduled_for
  filter :published_at
  filter :author
  filter :tags_contains, as: :string, label: "Tag (contains)"

  scope :all, default: true
  scope :published
  scope :scheduled

  index do
    selectable_column
    id_column
    column :title
    column :scripture_reference
    column :scheduled_for
    column "Published" do |d|
      if d.published?
        status_tag "Yes", class: "ok"
      else
        status_tag "No", class: "warning"
      end
    end
    column :author
    actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :scripture_reference
      row :excerpt
      row :author
      row :scheduled_for
      row :published_at
      row :tags
      row :created_at
      row :updated_at
    end

    panel "Body" do
      div class: "prose" do
        devotional.body.to_s.html_safe
      end
    end

    if devotional.featured_image.attached?
      panel "Featured image" do
        div do
          image_tag url_for(devotional.featured_image), style: "max-width: 480px; border-radius: 12px;"
        end
      end
    end

    if devotional.audio.attached?
      panel "Audio" do
        div do
          link_to "Download audio (#{devotional.audio.blob.filename})", url_for(devotional.audio)
        end
      end
    end

    active_admin_comments
  end

  form html: { multipart: true } do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.object.author ||= current_user

    f.inputs "Devotional" do
      f.input :title
      f.input :scripture_reference, label: "Scripture reference",
              hint: "e.g. Habakkuk 2:1–4"
      f.input :excerpt, as: :text, input_html: { rows: 3 },
              hint: "Two-line pull quote shown above the body."
      f.input :scheduled_for, as: :datepicker,
              hint: "One devotional per day. Setting this enforces uniqueness."
      f.input :tags, as: :string,
              input_html: { value: (f.object.tags || []).join(", ") },
              hint: "Comma-separated. Used for archive filtering."
      f.input :author, as: :select,
              collection: User.staff.order(:name),
              include_blank: false
      f.input :body, as: :text, input_html: { rows: 18 },
              hint: "Rich text — HTML allowed."
      f.input :featured_image, as: :file
      f.input :audio, as: :file, hint: "MP3 or M4A for read-aloud audio."
    end

    f.actions
  end

  controller do
    before_action :coerce_tags, only: [ :create, :update ]

    private

    def coerce_tags
      raw = params.dig(:devotional, :tags)
      return unless raw.is_a?(String)

      params[:devotional][:tags] = raw.split(",").map(&:strip).reject(&:blank?)
    end
  end

  batch_action :publish do |ids|
    Devotional.where(id: ids).where(published_at: nil).find_each(&:publish!)
    redirect_to collection_path, notice: "Selected devotionals published."
  end

  batch_action :unpublish do |ids|
    Devotional.where(id: ids).update_all(published_at: nil)
    redirect_to collection_path, notice: "Selected devotionals unpublished."
  end

  action_item :publish_now, only: :show do
    unless devotional.published?
      link_to "Publish now", publish_now_admin_devotional_path(devotional),
              method: :put,
              data: { confirm: "Publish this devotional immediately?" }
    end
  end

  action_item :unpublish, only: :show do
    if devotional.published?
      link_to "Unpublish", unpublish_admin_devotional_path(devotional),
              method: :put,
              data: { confirm: "Mark this devotional as unpublished?" }
    end
  end

  member_action :publish_now, method: :put do
    resource.publish!
    redirect_to admin_devotional_path(resource), notice: "Devotional published."
  end

  member_action :unpublish, method: :put do
    resource.update!(published_at: nil)
    redirect_to admin_devotional_path(resource), notice: "Devotional unpublished."
  end
end
