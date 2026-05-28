# frozen_string_literal: true

ActiveAdmin.register EventRsvp do
  menu priority: 6, label: "Event RSVPs"

  belongs_to :event, optional: true

  permit_params :event_id, :name, :email, :party_size, :notes

  filter :event
  filter :created_at
  filter :email
  filter :name

  index do
    selectable_column
    id_column
    column :name
    column :email
    column "Event" do |rsvp|
      link_to rsvp.event.title, admin_event_path(rsvp.event)
    end
    column :party_size
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :event
      row :party_size
      row :notes
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "RSVP" do
      f.input :event, collection: Event.order(:starts_at)
      f.input :name
      f.input :email
      f.input :party_size
      f.input :notes, as: :text, input_html: { rows: 3 }
    end
    f.actions
  end

  action_item :export_csv, only: :index do
    link_to "Export CSV", url_for(params.to_unsafe_h.merge(format: :csv))
  end

  csv do
    column :id
    column("Event") { |r| r.event.title }
    column :name
    column :email
    column :party_size
    column :notes
    column :created_at
  end
end
