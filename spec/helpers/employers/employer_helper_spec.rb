require "rails_helper"

RSpec.describe Employers::EmployerHelper, :type => :helper do
  describe "#enrollment_state" do

    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id) }
    let(:benefit_group_assignment) { double }
    let(:person) {double}
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:dental_plan) { FactoryGirl.create(:plan, coverage_kind: "dental", dental_level: "high" ) }
    let(:health_plan) { FactoryGirl.create(:plan, coverage_kind: "health") }
    let(:dental_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              coverage_kind: 'dental',
                                              plan: dental_plan
                                            )}
    let(:health_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              plan: health_plan
                                            )}

    before do
      allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_selected")
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(primary_family)
    end

    context ".enrollment_state" do

      context 'when enrollments not present' do

        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([])
        end

        it "should return initialized as default" do
          expect(helper.enrollment_state(census_employee)).to be_blank
        end
      end

      context 'when health coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return health enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)"
        end
      end

      context 'when dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([dental_enrollment])
        end

        it "should return dental enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Dental)"
        end
      end

      context 'when both health & dental coverage present' do
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        end

        it "should return enrollment status for both health & dental" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)<Br/> Coverage Selected (Dental)"
        end
      end

      context 'when coverage terminated' do
        before do
          health_enrollment.terminate_coverage!
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Terminated (Health)"
        end
      end

      context 'when coverage waived' do
        before do
          health_enrollment.update_attributes(:aasm_state => :inactive)
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment])
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Waived (Health)"
        end
      end
    end


    context "return coverage kind for a census_employee" do
      it " when coverage kind is nil " do
        expect(helper.coverage_kind(nil)).to eq ""
      end

      it " when coverage kind is 'health' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health"
      end

      it " when coverage kind is 'dental' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'health, dental' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'dental, health' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([dental_enrollment, health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end
    end

    context "invoice_formated_date" do
      it "should return Month-Year format for a giving date" do
        expect(helper.invoice_formated_date(Date.new(2001,2,10))).to eq "02/10/2001"
        expect(helper.invoice_formated_date(Date.new(2016,4,14))).to eq "04/14/2016"
      end
    end

    context "invoice_coverage_date" do
      it "should return Month-Date-Year format for a giving date" do
        expect(helper.invoice_coverage_date(Date.new(2001,2,10))).to eq "Mar 2001"
        expect(helper.invoice_coverage_date(Date.new(2016,4,14))).to eq "May 2016"
      end
    end


    context ".get_benefit_groups_for_census_employee" do
      let(:health_plan)       { FactoryGirl.create(:plan, 
                                                   :with_premium_tables,
                                                   coverage_kind: "health",
                                                   active_year: TimeKeeper.date_of_record.year) }

      let(:expired_plan_year) { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month - 1.year,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month - 1.day,
                                                  aasm_state: 'expired') }

      let(:active_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'active') }

      let(:draft_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'draft') }

      let(:published_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'published') }

      let(:renewing_plan_year)  { FactoryGirl.build(:plan_year,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  end_on: TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day,
                                                  aasm_state: 'renewing_draft') }


      let(:relationship_benefits) do
        [
          RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
          RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),    
          RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                                    plan_years: [expired_plan_year, active_plan_year, draft_plan_year]) }

      before do 
        [expired_plan_year, active_plan_year, draft_plan_year, renewing_plan_year, published_plan_year].each do |py|
          bg = py.benefit_groups.build({
            title: 'DC benefits',
            plan_option_kind: "single_plan",
            effective_on_kind: 'first_of_month',
            effective_on_offset: 0,
            relationship_benefits: relationship_benefits,
            reference_plan_id: health_plan.id,
            })
          bg.elected_plans= [health_plan]
          bg.save!
        end
        assign(:employer_profile, employer_profile)
      end

      context "for employer with plan years" do
  
        it 'should not return expired benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(expired_plan_year.benefit_groups.first)).to be_falsey
        end 

        it 'should return current benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(active_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(renewal_benefit_groups).to be_empty
        end
      end

      context 'for renewing employer' do 
        let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                    plan_years: [expired_plan_year, active_plan_year, draft_plan_year, renewing_plan_year]) }

        it 'should return both renewing and current benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(active_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(renewing_plan_year.benefit_groups.first)).to be_falsey
          expect(renewal_benefit_groups.include?(renewing_plan_year.benefit_groups.first)).to be_truthy
        end
      end

      context "for new initial employer" do
        let!(:employer_profile)  { FactoryGirl.create(:employer_profile, 
                                    plan_years: [draft_plan_year, published_plan_year]) }

        it 'should return upcoming draft and published plan year benefit groups' do
          current_benefit_groups, renewal_benefit_groups = helper.get_benefit_groups_for_census_employee
          expect(current_benefit_groups.include?(published_plan_year.benefit_groups.first)).to be_truthy
          expect(current_benefit_groups.include?(draft_plan_year.benefit_groups.first)).to be_truthy
          expect(renewal_benefit_groups).to be_empty
        end
      end
    end
  end
end

