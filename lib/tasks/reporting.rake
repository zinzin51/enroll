require 'yajl'
namespace :reporting do
  desc "Denormalize the historic data, so we can build time dimensions"
  task :denormalize_historic_data => :environment do
    ReportSources::HbxEnrollmentStatistic.delete_all
    ReportSources::HbxEnrollmentStatistic.populate_historic_data!
  end

  desc "Use the denormalized historic data to populate the time dimensions"
  task :populate_time_dimensions => :environment do
    ReportSources::HbxEnrollmentStatistic.populate_time_dimensions!
  end

  desc "Denormalize and populate time dimentions in one go."
  task :denormalize_and_populate_historic_dimensions => :environment do
    Rake::Task["reporting:denormalize_historic_data"].invoke
    Rake::Task["reporting:populate_time_dimensions"].invoke
  end

  desc "Load the policy_statistics.json file"
  task :load_policy_statistics_json => :environment do
    start_time = Time.now
    puts "start to load json file."
    json = File.new('db/seedfiles/policy_statistics.json', 'r')
    puts "finish load json file. #{Time.now - start_time}"
    parser = Yajl::Parser.new
    p_json = parser.parse(json)

    count = 0

    puts "clear old data of analytics #{Time.now - start_time}"
    ReportSources::HbxEnrollmentStatistic.delete_all

    p_json.each do |b_rec|
      thr = Thread.new do
        plan = b_rec['plan'] || {}
        start_on = DateTime.iso8601(b_rec['policy_start_on']['$date']) rescue ''
        family_created_at = DateTime.iso8601(b_rec['family_created_at']['$date']) rescue ''
        purchased_at = DateTime.iso8601(b_rec['policy_purchased_at']['$date']) rescue ''

        ReportSources::HbxEnrollmentStatistic.create(
          policy_start_on: start_on,
          family_created_at: family_created_at,
          policy_purchased_at: purchased_at,
          plan_id: (plan['_id']['$oid'] rescue ''),
          hbx_id: b_rec['hbx_id'],
          enrollment_kind: b_rec['enrollment_kind'],
          aasm_state: b_rec['aasm_state'],
          coverage_kind: b_rec['coverage_kind'],
          family_id: (b_rec['family_id']['$oid'] rescue ''),
          rp_ids: b_rec['rp_ids'],
          benefit_group_id: ([b_rec['benefit_group_id']['$oid']] rescue []),
          benefit_group_assignment_id: ([b_rec['benefit_group_assignment_id']['$oid']] rescue []),
          state_transitions: b_rec['state_transitions'],
          market: plan['market'],
          consumer_role_id: ([b_rec['consumer_role_id']['$oid']] rescue []),
        )
        puts "#{count}"
        count += 1
      end
      thr.join
    end
    puts "-----------------load #{count}-------------"
  end
end
