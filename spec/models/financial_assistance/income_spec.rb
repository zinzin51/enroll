require 'rails_helper'

RSpec.describe FinancialAssistance::Income, type: :model do
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
  context "valid income" do
    it "should save step_1 and submit" do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
      expect(FinancialAssistance::Income.create(valid_params).valid?(:step_1)).to be_truthy
      expect(FinancialAssistance::Income.create(valid_params).valid?(:submit)).to be_truthy
    end
  end

  describe "validations" do
    let(:income){FinancialAssistance::Income.new}

    context "on step_1 and submit title validations" do
      it "with a missing title" do
        income.title = nil
        income.valid?(:step_1)
        expect(income.errors["title"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["title"]).to be_empty
      end

      it "pick a name length between 3..30" do
        income.title = 'Te'
        income.valid?(:step_1)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
        income.valid?(:submit)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
        income.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        income.valid?(:step_1)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
        income.valid?(:submit)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
      end

      it "should be valid" do
        income.amount = 'Test'
        income.valid?(:step_1)
        expect(income.errors["title"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["title"]).to be_empty
      end
    end

    context "on step_1 and submit amount validations" do
      it "with a missing amount" do
        income.amount = nil
        income.valid?(:step_1)
        expect(income.errors["amount"]).to include("can't be blank")
        income.valid?(:submit)
        expect(income.errors["amount"]).to include("can't be blank")
      end

      it "amount must be greater than $0" do
        income.amount = 0
        income.valid?(:step_1)
        expect(income.errors["amount"]).to include("0.0 must be greater than $0")
        income.valid?(:submit)
        expect(income.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "should be valid" do
        income.amount = 10
        income.valid?(:step_1)
        expect(income.errors["amount"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["amount"]).to be_empty
      end
    end

    context "if step_1 and submit kind validations" do
      it "with a missing kind" do
        income.kind = nil
        income.valid?(:step_1)
        expect(income.errors["kind"]).to include("can't be blank")
        income.valid?(:submit)
        expect(income.errors["kind"]).to include("can't be blank")
      end

      it "is not a valid income type" do
        income.kind = 'self_employee'
        income.valid?(:step_1)
        expect(income.errors["kind"]).to include("self_employee is not a valid income type")
        income.valid?(:submit)
        expect(income.errors["kind"]).to include("self_employee is not a valid income type")
      end

      it "should be valid" do
        income.kind = 'capital_gains'
        income.valid?(:step_1)
        expect(income.errors["kind"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["kind"]).to be_empty
      end

    end

    context "if step_1 and submit frequency_kind validations" do
      it "with a missing frequency_kind" do
        income.frequency_kind = nil
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to include("can't be blank")
        income.valid?(:submit)
        expect(income.errors["frequency_kind"]).to include("can't be blank")
      end

      it "is not a valid frequency" do
        income.frequency_kind = 'self_employee'
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
        income.valid?(:submit)
        expect(income.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "should be valid" do
        income.frequency_kind = 'monthly'
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["frequency_kind"]).to be_empty
      end

    end

    context "if step_1 and submit start_on validations" do
      it "with a missing start_on" do
        income.start_on = nil
        income.valid?(:step_1)
        expect(income.errors["start_on"]).to include("can't be blank")
        income.valid?(:submit)
        expect(income.errors["start_on"]).to include("can't be blank")
      end

      it "should be valid" do
        income.start_on = Date.today
        income.valid?(:step_1)
        expect(income.errors["start_on"]).to be_empty
        income.valid?(:submit)
        expect(income.errors["start_on"]).to be_empty
      end

    end

    context "if end on date occur before start on date" do
      it "validate end on date can't occur before start on date" do
        income.start_on = Date.today
        income.end_on = Date.yesterday
        income.valid?
        expect(income.errors["end_on"]).to include("can't occur before start on date")
      end
    end

  end


  context "Hours worked per week" do
    let(:income) {
      FinancialAssistance::Application.any_instance.stub(:set_benchmark_plan_id)
      FactoryGirl.create(:income, applicant: applicant)
    }

    it "hours_worked_per_week" do
      FinancialAssistance::Application.any_instance.stub(:set_benchmark_plan_id)
      expect(income.hours_worked_per_week).to eql(nil)
    end

    it "Income same as Other" do
      FinancialAssistance::Application.any_instance.stub(:set_benchmark_plan_id)
      expect(income.same_as?(income)).to eql(true)
    end
  end
end