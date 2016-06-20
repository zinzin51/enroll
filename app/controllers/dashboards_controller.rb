class DashboardsController < ApplicationController
  layout "dashboard"

  def plan_comparison
    @plan_names =[
    "BlueChoice HSA Bronze $4,000",
    "BlueChoice HSA Bronze $6,000",
    "BlueChoice HSA Silver $1,300",
    "BlueCross BlueShield Preferred 1500, A Multi-State Plan",
    "HealthyBlue Gold $1,500",
    "BlueChoice Gold $0",
    "BlueCross BlueShield Preferred 500, A Multi-State Plan",
    "HealthyBlue Platinum $0",
    "BluePreferred Platinum $0",
    "BlueChoice Young Adult $6,600"
    ]

    @data = []
    @type = params[:type].present? ? params[:type] : 'premium'
    @unit = params[:unit].present? ? params[:unit] : '$'
    @age = params[:age].present? ? params[:age].to_i : 25
    if params[:years].present?
      @years = params[:years].split("-").map(&:to_i)
    else
      @years = [2014, 2015]
    end
    @years.each do |year|
      data_for_year = {name: year, data: []}
      @plan_names.each do |name|
        if year == @years.min
          plan = Plan.where(name: name, active_year: year).last
        else
          plan = Plan.where(name: name, active_year: @years.min).last.try(:renewal_plan)
        end

        case @type
        when 'premium'
          value = plan.premium_for(Date.new(year, 1, 1), @age) rescue 0
        when 'deductible'
          value = plan.deductible.to_s.gsub(/[$,]/, '').to_i rescue 0
        when 'family_deductible'
          value = plan.family_deductible.to_s.gsub(/[$,]/, '').to_i rescue 0
        when 'coinsurance'
          value = plan.co_insurance rescue 0
        end
        data_for_year[:data].push(value)
      end
      @data.push(data_for_year)
    end
    @unit = '%' if @type == 'coinsurance'

    @plan_names.count.times do |i|
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

  def copay_comparison
    @plan_names =[
    "BlueChoice HSA Bronze $4,000",
    "BlueChoice HSA Bronze $6,000",
    "BlueChoice HSA Silver $1,300",
    "BlueCross BlueShield Preferred 1500, A Multi-State Plan",
    "HealthyBlue Gold $1,500",
    "BlueChoice Gold $0",
    "BlueCross BlueShield Preferred 500, A Multi-State Plan",
    "HealthyBlue Platinum $0",
    "BluePreferred Platinum $0",
    "BlueChoice Young Adult $6,600"
    ]

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

    @data = []
    @unit = params[:unit].present? ? params[:unit] : '$'
    @plan_name = params[:plan_name].present? ? params[:plan_name] : @plan_names.first
    if params[:years].present?
      @years = params[:years].split("-").map(&:to_i)
    else
      @years = [2014, 2015]
    end
    @years.each do |year|
      data_for_year = {name: year, data: []}
      if year == @years.min
        plan = Plan.where(name: @plan_name, active_year: year).last
      else
        plan = Plan.where(name: @plan_name, active_year: @years.min).last.try(:renewal_plan)
      end
      @visit_types.each do |vtype|
        value = plan.co_pay_by_visit_type(vtype) rescue 0
        data_for_year[:data].push(value)
      end

      @data.push(data_for_year)
    end

    @visit_types.count.times do |i|
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

  def key_indicators
    @reports_for_month_options, @reports_for_month = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('month')
    @reports_for_week_options, @reports_for_week = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('week')
    @reports_for_day_options, @reports_for_day = ReportSources::HbxEnrollmentStatistic.report_for_chart_by('day')
  end
end
