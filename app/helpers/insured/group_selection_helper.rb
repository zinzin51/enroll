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

    def group_selection_market_kind(person, market_kind)
      if can_shop_shop?(person)
        'shop'
      elsif can_shop_individual?(person)
        'individual'
      elsif can_shop_resident?(person)
        'coverall'
      elsif market_kind.present?
        market_kind
      end
    end

    def benefit_type_radio(benefit_type)
      selected = (benefit_type == :health)
      content_tag :label, class: "n-radio", for: "coverage_kind_#{benefit_type}" do
        radio_button_tag('coverage_kind', "#{benefit_type}", selected, id: "coverage_kind_#{benefit_type}", class: 'n-radio') +
        content_tag(:span, '', class: 'n-radio') +
        "#{benefit_type.to_s.classify}"
      end
    end
  end
end
