require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_hbx_id_and_disable_account")

describe ChangePersonHbxIdAndDisableAccount do

  let(:given_task_name) { "change_person_hbx_id_and_disable_account" }
  subject { ChangePersonHbxIdAndDisableAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "disable person account & change hbx_id", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person)}

    before do
      allow(ENV).to receive(:[]).with('old_hbx').and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with('new_hbx').and_return("123496789")
      allow(ENV).to receive(:[]).with('hbx').and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with('action').and_return("change_hbx")
    end

    it "should change the hbx_id on person record" do
      subject.migrate
      person.reload
      expect(person.hbx_id).to eq "123496789"
    end

    it "should disable person record" do
      allow(ENV).to receive(:[]).with('action').and_return("disable_account")
      subject.migrate
      person.reload
      expect(person.is_disabled).to eq true
    end
  end
end