RSpec.describe Employers::EmployerHelper, "Scenarios for get_benefit_group_assignments_for_plan_year", type: :helper, dbclean: :after_each do
   
    let!(:employer_profile_cafe)      { FactoryGirl.create(:employer_profile) }
    let!(:employer_profile_salon)     { FactoryGirl.create(:employer_profile) }
    let!(:calender_year)              { TimeKeeper.date_of_record.year }

    let!(:middle_of_prev_year)        { Date.new(calender_year - 1, 6, 10) }
   
    let!(:shop_family)                { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:plan_year_start_on)         { Date.new(calender_year, 1, 1) }
    let!(:plan_year_end_on)           { Date.new(calender_year, 12, 31) }
    let!(:open_enrollment_start_on)   { Date.new(calender_year - 1, 12, 1) }
    let!(:open_enrollment_end_on)     { Date.new(calender_year - 1, 12, 10) }
    let!(:effective_date)             { plan_year_start_on }

    ["cafe", "salon"].each do |id|  
        employer_profile_id = "employer_profile_#{id}".to_sym
        plan_year_id = "plan_year_#{id}".to_sym
        let!(plan_year_id)                  { py = FactoryGirl.create(:plan_year,
                                               start_on: plan_year_start_on,
                                               end_on: plan_year_end_on,
                                               open_enrollment_start_on: open_enrollment_start_on,
                                               open_enrollment_end_on: open_enrollment_end_on,
                                               employer_profile: send(employer_profile_id)
                                             )

                                             blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                             white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
                                             py.benefit_groups = [blue, white]
                                             py.save
                                             py.update_attributes({:aasm_state => 'published'})
                                             py
                                          }
      end

    


    [{id: :barista, name: 'John', coverage_kind: "health", works_at: 'cafe', collar: "blue"}, 
     {id: :manager,  name: 'Grace', coverage_kind: "health", works_at: 'cafe', collar: "white"}, 
     {id: :janitor,  name: 'Bob', coverage_kind: "dental", works_at: 'cafe', collar: "blue"}, 
     {id: :hairdresser,  name: 'Tatiana', coverage_kind: "health", works_at: 'salon', collar: "blue"}
    ].each_with_index do |record, index|  
        id = record[:id]
        name = record[:name]
        works_at = record[:works_at]
        coverage_kind = record[:coverage_kind]
        social_class = "#{record[:collar]} collar"
        employer_profile_id = "employer_profile_#{works_at}".to_sym
        plan_year_id = "plan_year_#{works_at}".to_sym
        census_employee_id = "census_employee_#{id}".to_sym
        employee_role_id = "employee_role_#{id}".to_sym
        benefit_group_assignment_id = "benefit_group_assignment_#{id}".to_sym
        shop_enrollment_id = "shop_enrollment_#{id}".to_sym
        get_benefit_group = -> (year) { year.benefit_groups.detect {|bg| bg.title == social_class} }

        let!(id) { 
            FactoryGirl.create(:person, first_name: name, last_name: 'Smith', 
              dob: '1966-10-10'.to_date, ssn: "99966771#{index}") 
        }
    
        let!(census_employee_id) {
           FactoryGirl.create(:census_employee, first_name: name, last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: "99966770#{index}", created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year) 
        }
    
        let!(employee_role_id) {
            send(record[:id]).employee_roles.create(
              employer_profile: send(employer_profile_id),
              hired_on: send(census_employee_id).hired_on,
              census_employee_id: send(census_employee_id).id
            )
        }

        let!(benefit_group_assignment_id) {
          BenefitGroupAssignment.create({
            census_employee: send(census_employee_id),
            benefit_group: get_benefit_group.call(send(plan_year_id)),
            start_on: plan_year_start_on
          })
        }

        let!(shop_enrollment_id) { 
                                    benefit_group = get_benefit_group.call(send(plan_year_id))
                                    bga_id = send(benefit_group_assignment_id).id
                                    FactoryGirl.create(:hbx_enrollment,
                                                      household: shop_family.latest_household,
                                                      coverage_kind: coverage_kind,
                                                      effective_on: effective_date,
                                                      enrollment_kind: "open_enrollment",
                                                      kind: "employer_sponsored",
                                                      submitted_at: effective_date - 10.days,
                                                      benefit_group_id: benefit_group.id,
                                                      employee_role_id: send(employee_role_id).id,
                                                      benefit_group_assignment_id: bga_id
                                                    )
                                  }

          before do
            benefit_group_assignment = send(benefit_group_assignment_id)
            allow(send(employee_role_id)).to receive(:benefit_group).and_return(benefit_group_assignment.benefit_group)
            allow(send(census_employee_id)).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
            allow(send(shop_enrollment_id)).to receive(:employee_role).and_return(send(employee_role_id))
          end
    end
      
    context "get_benefit_group_assignments_for_plan_year" do
        it "should get the correct benefit group assignments for the businesses" do
          expect(Employers::EmployerHelper.get_benefit_group_assignments_for_plan_year(plan_year_cafe)).to eq [benefit_group_assignment_barista, benefit_group_assignment_manager, benefit_group_assignment_janitor]

          expect(Employers::EmployerHelper.get_benefit_group_assignments_for_plan_year(plan_year_salon)).to eq [benefit_group_assignment_hairdresser]      
        end
    end
end
