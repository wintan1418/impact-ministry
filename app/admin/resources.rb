# frozen_string_literal: true

ActiveAdmin.register Resource do
  menu priority: 6, label: "Resources"

  permit_params :title, :description, :category, :requires_email, :featured,
                :cover_photo_slug, :published_at, :file

  filter :title
  filter :category, as: :select, collection: Resource::CATEGORIES
  filter :featured
  filter :requires_email
  filter :published_at

  scope :all, default: true
  scope :published do |s|
    s.where.not(published_at: nil)
  end
  scope :drafts do |s|
    s.where(published_at: nil)
  end
  scope :featured do |s|
    s.where(featured: true)
  end

  index do
    selectable_column
    id_column
    column :title do |r|
      link_to r.title, admin_resource_path(r)
    end
    column :category do |r|
      status_tag r.category_label, class: "info"
    end
    column :requires_email do |r|
      status_tag(r.requires_email? ? "Gated" : "Open",
                 class: r.requires_email? ? "warning" : "ok")
    end
    column :featured do |r|
      status_tag(r.featured? ? "Featured" : "—",
                 class: r.featured? ? "ok" : "muted")
    end
    column :downloads_count
    column :published_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :description do |r|
        simple_format(r.description.to_s)
      end
      row :category do |r|
        r.category_label
      end
      row :requires_email
      row :featured
      row :downloads_count
      row :cover_photo_slug
      row :published_at
      row :file do |r|
        if r.file.attached?
          link_to "Download #{r.file.filename} (#{number_to_human_size(r.file.byte_size)})",
                  url_for(r.file)
        else
          status_tag "No file attached", class: "muted"
        end
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form html: { multipart: true } do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Resource" do
      f.input :title
      f.input :description, as: :text, input_html: { rows: 8 },
              hint: "Plain text. Paragraphs separated by blank lines."
      f.input :category, as: :select,
              collection: Resource::CATEGORIES.map { |c| [ c.tr("_", " ").titleize, c ] },
              include_blank: false
      f.input :requires_email,
              hint: "Gate the download behind an email signup (source = 'resource_download')."
      f.input :featured,
              hint: "Featured resources appear in the top-of-page grid on /resources."
      f.input :cover_photo_slug, as: :select,
              collection: PhotoHelper::PHOTO_IDS.keys,
              include_blank: "(default — open-bible)",
              hint: "Pick a cover from the PhotoHelper set."
      f.input :published_at, as: :datetime_picker,
              hint: "Resources only appear publicly when this is set."
      f.input :file, as: :file,
              hint: "PDF, EPUB, ZIP, MP3 — anything the audience can download."
    end

    f.actions
  end

  action_item :publish_now, only: :show, if: -> { !resource.published? } do
    link_to "Publish now", publish_now_admin_resource_path(resource),
            method: :put,
            data: { confirm: "Publish this resource immediately?" }
  end

  member_action :publish_now, method: :put do
    resource.publish!
    redirect_to admin_resource_path(resource), notice: "Resource published."
  end
end
