module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      person.present? && person.has_employer_benefits?
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def can_shop_resident?(person)
      person.try(:has_active_resident_role?)
    end

    def health_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

     def kind_message(kind)
      if kind=="shop"
        "Employer-Sponsored Benefits"
      else
        "Individual Benefits"
      end
    end

    def dental_offered?(person,role)
      can_shop_shop?(person) && !role.is_dental_offered?
    end

    def market_kind_dental_offered?(role)
      role.census_employee.active_benefit_group.present? && role.census_employee.active_benefit_group.is_offering_dental?
    end

    def kind_individual?(person,kind)
      can_shop_shop?(person) && kind != 'individual'
    end

    def show_dental_button?(role)
      role.census_employee.active_benefit_group.blank? || !role.census_employee.active_benefit_group.is_offering_dental?
    end

    def cover_kind_buttons?(person,role)
      (can_shop_shop?(person) || can_shop_both_markets?(person)) && role.census_employee.active_benefit_group.present? && role.census_employee.active_benefit_group.is_offering_dental?
    end


  end
end
