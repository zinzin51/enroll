
require File.join(Rails.root, "lib/mongoid_migration_task")
#person.primary_family.active_household.latest_active_tax_household.eligibility_determinations
class AddAptcAndCsrToPerson < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id:ENV['hbx_id'])
    action = ENV['action']
    if person.size==0
      puts "No person was found with the given hbx_id" #unless Rails.env.test?
      return
    elsif person.size > 1
      puts "More than one person was found with the given hbx_id" #unless Rails.env.test?
      return
    end
    if person.first.primary_family.nil?
      puts "No primary_family exists for person with the given hbx_id" #unless Rails.env.test?
      return
    end
    primary_family = person.first.primary_family

   if primary_family.active_household.nil?
     puts "No active household  exists for person with the given hbx_id" #unless Rails.env.test?
     return
   end
   active_household= primary_family.active_household
   if  active_household.latest_active_tax_household.nil?
     puts "No active tax household  exists for person with the given hbx_id" #unless Rails.env.test?
     return
   end

   eligibility_determinations = active_household.latest_active_tax_household.eligibility_determinations
   if eligibility_determinations.nil?
     puts "No eligibility_determinations for person with the given hbx_id" #unless Rails.env.test?
     return
   end
    case action
      when "change_aptc"
        change_aptc(eligibility_determinations)
      when "change_csr"
        change_csr(eligibility_determinations)
    end
  end

  def change_aptc(eligibility_determinations)
    eligibility_determinations.each do |i|
      i.max_aptc={"cents"=> ENV['max_aptc'].to_f*100, "currency_iso"=>"USD"}
      i.save
    end
  end

  def change_csr(eligibility_determinations)
    eligibility_determinations.each do |i|
      i.csr_percent_as_integer = ENV['csr_percent_as_integer'].to_i
      i.csr_percent=ENV['csr_percent']
      i.save!
    end
  end

end
