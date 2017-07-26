require 'rails_helper'

RSpec.describe FinancialAssistance::Deduction, type: :model do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:tax_household) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
  let(:family_member) { family.primary_applicant }
  let(:applicant) { FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member.id) }


  let(:valid_params){
    {
        applicant: applicant,
        amount: 1000,
        frequency_kind: 'monthly',
        start_on: Date.today
    }
  }

  before :each do
		allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  context "valid deduction" do
    it "should save step_1 and submit" do
      expect(FinancialAssistance::Deduction.create(valid_params).valid?(:step_1)).to be_truthy
      expect(FinancialAssistance::Deduction.create(valid_params).valid?(:submit)).to be_truthy
    end
  end

  describe "validations" do
    let(:deduction){FinancialAssistance::Deduction.new(applicant: applicant)}

    context "on step_1 and submit title validations" do
      it "with a missing title" do
        deduction.title = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to be_empty
      end

      it "pick a name length between 3..30" do
        deduction.title = 'Te'
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
        deduction.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
      end

      it "should be valid" do
        deduction.amount = 'Test'
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to be_empty
      end
    end

    context "on step_1 and submit amount validations" do
      it "with a missing amount" do
        deduction.amount = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to include("can't be blank")
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to include("can't be blank")
      end

      it "amount must be greater than $0" do
        deduction.amount = 0
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to include("0.0 must be greater than $0")
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "should be valid" do
        deduction.amount = 10
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to be_empty
      end
    end

    context "if step_1 and submit kind validations" do
      it "with a missing kind" do
        deduction.kind = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to include("can't be blank")
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to include("can't be blank")
      end

      it "is not a valid deduction type" do
        deduction.kind = 'self_employee'
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to include("self_employee is not a valid deduction type")
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to include("self_employee is not a valid deduction type")
      end

      it "should be valid" do
        deduction.kind = 'alimony_paid'
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to be_empty
      end

    end

    context "if step_1 and submit frequency_kind validations" do
      it "with a missing frequency_kind" do
        deduction.frequency_kind = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to include("can't be blank")
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to include("can't be blank")
      end

      it "is not a valid frequency" do
        deduction.frequency_kind = 'self_employee'
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "should be valid" do
        deduction.frequency_kind = 'monthly'
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to be_empty
      end

    end

    context "if step_1 and submit start_on validations" do
      it "with a missing start_on" do
        deduction.start_on = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["start_on"]).to include("can't be blank")
        deduction.valid?(:submission)
        expect(deduction.errors["start_on"]).to include("can't be blank")
      end

      it "should be valid" do
        deduction.start_on = Date.today
        deduction.valid?(:step_1)
        expect(deduction.errors["start_on"]).to be_empty
        deduction.valid?(:submission)
        expect(deduction.errors["start_on"]).to be_empty
      end

    end

    context "if step_1 and submit end on date occur before start on date" do
      it "end on date can't occur before start on date" do
        deduction.start_on = Date.today
        deduction.end_on = Date.yesterday
        deduction.valid?(:step_1)
        expect(deduction.errors["end_on"]).to include("can't occur before start on date")
        deduction.valid?(:submission)
        expect(deduction.errors["end_on"]).to include("can't occur before start on date")
      end
    end
  end
end
