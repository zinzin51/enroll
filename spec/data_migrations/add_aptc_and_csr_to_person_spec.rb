require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_aptc_and_csr_to_person")
describe AddAptcAndCsrToPerson do
  let(:given_task_name) { "add_aptc_and_csr_to_person" }
  subject { AddAptcAndCsrToPerson.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing person's aptc and csr" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household){FactoryGirl.create(:tax_household, household:family.active_household)}
    let!(:eligibility_determinations){FactoryGirl.create(:eligibility_determination, tax_household:tax_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(family.person.hbx_id)
    end
    context "change person's csr" do
      before do
        allow(ENV).to receive(:[]).with("action").and_return "change_csr"
        allow(ENV).to receive(:[]).with("csr_percent_as_integer").and_return 50
        allow(ENV).to receive(:[]).with("csr_percent").and_return 0.5
      end
      context "change person's csr"
       it "should change person' csr" do
         ed=eligibility_determinations
         expect(ed.csr_percent_as_integer).to eq eligibility_determinations.csr_percent_as_integer
         expect(ed.csr_percent).to eq eligibility_determinations.csr_percent
         subject.migrate
         family.reload
         eligibility_determinations.reload
         expect(ed.csr_percent_as_integer).to eq 50
         expect(ed.csr_percent).to eq 0.5
       end
    end
    context "change person's aptc" do
      before do
        allow(ENV).to receive(:[]).with("action").and_return "change_aptc"
        allow(ENV).to receive(:[]).with("max_aptc").and_return 100
      end
      context "change person's csr"
      it "should change person' csr" do
        ed=eligibility_determinations
        expect(ed.max_aptc).to eq ed.max_aptc
        subject.migrate
        family.reload
        eligibility_determinations.reload
        expect(ed.max_aptc).to eq 100
      end
    end
  end
end
