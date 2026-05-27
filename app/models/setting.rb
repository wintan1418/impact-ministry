# Key/value configuration store used for ministry-controllable flags and copy
# that should be editable without a deploy. Reads cached for 60 seconds.
#
# See docs/DOMAIN.md ("Setting") and CLAUDE.md §3 (feature flags).
class Setting < ApplicationRecord
  KINDS = %w[string boolean integer json].freeze

  enum :kind, KINDS.zip(KINDS).to_h, default: "string", validate: true

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  after_save    -> { Rails.cache.delete(self.class.cache_key_for(key)) }
  after_destroy -> { Rails.cache.delete(self.class.cache_key_for(key)) }

  # Read a setting by key, with a short Rails.cache window.
  # Returns nil if the key is unknown.
  def self.get(key)
    cache_key = cache_key_for(key)
    Rails.cache.fetch(cache_key, expires_in: 60.seconds) do
      record = find_by(key: key.to_s)
      next nil unless record

      cast(record.value, record.kind)
    end
  end

  # Write a setting by key. Creates if missing; updates if present.
  # Optionally accepts `kind:` to set/change the cast type at the same time.
  def self.set(key, value, kind: nil)
    record = find_or_initialize_by(key: key.to_s)
    record.kind  = kind if kind
    record.value = serialize(value, record.kind)
    record.save!
    Rails.cache.delete(cache_key_for(key))
    record
  end

  def self.cache_key_for(key)
    "setting:#{key}"
  end

  # Cast a stored string value back into its typed form.
  def self.cast(value, kind)
    return nil if value.nil?

    case kind
    when "boolean"
      ActiveModel::Type::Boolean.new.cast(value)
    when "integer"
      Integer(value)
    when "json"
      JSON.parse(value)
    else
      value.to_s
    end
  end

  # Serialize a typed value into the text column.
  def self.serialize(value, kind)
    return nil if value.nil?

    case kind
    when "json"
      value.is_a?(String) ? value : JSON.generate(value)
    else
      value.to_s
    end
  end
end
