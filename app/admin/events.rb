# frozen_string_literal: true

ActiveAdmin.register Event do
  menu priority: 5, label: "Events"

  permit_params :title, :description, :starts_at, :ends_at, :location,
                :virtual_link, :capacity, :published, :cover_photo_slug

  filter :title
  filter :starts_at
  filter :published
  filter :location

  scope :upcoming, default: true
  scope :past
  scope :all
  scope :published

  index do
    selectable_column
    id_column
    column :title do |event|
      link_to event.title, admin_event_path(event)
    end
    column :starts_at
    column :location
    column :capacity
    column "Seats taken", &:rsvp_seat_count
    column :published do |event|
      status_tag(event.published? ? "Published" : "Draft",
                 class: event.published? ? "ok" : "warning")
    end
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :description
      row :starts_at
      row :ends_at
      row :location
      row :virtual_link
      row :capacity
      row "Seats taken", &:rsvp_seat_count
      row "Seats remaining", &:seats_remaining
      row :published
      row :cover_photo_slug
      row :created_at
      row :updated_at
    end

    panel "RSVPs (#{event.event_rsvps.count})" do
      table_for event.event_rsvps.order(created_at: :desc) do
        column :name
        column :email
        column :party_size
        column :notes
        column :created_at
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Event" do
      f.input :title
      f.input :description, as: :text, input_html: { rows: 6 }
      f.input :starts_at, as: :datetime_picker
      f.input :ends_at,   as: :datetime_picker,
              hint: "Optional. If blank, the event is considered 'over' 24 hours after it starts."
      f.input :location, hint: "City, state — leave blank for online-only gatherings."
      f.input :virtual_link, hint: "Optional Zoom / Meet / Riverside link."
      f.input :capacity, hint: "Leave blank for an open invitation."
      f.input :cover_photo_slug, as: :select,
              collection: PhotoHelper::PHOTO_IDS.keys,
              include_blank: "(default — doorway-light)",
              hint: "Pick a cover from the PhotoHelper set."
      f.input :published
    end
    f.actions
  end
end
