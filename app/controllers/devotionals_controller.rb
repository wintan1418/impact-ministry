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

    if signed_in?
      @user_highlights = current_user.devotional_highlights
                                      .where(devotional_id: @devotional.id)
                                      .order(saved_at: :desc)
    end
  end

  # GET /devotionals/today
  def today
    devotional = Devotional.published.for_today.first

    if devotional
      redirect_to devotional_path(devotional)
    else
      load_no_today_locals
      render :no_today, status: :ok
    end
  end

  private

  # When today's word isn't ready, show the last few mornings + a quiet
  # peek at tomorrow's scripture (if known) so the page feels populated
  # rather than empty.
  def load_no_today_locals
    @recent_devotionals  = Devotional.published.recent_first.limit(4)
    @tomorrow_devotional =
      Devotional.published.where(scheduled_for: Date.current + 1).first ||
      Devotional.where(scheduled_for: Date.current + 1).first
    @tomorrow_book       = tomorrow_book_label(@tomorrow_devotional)
    @send_hour           = Integer(ENV.fetch("DEVOTIONAL_SEND_HOUR", "5"))
    @send_time_label     = format("%d:00am", @send_hour)
    @tomorrow_send_at    = (Date.current + 1).beginning_of_day + @send_hour.hours
  end

  # "Romans 12:1-3" → "Romans 12". Quiet preview, no verse range.
  def tomorrow_book_label(devotional)
    return nil if devotional.blank?

    ref = devotional.scripture_reference.to_s
    ref.split(":").first.to_s.strip.presence
  end

  def set_devotional
    @devotional = Devotional.friendly.find(params[:slug])
  end
end
