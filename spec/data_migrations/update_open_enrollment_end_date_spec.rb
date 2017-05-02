require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_open_enrollment_end_date")

describe UpdateOpenEnrollmentEndDate do

  let(:given_task_name) { "update_open_enrollment_end_date" }
  subject { UpdateOpenEnrollmentEndDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the open_enrollment_end_on date" do

    context "for latest plan year" do

      let(:organization) { FactoryGirl.create(:organization)}
      let(:employer_profile) {FactoryGirl.create(:employer_profile, organization: organization)}
      let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(plan_year.employer_profile.parent.fein)
        allow(ENV).to receive(:[]).with("open_enrollment_end_on").and_return(plan_year.open_enrollment_end_on)
        allow(ENV).to receive(:[]).with("new_date").and_return("01/01/2017")
      end

      it "should change the open_enrollment_end_on date" do
        subject.migrate
        organization.employer_profile.reload
        expect(organization.employer_profile.latest_plan_year.open_enrollment_end_on).to eq Date.new(2017,1,1)
      end
    end
  end
end
