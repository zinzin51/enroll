# this rake task is for merge the ivl account to the er account
# er has user, ivl has no user
#expected outcome is to access the ivl account from user login

require File.join(Rails.root, "app", "data_migrations", "merge_ivl_to_er_account")

# RAILS_ENV=production bundle exec rake migrations:merge_ivl_to_er_account  ivl_hbx_id="123123", employer_hbx_id="321321321"
namespace :migrations do
  desc "merge_ivl_to_er_account"
  MergeIvlToErAccount.define_task :merge_ivl_to_er_account => :environment
end