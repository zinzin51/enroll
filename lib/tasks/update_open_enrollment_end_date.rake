require File.join(Rails.root, "app", "data_migrations", "update_open_enrollment_end_date")
# This rake task is to change the open enrollment end on date
# RAILS_ENV=production bundle exec rake migrations:update_open_enrollment_end_date fein=521730890 new_date="1/1/2017"
namespace :migrations do
  desc "extending the open enrollment end date for conversion employers"
  UpdateOpenEnrollmentEndDate.define_task :update_open_enrollment_end_date => :environment
end
