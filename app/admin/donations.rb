# frozen_string_literal: true

# Admin-only — editors get an access_denied per CLAUDE.md §6.
ActiveAdmin.register Donation do
  menu priority: 10, label: "Donations"

  controller do
    before_action :require_admin!

    private

    def require_admin!
      access_denied unless current_user&.admin?
    end
  end

  filter :designation, as: :select, collection: Donation::DESIGNATIONS
  filter :frequency,   as: :select, collection: Donation::FREQUENCIES
  filter :status,      as: :select, collection: Donation::STATUSES
  filter :amount_cents
  filter :donated_at
  filter :created_at

  scope :all, default: true
  scope :succeeded
  scope("Monthly") { |s| s.where(frequency: "monthly") }

  index do
    selectable_column
    id_column
    column :donor
    column("Amount") { |d| d.amount_formatted }
    column :designation
    column :frequency
    column :status do |d|
      status_tag d.status, class: (d.status == "succeeded" ? "ok" : (d.status == "pending" ? "warning" : ""))
    end
    column :donated_at
    column :receipt_sent_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :donor
      row("Amount") { |d| d.amount_formatted }
      row :currency
      row :designation do |d|
        d.designation_label
      end
      row :frequency
      row :status do |d|
        status_tag d.status
      end
      row :stripe_payment_intent_id
      row :stripe_subscription_id
      row :stripe_checkout_session_id
      row :donated_at
      row :receipt_sent_at
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
