fein ="464197120"
folder_name = "tmp/dump_#{fein}"
begin
  FileUtils.mkdir_p(folder_name)
  org = Organization.where(:fein =>fein).first
  File.open(File.expand_path(folder_name+"/org"),'wb'){|f| f.write(Marshal.dump(org))}
  emp_profile = org.employer_profile
  File.open(File.expand_path(folder_name+"/employer_profile"),'wb'){|f| f.write(Marshal.dump(emp_profile))}
  broker_agency = org.employer_profile.broker_agency_profile
  File.open(File.expand_path(folder_name+"/broker_agency"),'wb'){|f| f.write(Marshal.dump(broker_agency))}
  org.employer_profile.census_employees.each do |ce|
    file_path = "tmp/dump_#{fein}/dump_marshal_census_employee_#{ce.id}"
    File.open(File.expand_path(file_path),'wb'){|f| f.write(Marshal.dump(ce))}
end
rescue Exception => e
  puts "#{e} #{e.backtrace}"
end