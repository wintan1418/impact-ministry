class DevotionalsController < ApplicationController
  before_action :set_devotional, only: :show

  # GET /devotionals
  def index
    scope = Devotional.published.recent_first
    scope = scope.tagged(params[:tag]) if params[:tag].present? && params[:tag] != "All"
    scope = scope.search_text(params[:q]) if params[:q].present?

    @tag    = params[:tag]
    @query  = params[:q]
    @available_tags = Devotional.published.pluck(:tags).flatten.uniq.sort

    @devotionals = if scope.respond_to?(:page)
      scope.page(params[:page]).per(12)
    else
      scope.limit(24)
    end
  end

  # GET /devotionals/:slug
  def show
    raise ActiveRecord::RecordNotFound unless @devotional.published?
  end

  # GET /devotionals/today
  def today
    devotional = Devotional.published.for_today.first

    if devotional
      redirect_to devotional_path(devotional)
    else
      render :no_today, status: :ok
    end
  end

  private

  def set_devotional
    @devotional = Devotional.friendly.find(params[:slug])
  end
end
