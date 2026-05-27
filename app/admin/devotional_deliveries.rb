# frozen_string_literal: true

# Engagement data is sensitive — admin role only (editors can't see who
# opened/clicked). Read-only: writes happen via DevotionalDeliveryJob
# and the Postmark webhook pipeline.
ActiveAdmin.register DevotionalDelivery do
  menu priority: 4, label: "Deliveries"

  actions :index, :show

  filter :devotional
  filter :email_subscriber
  filter :sent_at
  filter :opened_at
  filter :clicked_at
  filter :postmark_message_id

  scope :all, default: true
  scope :opened
  scope :clicked

  index do
    selectable_column
    id_column
    column "Subscriber" do |delivery|
      delivery.email_subscriber&.email
    end
    column :devotional
    column :sent_at
    column :opened_at
    column :clicked_at
    column :postmark_message_id
    actions
  end

  show do
    attributes_table do
      row :id
      row :devotional
      row "Subscriber" do |delivery|
        delivery.email_subscriber&.email
      end
      row :sent_at
      row :opened_at
      row :clicked_at
      row :postmark_message_id
      row :created_at
      row :updated_at
    end
  end

  controller do
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      flash[:alert] = "You don't have access to that section."
      redirect_to admin_root_path
    end
  end
end
