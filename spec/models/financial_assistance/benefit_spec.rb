require 'rails_helper'
require 'aasm/rspec'

RSpec.describe FinancialAssistance::Benefit, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
  let(:benefit) {FactoryGirl.build(:financial_assistance_benefit)}

 # let(:benefit){FactoryGirl.create(:financial_assistance_benefit)}

  let(:invalid_benefit) {FactoryGirl.build(:financial_assistance_benefit, {:title => "HELLO TITLE I AM EXPECTING YOU TO BE OUT OF RANGE", :insurance_kind => "I AM INVALID",:kind => "OUT OF VALUE"})}
  let(:empty_benefit) {FactoryGirl.build(:financial_assistance_benefit, {:title => nil})}
  let(:kinds) { FinancialAssistance::Benefit::KINDS }
  let(:title_range) { FinancialAssistance::Benefit::TITLE_SIZE_RANGE }

  it "is expected to be in range" do
    #title_range = FinancialAssistance::Benefit::TITLE_SIZE_RANGE
    expect(benefit.title.size).to be_between(title_range.min, title_range.max).inclusive
    #expect(title_range_size.title.size).not_to be_within(title_range.min).of(title_range.max)
  end

  it "is expected to be out of range" do
    #title_range = FinancialAssistance::Benefit::TITLE_SIZE_RANGE
    expect(invalid_benefit.title.size).not_to be_between(title_range.min, title_range.max).inclusive
  end

  it "title is expected to be empty" do
    # title_range = FinancialAssistance::Benefit::TITLE_SIZE_RANGE
    expect(empty_benefit.title).to be(nil)
  end


  it "is expected insurance kind matches and is valid" do
    insurance_kinds = FinancialAssistance::Benefit::INSURANCE_KINDS
    expect(insurance_kinds).to include(benefit.insurance_kind)
  end

  it "is expected kind matches and is valid" do
    #kinds = FinancialAssistance::Benefit::KINDS
    expect(kinds).to include(benefit.kind)
  end

  it "is expected non kind matches" do
    expect(kinds).not_to include(invalid_benefit.kind)
  end
end
