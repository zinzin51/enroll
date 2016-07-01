class DashboardsController < ApplicationController
  layout "dashboard"
  before_action :init_plan_data, only: [:plan_comparison, :plan_visit_type]
  before_action :init_visit_types, only: [:plan_visit_type]
  before_action :init_weekly_report_selections, only: [:weekly_reports]

  def plan_comparison
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'individual'
    @data = []
    @type = params[:type].present? ? params[:type] : 'premium'
    @unit = params[:unit].present? ? params[:unit] : '$'
    @age = params[:age].present? ? params[:age].to_i : 25
    if params[:years].present?
      @years = params[:years].split("-").map(&:to_i)
    else
      @years = [2015, 2016]
    end
    @plan_names = get_plan_hash_by_market_kind_and_years(@market_kind, @years).keys

    @years.each do |year|
      name_for_hash = "cost #{@unit} " + (year == @years.min ? "reduce" : "increase")
      data_for_year = {name: name_for_hash, data: []}
      get_plan_hash_by_market_kind_and_years(@market_kind, @years).each do |name, value|
        plan = Plan.where(active_year: year, hios_id: value[year]).last
        case @type
        when 'premium'
          value = plan.premium_for(Date.new(year, 1, 1), @age) rescue 0
        when 'deductible'
          value = plan.deductible.to_s.gsub(/[$,]/, '').to_i rescue 0
        when 'family_deductible'
          value = plan.family_deductible.to_s.gsub(/[$,]/, '').to_i rescue 0
        end
        data_for_year[:data].push(value)
      end
      @data.push(data_for_year)
    end

    @plan_names.count.times do |i|
      if @unit == '$'
        value = (@data.last[:data][i] - @data.first[:data][i]).round(2)
      else
        value = ((@data.last[:data][i] - @data.first[:data][i]) / @data.first[:data][i].to_f * 100).round(1) rescue 0
      end
      if value > 0
        @data.last[:data][i] = value
        @data.first[:data][i] = 0
      elsif value < 0
        @data.last[:data][i] = 0
        @data.first[:data][i] = value
      else
        @data.last[:data][i] = 0
        @data.first[:data][i] = 0
      end
    end
  end

  def plan_visit_type
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'individual'
    @data = []
    @type = params[:type].present? ? params[:type] : 'copay'
    @unit = params[:unit].present? ? params[:unit] : '$'
    if params[:years].present?
      @years = params[:years].split("-").map(&:to_i)
    else
      @years = [2015, 2016]
    end
    @shop_plan_names = get_plan_hash_by_market_kind_and_years('shop', @years).keys
    @individual_plan_names = get_plan_hash_by_market_kind_and_years('individual', @years).keys
    @plan_name = params[:plan_name].present? ? params[:plan_name] : @individual_plan_names.first
    @years.each do |year|
      name_for_hash = "cost #{@unit} " + (year == @years.min ? "reduce" : "increase")
      data_for_year = {name: name_for_hash, data: []}
      plan = Plan.where(active_year: year, hios_id: @plan_hash[@market_kind][@plan_name][year]).last
      @visit_types.each do |vtype|
        value = plan.co_pay_by_visit_type(vtype) rescue 0
        data_for_year[:data].push(value)
      end

      @data.push(data_for_year)
    end
    @unit = '%' if @type == 'coinsurance'

    @visit_types.count.times do |i|
      if @unit == '$' || @type == 'coinsurance'
        value = (@data.last[:data][i] - @data.first[:data][i]).round(2)
      else
        value = ((@data.last[:data][i] - @data.first[:data][i]) / @data.first[:data][i].to_f * 100).round(1) rescue 0
      end
      if value > 0
        @data.last[:data][i] = value
        @data.first[:data][i] = 0
      elsif value < 0
        @data.last[:data][i] = 0
        @data.first[:data][i] = value
      else
        @data.last[:data][i] = 0
        @data.first[:data][i] = 0
      end
    end
  end

  def key_indicators
    @reports_for_month_options, @reports_for_month = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('month')
    @reports_for_week_options, @reports_for_week = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('week')
    @reports_for_day_options, @reports_for_day = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('day')
  end

  def weekly_reports
    @kind = params[:kind].present? ? params[:kind] : @selections.first.first
    @subkind = params[:subkind].present? ? params[:subkind] : @selections.first.last.keys.first
    action_name = @selections[@kind][@subkind]
    if action_name.present?
      @report_for_options, @report_data, @title, @table_kind = ReportSources::HbxEnrollmentStatistic.public_send(action_name)
    else
      @report_for_options, @report_data, @title, @table_kind = [[], [], '']
    end
  end

  private
  def init_plan_data
    @plan_hash = {
      'shop' => {
        'BluePreferred PPO $1,000 100%/80%'              => {2014=>'78079DC0220012-01', 2015=>'78079DC0220012-01', 2016=>'78079DC0220020-01'},
        'HealthyBlue Advantage $1,500'                   => {2014=>'86052DC0520004-01', 2015=>'86052DC0520004-01', 2016=>'86052DC0440014-01'},
        'HealthyBlue PPO $1,500'                         => {2014=>'78079DC0300004-01', 2015=>'78079DC0300004-01', 2016=>'78079DC0220027-01'},
        'KP DC Gold 0/20/Dental/Ped Dental'              => {2014=>'94506DC0350004-01', 2015=>'94506DC0350004-01', 2016=>'94506DC0350004-01'},
        'BluePreferred PPO $500 $20/$30'                 => {2014=>'', 2015=>'78079DC0220019-01', 2016=>'78079DC0220021-01'},
        'BluePreferred PPO 100%/80%, Rx:$10/$45/$65/50%' => {2014=>'78079DC0220013-01', 2015=>'78079DC0220013-01', 2016=>'78079DC0220024-01'},
        'BlueChoice HMO $250'                            => {2014=>'86052DC0460006-01', 2015=>'86052DC0460006-01', 2016=>'86052DC0460010-01'},
        'BluePreferred PPO $1,000 80%/60%'               => {2014=>'78079DC0220014-01', 2015=>'78079DC0220014-01', 2016=>'78079DC0220020-01'},
        'BlueChoice Advantage $1000'                     => {2014=>'86052DC0440008-01', 2015=>'86052DC0440008-01', 2016=>'86052DC0440010-01'},
        'DC Gold OAMC 90/50'                             => {2014=>'77422DC0070013-01', 2015=>'77422DC0070013-01', 2016=>'77422DC0070013-01'},
      },
      'individual' => {
        'BluePreferred Platinum $0'                               => {2014=>'78079DC0210001-01', 2015=>'78079DC0210001-01', 2016=>'78079DC0210001-01'},
        'HealthyBlue Platinum $0'                                 => {2014=>'86052DC0430002-01', 2015=>'86052DC0430002-02', 2016=>'86052DC0400008-02'},
        'BlueCross BlueShield Preferred 500, A Multi-State Plan'  => {2014=>'78079DC0160001-01', 2015=>'78079DC0160001-01', 2016=>'78079DC0160001-01'},
        'BlueChoice Gold $0'                                      => {2014=>'86052DC0400002-01', 2015=>'86052DC0400002-01', 2016=>'86052DC0400002-01'},
        'HealthyBlue Gold $1,500'                                 => {2014=>'86052DC0430001-01', 2015=>'86052DC0430001-01', 2016=>'86052DC0400003-01'},
        'BlueCross BlueShield Preferred 1500, A Multi-State Plan' => {2014=>'78079DC0180001-01', 2015=>'78079DC0180001-01', 2016=>'78079DC0160002-01'},
        'BlueChoice HSA Silver $1,300'                            => {2014=>'86052DC0410003-01', 2015=>'86052DC0410003-01', 2016=>'86052DC0400006-01'},
        'BlueChoice HSA Bronze $6,000'                            => {2014=>'86052DC0410002-01', 2015=>'86052DC0410002-01', 2016=>'86052DC0400005-01'},
        'BlueChoice HSA Bronze $4,000'                            => {2014=>'86052DC0410001-01', 2015=>'86052DC0410001-01', 2016=>'86052DC0400005-01'},
        'BlueChoice Young Adult $6,600'                           => {2014=>'86052DC0400004-01', 2015=>'86052DC0400004-01', 2016=>'86052DC0400004-01'},
      }
    }
  end

  def get_plan_hash_by_market_kind_and_years(market_kind='individual', years=[])
    @plan_hash[market_kind].select do |key, value|
      result = true
      years.each do |year|
        result = false if value[year].blank?
      end
      result
    end
  end

  def init_visit_types
    @visit_types = [
      "Primary Care Visit to Treat an Injury or Illness",
      "Specialist Visit",
      "Outpatient Surgery Physician/Surgical Services",
      "Urgent Care Centers or Facilities",
      "Emergency Room Services",
      "Inpatient Hospital Services (e.g., Hospital Stay)",
      "Prenatal and Postnatal Care",
      "Generic Drugs",
      "Preferred Brand Drugs",
      "Non-Preferred Brand Drugs",
      "Specialty Drugs",
      "Imaging (CT/PET Scans, MRIs)",
      "Laboratory Outpatient and Professional Services",
      "X-rays and Diagnostic Imaging",
      "Prescription Drugs Other",
    ]
  end

  def init_weekly_report_selections
    @selections = {
      "Health Covered Lives" => {
        'Individual Market Total Covered Lives' => 'health_covered_lives_by_year',
        'Individual Market Age Group' => 'health_covered_lives_by_age',
        'Individual Market Gender' => 'health_covered_lives_by_gender',
        'Individual Market Covered Lives Zip Codes' => '',
      },
      "Health Plans" => {
        'Individual Market Total Plans' => 'health_plans_by_year',
        'Individual Market Count of People on Plan' => 'health_plans_by_member_count',
        'Individual Market Standard Plans' => 'health_plans_by_standard',
        'Individual Market Carriers' => 'health_plans_by_carrier_profile',
        'Individual Market Metal Level' => 'health_plans_by_metal_level',
        'Individual Market Plan Type' => 'health_plans_by_plan_type',
        'Individual Market APTC and CSR' => 'health_plans_by_csr',
        'Individual Market Plan Selection' => 'health_plans_by_name',
      },
      "Dental Covered Lives" => {
        'Individual Market Dental Total Covered Lives' => 'dental_covered_lives_by_year',
        'Individual Market Dental Age Groups' => '',
        'Individual Market Dental Gender' => '',
      },
      "Dental Plans" => {
        'Individual Market Dental Total Plans' => 'dental_plans_by_year',
        'Individual Market Dental Carriers' => 'dental_plans_by_carrier_profile',
        'Individual Market Dental Count of People on Plan' => 'dental_plans_by_member_count',
      }
    }
  end
end




