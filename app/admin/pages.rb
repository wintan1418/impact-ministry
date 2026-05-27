# frozen_string_literal: true

ActiveAdmin.register Page do
  menu priority: 4, label: "Pages"

  permit_params :title, :slug, :published, :body, seo_meta: {}

  # Filters
  filter :title
  filter :slug
  filter :published
  filter :updated_at

  # Index
  index do
    selectable_column
    id_column
    column :title
    column :slug
    column :published
    column :updated_at
    actions
  end

  # Show
  show do
    attributes_table do
      row :title
      row :slug
      row :published
      row :seo_meta
      row :created_at
      row :updated_at
    end

    panel "Body" do
      div class: "prose" do
        page.body.to_s.html_safe
      end
    end

    active_admin_comments
  end

  # Form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Page" do
      f.input :title
      f.input :slug, hint: "Leave blank to auto-generate from title. Used in URLs."
      f.input :published
      f.input :body, as: :text, input_html: { rows: 16 },
              hint: "Rich text — HTML allowed. ActionText editor coming in a follow-up ticket."
    end

    f.inputs "SEO metadata (JSON)" do
      f.input :seo_meta,
              as: :text,
              input_html: {
                rows: 5,
                value: f.object.seo_meta.is_a?(Hash) ? JSON.pretty_generate(f.object.seo_meta) : f.object.seo_meta.to_s
              },
              hint: 'Example: { "description": "...", "og_image_url": "..." }'
    end

    f.actions
  end

  # Coerce the seo_meta textarea into a Hash before assignment.
  controller do
    before_action :coerce_seo_meta, only: [ :create, :update ]

    private

    def coerce_seo_meta
      raw = params.dig(:page, :seo_meta)
      return unless raw.is_a?(String)

      params[:page][:seo_meta] =
        if raw.strip.empty?
          {}
        else
          begin
            JSON.parse(raw)
          rescue JSON::ParserError
            flash.now[:error] = "SEO metadata must be valid JSON."
            {}
          end
        end
    end
  end
end
