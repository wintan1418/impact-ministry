# frozen_string_literal: true

ActiveAdmin.register Partnership do
  menu priority: 7, label: "Partnerships"

  permit_params :organization_name, :contact_name, :contact_email,
                :contact_phone, :organization_type, :status, :message,
                interest_areas: []

  filter :status, as: :select, collection: Partnership::STATUSES
  filter :organization_type, as: :select, collection: Partnership::ORGANIZATION_TYPES
  filter :organization_name
  filter :contact_email
  filter :created_at

  scope :unread, default: true do |s|
    s.unread
  end
  scope :all
  Partnership::STATUSES.each do |status_value|
    next if status_value == "new" # `unread` already covers it

    scope status_value.to_sym, label: status_value.titleize do |s|
      s.where(status: status_value)
    end
  end

  index do
    selectable_column
    id_column
    column :organization_name
    column :contact_name
    column :contact_email
    column :organization_type do |p|
      status_tag p.organization_type,
                 class: (p.organization_type == "church" ? "ok" : "")
    end
    column "Interests" do |p|
      p.interests_label.presence || status_tag("—", class: "muted")
    end
    column :status do |p|
      status_tag p.status, class: (p.status == "new" ? "warning" : "ok")
    end
    column :created_at
    actions defaults: true do |p|
      unless p.status == "in_review"
        item "Review", mark_in_review_admin_partnership_path(p), method: :put
      end
      unless p.status == "engaged"
        item "Engage", mark_engaged_admin_partnership_path(p), method: :put
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :organization_name
      row :organization_type do |p|
        p.kind_label
      end
      row :contact_name
      row :contact_email
      row :contact_phone
      row "Interests" do |p|
        p.interests_label.presence || "—"
      end
      row :message do |p|
        simple_format(p.message)
      end
      row :status do |p|
        status_tag p.status
      end
      row :created_at
      row :updated_at
    end

    panel "Move through the queue" do
      div do
        unless partnership.status == "in_review"
          link_to "Mark in review",
                  mark_in_review_admin_partnership_path(partnership),
                  method: :put, class: "button"
        end
        text_node " "
        unless partnership.status == "engaged"
          link_to "Mark engaged",
                  mark_engaged_admin_partnership_path(partnership),
                  method: :put, class: "button"
        end
        text_node " "
        unless partnership.status == "declined"
          link_to "Mark declined",
                  mark_declined_admin_partnership_path(partnership),
                  method: :put, class: "button",
                  data: { confirm: "Mark this partnership as declined?" }
        end
        text_node " "
        unless partnership.status == "archived"
          link_to "Archive",
                  archive_admin_partnership_path(partnership),
                  method: :put, class: "button",
                  data: { confirm: "Archive this partnership?" }
        end
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Partnership" do
      f.input :organization_name
      f.input :organization_type,
              as: :select,
              collection: Partnership::ORGANIZATION_TYPES,
              include_blank: false
      f.input :contact_name
      f.input :contact_email
      f.input :contact_phone
      f.input :interest_areas,
              as: :check_boxes,
              collection: Partnership::INTEREST_AREAS
      f.input :message, as: :text, input_html: { rows: 10 }
      f.input :status,
              as: :select,
              collection: Partnership::STATUSES,
              include_blank: false
    end

    f.actions
  end

  # --- Action items (show page) ---
  action_item :mark_in_review, only: :show, if: -> { resource.status != "in_review" } do
    link_to "Mark in review",
            mark_in_review_admin_partnership_path(resource),
            method: :put
  end

  action_item :mark_engaged, only: :show, if: -> { resource.status != "engaged" } do
    link_to "Mark engaged",
            mark_engaged_admin_partnership_path(resource),
            method: :put
  end

  action_item :mark_declined, only: :show, if: -> { resource.status != "declined" } do
    link_to "Mark declined",
            mark_declined_admin_partnership_path(resource),
            method: :put,
            data: { confirm: "Mark this partnership as declined?" }
  end

  action_item :archive, only: :show, if: -> { resource.status != "archived" } do
    link_to "Archive",
            archive_admin_partnership_path(resource),
            method: :put,
            data: { confirm: "Archive this partnership?" }
  end

  # --- Member actions ---
  member_action :mark_in_review, method: :put do
    resource.update!(status: "in_review")
    redirect_to admin_partnership_path(resource), notice: "Marked in review."
  end

  member_action :mark_engaged, method: :put do
    resource.update!(status: "engaged")
    redirect_to admin_partnership_path(resource), notice: "Marked engaged."
  end

  member_action :mark_declined, method: :put do
    resource.update!(status: "declined")
    redirect_to admin_partnership_path(resource), notice: "Marked declined."
  end

  member_action :archive, method: :put do
    resource.update!(status: "archived")
    redirect_to admin_partnership_path(resource), notice: "Archived."
  end
end
