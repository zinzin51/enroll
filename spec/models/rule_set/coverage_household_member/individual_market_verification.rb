require "rails_helper"

describe RuleSet::CoverageHouseholdMember::IndividualMarketVerification do
  subject { RuleSet::CoverageHouseholdMember::IndividualMarketVerification.new(coverage_household_member) }
  let(:coverage_household_member) { instance_double(CoverageHouseholdMember) }
  states = {"fully_verified" => :move_to_eligible!,
            "verification_period_ended" => :move_to_ineligible!,
            "ineligible" => :move_to_ineligible!,
            "verification_outstanding" => :move_to_contingent!,
            "ssa_pending" => :move_to_contingent!,
            "dhs_pending" => :move_to_contingent!,
            "withdrawn" => :move_to_contingent!}

  states.each do |status, event|
    it "returns #{event} event for member in #{status} status" do
      allow(subject).to receive(:role_for_determination).and_return(status)
      expect(subject.determine_next_state).to eq event
    end
  end
end