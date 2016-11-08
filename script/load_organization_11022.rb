fein ="464197120"
folder_name = "tmp/dump_#{fein}"
begin
  org_file = File.open(File.expand_path(folder_name+"/org"),'rb')
  org = Marshal.load(org_file)
  org.save
  emp_file = File.open(File.expand_path(folder_name+"/employer_profile"),'rb')
  empl_profile = Marshal.load(emp_file)
  empl_profile.save

  broker_agency_file = File.open(File.expand_path(folder_name+"/broker_agency"),'rb')
  broker_agency = Marshal.load(broker_agency_file)
  broker_agency.save
  br_role_file = File.open(File.expand_path(folder_name+"/br_role"),'rb')
  brkr_role = Marshal.load(br_role_file)
  brkr_role.save
  person_broker_file = File.open(File.expand_path(folder_name+"/person_broker"),'rb')
  person_brkr = Marshal.load(person_broker_file)
  person_brkr_clone = person_brkr.clone
  person_brkr_clone.ssn ="987654321"
  person_brkr_clone.save(:validate => false)

  files = Dir.entries(folder_name)
  files.each do |file|
    next unless file.match("dump_marshal_census_employee")
    ce_file = File.open(File.expand_path(folder_name+"/#{file}"),'rb')
    ce = Marshal.load(ce_file)
    ce_clone = ce.clone 
    ce_clone.ssn ="123456789"
    ce_clone.save(:validate => false)
  end
rescue Exception => e
  puts "#{e} #{e.backtrace}"
end