
require File.join(Rails.root, "lib/mongoid_migration_task")
require 'date'
class UpdateOpenEnrollmentEndDate < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      puts 'Issues with fein'
      return
    end
      new_date = Date.strptime(ENV['new_date'],'%m/%d/%Y')
      organizations.first.employer_profile.latest_plan_year.update_attribute(:open_enrollment_end_on, new_date)
      puts "Changing Open Enrollment End On date to #{new_date} for #{organizations.first.legal_name}" unless Rails.env.test?
  end
end