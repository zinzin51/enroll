module SepAll
  
  def includeBothMarkets
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
    
  end

  def includeIVL

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

  end

  def includeShop

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

  def createSep
    qle = QualifyingLifeEventKind.find(params[:qle_id])
    @family = Family.find(params[:person])
    @name = params.permit(:firstName)[:firstName] + " " + params.permit(:lastName)[:lastName] 
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
    special_enrollment_period.market_kind = params.permit(:market_kind)[:market_kind] if params[:market_kind].present?
  
    if special_enrollment_period.save
        flash[:notice] = 'SEP added for ' + @name
      else
        flash[:error] = "Not saved"
      end
  end
end