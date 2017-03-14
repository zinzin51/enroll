class Insured::GroupSelectionController < ApplicationController
  before_action :set_bookmark_url, only: [:new]
  before_action :initialize_common_vars, only: [:new, :create, :terminate_selection]
  # before_action :is_under_open_enrollment, only: [:new]

  def new
    @employee_role = find_employee_role
    @market_kind = find_market_kind(:new)
    is_resident = Person.find(params[:person_id]).resident_role?
    if (@market_kind == 'individual' || (@person.try(:has_active_employee_role?) &&
      @person.try(:has_active_consumer_role?)) || is_resident) && params[:hbx_enrollment_id].present?
      session[:pre_hbx_enrollment_id] = params[:hbx_enrollment_id]
      pre_hbx = HbxEnrollment.find(params[:hbx_enrollment_id])
      pre_hbx.update_current(changing: true) if pre_hbx.present?
    end
    @disable_market_kind = (@market_kind == "shop" ? "individual" : "shop") if change_by_qle_or_sep_enrollment?
    insure_hbx_enrollment_for_shop_qle_flow

    # Set @new_effective_on to the date choice selected by user if this is a QLE with date options available.
    @new_effective_on = Enrollments::Hbx::GroupSelection.new_effective_on(
      effective_on_option_selected: params[:effective_on_option_selected],
      market_kind: @market_kind,
      qle: change_by_qle_or_sep_enrollment?,
      family: @family,
      employee_role: @employee_role
    ) # write rspec

    generate_coverage_family_members_for_cobra
  end

  def create
    keep_existing_plan = params[:commit] == "Keep existing plan"
    @market_kind = find_market_kind(:create)
    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?

    @employee_role = find_employee_role
    @change_plan, hbx_enrollment, valid = Enrollments::Hbx::GroupSelection.build_hbx_enrollment(
      employee_role: @employee_role,
      hbx_enrollment: @hbx_enrollment,
      person: @person,
      coverage_household: @coverage_household,
      market_kind: @market_kind,
      change_by_qle_or_sep_enrollment: change_by_qle_or_sep_enrollment?,
      keep_existing_plan: keep_existing_plan,
      current_user: current_user,
      family: @family,
      change_plan: @change_plan,
      family_member_ids: family_member_ids,
      coverage_kind: @coverage_kind,
      original_application_type: session[:original_application_type]
    )

    unless valid
      raise "You may not enroll for cobra after #{Settings.aca.shop_market.cobra_enrollment_period.months} months later of coverage terminated."
    end

    # Set effective_on if this is a case of QLE with date options available.
    hbx_enrollment.effective_on = Enrollments::Hbx::GroupSelection.new_effective_on(
      effective_on_option_selected: params[:effective_on_option_selected]
    ) if params[:effective_on_option_selected].present?

    if hbx_enrollment.save
      hbx_enrollment.inactive_related_hbxs # FIXME: bad name, but might go away
      if keep_existing_plan
        hbx_enrollment.update_coverage_kind_by_plan
        redirect_to purchase_insured_families_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, hbx_enrollment_id: hbx_enrollment.id)
      elsif @change_plan.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      else
        # FIXME: models should update relationships, not the controller
        hbx_enrollment.benefit_group_assignment.update(hbx_enrollment_id: hbx_enrollment.id) if hbx_enrollment.benefit_group_assignment.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      end
    else
      raise "You must select the primary applicant to enroll in the healthcare plan"
    end
  rescue Exception => error
    flash[:error] = error.message
    logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
    employee_role_id = @employee_role.id if @employee_role
    consumer_role_id = @consumer_role.id if @consumer_role
    return redirect_to new_insured_group_selection_path(person_id: @person.id, employee_role_id: employee_role_id, change_plan: @change_plan, market_kind: @market_kind, consumer_role_id: consumer_role_id, enrollment_kind: @enrollment_kind)
  end

  def terminate_selection
    @hbx_enrollments = @family.enrolled_hbx_enrollments.select{|pol| pol.may_terminate_coverage? } || []
  end

  def terminate_confirm
    @hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))
  end

  def terminate
    term_date = Date.strptime(params.require(:term_date),"%m/%d/%Y")
    hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))

    if hbx_enrollment.may_terminate_coverage?
      hbx_enrollment.termination_submitted_on = TimeKeeper.datetime_of_record
      hbx_enrollment.terminate_benefit(term_date)
      hbx_enrollment.propogate_terminate(term_date)
      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  private

  def initialize_common_vars
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
  end

  def insure_hbx_enrollment_for_shop_qle_flow
    if @market_kind == 'shop' && change_by_qle_or_sep_enrollment? && @hbx_enrollment.blank?
      @hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
    end
  end

  private
  def generate_coverage_family_members_for_cobra
    if @market_kind == 'shop' && !change_by_qle_or_sep_enrollment? && @employee_role.present? && @employee_role.is_cobra_status?
      hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
      if hbx_enrollment.present?
        @coverage_family_members_for_cobra = hbx_enrollment.hbx_enrollment_members.map(&:family_member)
      end
    end
  end

  def find_employee_role
    return @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?
    @employee_role
  end

  def find_market_kind(action)
    return params[:market_kind] if params[:market_kind].present?
    case action
    when :new
      return @person.market_kind
    when :create
      return 'shop'
    end
  end

  def change_by_qle_or_sep_enrollment?
    @change_plan == 'change_by_qle' or @enrollment_kind == 'sep'
  end

  def family_member_ids
    params.require(:family_member_ids).collect() do |index, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end
  end


  # def is_under_open_enrollment
  #   if @employee_role.present? && !@employee_role.is_under_open_enrollment?
  #     flash[:alert] = "You can only shop for plans during open enrollment."
  #     redirect_to family_account_path
  #   end
  # end
end
