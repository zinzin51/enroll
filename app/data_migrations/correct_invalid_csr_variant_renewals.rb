require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectInvalidCsrVariantRenewals < MongoidMigrationTask
  
  def migrate
    enrollment_group_ids = ENV['hbx_ids'].split(',')
    renewal_begin_date = Date.strptime(ENV['renewal_date'], "%m/%d/%Y")

    enrollment_group_ids.each do |hbx_id|
      enrollment = HbxEnrollment.by_hbx_id(hbx_id.to_s).first

      if enrollment.present?
        family = enrollment.family
        enrollments = family.active_household.hbx_enrollments.where({
          effective_on: renewal_begin_date, 
          kind: enrollment.kind, 
          coverage_kind: enrollment.coverage_kind
        }).enrolled_and_renewing

        passive_renewal = enrollments.detect{|e| e.workflow_state_transitions.where(to_state: 'auto_renewing').present?}

        if passive_renewal.present?

        else
          puts "Passive Renewal for eg Id #{hbx_id} missing."
        end
      else
        puts "Enrollment for eg Id #{hbx_id} missing."
      end
    end
  end
end