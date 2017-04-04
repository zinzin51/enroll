class FamilyMember
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies

  embedded_in :family
  embeds_many :person_relationships, cascade_callbacks: true, validate: true

  # Person responsible for this family
  field :is_primary_applicant, type: Boolean, default: false

  # Person is applying for coverage
  field :is_coverage_applicant, type: Boolean, default: true

  # Person who authorizes auto-renewal eligibility check
  field :is_consent_applicant, type: Boolean, default: false

  field :is_active, type: Boolean, default: true

  field :person_id, type: BSON::ObjectId
  field :broker_role_id, type: BSON::ObjectId

  # Immediately preceding family where this person was a member
  field :former_family_id, type: BSON::ObjectId

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }
  scope :by_primary_member_role, ->{ where(:is_active => true).where(:is_primary_applicant => true) }
  embeds_many :hbx_enrollment_exemptions
  accepts_nested_attributes_for :hbx_enrollment_exemptions

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  delegate :id, to: :family, prefix: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :first_name, to: :person, allow_nil: true
  delegate :last_name, to: :person, allow_nil: true
  delegate :middle_name, to: :person, allow_nil: true
  delegate :full_name, to: :person, allow_nil: true
  delegate :name_pfx, to: :person, allow_nil: true
  delegate :name_sfx, to: :person, allow_nil: true
  delegate :date_of_birth, to: :person, allow_nil: true
  delegate :dob, to: :person, allow_nil: true
  delegate :ssn, to: :person, allow_nil: true
  delegate :gender, to: :person, allow_nil: true
  # consumer fields
  delegate :race, to: :person, allow_nil: true
  delegate :ethnicity, to: :person, allow_nil: true
  delegate :language_code, to: :person, allow_nil: true
  delegate :is_tobacco_user, to: :person, allow_nil: true
  delegate :is_incarcerated, to: :person, allow_nil: true
  delegate :tribal_id, to: :person, allow_nil: true
  delegate :is_disabled, to: :person, allow_nil: true
  delegate :citizen_status, to: :person, allow_nil: true
  delegate :is_dc_resident?, to: :person, allow_nil: true
  delegate :ivl_coverage_selected, to: :person

  validates_presence_of :person_id, :is_primary_applicant, :is_coverage_applicant

  associated_with_one :person, :person_id, "Person"

  def former_family=(new_former_family)
    raise ArgumentError.new("expected Family") unless new_former_family.is_a?(Family)
    self.former_family_id = new_former_family._id
    @former_family = new_former_family
  end

  def former_family
    return @former_family if defined? @former_family
    @former_family = Family.find(former_family_id) unless former_family_id.blank?
  end

  def parent
    raise "undefined parent family" unless family
    self.family
  end

  def households
    # TODO parent.households.coverage_households.where()
  end

  def broker=(new_broker)
    return unless new_broker.is_a? BrokerRole
    self.broker_role_id = new_broker._id
  end

  def broker
    BrokerRole.find(self.broker_role_id) unless self.broker_role_id.blank?
  end

  def is_primary_applicant?
    self.is_primary_applicant
  end

  def is_consent_applicant?
    self.is_consent_applicant
  end

  def is_coverage_applicant?
    self.is_coverage_applicant
  end

  def is_active?
    self.is_active
  end

  def primary_relationship
    if is_primary_applicant?
      "self"
    else
      family.primary_applicant_person.find_relationship_with(person) unless family.primary_applicant_person.blank? || person.blank?
    end
  end

  def relationship
    primary_relationship
  end

  def reactivate!(relationship)
    family.primary_applicant_person.ensure_relationship_with(person, relationship)
    family.add_family_member(person)
  end

  # def update_relationship(relationship)
  #   return if (primary_relationship == relationship)
  #   family.remove_family_member(person)
  #   self.reactivate!(relationship)
  #   family.save!
  # end

  def self.find(family_member_id)
    return [] if family_member_id.nil?
    family = Family.where("family_members._id" => BSON::ObjectId.from_string(family_member_id)).first
    family.family_members.detect { |member| member._id.to_s == family_member_id.to_s } unless family.blank?
  end

  # Related to Relationship Matrix
  def add_relationship(successor, relationship_kind)
    if same_successor_exists?(successor)
      direct_relationship = family.person_relationships.where(predecessor_id: self.id, successor_id: successor.id).first # Direct Relationship
      inverse_relationship = family.person_relationships.where(predecessor_id: successor.id, successor_id: self.id).first # Inverse Relationship

      # Destroying the Row and Column relationships of the Family Member when updating the Existing VALID Relationship which is not "NIL".
      # if direct_relationship != nil
      #   family.person_relationships.where(predecessor_id: self.id, :id.nin =>[direct_relationship.id]).each(&:destroy)
      #   family.person_relationships.where(successor_id: self.id, :id.nin =>[inverse_relationship.id]).each(&:destroy)
      # end

      direct_relationship.update(kind: relationship_kind)
      inverse_relationship.update(kind: inverse_relationship_kind(relationship_kind))
    else
      if self.id != successor.id
        primary_person = self.family.primary_applicant.person
        family.person_relationships.create(family_id: self.family.id, predecessor_id: self.id, successor_id: successor.id, kind: relationship_kind) # Direct Relationship
        family.person_relationships.create(family_id: self.family.id, predecessor_id: successor.id, successor_id: self.id, kind: inverse_relationship_kind(relationship_kind)) # Inverse Relationship
      end
    end
  end

  def remove_relationship
    family.person_relationships.where(predecessor_id: self.id).each(&:destroy)
    family.person_relationships.where(successor_id: self.id).each(&:destroy)
  end

  def same_successor_exists?(successor)
    family.person_relationships.where(predecessor_id: self.id, successor_id: successor.id).first.present?
  end

  def inverse_relationship_kind(relationship_kind)
    PersonRelationship::InverseMap[relationship_kind]
  end
end
