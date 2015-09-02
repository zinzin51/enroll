class InsuredEligibleForBenefitRule

  # Insured role can be: EmployeeRole, ConsumerRole, ResidentRole


  # ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
  #     us_citizen
  #     naturalized_citizen
  #     indian_tribe_member
  #     alien_lawfully_present
  #     lawful_permanent_resident
  # )

  def initialize(role, benefit_package)
    @role = role
    @benefit_package = benefit_package
  end

  def setup
    hbx = HbxProfile.find_by_state_abbreviation("dc")
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bp| bp.start_on.year == 2015 }
    ivl_health_benefits_2015 = bc_period.benefit_packages.detect { |bp| bp.title == "individual_health_benefits_2015" }

    person = Person.where(last_name: "Murray").entries.first
    if person.consumer_role.nil?
      consumer_role = person.build_consumer_role(is_applicant: true)
      consumer_role.save!
      consumer_role
    else
      consumer_role = person.consumer_role
    end

    # rule = InsuredEligibleForBenefitRule.new(consumer_role, ivl_health_benefits_2015)
    # rule.satisfied?
  end

  def satisfied?
    if @role.class.name == "ConsumerRole"
      @errors = []
      status = @benefit_package.benefit_eligibility_element_group.class.fields.keys.reject{|k| k == "_id"}.reduce(true) do |eligible, element|
        if self.public_send("is_#{element}_satisfied?")
          true && eligible
        else
          @errors << ["eligibility failed on #{element}"]
          false
        end
      end
      return status, @errors
    end
  end

  def is_market_places_satisfied?
    true
  end

  def is_enrollment_periods_satisfied?
    true
  end

  def is_family_relationships_satisfied?
    true
  end

  def is_benefit_categories_satisfied?
    true
  end

  def is_citizenship_status_satisfied?
    true
  end

  def is_ethnicity_satisfied?
    true
  end

  def is_residency_status_satisfied?
    return true if @benefit_package.residency_status.include?("any")
    if @benefit_package.residency_status.include?("state_resident")
      addresses = @role.person.addresses
      return true if !addresses || addresses.count == 0 #TEMPORARY CODE FOR DEPENDENTS FIXME TOD
      address_to_use = addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
      addresses.each{|address| return true if address.kind == address_to_use && address.state == 'DC'}
    end
    return false
  end

  def is_incarceration_status_satisfied?
    return true if @benefit_package.incarceration_status.include?("any")
    @benefit_package.incarceration_status.include?("unincarcerated") && !@role.is_incarcerated?
  end

  def is_age_range_satisfied?
    return true # if @benefit_package.age_range == 0..0

    age = age_on_next_effective_date(@role.dob)
    @benefit_package.age_range.cover?(age)
  end

  def determination_results
    @errors
  end

  # def fails_market_places?
  #   if passes
  #     false
  #   else
  #     reason
  #   end
  # end

  def age_on_next_effective_date(dob)
    today = TimeKeeper.date_of_record
    today.day <= 15 ? age_on = today.end_of_month + 1.day : age_on = (today + 1.month).end_of_month + 1.day
    age_on.year - dob.year - ((age_on.month > dob.month || (age_on.month == dob.month && age_on.day >= dob.day)) ? 0 : 1)
  end

end
