module Api
  module V1
    class MobileApiController < ApplicationController
    
      include MobileApiHelper

      def employers_list
        employer_profiles, broker_agency_profile = self.class.fetch_employers_and_broker_agency(current_user, params[:id])
        if broker_agency_profile
          @employer_details =
                marshall_employer_summaries_json(employer_profiles, params[:report_date])
          render json: {
                 broker_agency:  broker_agency_profile.legal_name,
                 broker_clients: @employer_details 
          } 
        else
          render json: { error: 'no broker agency profile found' }, :status => :not_found
        end
#      rescue Exception => e 
#          render json: { error: e.message  }, :status => :internal_server_error
      end

      def employer_details
        id_params = params.permit(:id, :employer_profile_id, :report_date)
        id = id_params[:id] || id_params[:employer_profile_id]  #TODO user check
        employer_profile = EmployerProfile.find(id)
        #print "$$$$$ got ep #{employer_profile} : blank=#{employer_profile.blank?} from id #{id}\n\n"
        if employer_profile.blank?
          render json: { file: 'public/404.html'}, status: :not_found 
        else
          render json: marshall_employer_details_json(employer_profile, params[:report_date])
        end
      rescue Exception => e 
          render json: { error: e.message }, :status => :internal_server_error
      end

      def employee_roster
        render json: {}, :status => :no_content #TODO next release
      end

      private

      def self.fetch_employers_and_broker_agency(user, submitted_id)
        #print ("$$$$ fetch_employers_and_broker_agency(#{user}, #{submitted_id})\n")
        if submitted_id && (user.has_broker_agency_staff_role? || user.has_hbx_staff_role?)
          broker_agency_profile = BrokerAgencyProfile.find(submitted_id)
          employer_query = Organization.by_broker_agency_profile(broker_agency_profile._id) if broker_agency_profile
#TODO fix security hole
#@broker_agency_profile = current_user.person.broker_agency_staff_roles.first.broker_agency_profile

        else
          broker_role = user.person.broker_role
          if broker_role
            broker_agency_profile = broker_role.broker_agency_profile
            employer_query = Organization.by_broker_role(broker_role.id) 
          end
        end
        employer_profiles = (employer_query || []).map {|o| o.employer_profile}  
        [employer_profiles, broker_agency_profile] if employer_query
      end
      
    end
  end
end