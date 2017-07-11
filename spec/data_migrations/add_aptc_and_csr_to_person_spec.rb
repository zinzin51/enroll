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
    let!(:household) { FactoryGirl.create(:household)}
    let!(:tax_household){FactoryGril.create(:tax_household, household:household)}
    let(:eligibility_determinations){FactoryGril.create(:eligibility_determinations, tax_household:tax_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(family.person.hbx_id)
    end



    context "change person's csr" do
      before do
        allow(ENV).to receive(:[]).with("csr_percent_as_integer").and_return 50
        allow(ENV).to receive(:[]).with("csr_percent").and_return 0.5
      end
      context "change person's csr"
       it "should change person' csr" do
         ed=family.active_household.latest_active_tax_household.eligibility_determinations
         expect(ed.first.csr_percent_as_integer).to eq eligibility_determinations.first.csr_percent_as_integer
         expect(ed.first.csr_percent).to eq eligibility_determinations.first.csr_percent
         subject.migrate
         family.reload
         expect(ed.first.csr_percent_as_integer).to eq 50
         expect(ed.first.csr_percent).to eq 0.5
       end
    end
  end



end
