require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "init_chm_state_machine")

describe InitCHMStateMachine, :dbclean => :after_each do
  let(:family) { FactoryGirl.create(:individual_market_family) }
  subject { InitCHMStateMachine.new("fix me task", double(:current_scope => nil)) }
  states_map = { "fully_verified" => "eligible",
                 "verification_period_ended" => "ineligible",
                 "ineligible" => "ineligible",
                 "verification_outstanding" => "contingent",
                 "ssa_pending" => "contingent",
                 "dhs_pending" => "contingent",
                 "withdrawn" => "contingent",
                 "unverified" => "contingent" }

  before do
    allow(subject).to receive(:get_families).and_return [family]
  end
  states_map.each do |consumer_status, ch_member_status|
    it "moves" do
      family.active_household.coverage_households.first.coverage_household_members.first.family_member.person.consumer_role.aasm_state = consumer_status
      subject.migrate
      family.reload
      expect(family.active_household.coverage_households.first.coverage_household_members.first.aasm_state).to eq ch_member_status
    end
  end
end