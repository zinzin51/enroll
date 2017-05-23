require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeIvlToErAccount < MongoidMigrationTask
  def migrate
    ivl_hbx_id= ENV['ivl_hbx_id']
    employer_hbx_id= ENV['employer_hbx_id']
    return unless Person.where(hbx_id: ivl_hbx_id).size == 1
    return unless Person.where(hbx_id: employer_hbx_id).size == 1
    ivl = Person.where(hbx_id: ivl_hbx_id).first
    employer = Person.where(hbx_id: employer_hbx_id).first
    employer.consumer_role = ivl.consumer_role
    employer.save!
    employer.user.roles.append("consumer")
    employer.user.save!
  end
end