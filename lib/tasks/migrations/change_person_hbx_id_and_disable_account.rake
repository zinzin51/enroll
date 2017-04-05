require File.join(Rails.root, "app", "data_migrations", "change_person_hbx_id_and_disable_account")
# This rake task is to change person's hbx_id & also to disable the person's account
# RAILS_ENV=production bundle exec rake migrations:change_person_hbx_id_and_disable_account action="change_hbx" old_hbx="19749683" new_hbx="18840597"
# RAILS_ENV=production bundle exec rake migrations:change_person_hbx_id_and_disable_account action="disable_account" hbx="19869880"
namespace :migrations do
  desc "disable person's account or change hbx_id"
  ChangePersonHbxIdAndDisableAccount.define_task :change_person_hbx_id_and_disable_account => :environment
end 
