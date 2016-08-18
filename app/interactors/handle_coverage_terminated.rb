class HandleCoverageTerminated
  include Interactor
  include Acapi::Notifiers

  def call
    enrollment = context.hbx_enrollment
    term_date = context.term_date
    enrollment.terminated_on ||= term_date
    if enrollment.benefit_group_assignment
      enrollment.benefit_group_assignment.end_benefit(enrollment.terminated_on)
      enrollment.benefit_group_assignment.save
    end
    if enrollment.should_transmit_update?
      notify(HbxEnrollment::ENROLLMENT_UPDATED_EVENT_NAME, {policy_id: enrollment.hbx_id})
    end

    enrollment.hbx_enrollment_members.each do |hem|
      hem.ivl_withdrawn
    end

  end
end