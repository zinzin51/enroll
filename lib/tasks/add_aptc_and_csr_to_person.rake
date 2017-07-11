require File.join(Rails.root, "app", "data_migrations", "add_aptc_and_csr_to_person")
# This rake task is to change the attributes on enrollment
# RAILS_ENV=production bundle exec rake migrations:add_aptc_and_csr_to_person hbx_id=531828 max_aptc=407.00 action="change_aptc"
# RAILS_ENV=production bundle exec rake migrations:add_aptc_and_csr_to_person hbx_id=531828 csr_percent=0.73  csr_percent_as_integer=73  action="change_csr"


namespace :migrations do
  desc "add_aptc_and_csr_to_person"
  AddAptcAndCsrToPerson.define_task :add_aptc_and_csr_to_person => :environment
end
