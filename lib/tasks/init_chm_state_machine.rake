require File.join(Rails.root, "app", "data_migrations", "init_chm_state_machine")

namespace :migrations do
  desc "Init state machine for coverage household members"
  InitCHMStateMachine.define_task :init_chm_state_machine => :environment
end