class GivingController < ApplicationController
  # /give — when GIVING_ENABLED=true, render the live Stripe Checkout form;
  # otherwise the dignified "pre-501(c)(3)" placeholder (CLAUDE.md §5).
  def show
    @giving_enabled   = giving_enabled?
    @placeholder_copy = Setting.get(:giving_placeholder_copy)
  end

  # POST /give — builds a Stripe Checkout Session and redirects.
  def create
    unless giving_enabled?
      redirect_to give_path, alert: "Giving isn't open yet."
      return
    end

    result = Giving::CreateCheckoutSession.call(
      amount_cents: parsed_amount_cents,
      frequency:    params[:frequency],
      designation:  params[:designation],
      email:        params[:email],
      name:         params[:donor_name],
      success_url:  give_thanks_url,
      cancel_url:   give_url
    )

    if result.success?
      redirect_to result.value.url, allow_other_host: true, status: :see_other
    else
      flash.now[:alert] = result.error
      @giving_enabled = true
      @placeholder_copy = nil
      render :show, status: :unprocessable_entity
    end
  end

  # GET /give/thanks — Stripe redirects here on success. We don't trust the
  # session_id for state mutation (that's the webhook's job); just show a
  # quiet thank-you.
  def thanks
    @session_id = params[:session_id]
  end

  private

  def giving_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("GIVING_ENABLED", false))
  end

  def parsed_amount_cents
    raw = params[:amount].to_s.strip
    return 0 if raw.blank?
    # Allow $25, 25, 25.00 — convert to cents.
    cleaned = raw.delete("$").delete(",")
    (cleaned.to_f * 100).round
  end
end
