# frozen_string_literal: true

# Mix into any controller whose create action handles a public form.
# Per CLAUDE.md §3: every public form is Turnstile-protected.
#
# Usage:
#   class ContactController < ApplicationController
#     include TurnstileProtectable
#
#     def create
#       return render :new, status: :unprocessable_entity unless verify_turnstile!
#       # ...
#     end
#   end
module TurnstileProtectable
  extend ActiveSupport::Concern

  def verify_turnstile!
    token = params["cf-turnstile-response"]
    result = TurnstileVerifier.call(token: token, remote_ip: request.remote_ip)
    return true if result.success?

    flash.now[:alert] = "We couldn't verify you're human. Please try again."
    false
  end
end
