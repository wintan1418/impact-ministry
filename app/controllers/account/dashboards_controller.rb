class Account::DashboardsController < Account::BaseController
  def show
    @today              = Devotional.published.for_today.first
    @recent_devotionals = Devotional.published.recent_first.limit(5)
    @streak             = current_user.current_streak
    @longest            = current_user.longest_streak
    @last_read          = current_user.last_read_on
    @recent_highlights  = current_user.devotional_highlights.recent_first.limit(3).includes(:devotional)
    @total_highlights   = current_user.devotional_highlights.count
  end
end
