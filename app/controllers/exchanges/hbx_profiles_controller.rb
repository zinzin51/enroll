class Exchanges::HbxProfilesController < ApplicationController

  include DataTablesAdapter

  before_action :check_hbx_staff_role, except: [:request_help, :show, :assister_index, :family_index]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]
  before_action :find_hbx_profile, only: [:employer_index, :broker_agency_index, :inbox, :configuration, :show]
  #before_action :authorize_for, except: [:edit, :update, :destroy, :request_help, :staff_index, :assister_index]
  #before_action :authorize_for_instance, only: [:edit, :update, :destroy]
  before_action :check_csr_or_hbx_staff, only: [:family_index]
  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def employer_index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @employer_profiles = @organizations.map {|o| o.employer_profile}

    respond_to do |format|
      format.html { render "employers/employer_profiles/index" }
      format.js {}
    end
  end

  def staff_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(:$or => [{csr_role: {:$exists => true}}, {assister_role: {:$exists => true}}])
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def assister_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(assister_role: {:$exists =>true})
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def find_email(agent, role)
    if role == 'Broker'
      agent.try(:broker_role).try(:email).try(:address)
    else
      agent.try(:user).try(:email)
    end
  end

  def request_help
    role = nil
    if params[:type]
      cac_flag = params[:type] == 'CAC'
      match = CsrRole.find_by_name(params[:firstname], params[:lastname], cac_flag)
      if match.count > 0
        agent = match.first
        role = cac_flag ? 'Certified Applicant Counselor' : 'Customer Service Representative'
      end
    else
      if params[:broker].present?
        agent = Person.find(params[:broker])
        broker_role_id = agent.broker_role.id
        consumer = Person.find(params[:person])
        family = consumer.primary_family
        family.hire_broker_agency(broker_role_id)
        role = 'Broker'
      else
        agent = Person.find(params[:assister])
        role = 'In-Person Assister'
      end
    end
    if role
      status_text = 'Message sent to ' + role + ' ' + agent.full_name + ' <br>' 
      if find_email(agent, role)
        agent_assistance_messages(params,agent,role)
      else

        status_text = "Agent has no email.   Please select another"
      end
    else
      status_text = call_customer_service params[:firstname].strip, params[:lastname].strip
    end
    @person = Person.find(params[:person])
    broker_view = render_to_string 'insured/families/_consumer_brokers_widget', :layout => false
    render :text => {broker: broker_view, status: status_text}.to_json, layout: false
  end

  def family_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.page page_no
      @total = Family.count
    else
      total_families = Person.search(@q).map(&:families).flatten.uniq
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      format.html { render "insured/families/index" }
      format.js {}
    end
  end


  def sep_index

    @event_kinds_all = ['1st of next month', '15th day rule'];
    @event_kinds_default = ['1st of next month'];
    @qualifying_life_events_shop = QualifyingLifeEventKind.shop_market_events
    @qualifying_life_events_individual = QualifyingLifeEventKind.individual_market_events

    respond_to do |format|
      format.html { render "sep/approval/sep_index" }
      format.js {}
    end
  end

  def sep_index_datatable

    if Family.exists(special_enrollment_periods: true).present?

      if(params[:q] == 'both')

        dt_query = extract_datatable_parameters

        families_dt = []

        all_families = Family.exists(special_enrollment_periods: true)

        #@families = all_families.to_a     

        if dt_query.search_string.blank?
          families_dt = all_families
        else
          person_ids = Person.search(dt_query.search_string).pluck(:id)
          families_dt = all_families.where({
          "family_members.person_id" => {"$in" => person_ids}
          })
        end

        @draw = dt_query.draw
        @total_records = all_families.count
        @records_filtered = families_dt.count
        @families = families_dt.skip(dt_query.skip).limit(dt_query.take)
        @state = 'both'

     elsif(params[:q] == 'ivl')

        if QualifyingLifeEventKind.where(:market_kind => 'individual').present?
          ivl_qles = QualifyingLifeEventKind.where(:market_kind => 'individual').map(&:id)  
          all_families_in_ivl = Family.where(:"special_enrollment_periods.qualifying_life_event_kind_id".in => ivl_qles)
          
          dt_query = extract_datatable_parameters
          families_dt = []

          if dt_query.search_string.blank?
            families_dt = all_families_in_ivl
          else
            person_ids = Person.search(dt_query.search_string).pluck(:id)
            families_dt = all_families_in_ivl.where({
            "family_members.person_id" => {"$in" => person_ids}
            })
          end

          @draw = dt_query.draw
          @total_records = all_families_in_ivl.count
          @records_filtered = families_dt.count
          @families = families_dt.skip(dt_query.skip).limit(dt_query.take)
          @state = 'ivl'
        end

     else

        if QualifyingLifeEventKind.where(:market_kind => 'shop').present?
            shop_qles = QualifyingLifeEventKind.where(:market_kind => 'shop').map(&:id)  
            all_families_in_shop = Family.where(:"special_enrollment_periods.qualifying_life_event_kind_id".in => shop_qles)
        
            dt_query = extract_datatable_parameters
            families_dt = []

            if dt_query.search_string.blank?
              families_dt = all_families_in_shop
            else
              person_ids = Person.search(dt_query.search_string).pluck(:id)
              families_dt = all_families_in_shop.where({
              "family_members.person_id" => {"$in" => person_ids}
              })
            end

            @draw = dt_query.draw
            @total_records = all_families_in_shop.count
            @records_filtered = families_dt.count
            @families = families_dt.skip(dt_query.skip).limit(dt_query.take)
            @state = 'shop'

        end
     end

    end
    
    @event_kinds_all = ['1st of next month', '15th day rule'];
    @event_kinds_default = ['1st of next month'];
    @qualifying_life_events_shop = QualifyingLifeEventKind.shop_market_events
    @qualifying_life_events_individual = QualifyingLifeEventKind.individual_market_events

    render

  end


  def broker_agency_index
    @broker_agency_profiles = BrokerAgencyProfile.all

    respond_to do |format|
      format.html { render "broker" }
      format.js {}
    end
  end

  def issuer_index
    @issuers = CarrierProfile.all

    respond_to do |format|
      format.html { render "issuer_index" }
      format.js {}
    end
  end

  def product_index
    respond_to do |format|
      format.html { render "product_index" }
      format.js {}
    end
  end

  def configuration
    @time_keeper = Forms::TimeKeeper.new

    respond_to do |format|
      format.html { render partial: "configuration_index" }
      format.js {}
    end
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show

    if current_user.has_csr_role? || current_user.try(:has_assister_role?)
      redirect_to home_exchanges_agents_path
      return
    else 
      unless current_user.has_hbx_staff_role?
        redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
        return
      end
    end
    session[:person_id] = nil
    @unread_messages = @profile.inbox.unread_messages.try(:count) || 0

  end


    def add_new_sep
    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      @family = Family.find(params[:person])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = params.permit(:effective_on_date)[:effective_on_date] if params[:effective_on_date].present?
      special_enrollment_period.start_on = Date.strptime(params[:start_on], "%m/%d/%Y") if params[:start_on].present?
      special_enrollment_period.end_on = Date.strptime(params[:end_on], "%m/%d/%Y") if params[:end_on].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.admin_comment = params.permit(:admin_comment)[:admin_comment] if params[:admin_comment].present?
      special_enrollment_period.csl_num = params.permit(:csl_num)[:csl_num] if params[:csl_num].present?
      special_enrollment_period.next_poss_effective_date = Date.strptime(params[:next_poss_effective_date], "%m/%d/%Y") if params[:next_poss_effective_date].present?
      special_enrollment_period.option1_date = Date.strptime(params[:option1_date], "%m/%d/%Y") if params[:option1_date].present?
      special_enrollment_period.option2_date = Date.strptime(params[:option2_date], "%m/%d/%Y") if params[:option2_date].present?
      special_enrollment_period.option3_date = Date.strptime(params[:option3_date], "%m/%d/%Y") if params[:option3_date].present?
      special_enrollment_period.qle_on = Date.strptime(params[:event_date], "%m/%d/%Y") if params[:event_date].present?
      
      special_enrollment_period.save
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

  # GET /exchanges/hbx_profiles/new
  def new
    @organization = Organization.new
    @hbx_profile = @organization.build_hbx_profile
  end

  # GET /exchanges/hbx_profiles/1/edit
  def edit
  end

  # GET /exchanges/hbx_profiles/1/inbox
  def inbox
    @inbox_provider = current_user.person.hbx_staff_role.hbx_profile
    @folder = params[:folder] || 'inbox'
    @sent_box = true
  end

  # POST /exchanges/hbx_profiles
  # POST /exchanges/hbx_profiles.json
  def create
    @organization = Organization.new(organization_params)
    @hbx_profile = @organization.build_hbx_profile(hbx_profile_params.except(:organization))

    respond_to do |format|
      if @hbx_profile.save
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully created.' }
        format.json { render :show, status: :created, location: @hbx_profile }
      else
        format.html { render :new }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exchanges/hbx_profiles/1
  # PATCH/PUT /exchanges/hbx_profiles/1.json
  def update
    respond_to do |format|
      if @hbx_profile.update(hbx_profile_params)
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @hbx_profile }
      else
        format.html { render :edit }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exchanges/hbx_profiles/1
  # DELETE /exchanges/hbx_profiles/1.json
  def destroy
    @hbx_profile.destroy
    respond_to do |format|
      format.html { redirect_to exchanges_hbx_profiles_path, notice: 'HBX Profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def set_date
    forms_time_keeper = Forms::TimeKeeper.new(params[:forms_time_keeper])
    begin
      forms_time_keeper.set_date_of_record(forms_time_keeper.forms_date_of_record)
      flash[:notice] = "Date of record set to " + TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    rescue Exception=>e
      flash[:error] = "Failed to set date of record, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

private
  def agent_assistance_messages(params, agent, role)
    if params[:person].present?
      insured = Person.find(params[:person])
      first_name = insured.first_name
      last_name = insured.last_name
      name = insured.full_name
      insured_email = insured.emails.last.try(:address) || insured.try(:user).try(:email)
      root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + params[:person] +'&original_application_type:'
      body = 
        "Please contact #{insured.first_name} #{insured.last_name}. <br/> " + 
        "Plan Shopping help request from Person Id #{insured.id}, email #{insured_email}.<br/>" +
        "Additional PII is SSN #{insured.ssn} and DOB #{insured.dob}.<br>" +
        "<a href='" + root+"phone'>Assist Customer</a>  <br>" 
    else
      first_name = params[:first_name]
      last_name = params[:last_name]
      name = first_name.to_s + ' ' + last_name.to_s 
      insured_email = params[:email]
      body =  "Please contact #{first_name} #{last_name}. <br/>" +
        "Plan shopping help has been requested by #{insured_email}<br>"
      body += "SSN #{params[:ssn]} <br>" if params[:ssn].present?
      body += "DOB #{params[:dob]} <br>" if params[:dob].present?
    end
    hbx_profile = HbxProfile.find_by_state_abbreviation('DC')
    message_params = {
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Please contact #{first_name} #{last_name}. ",
      body: body,
      }
    create_secure_message message_params, hbx_profile, :sent
    create_secure_message message_params, agent, :inbox
    result = UserMailer.new_client_notification(find_email(agent,role), first_name, name, role, insured_email, params[:person].present?)
    result.deliver_now
    puts result.to_s if Rails.env.development?
   end  

  def find_hbx_profile
    @profile = current_user.person.try(:hbx_staff_role).try(:hbx_profile)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = HbxProfile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def organization_params
    params[:hbx_profile][:organization].permit(:organization_attributes)
  end

  def hbx_profile_params
    params[:hbx_profile].permit(:hbx_profile_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def check_csr_or_hbx_staff
    unless current_user.has_hbx_staff_role? || (current_user.person.csr_role && !current_user.person.csr_role.cac)
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member or a CSR" }
    end
  end

  def authorize_for_instance
    authorize @hbx_profile, "#{action_name}?".to_sym 
  end

  def call_customer_service(first_name, last_name)
    "No match found for #{first_name} #{last_name}.  Please call Customer Service at: (855)532-5465 for assistance.<br/>"
  end
end
