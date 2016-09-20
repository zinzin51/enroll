require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_special_verif_period")

describe MoveVerifPeriod, :dbclean => :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  subject { MoveVerifPeriod.new("fix me task", double(:current_scope => nil)) }

  before do
    allow_any_instance_of(InitCHMStateMachine).to receive(:get_families).and_return [family]
    family.active_household.hbx_enrollments<<FactoryGirl.build(:hbx_enrollment, :household => family.active_household, :special_verification_period => Date.today)
    subject.migrate
    family.reload
  end

  it "test" do
    expect(family.active_household.special_verification_period).to eq family.active_household.hbx_enrollments.first.special_verification_period
  end
end