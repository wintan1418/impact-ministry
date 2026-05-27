# frozen_string_literal: true

ActiveAdmin.register EmailSubscriber do
  menu priority: 3, label: "Subscribers"

  # Email + token are not editable from the admin. Capture happens publicly;
  # admin can adjust attribution (source) and contact name only.
  permit_params :name, :source

  filter :email
  filter :source, as: :select, collection: EmailSubscriber::SOURCES
  filter :unsubscribed_at
  filter :created_at

  scope :all, default: true
  scope :active
  scope :unsubscribed

  index do
    selectable_column
    id_column
    column :email
    column :name
    column :source
    column :subscribed_at
    column "Status" do |s|
      if s.active?
        status_tag "Active", class: "ok"
      else
        status_tag "Unsubscribed", class: "warning"
      end
    end
    column :created_at
    actions defaults: true do |subscriber|
      if subscriber.active?
        item "Unsubscribe", unsubscribe_admin_email_subscriber_path(subscriber),
             method: :put,
             data: { confirm: "Mark this subscriber as unsubscribed?" }
      end
    end
  end

  show do
    attributes_table do
      row :email
      row :name
      row :source
      row :preferences
      row :subscribed_at
      row :unsubscribed_at
      row :token
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :source, as: :select, collection: EmailSubscriber::SOURCES,
                       include_blank: false
    end
    f.actions
  end

  member_action :unsubscribe, method: :put do
    resource.unsubscribe!
    redirect_to admin_email_subscriber_path(resource), notice: "Subscriber unsubscribed."
  end

  # CSV export is provided by ActiveAdmin out of the box on the index page.
end
