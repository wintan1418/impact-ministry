# frozen_string_literal: true

ActiveAdmin.register Testimony do
  menu priority: 5, label: "Testimonies"

  permit_params :name, :location, :body, :featured, :approved, :photo

  # Filters
  filter :name
  filter :location
  filter :approved
  filter :featured
  filter :submitted_at
  filter :approved_at

  # Scopes — moderation queue is the default landing surface.
  scope :unapproved, default: true do |s|
    s.where(approved: false)
  end
  scope :approved do |s|
    s.where(approved: true)
  end
  scope :featured do |s|
    s.where(featured: true)
  end
  scope :all

  # Index
  index do
    selectable_column
    id_column
    column :name do |t|
      t.display_name
    end
    column :location
    column "Story" do |t|
      truncate(t.body.to_s, length: 80)
    end
    column "Photo" do |t|
      if t.photo.attached?
        image_tag t.photo.variant(resize_to_limit: [ 64, 64 ]), style: "border-radius: 6px;"
      else
        status_tag "—", class: "muted"
      end
    end
    column :approved do |t|
      status_tag(t.approved? ? "Approved" : "Pending", class: t.approved? ? "ok" : "warning")
    end
    column :featured do |t|
      status_tag(t.featured? ? "Featured" : "—", class: t.featured? ? "ok" : "muted")
    end
    column :submitted_at
    actions defaults: true do |testimony|
      unless testimony.approved?
        item "Approve", approve_admin_testimony_path(testimony),
             method: :put,
             data: { confirm: "Approve this testimony for the public wall?" }
      end
      if testimony.approved? && !testimony.featured?
        item "Feature", feature_admin_testimony_path(testimony), method: :put
      end
      if testimony.featured?
        item "Unfeature", unfeature_admin_testimony_path(testimony), method: :put
      end
    end
  end

  # Show
  show do
    attributes_table do
      row :name
      row :display_name
      row :location
      row :body do |t|
        simple_format(t.body)
      end
      row :photo do |t|
        if t.photo.attached?
          image_tag t.photo.variant(resize_to_limit: [ 300, 300 ]), style: "border-radius: 12px;"
        else
          status_tag "No photo attached", class: "muted"
        end
      end
      row :approved
      row :approved_at
      row :featured
      row :submitted_at
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  # Form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Testimony" do
      f.input :name, hint: "Leave blank to display 'A friend' on the wall."
      f.input :location, hint: "e.g. Jackson, MS"
      f.input :body, as: :text, input_html: { rows: 10 }
      f.input :photo, as: :file, hint: "Optional. JPG / PNG / WEBP. Resized automatically."
      f.input :approved, hint: "Approved testimonies appear on the public wall."
      f.input :featured, hint: "Featured rotates into the homepage and the /testimonies featured row."
    end
    f.actions
  end

  # --- Member actions ---
  member_action :approve, method: :put do
    resource.update!(approved: true)
    redirect_to admin_testimony_path(resource), notice: "Testimony approved."
  end

  member_action :feature, method: :put do
    resource.update!(featured: true, approved: true)
    redirect_to admin_testimony_path(resource), notice: "Testimony featured."
  end

  member_action :unfeature, method: :put do
    resource.update!(featured: false)
    redirect_to admin_testimony_path(resource), notice: "Testimony unfeatured."
  end

  # --- Show-page action items (quick-actions row) ---
  action_item :approve, only: :show, if: -> { !resource.approved? } do
    link_to "Approve", approve_admin_testimony_path(resource),
            method: :put,
            data: { turbo_method: :put, turbo_confirm: "Approve this testimony?" }
  end

  action_item :feature, only: :show, if: -> { resource.approved? && !resource.featured? } do
    link_to "Feature", feature_admin_testimony_path(resource),
            method: :put,
            data: { turbo_method: :put }
  end

  action_item :unfeature, only: :show, if: -> { resource.featured? } do
    link_to "Unfeature", unfeature_admin_testimony_path(resource),
            method: :put,
            data: { turbo_method: :put }
  end
end
