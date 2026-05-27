class SitemapsController < ApplicationController
  # Public XML sitemap of indexable surfaces.
  # Generated dynamically — kept fast via `published` scopes + DB indexes.

  def show
    @host = ENV.fetch("APP_HOST", request.host_with_port)
    @protocol = ENV.fetch("APP_PROTOCOL", request.protocol.delete(":/"))
    @pages = published_pages
    @devotionals = published_devotionals

    respond_to do |format|
      format.xml { render :show, layout: false }
    end
  end

  private

  def published_pages
    return [] unless defined?(Page) && Page.table_exists?
    Page.published.order(updated_at: :desc)
  rescue ActiveRecord::StatementInvalid
    []
  end

  def published_devotionals
    return [] unless defined?(Devotional) && Devotional.table_exists?
    Devotional.published.order(published_at: :desc).limit(5_000)
  rescue ActiveRecord::StatementInvalid
    []
  end
end
