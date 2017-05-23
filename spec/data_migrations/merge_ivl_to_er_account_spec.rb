require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "merge_ivl_to_er_account")

describe MergeIvlToErAccount do

  let(:given_task_name) { "merge ivl_to_er_account" }
  subject { MergeIvlToErAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "merge ivl and er account" do

    let!(:user) { FactoryGirl.create(:user, person: employer_staff_role.person)}
    let(:person)  {FactoryGirl.create(:person,:with_consumer_role, hbx_id: "1234567")}
    let(:employer_staff_role) {FactoryGirl.create(:employer_staff_role,employer_profile_id:employer_profile.id)}
    let(:employer_profile){FactoryGirl.create(:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("ivl_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("employer_hbx_id").and_return(employer_staff_role.person.hbx_id)
    end

    context "giving a new state" do
      it "should assign user to the employee" do
        subject.migrate
        employer_staff_role.person.reload
        person.reload
        user.reload
        expect(employer_staff_role.person.consumer_role).not_to eq nil
        expect(user.roles).to include("consumer")
      end
    end
  end
end