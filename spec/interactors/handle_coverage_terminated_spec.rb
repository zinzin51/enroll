require "rails_helper"

describe HandleCoverageTerminated do

  let(:context)  do
    { :hbx_enrollment => hbx_enrollment, :terminated_on => Date.today }
  end

  let(:the_hbx_id) { "ALKJFKLJEIJFDLF" }
  let(:the_update_time) { Time.now }


  describe "given an IVL policy with multiple members" do
    let(:hbx_enrollment) { instance_double(HbxEnrollment,
                                           :is_shop? => false,
                                           :hbx_enrollment_members => enrollment_members,
                                           :hbx_id => the_hbx_id,
                                           :terminated_on => nil,
                                           :benefit_group_assignment => benefit_group_assignment) }

    let(:enrollment_member_1) { instance_double(HbxEnrollmentMember) }
    let(:enrollment_member_2) { instance_double(HbxEnrollmentMember) }
    let(:benefit_group_assignment) { instance_double(BenefitGroupAssignment) }

    let(:enrollment_members) { [enrollment_member_1, enrollment_member_2] }

    before(:each) do
      allow(enrollment_member_1).to receive(:ivl_withdrawn)
      allow(enrollment_member_2).to receive(:ivl_withdrawn)
      allow(benefit_group_assignment).to receive(:end_benefit)
      allow(benefit_group_assignment).to receive(:save)
      allow(hbx_enrollment).to receive(:terminated_on=)
      allow(hbx_enrollment).to receive(:should_transmit_update?).and_return true
      allow(enrollment_member_1).to receive(:any_other_active_enrollments?)
      allow(enrollment_member_2).to receive(:any_other_active_enrollments?)
    end

    it "has a successful result" do
      expect(HandleCoverageTerminated.call(context).success?).to be_truthy
    end

    it "notifies of coverage selection for enrollment member 1" do
      expect(enrollment_member_1).to receive(:ivl_withdrawn).with(no_args)
      HandleCoverageTerminated.call(context)
    end

    it "notifies of coverage selection for enrollment member 2" do
      expect(enrollment_member_2).to receive(:ivl_withdrawn).with(no_args)
      HandleCoverageTerminated.call(context)
    end
  end
end