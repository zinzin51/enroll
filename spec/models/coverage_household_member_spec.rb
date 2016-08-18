require 'rails_helper'
require 'aasm/rspec'


describe CoverageHouseholdMember do
  describe "state machine" do
    let(:family_member) { FamilyMember.new }
    let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id, :coverage_household => CoverageHousehold.new ) }

    context "move_to_contingent!" do
      it "moves from applicant to contingent" do
        expect(coverage_household_member).to transition_from(:applicant).to(:contingent).on_event(:move_to_contingent)
      end

      it "moves from contingent to contingent" do
        expect(coverage_household_member).to transition_from(:contingent).to(:contingent).on_event(:move_to_contingent)
      end

      it "records transition with callback" do
        expect(coverage_household_member).to receive(:record_transition)
        coverage_household_member.move_to_contingent!
      end
    end

    context "move_to_eligible!" do
      it "moves from applicant to eligible" do
        expect(coverage_household_member).to transition_from(:applicant).to(:eligible).on_event(:move_to_eligible)
      end

      it "moves from ineligible to eligible" do
        expect(coverage_household_member).to transition_from(:ineligible).to(:eligible).on_event(:move_to_eligible)
      end

      it "moves from eligible to eligible" do
        expect(coverage_household_member).to transition_from(:eligible).to(:eligible).on_event(:move_to_eligible)
      end

      it "moves from contingent to move_to_eligible" do
        expect(coverage_household_member).to transition_from(:contingent).to(:eligible).on_event(:move_to_eligible)
      end

      it "records transition with callback" do
        expect(coverage_household_member).to receive(:record_transition)
        coverage_household_member.move_to_eligible!
      end
    end

    context "move_to_ineligible!" do
      it "moves from applicant to contingent" do
        expect(coverage_household_member).to transition_from(:applicant).to(:ineligible).on_event(:move_to_ineligible)
      end

      it "moves from contingent to ineligible" do
        expect(coverage_household_member).to transition_from(:contingent).to(:ineligible).on_event(:move_to_ineligible)
      end

      it "moves from ineligible to ineligible" do
        expect(coverage_household_member).to transition_from(:ineligible).to(:ineligible).on_event(:move_to_ineligible)
      end

      it "records transition with callback" do
        expect(coverage_household_member).to receive(:record_transition)
        coverage_household_member.move_to_ineligible!
      end
    end
  end
end