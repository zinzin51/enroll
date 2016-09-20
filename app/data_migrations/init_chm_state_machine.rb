require File.join(Rails.root, "lib/mongoid_migration_task")

class InitCHMStateMachine < MongoidMigrationTask

  def get_families
    Family.by_enrollment_individual_market
  end

  def migrate
    families_to_fix = get_families
    families_to_fix.flat_map(&:active_household).flat_map(&:coverage_households).flat_map(&:coverage_household_members).each do |member|
      begin
        member.evaluate_individual_market_eligiblity if member.family_member.person.consumer_role
      rescue => e
        $stderr.puts "Issue migrating coverage household member: #{member.id}, #{e.backtrace}"
      end
    end
  end
end