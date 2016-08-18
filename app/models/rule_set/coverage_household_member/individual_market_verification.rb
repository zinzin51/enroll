module RuleSet
  module CoverageHouseholdMember
    class IndividualMarketVerification
      attr_reader :coverage_household_member

      ELIGIBLE_STATES = %w(fully_verified)
      INELIGIBLE_STATES = %w(verification_period_ended ineligible )
      CONTINGENT_STATES = %w(verification_outstanding ssa_pending dhs_pending withdrawn unverified)

      def initialize(ch_member)
        @coverage_household_member = ch_member
      end

      def role_for_determination
        coverage_household_member.family_member.person.consumer_role.aasm_state
      end

      def determine_next_state
        return(:move_to_ineligible!) if INELIGIBLE_STATES.include? role_for_determination
        return(:move_to_contingent!) if CONTINGENT_STATES.include? role_for_determination
        :move_to_eligible! if role_for_determination == "fully_verified"
      end
    end
  end
end
