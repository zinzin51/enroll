
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePersonHbxIdAndDisableAccount < MongoidMigrationTask
  def migrate
    old_hbx = ENV["old_hbx"].to_s
    new_hbx = ENV["new_hbx"].to_s
    hbx = ENV["hbx"].to_s
    action = ENV["action"].to_s
    begin
      if action == "change_hbx"
        old_people = Person.where(hbx_id: old_hbx)
        if old_people.size != 1
          puts "Found No or more than 1 records for the hbx_id you entered" unless Rails.env.test?
          return
        end
        old_people.first.update_attributes!(hbx_id: new_hbx)
        puts "changed hbx_id" unless Rails.env.test?
      elsif action == "disable_account"
        people = Person.where(hbx_id: hbx)
        if people.size != 1
          puts "Found No or more than 1 records for the hbx_id you entered" unless Rails.env.test?
          return
        end
        people.first.update_attributes!(is_disabled: true)
        puts "Disabled person account" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}" unless Rails.env.test?
    end
  end
end
