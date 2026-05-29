module Giving
  # Tiny result object returned by Giving service objects so callers can
  # branch on .success? without exception flow. See CLAUDE.md §3 — services
  # return a result, not a boolean.
  Result = Struct.new(:success, :value, :error, keyword_init: true) do
    def success? = !!success
    def failure? = !success?
  end
end
