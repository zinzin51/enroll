module Api::V1::MobileApiRosterHelper

 def employees_by(employer_profile, by_employee_name = nil, by_status = 'active')
    census_employees = case by_status
                   when 'terminated'
                     employer_profile.census_employees.terminated
                   when 'all'
                     employer_profile.census_employees
                   else
                     employer_profile.census_employees.active
                   end.sorted
    by_employee_name ? census_employees.employee_name(by_employee_name) : census_employees
  end

  def status_label_for(enrollment_status)
  	{
      'Waived' => HbxEnrollment::WAIVED_STATUSES,
      'Enrolled' => HbxEnrollment::ENROLLED_STATUSES,
      'Terminated' => HbxEnrollment::TERMINATED_STATUSES,
      'Renewing' => HbxEnrollment::RENEWAL_STATUSES
    }.inject(nil) do |result, (label, enrollment_statuses)|
         enrollment_statuses.include?(enrollment_status.to_s) ? label : result
    end
  end

  ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER = [:plan_type, :deductible, :family_deductible, :provider_directory_url, :rx_formulary_url]  
  def render_roster_employee(census_employee, has_renewal)
    assignments = { active: census_employee.active_benefit_group_assignment }
    assignments[:renewal] = census_employee.renewal_benefit_group_assignment if has_renewal
    #active_benefit_group
    enrollments = {}
    assignments.keys.each do |period_type|
      assignment = assignments[period_type]
      enrollments[period_type] = {}
      %w{health dental}.each do |coverage_kind|
          enrollment = assignment.hbx_enrollments.detect { |e| e.coverage_kind == coverage_kind } if assignment
          rendered_enrollment = if enrollment then
            {
              status: status_label_for(enrollment.aasm_state),
              employer_contribution: enrollment.total_employer_contribution,
              employee_cost: enrollment.total_employee_cost,
              total_premium: enrollment.total_premium,
              plan_name: enrollment.plan.try(:name),
              metal_level:  enrollment.plan.try(coverage_kind == :health ? :metal_level : :dental_level)
            } 
          else 
            {
              status: 'Not Enrolled'
            }
          end
          if enrollment && enrollment.plan 
            ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER.each do |field|
              value = enrollment.plan.try(field)
              rendered_enrollment[field] = value if value
            end
          end
          enrollments[period_type][coverage_kind] = rendered_enrollment
      end
    end

    {
      id: census_employee.id,
      first_name:        census_employee.first_name,
      middle_name:       census_employee.middle_name,
      last_name:         census_employee.last_name,
      name_suffix:       census_employee.name_sfx,
      date_of_birth:     census_employee.dob,
      ssn_masked:        "***-**-#{ census_employee.ssn.chars.last(4).join }", 
      gender:            census_employee.gender,
      hired_on:          census_employee.hired_on,
      is_business_owner: census_employee.is_business_owner,
      enrollments:       enrollments
    } 
  end

  def render_roster_employees(employees, has_renewal)
    employees.compact.map do |ee| 
      render_roster_employee(ee, has_renewal) 
    end
  end

end