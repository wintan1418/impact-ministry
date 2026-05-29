class Account::DonationsController < Account::BaseController
  before_action :load_donor

  def index
    @donations = @donor&.donations&.recent_first&.limit(50) || Donation.none
    @has_recurring = @donations.any? { |d| d.recurring? && d.stripe_subscription_id.present? }
  end

  def portal
    if @donor.nil? || @donor.stripe_customer_id.blank?
      redirect_to account_donations_path, alert: "You don't have a billing portal yet — no recurring gift on file."
      return
    end

    result = Giving::CreateBillingPortalSession.call(
      donor: @donor,
      return_url: account_donations_url
    )

    if result.success?
      redirect_to result.value.url, allow_other_host: true, status: :see_other
    else
      redirect_to account_donations_path, alert: result.error
    end
  end

  private

  def load_donor
    @donor = Donor.find_by(user: current_user) ||
             Donor.find_by("LOWER(email) = ?", current_user.email_address.to_s.downcase)
  end
end
