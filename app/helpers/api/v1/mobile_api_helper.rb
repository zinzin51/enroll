module Api::V1::MobileApiHelper

  def render_employee_contacts_json(staff, offices)
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

  def render_employer_summary_json(employer_profile: nil, year: nil, num_enrolled: nil, 
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
    print "$$$$$$$$$ returning #{summary}\n$$$$$$$\n\n"
    summary
  end

  def render_employer_details_json(employer_profile: nil, year: nil, num_enrolled: nil, 
                                        num_waived: nil, total_premium: nil, 
                                        employer_contribution: nil, employee_contribution: nil)
    details = render_employer_summary_json(employer_profile: employer_profile, year: year, 
                                           num_enrolled: num_enrolled, num_waived: num_waived)
    details[:total_premium] = total_premium
    details[:employer_contribution] = employer_contribution
    details[:employee_contribution] = employee_contribution
    details[:active_general_agency] = employer_profile.active_general_agency_legal_name # Note: queries DB

    #TODO next release
    #details[:reference_plan] = 
    #details[:offering_type] = 
    #details[:new_hire_rule] = 
    #details[:contribution_levels] = 
     details
  end

  def get_benefit_group_assignments_for_plan_year(plan_year)
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
  def count_enrolled_and_waived_employees(plan_year)  
    if plan_year && plan_year.employer_profile.census_employees.count < 100 then
      assignments = get_benefit_group_assignments_for_plan_year(plan_year)
      HbxEnrollment.count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments(assignments)
    end 
  end
  
  # as a performance optimization, in the mobile summary API (list of all employers for a broker)
  # we only bother counting the subscribers if the employer is currently in OE
  def count_enrolled_and_waived_employees_if_in_open_enrollment(plan_year, as_of)
    if plan_year && as_of && 
       plan_year.open_enrollment_start_on && plan_year.open_enrollment_end_on &&
       plan_year.open_enrollment_contains?(as_of) then
        count_enrolled_and_waived_employees(plan_year) 
    else
        nil
    end
  end

  def marshall_employer_summaries_json(employer_profiles, report_date) 
    print "$$$$$$$ marshall_employer_summaries_json(#{employer_profiles}, #{report_date})$$$$\n\n"
    return [] if employer_profiles.blank?
    all_staff_by_employer_id = Person.staff_for_employers_including_pending(employer_profiles.map(&:id))
    employer_profiles.map do |er|  
        #print "$$$$ in map with #{er} \n\n" 
        offices = er.organization.office_locations.select { |loc| loc.primary_or_branch? }
        staff = all_staff_by_employer_id[er.id]
        plan_year = er.show_plan_year
        enrolled, waived = count_enrolled_and_waived_employees_if_in_open_enrollment(plan_year, TimeKeeper.date_of_record) 
        render_employer_summary_json(employer_profile: er, year: plan_year, 
                                     num_enrolled: enrolled, num_waived: waived, 
                                     staff: staff, offices: offices, include_details_url: true) 
    end  
  end

  def marshall_employer_details_json(employer_profile, report_date)
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

end


