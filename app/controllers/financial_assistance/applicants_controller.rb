class FinancialAssistance::ApplicantsController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find, :find_application


  def edit
  	@applicant = @application.applicants.find(params[:id])
  end

  def step
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    
    @model.update_attributes!(permit_params(model_params)) if model_params.present?

    if params.key?(:step)
      @model.workflow = { current_step: @current_step.to_i }
    else
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    end
    @model.save!

    if @steps.last_step?(@current_step) && params[model_name].present?
    	flash[:notice] = 'Applicants Info Added.'
    	redirect_to edit_financial_assistance_application_path(@application)
    else
    	render 'workflow/step' 
    end
    
  end


  private
  def find_application
  	@application = FinancialAssistance::Application.find(params[:application_id])
  end

  def find
  	@applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:id])
  end

  def permit_params(attributes)
    attributes.permit!
  end
end