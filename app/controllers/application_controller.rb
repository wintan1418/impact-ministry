class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Resume session early (without enforcing it) so current_user is available in views.
  before_action :resume_session

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses.
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Used by ActiveAdmin's `config.authentication_method`. Gates /admin to staff users.
  def authenticate_admin!
    unless signed_in? && current_user.staff?
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path, alert: "Staff access only."
    end
  end

  # Used by ActiveAdmin's `config.on_unauthorized_access` when an editor hits an admin-only resource.
  def access_denied(_exception = nil)
    redirect_to (defined?(admin_root_path) ? admin_root_path : root_path),
                alert: "You don't have access to that section."
  end

  private

  def user_not_authorized
    flash[:alert] = "You don't have access to that."
    redirect_back(fallback_location: root_path)
  end
end
