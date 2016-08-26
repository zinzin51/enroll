module Api
  module V1
    class MobileApiController < ApplicationController
    
      def employers_list
        @employer_profiles = find_relevant_employers(current_user, params[:id]).distinct(:employer_profile)
        @renewals_offset_in_months = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months
        report_date = params[:report_date] || TimeKeeper.date_of_record.next_month

        #### TODO extract method
        all_staff_by_employer_id = Person.staff_for_employers_including_pending(@employer_profiles.map(&:id))
        @employer_list = @employer_profiles.map do |er| 
          subscriber_count = count_enrolled_subscribers(er.show_plan_year, report_date)
          staff = all_staff_by_employer_id[er.id] || [] 
          offices = er.organization.office_locations.select { |loc| loc.primary_or_branch? }
          Employers::EmployerHelper.render_employer_summary_json(er, er.show_plan_year, staff, offices, subscriber_count, @renewals_offset_in_months) 
        end         
        #### TODO extract method

        render json: {
           broker_agency: @broker_agency_profile.legal_name,
           broker_clients: @employer_details
        } 
      rescue Exception => e 
          render json: { error: "#{e.message}"}, :status => :internal_server_error
      end

      def employer_details
          # TODO move to detail API  
          #  enrollments = er.enrollments_for_billing(billing_report_date)
          #  premium_amt_total, employee_cost_total, employer_contribution_total = enrollments.inject([0,0,0]) do |(pt, eec, erc), en|
          #    info = en.decorated_hbx_enrollment
          #    [ pt + info.total_premium, eec + info.total_employee_cost, erc + info.total_employer_contribution]
          #  end
      end

      private

      def find_relevant_employers(user, submitted_id)
        if user.has_broker_agency_staff_role? || user.has_hbx_staff_role?
            @broker_agency_profile = BrokerAgencyProfile.find(submitted_id)
            Organization.by_broker_agency_profile(@broker_agency_profile._id)
         else
            broker_role_id = user.person.broker_role.id
            Organization.by_broker_role(broker_role_id)
         end
      end
       
      def count_enrolled_subscribers(plan_year, report_date)  
         subscribers_already_counted = {}
         if plan_year.nil? then
           subscriber_count = nil
         else 
           enrollments = plan_year.hbx_enrollments_by_month(report_date).compact
           subscriber_count = enrollments.inject(0) do |subs, en|
             if (!subscribers_already_counted[en.subscriber.applicant_id]) then
               subscribers_already_counted[en.subscriber.applicant_id] = true
               subs += 1
             end
             subs 
           end
         end
      end

    end
  end
end