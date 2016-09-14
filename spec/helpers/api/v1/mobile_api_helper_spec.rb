require "rails_helper"

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