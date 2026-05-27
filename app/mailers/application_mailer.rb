# Base mailer for the IMPACT Ministry app.
#
# All mailers inherit from this class. Postmark message streams are
# selected per-send via `message_stream_for(:broadcast)` (for the daily
# devotional blast) or `message_stream_for(:transactional)` (for welcomes,
# receipts, password resets, prayer-request confirmations, etc.).
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_FROM_ADDRESS", "team@impactministry.org")
  layout "mailer"

  # Map a semantic kind to the Postmark message stream name.
  #
  # Postmark provisions two default streams on every server:
  #   - "outbound"  — transactional (welcomes, receipts, password reset)
  #   - "broadcast" — bulk marketing / daily devotional sends
  #
  # Use it in a mailer like:
  #
  #   mail(to: subscriber.email,
  #        subject: "Today's devotional",
  #        message_stream: message_stream_for(:broadcast))
  #
  # Unknown kinds fall back to the transactional stream so a typo never
  # accidentally sends a bulk-graded message on the transactional rep.
  def message_stream_for(kind)
    case kind.to_sym
    when :broadcast     then "broadcast"
    when :transactional then "outbound"
    else                     "outbound"
    end
  end
end
