require "rails_helper"

RSpec.describe DevotionalHighlightPolicy do
  subject(:policy) { described_class.new(actor, highlight) }

  let(:owner)      { create(:user, :confirmed) }
  let(:other)      { create(:user, :confirmed) }
  let(:devotional) { create(:devotional, :published, :with_body) }
  let(:highlight)  { create(:devotional_highlight, user: owner, devotional: devotional) }

  describe "#destroy?" do
    context "as the owner" do
      let(:actor) { owner }
      it { expect(policy.destroy?).to be true }
    end

    context "as another signed-in user" do
      let(:actor) { other }
      it { expect(policy.destroy?).to be false }
    end

    context "anonymous" do
      let(:actor) { nil }
      it { expect(policy.destroy?).to be false }
    end
  end

  describe "#show?" do
    context "owner sees their own" do
      let(:actor) { owner }
      it { expect(policy.show?).to be true }
    end

    context "stranger cannot" do
      let(:actor) { other }
      it { expect(policy.show?).to be false }
    end
  end

  describe "#create?" do
    let(:actor) { other }
    it "is allowed for any signed-in user (the controller scopes to themselves)" do
      expect(policy.create?).to be true
    end
  end

  describe "Scope" do
    it "returns only the user's highlights" do
      create(:devotional_highlight, user: other, devotional: devotional)
      create(:devotional_highlight, user: owner, devotional: devotional)
      resolved = described_class::Scope.new(owner, DevotionalHighlight.all).resolve
      expect(resolved.pluck(:user_id).uniq).to eq([ owner.id ])
    end

    it "returns nothing for an anonymous user" do
      create(:devotional_highlight, user: owner, devotional: devotional)
      resolved = described_class::Scope.new(nil, DevotionalHighlight.all).resolve
      expect(resolved).to be_empty
    end
  end
end
