# frozen_string_literal: true

ActiveAdmin.register PrayerRequest do
  menu priority: 4, label: "Prayer Wall"

  permit_params :name, :email, :body, :status, :is_anonymous, :is_public, :prayed_count

  filter :status, as: :select, collection: PrayerRequest::STATUSES
  filter :is_public
  filter :created_at

  scope :pending_moderation, default: true
  scope :visible
  scope :answered_only
  scope :all

  index do
    selectable_column
    id_column
    column "Request" do |pr|
      pr.body.to_s.truncate(80)
    end
    column "Name", &:display_name
    column :status do |pr|
      status_tag pr.status, class: (pr.status_answered? ? "ok" : (pr.status_new? ? "warning" : ""))
    end
    column :is_public
    column :prayed_count
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row "Name", &:display_name
      row :name
      row :email
      row :is_anonymous
      row :status
      row :is_public
      row :prayed_count
      row :body
      row :created_at
      row :updated_at
    end

    panel "Moderation" do
      div do
        unless prayer_request.status_praying? || prayer_request.status_answered?
          span do
            link_to "Approve to public wall",
                    approve_public_admin_prayer_request_path(prayer_request),
                    method: :put,
                    class: "button",
                    data: { confirm: "Publish this request to the public prayer wall?" }
          end
          span "  "
        end

        unless prayer_request.status_answered?
          span do
            link_to "Mark answered",
                    mark_answered_admin_prayer_request_path(prayer_request),
                    method: :put,
                    class: "button",
                    data: { confirm: "Mark this prayer request as answered?" }
          end
          span "  "
        end

        unless prayer_request.status_archived?
          span do
            link_to "Archive",
                    archive_admin_prayer_request_path(prayer_request),
                    method: :put,
                    class: "button",
                    data: { confirm: "Archive this request? It will be removed from the wall." }
          end
        end
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Prayer request" do
      f.input :name
      f.input :email
      f.input :is_anonymous
      f.input :body, as: :text, input_html: { rows: 8 }
      f.input :status, as: :select, collection: PrayerRequest::STATUSES, include_blank: false
      f.input :is_public
      f.input :prayed_count
    end

    f.actions
  end

  action_item :approve_public, only: :show do
    unless prayer_request.status_praying? || prayer_request.status_answered?
      link_to "Approve to wall", approve_public_admin_prayer_request_path(prayer_request),
              method: :put,
              data: { confirm: "Publish this request to the public prayer wall?" }
    end
  end

  action_item :mark_answered, only: :show do
    unless prayer_request.status_answered?
      link_to "Mark answered", mark_answered_admin_prayer_request_path(prayer_request),
              method: :put,
              data: { confirm: "Mark this prayer request as answered?" }
    end
  end

  action_item :archive, only: :show do
    unless prayer_request.status_archived?
      link_to "Archive", archive_admin_prayer_request_path(prayer_request),
              method: :put,
              data: { confirm: "Archive this request? It will be removed from the wall." }
    end
  end

  member_action :approve_public, method: :put do
    resource.update!(status: "praying", is_public: true)
    redirect_to admin_prayer_request_path(resource), notice: "Request approved to the public wall."
  end

  member_action :mark_answered, method: :put do
    resource.update!(status: "answered", is_public: true)
    redirect_to admin_prayer_request_path(resource), notice: "Marked as answered."
  end

  member_action :archive, method: :put do
    resource.update!(status: "archived")
    redirect_to admin_prayer_request_path(resource), notice: "Request archived."
  end
end
