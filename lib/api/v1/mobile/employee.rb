module Api
  module V1
    module Mobile
      class Employee < Base
        ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER = [:plan_type, :deductible, :family_deductible, :provider_directory_url, :rx_formulary_url]

        def initialize args={}
          super args
        end

        def employees_sorted_by
          census_employees = case @status
                               when 'terminated'
                                 @employer_profile.census_employees.terminated
                               when 'all'
                                 @employer_profile.census_employees
                               else
                                 @employer_profile.census_employees.active
                             end.sorted
          @employee_name ? census_employees.employee_name(@employee_name) : census_employees
        end

        def roster_employees
          employees_benefits = @employees.map { |e| {"#{e.id}" => e, benefit_group_assignments: e.benefit_group_assignments} }.flatten
          benefit_group_assignment_ids = employees_benefits.map { |x| x[:benefit_group_assignments] }.flatten.map(&:id)
          enrollments_for_benefit_groups = hbx_enrollments benefit_group_assignment_ids
          grouped_bga_enrollments = enrollments_for_benefit_groups.group_by { |x| x.benefit_group_assignment_id.to_s }

          plan_ids = enrollments_for_benefit_groups.map { |x| x.plan_id }.flatten
          indexed_plans = Plan.where(:'id'.in => plan_ids).index_by(&:id)
          enrollments_for_benefit_groups.map { |e| e.plan = indexed_plans[e.plan_id] }

          benefit_groups = @employer_profile.plan_years.map { |p| p.benefit_groups }.flatten.compact.index_by(&:id)
          enrollments_for_benefit_groups.map { |e| e.benefit_group = benefit_groups[e.benefit_group_id] }


          @employees.compact.map { |ee|
            benefit_group_assignments = employees_benefits.detect { |b| b.keys.include? ee.id.to_s }.try(:[], :benefit_group_assignments)
            roster_employee ee, benefit_group_assignments, grouped_bga_enrollments
          }
        end

        #
        # A faster way of counting employees who are enrolled vs waived vs terminated
        # where enrolled + waived = counting towards SHOP minimum healthcare participation
        # We first do the query to find families with appropriate enrollments,
        # then check again inside the map/reduce to get only those enrollments.
        # This avoids undercounting, e.g. two family members working for the same employer.
        #
        def count_by_enrollment_status
          return [0, 0, 0] if benefit_group_assignments.blank?

          enrolled_or_renewal = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
          waived = HbxEnrollment::WAIVED_STATUSES
          terminated = HbxEnrollment::TERMINATED_STATUSES

          id_list = @benefit_group_assignments.map(&:id)
          all_enrollments = Api::V1::Mobile::Family.new(benefit_group_assignment_ids: id_list, aasm_states: enrolled_or_renewal + waived + terminated).hbx_enrollments
          enrollment = Api::V1::Mobile::Enrollment.new all_enrollments: all_enrollments

          # return count of enrolled, count of waived, count of terminated
          # only including those originally asked for
          enrollment.benefit_group_assignment_ids enrolled_or_renewal, waived, terminated do |enrolled_ids, waived_ids, terminated_ids|
            [enrolled_ids, waived_ids, terminated_ids].map { |found_ids| (found_ids & id_list).count }
          end
        end

        #
        # Private
        #
        private

        def hbx_enrollments benefit_group_assignment_ids
          families = ::Family.where(:'households.hbx_enrollments'.elem_match => {
              :'benefit_group_assignment_id'.in => benefit_group_assignment_ids
          })
          families.map { |f| f.households.map { |h| h.hbx_enrollments } }.flatten.compact
        end

        def benefit_group_assignments
          @benefit_group_assignments ||= @benefit_group.employees.map do |ee|
            ee.benefit_group_assignments.select do |bga|
              @benefit_group.ids.include?(bga.benefit_group_id) &&
                  (::PlanYear::RENEWING_PUBLISHED_STATE.include?(@benefit_group.plan_year.aasm_state) || bga.is_active)
            end
          end.flatten
        end

        def roster_employee employee, benefit_group_assignments, grouped_bga_enrollments
          result = basic_individual employee
          result[:id] = employee.id
          result[:hired_on] = employee.hired_on
          result[:is_business_owner] = employee.is_business_owner

          assignments = benefit_group_assignments.select do |a|
            Api::V1::Mobile::PlanYear.new(plan_year: a.plan_year).is_current_or_upcoming?
          end

          result[:enrollments] = Api::V1::Mobile::Enrollment.new(
              assignments: assignments, grouped_bga_enrollments: grouped_bga_enrollments).employee_enrollments
          result[:dependents] = dependents_of(employee).map do |d|
            basic_individual(d).merge(relationship: relationship_with(d))
          end

          result
        end

        def basic_individual employee
          ssn = employee.try(:ssn)
          ssn_masked = "***-**-#{ ssn.chars.last(4).join }" if ssn

          {first_name: employee.try(:first_name),
           middle_name: employee.try(:middle_name),
           last_name: employee.try(:last_name),
           name_suffix: employee.try(:name_sfx),
           date_of_birth: employee.try(:dob),
           ssn_masked: ssn_masked,
           gender: employee.try(:gender)
          }
        end

        def dependents_of employee
          all_family_dependents = employee.try(:employee_role).try(:person).try(:primary_family).try(:active_family_members) || []
          family_dependents = all_family_dependents.reject { |d| relationship_with(d) == 'self' }
          census_dependents = employee.census_dependents || []
          (family_dependents + census_dependents).uniq { |p| p.ssn }
        end


        def relationship_with dependent
          dependent.try(:relationship) || dependent.try(:employee_relationship)
        end

      end
    end
  end
end