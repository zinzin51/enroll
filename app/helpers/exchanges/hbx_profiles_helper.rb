module  Exchanges::HbxProfilesHelper

  def can_cancel_employer_plan_year?(employer_profile)
    if employer_profile.active_plan_year.present?
      ['published', 'enrolling', 'enrolled', 'active'].include?(employer_profile.active_plan_year.aasm_state)
    else
      false
    end
  end
end