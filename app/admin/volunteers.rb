# frozen_string_literal: true

ActiveAdmin.register Volunteer do
  menu priority: 8, label: "Volunteers"

  permit_params :name, :email, :phone, :availability, :status, :gifts, :message,
                interest_areas: []

  filter :status,        as: :select, collection: Volunteer::STATUSES
  filter :availability,  as: :select, collection: Volunteer::AVAILABILITIES
  filter :name
  filter :email
  filter :created_at

  scope :unread, default: true do |s|
    s.unread
  end
  scope :all
  Volunteer::STATUSES.each do |status_value|
    next if status_value == "new"

    scope status_value.to_sym, label: status_value.titleize do |s|
      s.where(status: status_value)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :availability do |v|
      v.availability_label
    end
    column "Interests" do |v|
      v.interests_label.presence || status_tag("—", class: "muted")
    end
    column :status do |v|
      status_tag v.status, class: (v.status == "new" ? "warning" : "ok")
    end
    column :created_at
    actions defaults: true do |v|
      unless v.status == "in_review"
        item "Review", mark_in_review_admin_volunteer_path(v), method: :put
      end
      unless v.status == "engaged"
        item "Engage", mark_engaged_admin_volunteer_path(v), method: :put
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :phone
      row :availability do |v|
        v.availability_label
      end
      row "Interests" do |v|
        v.interests_label.presence || "—"
      end
      row :gifts do |v|
        simple_format(v.gifts.presence || "—")
      end
      row :message do |v|
        simple_format(v.message)
      end
      row :status do |v|
        status_tag v.status
      end
      row :created_at
      row :updated_at
    end

    panel "Move through the queue" do
      div do
        unless volunteer.status == "in_review"
          link_to "Mark in review",
                  mark_in_review_admin_volunteer_path(volunteer),
                  method: :put, class: "button"
        end
        text_node " "
        unless volunteer.status == "engaged"
          link_to "Mark engaged",
                  mark_engaged_admin_volunteer_path(volunteer),
                  method: :put, class: "button"
        end
        text_node " "
        unless volunteer.status == "declined"
          link_to "Mark declined",
                  mark_declined_admin_volunteer_path(volunteer),
                  method: :put, class: "button",
                  data: { confirm: "Mark this signup as declined?" }
        end
        text_node " "
        unless volunteer.status == "archived"
          link_to "Archive",
                  archive_admin_volunteer_path(volunteer),
                  method: :put, class: "button",
                  data: { confirm: "Archive this volunteer?" }
        end
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Volunteer" do
      f.input :name
      f.input :email
      f.input :phone
      f.input :availability,
              as: :select,
              collection: Volunteer::AVAILABILITIES,
              include_blank: false
      f.input :interest_areas,
              as: :check_boxes,
              collection: Volunteer::INTEREST_AREAS
      f.input :gifts, as: :text, input_html: { rows: 4 }
      f.input :message, as: :text, input_html: { rows: 10 }
      f.input :status,
              as: :select,
              collection: Volunteer::STATUSES,
              include_blank: false
    end

    f.actions
  end

  action_item :mark_in_review, only: :show, if: -> { resource.status != "in_review" } do
    link_to "Mark in review",
            mark_in_review_admin_volunteer_path(resource),
            method: :put
  end

  action_item :mark_engaged, only: :show, if: -> { resource.status != "engaged" } do
    link_to "Mark engaged",
            mark_engaged_admin_volunteer_path(resource),
            method: :put
  end

  action_item :mark_declined, only: :show, if: -> { resource.status != "declined" } do
    link_to "Mark declined",
            mark_declined_admin_volunteer_path(resource),
            method: :put,
            data: { confirm: "Mark this signup as declined?" }
  end

  action_item :archive, only: :show, if: -> { resource.status != "archived" } do
    link_to "Archive",
            archive_admin_volunteer_path(resource),
            method: :put,
            data: { confirm: "Archive this volunteer?" }
  end

  member_action :mark_in_review, method: :put do
    resource.update!(status: "in_review")
    redirect_to admin_volunteer_path(resource), notice: "Marked in review."
  end

  member_action :mark_engaged, method: :put do
    resource.update!(status: "engaged")
    redirect_to admin_volunteer_path(resource), notice: "Marked engaged."
  end

  member_action :mark_declined, method: :put do
    resource.update!(status: "declined")
    redirect_to admin_volunteer_path(resource), notice: "Marked declined."
  end

  member_action :archive, method: :put do
    resource.update!(status: "archived")
    redirect_to admin_volunteer_path(resource), notice: "Archived."
  end
end
