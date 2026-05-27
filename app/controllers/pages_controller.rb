# Public, editor-managed pages.
#
# Resolves a `:slug` param against the Page model and renders either:
#   - a slug-specific template at `app/views/pages/<slug>.html.erb` (e.g. about), or
#   - the generic editorial layout at `app/views/pages/show.html.erb`.
class PagesController < ApplicationController
  def show
    @page = Page.published.friendly.find(params[:slug])

    @page_title       = page_title
    @page_description = page_description

    render_for_slug
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Page not found: #{params[:slug]}"
  end

  private

  def page_title
    [ @page.title, "IMPACT Ministry" ].join(" — ")
  end

  def page_description
    @page.seo_meta.is_a?(Hash) ? @page.seo_meta["description"].presence : nil
  end

  # Render `pages/<slug>` if a template exists; otherwise fall back to the
  # generic editorial show template. Keeps slug-specific designs (e.g. the
  # magazine-feature `about` layout) without a controller branch per slug.
  def render_for_slug
    template = "pages/#{@page.slug}"
    if lookup_context.template_exists?(template)
      render template: template
    else
      render :show
    end
  end
end
