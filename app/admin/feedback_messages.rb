# frozen_string_literal: true

ActiveAdmin.register FeedbackMessage do
  menu priority: 6, label: "Feedback"

  permit_params :name, :email, :subject, :body, :kind, :replied

  filter :kind, as: :select, collection: FeedbackMessage::KINDS
  filter :replied
  filter :created_at

  scope :unread, default: true do |s|
    s.unread
  end
  scope :replied do |s|
    s.where(replied: true)
  end
  scope :all

  FeedbackMessage::KINDS.each do |k|
    scope k.to_sym, label: k.titleize do |s|
      s.by_kind(k)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :kind do |msg|
      status_tag msg.kind, class: (msg.kind == "bug" ? "warning" : (msg.kind == "partnership" ? "ok" : ""))
    end
    column "Subject" do |msg|
      truncate(msg.to_s, length: 60)
    end
    column :replied do |msg|
      status_tag(msg.replied? ? "Replied" : "Unread", class: msg.replied? ? "ok" : "warning")
    end
    column :created_at
    actions defaults: true do |msg|
      unless msg.replied?
        item "Mark replied", mark_replied_admin_feedback_message_path(msg),
             method: :put,
             data: { confirm: "Mark this message as replied?" }
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :kind
      row :subject
      row :body do |msg|
        simple_format(msg.body)
      end
      row :replied
      row :replied_at
      row :created_at
      row :updated_at
    end

    panel "Moderation" do
      div do
        unless feedback_message.replied?
          link_to "Mark replied",
                  mark_replied_admin_feedback_message_path(feedback_message),
                  method: :put,
                  class: "button",
                  data: { confirm: "Mark this message as replied?" }
        end
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Feedback message" do
      f.input :name
      f.input :email
      f.input :subject
      f.input :kind, as: :select, collection: FeedbackMessage::KINDS, include_blank: false
      f.input :body, as: :text, input_html: { rows: 10 }
      f.input :replied
    end

    f.actions
  end

  action_item :mark_replied, only: :show, if: -> { !resource.replied? } do
    link_to "Mark replied", mark_replied_admin_feedback_message_path(resource),
            method: :put,
            data: { confirm: "Mark this message as replied?" }
  end

  member_action :mark_replied, method: :put do
    resource.mark_replied!
    redirect_to admin_feedback_message_path(resource), notice: "Marked as replied."
  end
end
