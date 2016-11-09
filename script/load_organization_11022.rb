
fein ="521992631"
folder_name = "tmp/dump_#{fein}"

def files
  fein ="521992631"
  folder_name = "tmp/dump_#{fein}"
  Dir.entries(folder_name)
end

def load_census_employee(file)
  fein ="521992631"
  folder_name = "tmp/dump_#{fein}"
  ce_file = File.open(File.expand_path(folder_name+"/#{file}"),'rb')
  ce = Marshal.load(ce_file)
  ce_clone = ce.clone
  ce_clone.ssn ="123456789"
  ce_clone.save(:validate => false)
end

def load_person_and_families(file)
  fein ="521992631"
  folder_name = "tmp/dump_#{fein}"
  person_file = File.open(File.expand_path(folder_name+"/#{file}"),'rb')
  person = Marshal.load(person_file)
  person_clone = person.clone
  family_files = files.select { |f| f.match("dump_marshal_family_#{person.id}") }
  family_files.each do |file|
    family_file = File.open(File.expand_path(folder_name+"/#{file}"),'rb')
    family = Marshal.load(family_file)
    family_clone = family.clone
    family_clone.primary_family_member.person_id = person_clone.id
    family_clone.save(:validate => false)
  end
  person_clone.ssn = "123456789"
  person_clone.save(:validate => false)
end

###
begin
  #load employer profile
  org_file = File.open(File.expand_path(folder_name+"/org"),'rb')
  org = Marshal.load(org_file)
  org_clone = org.clone
  org_clone.save
  bg = org_clone.employer_profile.plan_years.last.benefit_groups.last
  # emp_file = File.open(File.expand_path(folder_name+"/employer_profile"),'rb')
  # empl_profile = Marshal.load(emp_file)
  # empl_profile_clone = empl_profile.clone
  # empl_profile_clone.save

  # load broker agency profile
  broker_agency_file = File.open(File.expand_path(folder_name+"/broker_agency"),'rb')
  broker_agency = Marshal.load(broker_agency_file)
  broker_agency_clone = broker_agency.clone
  broker_agency_clone.save

  #load reference health plan
  plan_file = File.open(File.expand_path(folder_name+"/plan"),'rb')
  plan = Marshal.load(plan_file)
  plan_clone = plan.clone
  plan_clone.save
  bg.elected_plans << plan_clone
  bg.reference_plan_id = plan_clone.id
  bg.save(:validate => false)

  #load dental reference plan
  dental_plan_file = File.open(File.expand_path(folder_name+"/dental_plan"),'rb') rescue nil
  if !dental_plan_file.nil?
    dental_plan = Marshal.load(dental_plan_file)
    dental_plan_clone = dental_plan.clone
    dental_plan_clone.save
    bg.elected_plans << dental_plan_clone
    bg.dental_reference_plan_id = dental_plan_clone.id
    bg.save(:validate => false)
  end

  br_profile = org.employer_profile.broker_agency_profile
  br_role_file = File.open(File.expand_path(folder_name+"/br_role"),'rb')
  brkr_role = Marshal.load(br_role_file)
  brkr_role_clone = brkr_role.clone
  # brkr_role_clone.save
  br_profile.primary_broker_role_id = brkr_role_clone.id
  br_profile.save

  person_broker_file = File.open(File.expand_path(folder_name+"/person_broker"),'rb')
  person_brkr = Marshal.load(person_broker_file)
  person_brkr_clone = person_brkr.clone
  person_brkr_clone.ssn ="987654321"
  person_brkr_clone.save(:validate => false)



  files.each do |file|
    case file
    when /dump_marshal_census_employee/
      load_census_employee(file)
    when /dump_marshal_person/
      load_person_and_families(file)
    end
  end
rescue Exception => e
  puts "Error while loading census_employee #{e} #{e.backtrace}"
end