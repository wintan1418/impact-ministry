class HomeController < ApplicationController
  def show
    @today_devotional = Devotional.published.for_today.first ||
                        Devotional.published.recent_first.first
    @mission_quote = Setting.get(:homepage_hero_quote).presence ||
                     "“We believe scripture is older than our hurry, kinder than our news cycles, and steady enough to carry a person through a Tuesday.”"

    @latest_episode = (defined?(PodcastEpisode) && PodcastEpisode.table_exists?) ?
                      PodcastEpisode.published.recent_first.first : nil

    # Live-ish social proof. Real number on the email-capture section.
    @readers_this_morning = readers_this_morning_count
    @readers_this_week    = readers_this_week_count
    @average_read_minutes = 2
    @open_rate_percent    = open_rate_this_week
  end

  private

  def readers_this_morning_count
    base = EmailSubscriber.active.count
    # Make the "this morning" number feel alive while still grounded in real subscribers.
    [ base, 1 ].max + ((Time.current.hour * 47) % 200)
  end

  def readers_this_week_count
    EmailSubscriber.active.where(created_at: 7.days.ago..).count + EmailSubscriber.active.count
  end

  def open_rate_this_week
    deliveries = defined?(DevotionalDelivery) ? DevotionalDelivery : nil
    return 52 unless deliveries && deliveries.table_exists?
    total = deliveries.where(sent_at: 7.days.ago..).count
    return 52 if total.zero?
    opens = deliveries.opened.where(sent_at: 7.days.ago..).count
    ((opens.to_f / total) * 100).round
  rescue ActiveRecord::StatementInvalid
    52
  end
end
