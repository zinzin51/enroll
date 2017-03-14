module Enrollments
  module Hbx
    class GroupSelection
      class << self
        def new_effective_on(**attributes)
          return if attributes.blank?
          effective_on_date = if attributes[:effective_on_option_selected].present?
            Date.strptime(attributes[:effective_on_option_selected], '%m/%d/%Y')
          else
            employee_role = attributes[:employee_role]
            HbxEnrollment.calculate_effective_on_from(
              market_kind: attributes[:market_kind],
              qle: attributes[:qle],
              family: attributes[:family],
              employee_role: employee_role,
              benefit_group: employee_role.present? ? employee_role.benefit_group : nil,
              benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship)
            )
          end
          effective_on_date
        end

        def build_hbx_enrollment(**attributes)
          return if attributes.blank?
          employee_role = attributes[:employee_role]
          hbx_enrollment = attributes[:hbx_enrollment]
          person = attributes[:person]
          coverage_household = attributes[:coverage_household]
          current_user = attributes[:current_user]
          original_application_type = attributes[:original_application_type]
          coverage_kind = attributes[:coverage_kind]
          change_by_qle_or_sep_enrollment = attributes[:change_by_qle_or_sep_enrollment]
          change_plan = attributes[:change_plan]
          enrollment = case attributes[:market_kind]
          when 'shop'
            if hbx_enrollment.present?
              change_plan = 'change_by_qle' if hbx_enrollment.is_special_enrollment?
              if employee_role == hbx_enrollment.employee_role
                benefit_group = hbx_enrollment.benefit_group
                benefit_group_assignment = hbx_enrollment.benefit_group_assignment
              else
                benefit_group = employee_role.benefit_group
                benefit_group_assignment = employee_role.census_employee.active_benefit_group_assignment
              end
            end
            coverage_household.household.new_hbx_enrollment_from(
              employee_role: employee_role,
              resident_role: person.resident_role,
              coverage_household: coverage_household,
              benefit_group: benefit_group,
              benefit_group_assignment: benefit_group_assignment,
              qle: change_by_qle_or_sep_enrollment)
          when 'individual', 'coverall'
            coverage_household.household.new_hbx_enrollment_from(
              consumer_role: person.consumer_role,
              resident_role: person.resident_role,
              coverage_household: coverage_household,
              qle: change_by_qle_or_sep_enrollment)
          end

          if (attributes[:keep_existing_plan] && hbx_enrollment.present?)
            sep_id = hbx_enrollment.is_shop? ? hbx_enrollment.family.earliest_effective_shop_sep.id : hbx_enrollment.family.earliest_effective_ivl_sep.id
            enrollment.special_enrollment_period_id = sep_id
            enrollment.plan = hbx_enrollment.plan
          end

          enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.select do |member|
            attributes[:family_member_ids].include? member.applicant_id
          end
          enrollment.generate_hbx_signature

          attributes[:family].hire_broker_agency(current_user.person.broker_role.try(:id))
          enrollment.writing_agent_id = current_user.person.try(:broker_role).try(:id)
          enrollment.original_application_type = original_application_type
          broker_role = current_user.person.broker_role
          enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role

          enrollment.coverage_kind = coverage_kind
          enrollment, valid = amend_enrollment_for_cobra(employee_role, enrollment)
          return [change_plan, enrollment, valid]
        end

        private
        def amend_enrollment_for_cobra(employee_role, hbx_enrollment)
          if employee_role.present? && employee_role.is_cobra_status?
            hbx_enrollment.kind = 'employer_sponsored_cobra'
            hbx_enrollment.effective_on = employee_role.census_employee.coverage_terminated_on.end_of_month + 1.days if employee_role.census_employee.need_update_hbx_enrollment_effective_on?
            if employee_role.census_employee.coverage_terminated_on.present? && !employee_role.census_employee.have_valid_date_for_cobra?
              return [hbx_enrollment, false]
            end
          end
          [hbx_enrollment, true]
        end
      end
    end
  end
end
