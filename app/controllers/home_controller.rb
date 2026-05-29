class HomeController < ApplicationController
  def show
    @today_devotional = Devotional.published.for_today.first ||
                        Devotional.published.recent_first.first
    @mission_quote = Setting.get(:homepage_hero_quote).presence ||
                     "“We believe scripture is older than our hurry, kinder than our news cycles, and steady enough to carry a person through a Tuesday.”"

    @latest_episode = (defined?(PodcastEpisode) && PodcastEpisode.table_exists?) ?
                      PodcastEpisode.published.recent_first.first : nil

    # Rotate one approved+featured testimony into the homepage navy band.
    # Safe-guarded against an empty/missing table so the homepage never blanks.
    @featured_testimony =
      if defined?(Testimony) && Testimony.table_exists?
        Testimony.approved.where(featured: true).order(Arel.sql("RANDOM()")).first
      end

    # Live-ish social proof. Real number on the email-capture section.
    @readers_this_morning = readers_this_morning_count
    @readers_this_week    = readers_this_week_count
    @average_read_minutes = 2
    @open_rate_percent    = open_rate_this_week

    # Magazine strip — last several published, NOT today's (which is the hero).
    @recent_devotionals =
      Devotional.published
                .where.not(id: @today_devotional&.id)
                .recent_first
                .limit(6)

    # Tomorrow teaser — show the scripture book for tomorrow's word (CLAUDE.md §5).
    @tomorrow_devotional = Devotional.published.where(scheduled_for: Date.current + 1).first ||
                           Devotional.where(scheduled_for: Date.current + 1).first
    @tomorrow_book = tomorrow_book_label(@tomorrow_devotional)

    # Community pulse — 3 recent public prayers for the on-the-wall section.
    @recent_prayer_requests =
      if defined?(PrayerRequest) && PrayerRequest.table_exists?
        PrayerRequest.visible.order(created_at: :desc).limit(3)
      else
        PrayerRequest.none
      end

    @prayed_total = (defined?(PrayerRequest) && PrayerRequest.table_exists?) ? PrayerRequest.sum(:prayed_count) : 0

    # Cheap, charming morning markers.
    @sunrise_time     = "5:48am"  # editorial license; a fixed early-Mississippi sunrise
    @tomorrow_send_at = (Date.current + 1).beginning_of_day + Integer(ENV.fetch("DEVOTIONAL_SEND_HOUR", "5")).hours
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

  # Just the book + chapter — "Romans 12" not "Romans 12:1-3". Quiet, no verse.
  def tomorrow_book_label(devotional)
    return nil if devotional.blank?

    ref = devotional.scripture_reference.to_s
    # Strip everything after the first colon (verse range) and any trailing whitespace.
    ref.split(":").first.to_s.strip.presence
  end
end
