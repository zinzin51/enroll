
fein ="521992631"
folder_name = "tmp/dump_#{fein}"
begin
  FileUtils.mkdir_p(folder_name)
  org = Organization.where(:fein =>fein).first
  File.open(File.expand_path(folder_name+"/org"),'wb'){|f| f.write(Marshal.dump(org))}
  emp_profile = org.employer_profile
  File.open(File.expand_path(folder_name+"/employer_profile"),'wb'){|f| f.write(Marshal.dump(emp_profile))}
  bg = org.employer_profile.plan_years.last.benefit_groups.last
  plan = bg.reference_plan
  File.open(File.expand_path(folder_name+"/plan"),'wb'){|f| f.write(Marshal.dump(plan))}
  if !bg.dental_reference_plan.nil?
    plan = bg.dental_reference_plan
    File.open(File.expand_path(folder_name+"/dental_plan"),'wb'){|f| f.write(Marshal.dump(plan))}
  end
  broker_agency = org.employer_profile.broker_agency_profile
  if !broker_agency.nil?
    File.open(File.expand_path(folder_name+"/broker_agency"),'wb'){|f| f.write(Marshal.dump(broker_agency.organization))}
    br_role = broker_agency.primary_broker_role
    File.open(File.expand_path(folder_name+"/br_role"),'wb'){|f| f.write(Marshal.dump(br_role))}
    person_broker = broker_agency.primary_broker_role.person
    File.open(File.expand_path(folder_name+"/person_broker"),'wb'){|f| f.write(Marshal.dump(person_broker))}
  end
  org.employer_profile.census_employees.each do |ce|
    personid = ce.employee_role.person.id
    file_path_ce = "tmp/dump_#{fein}/dump_marshal_census_employee_#{personid}"
    File.open(File.expand_path(file_path_ce),'wb'){|f| f.write(Marshal.dump(ce))}
    file_path_ee = "tmp/dump_#{fein}/dump_marshal_employee_role_#{personid}"
    File.open(File.expand_path(file_path_ee),'wb'){|f| f.write(Marshal.dump(ce.employee_role))}
    file_path_person = "tmp/dump_#{fein}/dump_marshal_person_#{personid}"
    File.open(File.expand_path(file_path_person),'wb'){|f| f.write(Marshal.dump(Person.includes(:user).find(personid)))}
    # file_path_user = "tmp/dump_#{fein}/dump_marshal_user_#{ce.id}"
    # File.open(File.expand_path(file_path_user),'wb'){|f| f.write(Marshal.dump(ce.employee_role.person.user))}
    file_path_family = "tmp/dump_#{fein}/dump_marshal_family_#{personid}"
    File.open(File.expand_path(file_path_family),'wb'){|f| f.write(Marshal.dump(ce.employee_role.person.families.first))}
    # file_path_primary = "tmp/dump_#{fein}/dump_marshal_primary_#{ce.id}"
    # File.open(File.expand_path(file_path_primary),'wb'){|f| f.write(Marshal.dump(ce.employee_role.person.families.first.primary_family_member))}
end
rescue Exception => e
  puts "#{e} #{e.backtrace}"
end