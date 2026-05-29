# Highlights are personal — only the owner can read or destroy them.
# Even though HighlightsController scopes its queries through
# `current_user.devotional_highlights` (so a foreign id would 404 by
# missing-record before authorization), this policy makes the rule
# explicit at the controller layer per CLAUDE.md §3.
class DevotionalHighlightPolicy < ApplicationPolicy
  def index?   = user.present?
  def show?    = owner?
  def create?  = user.present?
  def destroy? = owner?

  private

  def owner?
    user.present? && record.respond_to?(:user_id) && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(user_id: user.id)
    end
  end
end
