class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :coverage_household

  embeds_many :workflow_state_transitions, as: :transitional

  field :family_member_id, type: BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false
  field :aasm_state
  field :verification_init, type: DateTime, default: DateTime.now

  # def save_parent
  #   coverage_household.save
  # end

  include BelongsToFamilyMember

  scope :unverified, -> { where(:verification_init.ne => nil ).or({ :aasm_state => "ineligible" },{ :aasm_state => "contingent" }).order(verification_init: :desc)}

  aasm do
    state :applicant, initial: true
    state :contingent
    state :ineligible
    state :eligible


    event :move_to_contingent, :after => :record_transition do
      transitions from: :applicant, to: :contingent
      transitions from: :contingent, to: :contingent
    end

    event :move_to_eligible, :after => :record_transition do
      transitions from: :applicant, to: :eligible
      transitions from: :contingent, to: :eligible
      transitions from: :ineligible, to: :eligible
      transitions from: :eligible, to: :eligible
    end

    event :move_to_ineligible, :after => :record_transition do
      transitions from: :applicant, to: :ineligible
      transitions from: :contingent, to: :ineligible
      transitions from: :ineligible, to: :ineligible
    end

  end

  def self.update_individual_eligibilities_for(consumer_role)
    found_families = Family.find_all_by_person(consumer_role.person)
    found_families.each do |ff|
      ff.households.each do |hh|
        hh.coverage_households.each do |ch|
          ch.coverage_household_members.each do |ch_member|
            ch_member.evaluate_individual_market_eligiblity if ch_member.family_member.person.consumer_role.id == consumer_role.id
          end
        end
        hh.hbx_enrollments.each do |he|
          he.evaluate_individual_market_eligiblity
        end
      end
    end
  end

  def evaluate_individual_market_eligiblity
    eligibility_ruleset = ::RuleSet::CoverageHouseholdMember::IndividualMarketVerification.new(self)
    self.send(eligibility_ruleset.determine_next_state)
  end

  def family
    coverage_household.household.family
  end

  def family_member=(new_family_member)
    self.family_member_id = new_family_member._id
    @family_member = new_family_member
  end

  def family_member
    return @family_member if defined? @family_member
    @family_member = family.family_members.find(family_member_id) if family_member_id.present?
  end

  def applicant=(new_applicant)
    @applicant = new_applicant
  end

  def applicant
    return @applicant if defined? @applicant
    @applicant = family_member
  end

  def is_subscriber?
    self.is_subscriber
  end

  private
  def record_transition(*args)
    workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
    )
  end
end
