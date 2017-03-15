module Forms
	class GroupSelection
		class << self

		def select_market(person, market_kind)
			return market_kind if market_kind.present?
		    if person.try(:has_active_employee_role?)
		      'shop'
		    elsif person.try(:has_active_consumer_role?)
		      'individual'
		    elsif person.try(:has_active_resident_role?)
		      'coverall'
		    else
		      nil
		    end
		  end

		  def get_employee_role(person, employee_role_id)
    	  person.employee_roles.detect { |emp_role| emp_role.id.to_s == employee_role_id.to_s }
		  end

		  def set_market_kind(market_kind)
		  	market_kind == "shop" ? "individual" : "shop"
		  end

		  def insure_hbx_enrollment_for_shop(family)
		  	@hbx_enrollment = family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
		  end

		  def generate_coverage_family_members_for_cobra(family)
		  	@hbx_enrollment = family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
		  	@coverage_family_members_for_cobra = @hbx_enrollment.hbx_enrollment_members.map(&:family_member) if @hbx_enrollment.present?
		  end

		end
	end
end
