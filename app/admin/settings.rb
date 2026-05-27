# frozen_string_literal: true

# Settings are admin-only — editors don't see this resource in the menu, and
# direct URLs are guarded by `require_admin_only` below.
ActiveAdmin.register Setting do
  menu priority: 99, label: "Settings", if: proc { current_user&.admin? }

  permit_params :key, :value, :kind, :description

  # Filters
  filter :key
  filter :kind, as: :select, collection: Setting::KINDS
  filter :updated_at

  # Index
  index do
    selectable_column
    id_column
    column :key
    column :kind
    column :value do |s|
      truncate(s.value.to_s, length: 80)
    end
    column :description do |s|
      truncate(s.description.to_s, length: 80)
    end
    column :updated_at
    actions
  end

  # Show
  show do
    attributes_table do
      row :key
      row :kind
      row :value
      row :description
      row :created_at
      row :updated_at
    end
  end

  # Form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Setting" do
      f.input :key, hint: "Stable identifier. Don't rename once code references it."
      f.input :kind, as: :select, collection: Setting::KINDS, include_blank: false
      f.input :value, as: :text, input_html: { rows: 6 },
              hint: "For 'json' kind, paste valid JSON. For 'boolean', use true/false."
      f.input :description, as: :text, input_html: { rows: 2 }
    end
    f.actions
  end

  # Admin-only guard. Editors get redirected with a flash.
  controller do
    before_action :require_admin_only

    private

    def require_admin_only
      return if current_user&.admin?

      redirect_to admin_root_path, alert: "Admin access only."
    end
  end
end
