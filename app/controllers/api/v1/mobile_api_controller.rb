module Api
  module V1
    class MobileApiController < ApplicationController
    
      def employers_list
        employer_profiles, broker_agency_profile = fetch_employers_and_broker_agency(current_user, params[:id])
        if broker_agency_profile
          employer_details =
                Employers::EmployerHelper.marshall_employer_summaries_json(employer_profiles, params[:report_date])
          end                                 
          render json: {
                 broker_agency:  broker_agency_profile.legal_name,
                 broker_clients: employer_details 
          } 
        else
          render json: { error: 'no broker agency profile found', :status => :not_found} 
        end
      rescue Exception => e 
          render json: { error: e.message }, :status => :internal_server_error
      end

      def employer_details
        id_params = params.permit(:id, :employer_profile_id, :report_date)
        id = id_params[:id] || id_params[:employer_profile_id]
        employer_profile = EmployerProfile.find(id)
        if employer_profile.blank?
          render json: { file: 'public/404.html', status: :not_found 
        else
          render json: Employers::EmployerHelper.marshall_employer_details_json(employer_profile, 
                                                                           params[:report_date])
        end
      rescue Exception => e 
          render json: { error: e.message }, :status => :internal_server_error
      end

      def employee_roster
        render json: {}, :status => :no_content #TODO next release
      end

      private

      def fetch_employers_and_broker_agency(user, submitted_id)
        if submitted_id && (user.has_broker_agency_staff_role? || user.has_hbx_staff_role?)
            broker_agency_profile = BrokerAgencyProfile.find(submitted_id)
            employer_query = Organization.by_broker_agency_profile(@broker_agency_profile._id)
         else
            broker_role = user.person.broker_role
            broker_agency_profile = broker_role.broker_agency_profile_id
            employer_query = Organization.by_broker_role(broker_role.id)
         end
         [employer_query.distinct(:employer_profile), broker_agency_profile]
      end
      
    end
  end
end