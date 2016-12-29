require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's account information"
    task :employer_information_dc => :environment do
      begin
        csv = CSV.open('NFP_SampleERInfo.csv',"r",:headers =>true, :encoding => 'ISO-8859-1')
        @data= csv.to_a
        miss_match = CSV.open('miss_match_nfp_file.csv',"w",:headers =>true, :encoding => 'ISO-8859-1')
        
        @data.each do |data_row|
          mismatches=[]
          organization = Organization.where(:hbx_id => data_row["CUSTOMER_CODE"]).first
          poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,:"employer_staff_roles.is_active" => true).first unless organization.nil?
          if organization.nil? 
            # binding.pry
            row = data_row.push("Organization missing")
            miss_match << row
            next
          end  
          if organization.fein = data_row["TAX_ID"]
              mismatches << 'fein not matching'
          end
          if organization.dba != data_row["CUSTOMER_NAME"]
              mismatches <<'dba not matching'
          end
          if  organization.primary_office_location.address.try(:address_1).upcase !=data_row["B_ADD1"].upcase||
              mismatches << 'address not matching'
          end
          if  organization.primary_office_location.address.try(:address_2).upcase !=data_row["B_ADD2"].upcase||
              mismatches << 'address not matching'
          end
          if organization.primary_office_location.address.try(:city).upcase !=data_row["B_CITY"].upcase||
              mismatches << 'city not matching'
          end
          if organization.primary_office_location.address.try(:state).upcase !=data_row["B_STATE"].upcase||
            mismatches << 'state not matching'
          end
          if  organization.primary_office_location.address.try(:zip) !=data_row["B_ZIP"]||
            mismatches << 'zip not matching'
          end
          if  organization.mailing_address.address.try(:address_1).upcase !=data_row["M_ADD1"].upcase|| 
            mismatches <<'mailling address not matching'  
          end
          if organization.mailing_address.address.try(:address_2).upcase !=data_row["M_ADD2"].upcase||
            mismatches << 'mailling address not matching' 
           end
           if organization.mailing_address.address.try(:city).upcase !=data_row["M_CITY"].upcase||
              mismatches << 'mailling city not matching'
          end
          if  organization.mailing_address.address.try(:state).upcase !=data_row["M_STATE"].upcase||
              mismatches <<'mailling state not matching'
           end
          if  organization.mailing_address.address.try(:zip).upcase !=data_row["M_ZIP"].upcase||
              mismatches <<'mailling zip not matching'
           end
           if organization.primary_office_location.address.try(:mailling_address).try(:phone).try(:full_phone_number)!=data_row["M_PHONE"].upcase||
              mismatches <<'mailling phone not matching'
           end 
            if  poc.try(:name_pfx)  != data_row["B_CONTACT_PREFIX"]||
              mismatches << 'person prefix not matching'
            end
            if poc.try(:first_name)  != data_row["B_CONTACT_FNAME"]||
              mismatches << 'person first name not matching'
            end
            if poc.try(:middle_name)  != data_row["B_CONTACT_MI"]||
              mismatches << 'person middle name not matching'
            end
            if poc.try(:last_name)  != data_row["B_CONTACT_LNAME"]||
              mismatches << 'person last name not matching'
            end 
            if poc.try(:name_sfx)  != data_row["B_CONTACT_SUFFIX"]||
              mismatches <<'person suffix not matching'
            end
            if poc.try(:work_email).try(:address) !=data_row["M_EMAIL"] 
            mismatches << 'person email not matching'          
            end
            row = data_row.push(mismatches.join(","))
            miss_match << row
        end
      rescue Exception => e
        puts "Unable to open file #{e}" 
    end
  end
end
end