class Account::HighlightsController < Account::BaseController
  def index
    @grouped_highlights = current_user.devotional_highlights
                                       .includes(:devotional)
                                       .recent_first
                                       .group_by(&:devotional)
  end
end
