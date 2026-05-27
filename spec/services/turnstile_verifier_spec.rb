require "rails_helper"

RSpec.describe TurnstileVerifier do
  describe ".call" do
    context "in the test environment (short-circuit)" do
      it "returns a success result for an ordinary token" do
        result = described_class.call(token: "anything")

        expect(result).to be_success
        expect(result.errors).to eq([])
      end

      it "returns a success result for an empty/nil token (test env always passes)" do
        result = described_class.call(token: nil)

        expect(result).to be_success
      end

      it "returns a failure result when the token is the literal 'FORCE_FAIL'" do
        result = described_class.call(token: "FORCE_FAIL")

        expect(result).not_to be_success
        expect(result.errors).to be_an(Array)
        expect(result.errors).not_to be_empty
      end

      it "accepts a remote_ip argument without erroring" do
        expect {
          described_class.call(token: "ok", remote_ip: "203.0.113.5")
        }.not_to raise_error
      end
    end

    describe "result object shape" do
      it "exposes success? and errors on success" do
        result = described_class.call(token: "ok")

        expect(result).to respond_to(:success?)
        expect(result).to respond_to(:errors)
        expect(result.success?).to be(true)
        expect(result.errors).to eq([])
      end

      it "exposes success? and errors on failure" do
        result = described_class.call(token: "FORCE_FAIL")

        expect(result.success?).to be(false)
        expect(result.errors).to all(be_a(String))
      end
    end
  end
end
