require File.join(Rails.root, "app", "data_migrations", "move_special_verif_period")

namespace :migrations do
  desc "Move special verification period to ivl level"
  MoveVerifPeriod.define_task :move_special_verif_period => :environment
end