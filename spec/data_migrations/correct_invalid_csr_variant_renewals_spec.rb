require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_invalid_csr_variant_renewals")

describe CorrectInvalidCsrVariantRenewals do

  let(:given_task_name) { "correct_invalid_csr_variant_renewals" }
  subject { CorrectInvalidCsrVariantRenewals.new(given_task_name, double(:current_scope => nil)) }

  let(:current_year) { TimeKeeper.date_of_record.year }
  let(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }

  let!(:base_plan) {
    FactoryGirl.create(:plan, market: 'individual', active_year: current_year-1, hios_id: "11111111122302-03", csr_variant_id: "03", cat_age_off_renewal_plan_id: cat_age_off_renewal_plan.id)
  }

  let!(:cat_age_off_renewal_plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', active_year: current_year, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let!(:renewal_plan) {
    FactoryGirl.create(:plan, market: 'individual', active_year: current_year, hios_id: "11111111122302-03", csr_variant_id: "03")
  }

  let!(:ivl_family)        { FactoryGirl.create(:family, :with_primary_family_member) }

  let(:base_enrollment)    { FactoryGirl.create(:hbx_enrollment,
    household: ivl_family.latest_household,
    coverage_kind: "health",
    effective_on: effective_date.prev_year,
    enrollment_kind: "open_enrollment",
    kind: "individual",
    plan_id: base_plan.id,
    aasm_state: 'coverage_expired'
    )
  }

  let(:passive_renewal)    { 
    enrollment = FactoryGirl.create(:hbx_enrollment,
      household: ivl_family.latest_household,
      coverage_kind: "health",
      effective_on: effective_date,
      enrollment_kind: "open_enrollment",
      kind: "individual",
      plan_id: renewal_plan.id,
      aasm_state: 'shopping'
    )
    enrollment.renew_enrollment!
    enrollment.begin_coverage!
    enrollment
  }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Given renewal enrollment has incorrect plan" do
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_ids").and_return(passive_renewal.hbx_id.to_s)
      allow(ENV).to receive(:[]).with("renewal_date").and_return(effective_date.strftime("%m/%d/%Y"))
      allow(subject).to receive(:has_catastrophic_plan?).with(base_enrollment).and_return(true)
      allow(subject).to receive(:is_cat_plan_ineligible?).with(base_enrollment).and_return(true)
    end

    context "and eligible for catastrophic age of plan", dbclean: :after_each do

      it "should fix renewal enrollment with correct cat_age_off_renewal_plan" do
        subject.migrate
        passive_renewal.reload
        expect(passive_renewal.plan_id).to eq cat_age_off_renewal_plan.id
      end
    end
  end
end
