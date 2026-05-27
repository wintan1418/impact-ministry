class GivingController < ApplicationController
  # Live Stripe Checkout flow lands in Phase 3 (3.13–3.20). Until
  # GIVING_ENABLED=true is set, we render the dignified "pre-501(c)(3)"
  # placeholder per CLAUDE.md §5.
  def show
    @giving_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("GIVING_ENABLED", false))
    @placeholder_copy = Setting.get(:giving_placeholder_copy)
  end
end
