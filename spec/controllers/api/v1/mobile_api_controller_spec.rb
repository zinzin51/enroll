require 'rails_helper'

RSpec.describe Api::V1::MobileApiController do

 describe "get employers_list" do
    let!(:broker_role) {FactoryGirl.create(:broker_role)}
    let(:person) {double("person", broker_role: broker_role, first_name: "Brunhilde")}
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :person => person)}
    let(:organization) {
      o = FactoryGirl.create(:employer)
      a = o.primary_office_location.address
      a.address_1 = '500 Employers-Api Avenue'
      a.address_2 = '#555'
      a.city = 'Washington'
      a.state = 'DC'
      a.zip = '20001'
      o.primary_office_location.phone = Phone.new(:kind => 'main', :area_code => '202', :number => '555-9999')
      o.save
      o
    }
    let(:broker_agency_profile) { 
    	profile = FactoryGirl.create(:broker_agency_profile, organization: organization) 
    	broker_role.broker_agency_profile_id = profile.id
    	profile
    }

    let(:staff_user) { FactoryGirl.create(:user) }
    let(:staff) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user
      s.first_name = "Seymour"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'seymour@example.com')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0000')
      s.save
      s
    end

    let(:staff_user2) { FactoryGirl.create(:user) }
    let(:staff2) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user2
      s.first_name = "Beatrice"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'beatrice@example.com')
      s.phones << ::Phone.new(:kind => 'work', :area_code => '202', :number => '555-0001')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0002')
      s.save
      s
    end

    let (:broker_agency_account) { 
    	FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile) 
    }
    let (:employer_profile) do 
      e = FactoryGirl.create(:employer_profile, organization: organization) 
      e.broker_agency_accounts << broker_agency_account 
      e.save   
      e
    end
    
    before(:each) do 
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      sign_in(user)
    end

    it "should get summaries for employers where broker_agency_account is active" do
      
      #TODO tests for open_enrollment_start_on, open_enrollment_end_on, start_on, is_renewing?, etc              

      staff.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
      staff2.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      xhr :get, :employers_list, id: broker_agency_profile.id, format: :json
      expect(response).to have_http_status(:success), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
      details = assigns[:employer_details]
      detail = details[0]
      expect(details.count).to eq 1
      expect(detail[:employer_name]).to eq employer_profile.legal_name
      contacts = detail[:contact_info]

      seymour = contacts.detect  { |c| c[:first] == 'Seymour' }
      beatrice = contacts.detect { |c| c[:first] == 'Beatrice' }
      office = contacts.detect   { |c| c[:first] == 'Primary' }
      expect(seymour[:mobile]).to eq '(202) 555-0000'
      expect(seymour[:phone]).to eq ''
      expect(beatrice[:phone]).to eq '(202) 555-0001'
      expect(beatrice[:mobile]).to eq '(202) 555-0002'
      expect(seymour[:emails]).to include('seymour@example.com')
      expect(beatrice[:emails]).to include('beatrice@example.com')
      expect(office[:phone]).to eq '(202) 555-9999'
      expect(office[:address_1]).to eq '500 Employers-Api Avenue'
      expect(office[:address_2]).to eq '#555'
      expect(office[:city]).to eq 'Washington'
      expect(office[:state]).to eq 'DC'
      expect(office[:zip]).to eq '20001'
   
      output = JSON.parse(response.body)

      expect(output["broker_name"]                  ).to eq("Brunhilde")
      employer = output["broker_clients"][0]
      expect(employer).not_to be(nil), "in #{output}"
      expect(employer["employer_name"]                ).to eq(employer_profile.legal_name)
      expect(employer["employees_total"]              ).to eq(employer_profile.roster_size)   
      expect(employer["employees_enrolled"]           ).to be(nil)
      expect(employer["employees_waived"]             ).to be(nil)
      expect(employer["open_enrollment_begins"]       ).to be(nil)
      expect(employer["open_enrollment_ends"]         ).to be(nil)
      expect(employer["plan_year_begins"]             ).to be(nil)
      expect(employer["renewal_in_progress"]          ).to be(nil)
      expect(employer["renewal_application_available"]).to be(nil)
      expect(employer["renewal_application_due"]      ).to be(nil)
      expect(employer["employer_details_url"]         ).to end_with("mobile_api/employer_details/#{employer_profile.id}")
    end
  end

describe "GET employer_details" do  
  let(:user) { double("user", :person => person) }
  let(:person) { double("person", :employer_staff_roles => [employer_staff_role]) }
  let(:employer_staff_role) { double(:employer_profile_id => employer_profile.id) }
  let(:plan_year) { FactoryGirl.create(:plan_year) }
  let(:employer_profile) { plan_year.employer_profile}

  before(:each) do 
   sign_in(user)
  end

  it "should render 200 with valid ID" do
    get :employer_details, {employer_profile_id: employer_profile.id.to_s}
    expect(response).to have_http_status(200), "expected status 200, got #{response.status}: \n----\n#{response.body}\n\n"
   expect(response.content_type).to eq "application/json"
  end

  it "should render 404 with Invalid ID" do
    get :employer_details, {employer_profile_id: "Invalid Id"}
    expect(response).to have_http_status(404), "expected status 404, got #{response.status}: \n----\n#{response.body}\n\n"
  end

  it "should match with the expected result set" do
    get :employer_details, {employer_profile_id: employer_profile.id.to_s}
    output = JSON.parse(response.body)
    puts "#{employer_profile.inspect}"
    expect(output["employer_name"]).to eq(employer_profile.legal_name)
    expect(output["employees_total"]).to eq(employer_profile.roster_size)
    expect(output["active_general_agency"]).to eq(employer_profile.active_general_agency_legal_name)

    if employer_profile.show_plan_year
      expect(output["employees_waived"]).to eq(employer_profile.show_plan_year.waived_count)
      expect(output["open_enrollment_begins"]).to eq(employer_profile.show_plan_year.open_enrollment_start_on)
      expect(output["open_enrollment_ends"]).to eq(employer_profile.show_plan_year.open_enrollment_end_on) 
      expect(output["plan_year_begins"]).to eq(employer_profile.show_plan_year.start_on) 
      expect(output["renewal_in_progress"]).to eq(employer_profile.show_plan_year.is_renewing?) 
      expect(output["renewal_application_due"]).to eq(employer_profile.show_plan_year.due_date_for_publish) 
      expect(output["minimum_participation_required"]).to eq(employer_profile.show_plan_year. minimum_enrolled_count) 
    end
  end
 end
end