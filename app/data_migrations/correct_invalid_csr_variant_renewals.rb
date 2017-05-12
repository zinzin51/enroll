require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectInvalidCsrVariantRenewals < MongoidMigrationTask
  
  def migrate
    enrollment_group_ids = ENV['hbx_ids'].split(',')
    renewal_begin_date = Date.strptime(ENV['renewal_date'], "%m/%d/%Y")
    valid_statuses = %w(coverage_selected transmitted_to_carrier coverage_enrolled coverage_expired enrolled_contingent unverified)

    enrollment_group_ids.each do |hbx_id|
      enrollment = HbxEnrollment.by_hbx_id(hbx_id.to_s).first
      if enrollment.blank?
        puts "Enrollment missing for EG id #{hbx_id}."
        next
      end

      if enrollment.workflow_state_transitions.where(to_state: 'auto_renewing').present?
        coverage_start = enrollment.effective_on.prev_year

        enrollments = enrollment.household.hbx_enrollments.where({
          :effective_on.gte => coverage_start,
          :effective_on.lt => enrollment.effective_on,
          kind: enrollment.kind, 
          coverage_kind: enrollment.coverage_kind
        }).where(:aasm_state.in => valid_statuses)
      else
        puts "Enrollment Group #{hbx_id} not a passive renewal."
      end

      if enrollments.present?
        base_enrollment = enrollments.first

        if has_catastrophic_plan?(base_enrollment)
          renewal_plan = base_enrollment.plan.cat_age_off_renewal_plan

          if enrollment.plan.hios_id != renewal_plan.hios_id
            enrollment.update(plan_id: renewal_plan.id)
            puts "EG #{hbx_id} is renewed into #{enrollment.plan.hios_id}...but the correct plan is #{renewal_plan.hios_id}."
          end
        end
      else
        puts "Previous Year Enrollment missing for EG Id #{hbx_id}."
      end
    end
  end

  def has_catastrophic_plan?(enrollment)
    enrollment.plan.metal_level == 'catastrophic'       
  end
end