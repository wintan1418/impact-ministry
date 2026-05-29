# frozen_string_literal: true

# Admin-only — donations are gated to staff with role: "admin" (CLAUDE.md §6).
ActiveAdmin.register Donor do
  menu priority: 9, label: "Donors"

  controller do
    before_action :require_admin!

    private

    def require_admin!
      access_denied unless current_user&.admin?
    end
  end

  permit_params :name, :email, :stripe_customer_id

  filter :name
  filter :email
  filter :stripe_customer_id
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :stripe_customer_id
    column "Donations" do |d|
      d.donations.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :stripe_customer_id
      row :user
      row :address
      row :created_at
      row :updated_at
    end

    panel "Donations" do
      table_for donor.donations.recent_first.limit(50) do
        column(:id) { |d| link_to d.id, admin_donation_path(d) }
        column(:amount) { |d| d.amount_formatted }
        column :designation
        column :frequency
        column :status
        column :donated_at
      end
    end
  end
end
