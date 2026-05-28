# Public Resource Library surface. Mounted at:
#
#   GET  /resources                 → #index    (featured + per-category sections)
#   GET  /resources/:slug           → #show     (with download gate)
#   POST /resources/:slug/download  → #download (Turbo Stream)
#
# Anonymous read access — no authentication. When a non-subscriber downloads a
# resource flagged `requires_email: true`, we create an EmailSubscriber with
# source="resource_download" (per EmailSubscriber::SOURCES).
#
# Submission errors render inline in the gate frame — no toasts, per CLAUDE.md §3.
class ResourcesController < ApplicationController
  include TurnstileProtectable

  before_action :set_resource, only: %i[show download]

  # GET /resources
  def index
    @categories = Resource::CATEGORIES
    @category   = params[:category].presence
    @query      = params[:q].to_s.strip

    scope = Resource.published

    if @query.present?
      # pg_search returns an unscoped relation — re-apply published to be safe.
      scope = Resource.search_text(@query).where.not(published_at: nil)
    end

    if @category.present? && Resource::CATEGORIES.include?(@category)
      scope = scope.by_category(@category)
      @featured    = Resource.none
      @by_category = { @category => scope.recent_first.to_a }
    else
      @featured = Resource.published.featured.recent_first.limit(3).to_a
      featured_ids = @featured.map(&:id)
      remainder = scope.recent_first.where.not(id: featured_ids).to_a
      @by_category = remainder.group_by(&:category)
    end
  end

  # GET /resources/:slug
  def show
    # Build a fresh subscriber form object so the gate form has a model.
    @subscriber = EmailSubscriber.new
  end

  # POST /resources/:slug/download
  def download
    if @resource.requires_email?
      handle_gated_download
    else
      handle_open_download
    end
  end

  private

  def set_resource
    # Scoped to published — an unpublished slug yields 404 to the public.
    @resource = Resource.published.friendly.find(params[:slug])
  end

  def download_params
    # Form is small, so params arrive top-level (matches email_subscribers#create).
    params.permit(:email, :name)
  end

  def handle_gated_download
    submitted_email = download_params[:email].to_s.strip.downcase
    submitted_name  = download_params[:name].to_s.strip

    unless verify_turnstile!
      flash.delete(:alert)
      @subscriber = EmailSubscriber.new(email: submitted_email, name: submitted_name)
      @error_message = "We couldn't verify you're human. Please try again."
      render_gate_failure
      return
    end

    if submitted_email.blank? || !submitted_email.match?(URI::MailTo::EMAIL_REGEXP)
      @subscriber = EmailSubscriber.new(email: submitted_email, name: submitted_name)
      @error_message = "Please enter a valid email."
      render_gate_failure
      return
    end

    @subscriber = EmailSubscriber.find_by("lower(email) = ?", submitted_email)

    if @subscriber.nil?
      @subscriber = EmailSubscriber.new(
        email:  submitted_email,
        name:   submitted_name.presence,
        source: "resource_download"
      )
      unless @subscriber.save
        @error_message = @subscriber.errors[:email].first.presence || "Please enter a valid email."
        render_gate_failure
        return
      end
      WelcomeEmailJob.perform_later(@subscriber.id) if defined?(WelcomeEmailJob)
    elsif !@subscriber.active?
      @subscriber.resubscribe!
    end

    @resource.increment_downloads!
    render_gate_success
  end

  def handle_open_download
    @resource.increment_downloads!

    respond_to do |format|
      format.html do
        if @resource.file.attached?
          redirect_to rails_blob_url(@resource.file, disposition: "attachment"), allow_other_host: false
        else
          redirect_to resource_path(@resource.slug), notice: "Download not yet available."
        end
      end
      format.turbo_stream { render :download, status: :ok }
    end
  end

  def render_gate_success
    respond_to do |format|
      format.turbo_stream { render :download, status: :ok }
      format.html do
        if @resource.file.attached?
          redirect_to rails_blob_url(@resource.file, disposition: "attachment"), allow_other_host: false
        else
          redirect_to resource_path(@resource.slug), notice: "Thanks — we'll send the file the moment it's ready."
        end
      end
    end
  end

  def render_gate_failure
    respond_to do |format|
      format.turbo_stream { render :download, status: :unprocessable_entity }
      format.html         { redirect_to resource_path(@resource.slug), alert: @error_message }
    end
  end
end
