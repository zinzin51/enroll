require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveVerifPeriod < MongoidMigrationTask

  def get_families
    Family.where("households.hbx_enrollments.special_verification_period"=>{"$exists"=>true})
  end

  def migrate
    families_to_fix = get_families
    families_to_fix.each do |family|
      verification_date = family.active_household.hbx_enrollments.where(:special_verification_period => {"$exists" => true}).first.special_verification_period
      begin
        family.active_household.update_attributes!(:special_verification_period => verification_date)
      rescue => e
        $stderr.puts "Issue migrating family: #{family.id}, #{e.backtrace}"
      end
    end
  end
end