module Employers::EmployerHelper
  def address_kind
    @family.try(:census_employee).try(:address).try(:kind) || 'home'
  end

  def enrollment_state(census_employee=nil)
    humanize_enrollment_states(census_employee.active_benefit_group_assignment)
  end

  def renewal_enrollment_state(census_employee=nil)
    humanize_enrollment_states(census_employee.renewal_benefit_group_assignment)
  end

  def humanize_enrollment_states(benefit_group_assignment)
    enrollment_states = []

    if benefit_group_assignment
      enrollments = benefit_group_assignment.hbx_enrollments

      %W(health dental).each do |coverage_kind|
        if coverage = enrollments.detect{|enrollment| enrollment.coverage_kind == coverage_kind}
          enrollment_states << "#{benefit_group_assignment_status(coverage.aasm_state)} (#{coverage_kind})"
        end
      end
      enrollment_states << '' if enrollment_states.compact.empty?
    end

    "#{enrollment_states.compact.join('<br/> ').titleize.to_s}".html_safe
    
  end

  def benefit_group_assignment_status(enrollment_status)
    assignment_mapping = {
      'coverage_renewing' => HbxEnrollment::RENEWAL_STATUSES,
      'coverage_terminated' => HbxEnrollment::TERMINATED_STATUSES,
      'coverage_selected' => HbxEnrollment::ENROLLED_STATUSES,
      'coverage_waived' => HbxEnrollment::WAIVED_STATUSES
    }

    assignment_mapping.each do |bgsm_state, enrollment_statuses|
      if enrollment_statuses.include?(enrollment_status.to_s)
        return bgsm_state
      end
    end
  end

  def render_plan_offerings(benefit_group)

    assignment_mapping.each do |bgsm_state, enrollment_statuses|
      if enrollment_statuses.include?(enrollment_status.to_s)
        return bgsm_state
      end
    end
  end

  def self.render_employee_contacts_json(staff, offices)
      #TODO null handling
      staff.map do |s| 
                { 
                  first: s.first_name, last: s.last_name, phone: s.work_phone.to_s,
                  mobile: s.mobile_phone.to_s, emails: [s.work_email_or_best]
                }
             end + offices.map do |loc|
                {
                  first: loc.address.kind.capitalize, last: "Office", phone: loc.phone.to_s, 
                  address_1: loc.address.address_1, address_2: loc.address.address_2,
                  city: loc.address.city, state: loc.address.state, zip: loc.address.zip
                }
             end
  end

  def self.render_employer_summary_json(employer_profile: nil, year: nil, num_enrolled: nil, 
                                        num_waived: nil, staff: nil, offices: nil, 
                                        include_details_url: false)
    renewals_offset_in_months = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months

    summary = { 
      employer_name: employer_profile.legal_name,
      employees_total: employer_profile.roster_size,   
      employees_enrolled:             num_enrolled,  
      employees_waived:               num_waived,
      open_enrollment_begins:         year ? year.open_enrollment_start_on                 : nil,
      open_enrollment_ends:           year ? year.open_enrollment_end_on                   : nil,
      plan_year_begins:               year ? year.start_on                                 : nil,
      renewal_in_progress:            year ? year.is_renewing?                             : nil,
      renewal_application_available:  year ? (year.start_on >> renewals_offset_in_months)  : nil,
      renewal_application_due:        year ? year.due_date_for_publish                     : nil,
      binder_payment_due:             "",
      minimum_participation_required: year ? year.minimum_enrolled_count                   : nil,
    }
    if staff or offices then
      summary[:contact_info] = render_employee_contacts_json(staff || [], offices || [])
    end
    if include_details_url then
      summary[:employer_details_url] = Rails.application.routes.url_helpers.employers_employer_profile_employer_details_api_path(employer_profile.id)
    end
    summary
  end

  def self.render_employer_details_json(employer_profile: nil, year: nil, num_enrolled: nil, 
                                        num_waived: nil, total_premium: nil, 
                                        employer_contribution: nil, employee_contribution: nil)
    details = render_employer_summary_json(employer_profile: employer_profile, year: year, 
                                           num_enrolled: num_enrolled, num_waived: num_waived)
    details[:total_premium] = total_premium
    details[:employer_contribution] = employer_contribution
    details[:employee_contribution] = employee_contribution
    details[:active_general_agency] = employer_profile.active_general_agency_legal_name # Note: queries DB
    details
  end

  def self.get_benefit_group_assignments_for_plan_year(plan_year)
      #check if the plan year is in renewal without triggering an additional query
      in_renewal = plan_year.is_renewing_published?
      benefit_group_ids = plan_year.benefit_groups.map(&:id)
      employees = CensusMember.where({
        "benefit_group_assignments.benefit_group_id" => { "$in" => benefit_group_ids },
        :aasm_state => { '$in' => ['eligible', 'employee_role_linked']}
        })
      employees.map do |ee|
            ee.benefit_group_assignments.select do |bga| 
                benefit_group_ids.include?(bga.benefit_group_id) && (in_renewal || bga.is_active)
            end
      end.flatten
  end

  # alternative, faster way to calcuate total_enrolled_count 
  # returns a list of number enrolled (actually enrolled, not waived)
  def self.count_enrolled_and_waived_employees(plan_year)  
    if plan_year && plan_year.employer_profile.census_employees.count < 100 then
      assignments = get_benefit_group_assignments_for_plan_year(plan_year)
      HbxEnrollment.count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments(assignments)
    end 
  end
  
  # as a performance optimization, in the mobile summary API (list of all employers for a broker)
  # we only bother counting the subscribers if the employer is currently in OE
  def self.count_enrolled_and_waived_employees_if_in_open_enrollment(plan_year, as_of)
    if plan_year && as_of && 
       plan_year.open_enrollment_start_on && plan_year.open_enrollment_end_on &&
       plan_year.open_enrollment_contains?(as_of) then
        count_enrolled_and_waived_employees(plan_year) 
    else
        nil
    end
  end

  def self.marshall_employer_summaries_json(employer_profiles, report_date) 
    employer_profiles ||= []
    all_staff_by_employer_id = Person.staff_for_employers_including_pending(employer_profiles.map(&:id))
    employer_profiles.map do |er|   
        offices = er.organization.office_locations.select { |loc| loc.primary_or_branch? }
        staff = all_staff_by_employer_id[er.id]
        plan_year = er.show_plan_year
        enrolled, waived = count_enrolled_and_waived_employees_if_in_open_enrollment(plan_year, TimeKeeper.date_of_record) 
        render_employer_summary_json(employer_profile: er, year: plan_year, 
                                     num_enrolled: enrolled, num_waived: waived, 
                                     staff: staff, offices: offices, include_details_url: true) 
    end  
  end

  def self.marshall_employer_details_json(employer_profile, report_date)
    plan_year = employer_profile.show_plan_year
    if plan_year then
      enrollments = employer_profile.enrollments_for_billing(report_date)
      premium_amt_total   = enrollments.map(&:total_premium).sum 
      employee_cost_total = enrollments.map(&:total_employee_cost).sum
      employer_contribution_total = enrollments.map(&:total_employer_contribution).sum
      enrolled, waived = count_enrolled_and_waived_employees(plan_year)
      
      render_employer_details_json(employer_profile: employer_profile, 
                                   year: plan_year,  
                                   num_enrolled: enrolled, 
                                   num_waived: waived, 
                                   total_premium: premium_amt_total, 
                                   employer_contribution: employer_contribution_total, 
                                   employee_contribution: employee_cost_total)
    else
      render_employer_details_json(employer_profile: employer_profile)
    end
  end

  def invoice_formated_date(date)
    date.strftime("%m/%d/%Y")
  end

  def invoice_coverage_date(date)
    "#{date.next_month.beginning_of_month.strftime('%b %Y')}" rescue nil
  end

  def coverage_kind(census_employee=nil)
    return "" if census_employee.blank? || census_employee.employee_role.blank?
    enrolled = census_employee.active_benefit_group_assignment.try(:aasm_state)
    if enrolled.present? && enrolled != "initialized"
      begin
        #kind = census_employee.employee_role.person.primary_family.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind).sort.reverse.uniq.join(", ")
        kind = census_employee.employee_role.person.primary_family.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind).sort.reverse.join(", ")
      rescue
        kind = ""
      end
    else
      kind = ""
    end
    return kind.titleize
  end

  def render_plan_offerings(benefit_group, coverage_type)
    reference_plan = benefit_group.reference_plan
    if coverage_type == ".dental" && benefit_group.dental_plan_option_kind == "single_plan"
      plan_count = benefit_group.elected_dental_plan_ids.count
      "#{plan_count} Plans"
    elsif coverage_type == ".dental" && benefit_group.dental_plan_option_kind == "single_carrier"
      plan_count = Plan.shop_dental_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
      "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
    else
      return "1 Plan Only" if benefit_group.single_plan_type?
      if benefit_group.plan_option_kind == "single_carrier"
        plan_count = Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
        "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
      else
        plan_count = Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level]).count
        "#{reference_plan.metal_level.titleize} Plans (#{plan_count})"
      end
    end
  end

  def get_benefit_groups_for_census_employee
    plan_years = @employer_profile.plan_years.select{|py| (PlanYear::PUBLISHED + ['draft']).include?(py.aasm_state) && py.end_on > TimeKeeper.date_of_record}
    benefit_groups = plan_years.flat_map(&:benefit_groups)
    renewing_benefit_groups = @employer_profile.renewing_plan_year.benefit_groups if @employer_profile.renewing_plan_year
    return benefit_groups, (renewing_benefit_groups || [])
  end
end
