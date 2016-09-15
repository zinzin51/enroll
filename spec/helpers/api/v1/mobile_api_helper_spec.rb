require "rails_helper"

RSpec.describe Api::V1::MobileApiHelper, type: :helper, dbclean: :after_each do
   
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
      
  context "count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments" do
       it "should count enrollment for three people in the same family who work for the same employer, but onehas only dental" do
         
         #check that our connections are as we expect
         expect(barista.employee_roles.first.employer_profile.id).to eq (employer_profile_cafe.id)
         expect(barista.employee_roles.first.id).to eq (employee_role_barista.id)
         expect(barista.employee_roles.first.census_employee.id).to eq (census_employee_barista.id)
         salon_benefit_groups = [benefit_group_assignment_hairdresser]  
         cafe_benefit_groups = [benefit_group_assignment_barista, benefit_group_assignment_manager,
           benefit_group_assignment_janitor] 
         #there are three people working at the cafe, but only two have health insurance; none waived    
         expect(count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments(cafe_benefit_groups)).to eq [2, 0]
         #there is one person working at the salon, none waived    
         expect(count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments(salon_benefit_groups)).to eq [1, 0]
         
          
        end
      # TODO it "should count enrollment for two people in different households in the same family" do
      # -> both enrolled, none waived: [2,0]
      # -> both waived: [0,2]
      # -> one each: [1,1]
      # TODO people with shopped-for-but-not-bought or terminated policies - see UI for values
      # -> one shopped but didn't buy, one enrolled but terminated (e.g. got fired) [0, 0]
      # TODO 2 waived in the same family
      # -> [0,2]
      # TODO not enrolled this year but already enrolled for next year (2 plan years for same employer)
      # -> [1,0] if looking at next year
      # TODO enrolled this year but already waived for next year
      # -> [0,1] if looking at next year
      # TODO someone enrolled in two policies -- for instance one via SHOP, and another one privately -- ifthat's possible -- maybe some kind of enhanced coverage? 
      # the person has 1 health policy from employer, 1 dental policy from employer, and 1 policy fromindividual/non-SHOP
      # -> [1, 0]
  end

  context "should count enrollment for two people in different households in the same family" do
     include_context "BradyWorkAfterAll"
  
     before :all do
      create_brady_census_families
     end
  
     context "is created from an employer_profile, benefit_group, and coverage_household" do
      attr_reader :enrollment, :household, :coverage_household
      before(:all) do
        @household = mikes_family.households.first
        @coverage_household = household.coverage_households.first
  
          @enrollment1 = household.create_hbx_enrollment_from(
            employee_role: mikes_employee_role,
            coverage_household: coverage_household,
            benefit_group: mikes_benefit_group,
            benefit_group_assignment: @mikes_benefit_group_assignments
          )
          @enrollment1.save
          @enrollment2 = household.create_hbx_enrollment_from(
            employee_role: mikes_employee_role,
            coverage_household: coverage_household,
            benefit_group: mikes_benefit_group,
            benefit_group_assignment: @mikes_benefit_group_assignments
          )
          @enrollment2.save
          @enrollment1.waive_coverage_by_benefit_group_assignment("start a new job")
          @enrollment2.reload
  
      end
  
      it "should count enrollement for one waived in the same family" do 
          benefit_group_assignment = [@mikes_benefit_group_assignments]
          expect(HbxEnrollment.count_shop_and_health_enrolled_and_waived_by_benefit_group_assignments(  benefit_group_assignment)).to eq [0, 1]
      end
     end
  
     context "get_benefit_group_assignments_for_plan_year" do
      it "should get the correct benefit group assignments for the businesses" do
        expect(get_benefit_group_assignments_for_plan_year(plan_year_cafe)).to eq [   benefit_group_assignment_barista, benefit_group_assignment_manager, benefit_group_assignment_janitor ]
  
        expect(get_benefit_group_assignments_for_plan_year(plan_year_salon)).to eq [    benefit_group_assignment_hairdresser]      
      end
     end
  
     describe "staff_for_employers_including_pending", :dbclean => :after_all do
  	   before(:each) do
  	     employer_profile = []
  	     person = []
  	    
  	     3.times do
  	        employer_profile << FactoryGirl.build(:employer_profile)
  	     end
    
  	     6.times do
  	        person << FactoryGirl.build(:person)
  	     end
   
  	     FactoryGirl.create(:employer_staff_role, person: person[0], employer_profile_id: employer_profile[0].id,    aasm_state: "is_applicant")
  	     FactoryGirl.create(:employer_staff_role, person: person[1], employer_profile_id: employer_profile[0].id,    aasm_state: "is_active")
  	     FactoryGirl.create(:employer_staff_role, person: person[2], employer_profile_id: employer_profile[0].id,    aasm_state: "is_closed")
  	     FactoryGirl.create(:employer_staff_role, person: person[3], employer_profile_id: employer_profile[1].id,    aasm_state: "is_applicant")
  	     FactoryGirl.create(:employer_staff_role, person: person[4], employer_profile_id: employer_profile[1].id,    aasm_state: "is_closed")
  	     FactoryGirl.create(:employer_staff_role, person: person[5], employer_profile_id: employer_profile[2].id,    aasm_state: "is_active")
  	     
  	     @employer_profile_ids = [employer_profile[0].id, employer_profile[1].id, employer_profile[2].id] 
  	     @res = staff_for_employers_including_pending(@employer_profile_ids)  
  	   end
  	   
  	   it "Should give the correct count of staff members across multiple employers" do
  	    expect(@res[@employer_profile_ids[0]].count).to eql 2
  	    expect(@res[@employer_profile_ids[1]].count).to eql 1
  	    expect(@res[@employer_profile_ids[2]].count).to eql 1
  	   end
     end
  end
end
 