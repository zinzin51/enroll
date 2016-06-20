require 'csv'

namespace :seed do
  desc "Load the ivl plans data"
  task :ivl_plans => :environment do
    years = [2015, 2016]
    years.each do |year|
      puts "start to load plans for #{year} -------------"
      CSV.foreach("./IVL#{year}.csv", headers: true) do |row|
        plan = Plan.where(name: row['Plan Name'], active_year: year).try(:first)
        if plan.present?
          puts "#{plan.name} - #{plan.hios_base_id}"
        else
          next if row[0].blank?
          if row['Network'] == "Nationwide In-Network"
            nationwide = true
            dc_in_network = false
          elsif ["DC Metro In-Network", "Signature - DC Metro In-Network"].include? row['Network']
            nationwide = false
            dc_in_network = true
          end
          if row[0].include? 'CareFirst'
            carrier_profile_id = CarrierProfile.find_by_legal_name("CareFirst")
          else
            carrier_profile_id = CarrierProfile.find_by_legal_name(row[0].match(/(\w+)/)[1])
          end
          if row['Plan Name'].downcase.include? 'dental'
            coverage_kind = 'dental'
          else
            coverage_kind = 'health'
          end
          plan = Plan.create(
            name: row['Plan Name'],
            coverage_kind: coverage_kind,
            carrier_profile_id: carrier_profile_id,
            active_year: year,
            market: 'individual',
            plan_type: row['Product'].try(:downcase),
            hios_base_id: row[2],
            hios_id: row[2],
            metal_level: row['Metal Level'].match(/(\w+)/)[1].try(:downcase),
            sbc_file: row['SBC File Name'],
            ehb: row['EHB %'].to_f/100.0,
            minimum_age: 20, maximum_age: 65, is_active: true,
            dental_level: 'low',
            nationwide: nationwide,
            dc_in_network: dc_in_network,
            provider_directory_url: row['Provider Directory URL'],
            rx_formulary_url: row['Rx Formulary URL']
          )
          start_on = Date.new(year, 1, 1)
          end_on = Date.new(year, 12, 31)
          plan.premium_tables.create(start_on: start_on, end_on: end_on, age: 20, cost: row['0-20'].to_f)

          (21..63).each do |age|
            plan.premium_tables.create(start_on: start_on, end_on: end_on, age: age, cost: row[age.to_s].to_f)
          end
          plan.premium_tables.create(start_on: start_on, end_on: end_on, age: 64, cost: row['64 +'].to_f)
          plan.premium_tables.create(start_on: start_on, end_on: end_on, age: 65, cost: row['64 +'].to_f)
        end
      end
    end
  end

  desc "Update the ivl plans data for copay and coinsurance"
  task :update_plans_for_copay_and_coinsurance => :environment do
    CSV.foreach("./health.csv", headers: true) do |row|
      plan = Plan.where(name: row['Plan Name'], active_year: row['Active Year']).try(:last)
      if plan.present?
        puts "update for #{plan.name} - #{plan.hios_base_id}"
        coinsurance = row['Co Pay'].match(/\$(\d+)/)[1].to_f rescue 0.0
        copay = row['Co Insurance'].match(/(\d+)\%/)[1].to_f rescue 0.0
        binding.pry if coinsurance == 0 and copay == 0
        plan.update(coinsurance: coinsurance, copay: copay)
      else
        next if row[0].blank?
      end
    end
  end
end
