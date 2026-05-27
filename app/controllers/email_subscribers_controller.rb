# Public email capture endpoint. Mounted at:
#
#   POST   /subscribe                    → #create
#   GET    /unsubscribe/:token           → #confirm_unsubscribe
#   DELETE /unsubscribe/:token           → #destroy
#
# Submissions are Turbo Stream by default — the controller replaces the
# `email-capture-<source>` turbo frame with either a quiet confirmation or
# the form re-rendered with an inline error (no toast — see CLAUDE.md §3).
#
# CSRF protection stays on; the Rails form helper supplies the token.
class EmailSubscribersController < ApplicationController
  include TurnstileProtectable

  before_action :find_subscriber_by_token, only: %i[confirm_unsubscribe destroy]

  def create
    @source = resolve_source

    unless verify_turnstile!
      flash.delete(:alert) # we don't toast — error renders inline in the frame
      @subscriber = build_subscriber_for_render
      @error_message = "We couldn't verify you're human. Please try again."
      render_capture_failure
      return
    end

    @subscriber = EmailSubscriber.find_by("lower(email) = ?", submitted_email)

    if @subscriber
      handle_existing_subscriber
    else
      handle_new_subscriber
    end
  end

  def confirm_unsubscribe
    # GET /unsubscribe/:token — confirmation page (no destructive action on GET).
  end

  def destroy
    @subscriber.unsubscribe! if @subscriber.active?
    render :unsubscribed
  end

  private

  def find_subscriber_by_token
    @subscriber = EmailSubscriber.find_by(token: params[:token])
    head :not_found unless @subscriber
  end

  def subscriber_params
    if params[:email_subscriber].present?
      params.require(:email_subscriber).permit(:email, :name, :source)
    else
      params.permit(:email, :name, :source)
    end
  end

  def submitted_email
    subscriber_params[:email].to_s.strip.downcase
  end

  def resolve_source
    raw = subscriber_params[:source].to_s
    EmailSubscriber::SOURCES.include?(raw) ? raw : "manual"
  end

  def build_subscriber_for_render
    EmailSubscriber.new(
      email: subscriber_params[:email],
      name: subscriber_params[:name],
      source: @source
    )
  end

  def handle_existing_subscriber
    if @subscriber.active?
      # Idempotent: don't re-enqueue welcome, don't churn timestamps.
      render_capture_success
    else
      @subscriber.source = @source if @subscriber.source.blank? || @subscriber.source == "manual"
      @subscriber.resubscribe!
      WelcomeEmailJob.perform_later(@subscriber.id)
      render_capture_success
    end
  end

  def handle_new_subscriber
    @subscriber = EmailSubscriber.new(
      email: subscriber_params[:email],
      name: subscriber_params[:name],
      source: @source
    )

    if @subscriber.save
      WelcomeEmailJob.perform_later(@subscriber.id)
      render_capture_success
    else
      @error_message = @subscriber.errors[:email].first.presence || "Please enter a valid email."
      render_capture_failure
    end
  end

  def render_capture_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to safe_after_subscribe_path, notice: "See you tomorrow morning." }
    end
  end

  def render_capture_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { redirect_back fallback_location: root_path, alert: @error_message }
    end
  end

  def safe_after_subscribe_path
    # /devotionals/today is owned by a parallel agent. Try it; fall back to root.
    url_for(controller: "devotionals", action: "today")
  rescue ActionController::UrlGenerationError, NoMethodError
    root_path
  end
end
