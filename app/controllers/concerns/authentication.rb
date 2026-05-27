module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :authenticated?, :signed_in?
  end

  class_methods do
    # Rails 8's `bin/rails generate authentication` opts every controller into
    # `require_authentication` and asks unauth-friendly controllers to opt out
    # via this helper. Per CLAUDE.md §3 we invert that — auth is opt-in per
    # controller (`before_action :require_authentication`). This helper becomes
    # a no-op so generated controllers using it continue to load cleanly.
    def allow_unauthenticated_access(**_options)
      # intentional no-op
    end

    # Inverse helper for the controllers that *do* require auth.
    def require_authentication(**options)
      before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end
  alias_method :signed_in?, :authenticated?

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    return unless cookies.signed[:session_id]
    Session.find_by(id: cookies.signed[:session_id])
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |new_session|
      Current.session = new_session
      cookies.signed.permanent[:session_id] = { value: new_session.id, httponly: true, same_site: :lax }
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end
