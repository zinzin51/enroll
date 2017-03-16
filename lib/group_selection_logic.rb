class GroupSelectionLogic

  def initialize(params)
    @params = params
    person_id = params.require(:person_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @coverage_household = @family.active_household.immediate_family_coverage_household
    @hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id].present?

    if params[:employee_role_id].present?
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
      @role = @employee_role
    elsif params[:resident_role_id].present?
      @resident_role = @person.resident_role
      @role = @resident_role
    else
      @consumer_role = @person.consumer_role
      @role = @consumer_role
    end
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    @shop_for_plans = params[:shop_for_plans].present? ? params{:shop_for_plans} : ''
    @employee_role = @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?
  end

  def self.select_market(person, params)
    return params[:market_kind] if params[:market_kind].present?
    if person.try(:has_active_employee_role?)
      'shop'
    elsif person.try(:has_active_consumer_role?)
      'individual'
    elsif person.try(:has_active_resident_role?)
      'coverall'
    else
      nil
    end
  end


  def individualhealth_benifits(session)
    if @params[:hbx_enrollment_id].present?
      session[:pre_hbx_enrollment_id] = @params[:hbx_enrollment_id]
      pre_hbx = HbxEnrollment.find(@params[:hbx_enrollment_id])
      pre_hbx.update_current(changing: true) if pre_hbx.present?
    end
    correct_effective_on = HbxEnrollment.calculate_effective_on_from(
        market_kind: 'individual',
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        family: @family,
        employee_role: nil,
        benefit_group: nil,
        benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
    @benefit = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select{|bcp| bcp.contains?(correct_effective_on)}.first.benefit_packages.select{|bp|  bp[:title] == "individual_health_benefits_#{correct_effective_on.year}"}.first

  end



end
