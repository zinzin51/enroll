require 'rails_helper'

RSpec.describe Enrollments::Hbx::GroupSelection, type: :model do
  describe ".new_effective_on" do
    context "without any attributes" do
      let(:effective_on) {described_class.new_effective_on}
      it 'returns nil' do
        expect(effective_on).to be_nil
      end
    end

    context "with valid effective_on_option_selected" do
      let(:effective_on_date) {'03/03/2014'}
      let(:expected_date) {Date.strptime(effective_on_date, '%m/%d/%Y')}
      let(:effective_on) {described_class.new_effective_on(effective_on_option_selected: effective_on_date)}
      it 'returns valid date' do
        expect(effective_on).to eq expected_date
      end
    end

    context "without effective_on_option_selected" do
      let(:employee_role) {double('EmployeeRole')}
      let(:family) {double('Family')}
      let(:effective_on) {
        described_class.new_effective_on(
          employee_role: employee_role,
          market_kind: 'shop',
          qle: false,
          family: family,
        )
      }
      before {
        allow(employee_role).to receive(:benefit_group).and_return(nil)
        allow(HbxEnrollment).to receive(:calculate_effective_on_from).and_return(Date.today)
      }
      it 'returns valid date' do
        expect(effective_on).not_to be_nil
        expect(effective_on).to be_an_instance_of(Date)
      end
    end
  end

  describe ".build_hbx_enrollment" do
    let(:person) {FactoryGirl.create(:person)}
    let(:user) { instance_double("User", :person => person) }
    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:employee_role) {FactoryGirl.create(:employee_role)}
    let(:household) {double(:immediate_family_coverage_household=> coverage_household, :hbx_enrollments => hbx_enrollments)}
    let(:coverage_household) {double}
    let(:family) {Family.new}
    let(:hbx_enrollment) {HbxEnrollment.create}
    let(:hbx_enrollments) {double(:enrolled => [hbx_enrollment])}
    let(:family_member_ids) {{"0"=>"559366ca63686947784d8f01", "1"=>"559366ca63686947784e8f01", "2"=>"559366ca63686947784f8f01", "3"=>"559366ca6368694778508f01"}}
    let(:benefit_group) {FactoryGirl.create(:benefit_group)}
    let(:benefit_group_assignment) {double(update: true)}
    let(:employee_roles){ [double("EmployeeRole")] }
    let(:census_employee) {FactoryGirl.create(:census_employee)}
    context "without attributes" do
      let(:build_hbx_enrollment) {described_class.build_hbx_enrollment}
      it 'returns nil' do
        expect(build_hbx_enrollment).to be_nil
      end
    end

    context "with valid attributes" do
      before do
        allow(coverage_household).to receive(:household).and_return(household)
        allow(household).to receive(:new_hbx_enrollment_from).and_return(hbx_enrollment)
        allow(person).to receive(:employee_roles).and_return([employee_role])
        allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
        allow(employee_role).to receive(:census_employee).and_return(census_employee)
        allow(hbx_enrollment).to receive(:rebuild_members_by_coverage_household).with(coverage_household: coverage_household).and_return(true)
        allow(family).to receive(:latest_household).and_return(household)
        allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
        allow(hbx_enrollment).to receive(:inactive_related_hbxs).and_return(true)
        allow(hbx_enrollment).to receive(:family).and_return(family)
      end

      context "with keep_existing_plan as false" do
        let(:build_hbx_enrollment) {
          described_class.build_hbx_enrollment(
            employee_role: employee_role,
            hbx_enrollment: hbx_enrollment,
            person: person,
            coverage_household: coverage_household,
            market_kind: 'shop',
            change_by_qle_or_sep_enrollment: false,
            keep_existing_plan: false,
            current_user: user,
            family: family,
            change_plan: ''
          )
        }

        it 'returns hbx_enrollment' do
          hbx_enrollment = build_hbx_enrollment[1]
          expect(hbx_enrollment).not_to be_nil
          expect(hbx_enrollment).to be_an_instance_of(HbxEnrollment)
        end

        it 'returns valid as true' do
          valid = build_hbx_enrollment[2]
          expect(valid).to be_truthy
        end
      end

      context "with keep_existing_plan as true" do
        let(:old_hbx) { HbxEnrollment.new }
        let(:special_enrollment) { FactoryGirl.build(:special_enrollment_period) }
        let(:build_hbx_enrollment) {
          described_class.build_hbx_enrollment(
            employee_role: employee_role,
            hbx_enrollment: hbx_enrollment,
            person: person,
            coverage_household: coverage_household,
            market_kind: 'shop',
            change_by_qle_or_sep_enrollment: false,
            keep_existing_plan: true,
            current_user: user,
            family: family,
            change_plan: ''
          )
        }
        before {
          allow(hbx_enrollment).to receive(:save).and_return(true)
          allow(hbx_enrollment).to receive(:plan=).and_return(true)
          allow(hbx_enrollment).to receive(:is_shop?).and_return true
          allow(hbx_enrollment).to receive(:family).and_return family
          allow(family).to receive(:earliest_effective_shop_sep).and_return special_enrollment
        }

        it 'returns hbx_enrollment' do
          hbx_enrollment = build_hbx_enrollment[1]
          expect(hbx_enrollment).not_to be_nil
          expect(hbx_enrollment).to be_an_instance_of(HbxEnrollment)
        end

        it 'returns valid as true' do
          valid = build_hbx_enrollment[2]
          expect(valid).to be_truthy
        end
      end

      context "for cobra with valid date" do
        let(:expected_kind) {'employer_sponsored_cobra'}
        before {
          allow(person).to receive(:employee_roles).and_return([employee_role])
          allow(employee_role).to receive(:census_employee).and_return(census_employee)
          allow(employee_role).to receive(:is_cobra_status?).and_return(true)
          allow(census_employee).to receive(:coverage_terminated_on).and_return(false)
        }

        let(:build_hbx_enrollment) {
          described_class.build_hbx_enrollment(
            employee_role: employee_role,
            hbx_enrollment: hbx_enrollment,
            person: person,
            coverage_household: coverage_household,
            market_kind: 'shop',
            change_by_qle_or_sep_enrollment: false,
            keep_existing_plan: false,
            current_user: user,
            family: family,
            change_plan: ''
          )
        }

        it 'returns hbx_enrollment with kind set to cobra' do
          hbx_enrollment = build_hbx_enrollment[1]
          expect(hbx_enrollment).not_to be_nil
          expect(hbx_enrollment.kind).to eq expected_kind
        end

        it 'returns valid as true' do
          valid = build_hbx_enrollment[2]
          expect(valid).to be_truthy
        end
      end

      context "for cobra with invalid date" do
        let(:expected_kind) {'employer_sponsored_cobra'}
        before {
          allow(person).to receive(:employee_roles).and_return([employee_role])
          allow(employee_role).to receive(:census_employee).and_return(census_employee)
          allow(employee_role).to receive(:is_cobra_status?).and_return(true)
          allow(census_employee).to receive(:have_valid_date_for_cobra?).and_return(false)
          allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record)
        }

        let(:build_hbx_enrollment) {
          described_class.build_hbx_enrollment(
            employee_role: employee_role,
            hbx_enrollment: hbx_enrollment,
            person: person,
            coverage_household: coverage_household,
            market_kind: 'shop',
            change_by_qle_or_sep_enrollment: false,
            keep_existing_plan: false,
            current_user: user,
            family: family,
            change_plan: ''
          )
        }

        it 'returns hbx_enrollment with kind set to cobra' do
          hbx_enrollment = build_hbx_enrollment[1]
          expect(hbx_enrollment).not_to be_nil
          expect(hbx_enrollment.kind).to eq expected_kind
        end

        it 'returns valid as false' do
          valid = build_hbx_enrollment[2]
          expect(valid).to be_falsey
        end
      end
    end
  end
end
