require "rails_helper"

RSpec.describe StreakRecalculationJob, type: :job do
  # Anchor "today" to mid-day Central so any UTC <-> local conversions in
  # the job's default_date helper land on the date we expect.
  let(:today) { Date.new(2026, 5, 28) }

  around do |example|
    travel_to(Time.zone.parse("2026-05-28 12:00:00")) { example.run }
  end

  def create_delivery_opened_on(user, date)
    subscriber = create(:email_subscriber, email: user.email_address)
    devotional = create(:devotional, scheduled_for: date)
    create(
      :devotional_delivery,
      email_subscriber: subscriber,
      devotional:       devotional,
      sent_at:          date.to_time.change(hour: 6),
      opened_at:        date.to_time.change(hour: 8)
    )
  end

  def create_highlight_on(user, date)
    devotional = create(:devotional, scheduled_for: date)
    DevotionalHighlight.create!(
      user:       user,
      devotional: devotional,
      text_range: { start: 0, end: 10, text: "highlight" }.to_json,
      saved_at:   date.to_time.change(hour: 9)
    )
  end

  describe "#perform — streak transitions" do
    it "case 1: first read ever — streak goes from 0 to 1 and longest catches up" do
      user = create(:user, current_streak: 0, longest_streak: 0, last_read_on: nil)
      create_delivery_opened_on(user, today)

      described_class.new.perform(date: today)

      user.reload
      expect(user.current_streak).to eq(1)
      expect(user.longest_streak).to eq(1)
      expect(user.last_read_on).to eq(today)
    end

    it "case 2: consecutive day — current streak ticks from N to N+1 and longest grows" do
      user = create(
        :user,
        current_streak: 4,
        longest_streak: 4,
        last_read_on:   today - 1
      )
      create_highlight_on(user, today)

      described_class.new.perform(date: today)

      user.reload
      expect(user.current_streak).to eq(5)
      expect(user.longest_streak).to eq(5)
      expect(user.last_read_on).to eq(today)
    end

    it "case 3: same-day re-read — no change (idempotent)" do
      user = create(
        :user,
        current_streak: 7,
        longest_streak: 9,
        last_read_on:   today
      )
      create_delivery_opened_on(user, today)

      expect {
        described_class.new.perform(date: today)
      }.not_to(change { user.reload.attributes.slice("current_streak", "longest_streak", "last_read_on") })
    end

    it "case 4: streak broken, but the user read today — resets to 1 without lowering longest" do
      user = create(
        :user,
        current_streak: 12,
        longest_streak: 12,
        last_read_on:   today - 5
      )
      create_delivery_opened_on(user, today)

      described_class.new.perform(date: today)

      user.reload
      expect(user.current_streak).to eq(1)
      expect(user.longest_streak).to eq(12)
      expect(user.last_read_on).to eq(today)
    end

    it "case 5: no read today and last read 2+ days ago — current resets to 0, last_read_on unchanged" do
      user = create(
        :user,
        current_streak: 6,
        longest_streak: 10,
        last_read_on:   today - 3
      )

      described_class.new.perform(date: today)

      user.reload
      expect(user.current_streak).to eq(0)
      expect(user.longest_streak).to eq(10)
      expect(user.last_read_on).to eq(today - 3)
    end
  end

  describe "#perform — role scoping and signal sources" do
    it "skips visitor-role users entirely" do
      visitor = create(:user, role: "visitor", current_streak: 3, last_read_on: today - 1)
      create_delivery_opened_on(visitor, today)

      described_class.new.perform(date: today)

      visitor.reload
      expect(visitor.current_streak).to eq(3)
      expect(visitor.last_read_on).to eq(today - 1)
    end

    it "matches DevotionalDelivery email case-insensitively" do
      user = create(
        :user,
        email_address: "mixedcase@example.test",
        current_streak: 0,
        last_read_on:   nil
      )
      # EmailSubscriber.normalizes downcases on write; force the
      # stored value to be uppercased to prove the LOWER() match works.
      subscriber = create(:email_subscriber, email: "MIXEDCASE@EXAMPLE.TEST")
      subscriber.update_column(:email, "MIXEDCASE@EXAMPLE.TEST")
      devotional = create(:devotional, scheduled_for: today)
      create(
        :devotional_delivery,
        email_subscriber: subscriber,
        devotional:       devotional,
        sent_at:          today.to_time.change(hour: 6),
        opened_at:        today.to_time.change(hour: 8)
      )

      described_class.new.perform(date: today)

      expect(user.reload.current_streak).to eq(1)
    end

    it "logs a summary line counting processed / ticked / broken users" do
      # Only count users that are streak-eligible. Use a visitor as the
      # devotional author so they don't show up in the processed total.
      author = create(:user, role: "visitor")
      ticker = create(:user, current_streak: 0, last_read_on: nil)
      breaker = create(:user, current_streak: 4, last_read_on: today - 5)

      devotional = create(:devotional, scheduled_for: today, author: author)
      DevotionalHighlight.create!(
        user:       ticker,
        devotional: devotional,
        text_range: { start: 0, end: 5, text: "hello" }.to_json,
        saved_at:   today.to_time.change(hour: 9)
      )
      _ = breaker

      expect(Rails.logger).to receive(:info).with(
        /processed 2 users; 1 streaks ticked; 1 broken\./
      )

      described_class.new.perform(date: today)
    end
  end

  describe "queue" do
    it "enqueues onto :default" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
