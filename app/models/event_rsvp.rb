# EventRsvp — a single seat reservation for an Event. One row per email per
# event (case-insensitively enforced). Party size handles "+1" attendance.
#
# Anonymous-first: no FK to User. We surface RSVPs back to the attendee via
# the saved email + a Turbo Stream confirmation.
class EventRsvp < ApplicationRecord
  belongs_to :event

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false, scope: :event_id }
  validates :party_size, presence: true,
                         numericality: {
                           only_integer: true,
                           greater_than: 0,
                           less_than_or_equal_to: 10
                         }
  validates :notes, length: { maximum: 2_000 }, allow_blank: true

  validate :capacity_not_exceeded, on: :create

  private

  def capacity_not_exceeded
    return unless event&.capacity.present?
    return unless party_size.is_a?(Integer) && party_size.positive?

    if event.rsvp_seat_count + party_size > event.capacity
      errors.add(:party_size, "would exceed the seats still available for this gathering")
    end
  end
end
