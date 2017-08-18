module PdfTemplates
  class ConditionalEligibilityNotice
    include Virtus.model

    attribute :mpi_indicator, String
    attribute :notification_type, String
    attribute :primary_firstname, String
    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :request_full_determination, Boolean, :default => false
    attribute :is_family_totally_ineligibile, Boolean, :default => false
    attribute :has_applied_for_assistance, Boolean, :default => false
    attribute :notice_date, Date
    attribute :hbe, PdfTemplates::Hbe
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :enrollments, Array[PdfTemplates::Enrollment]
    attribute :individuals, Array[PdfTemplates::Individual]
    attribute :ssa_unverified, Array[PdfTemplates::Individual]
    attribute :dhs_unverified, Array[PdfTemplates::Individual]
    attribute :residency_inconsistency, Array[PdfTemplates::Individual]
    attribute :income_unverified, Array[PdfTemplates::Individual]
    attribute :indian_inconsistency, Array[PdfTemplates::Individual]
    attribute :mec_conflict, Array[PdfTemplates::Individual]
    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :first_name, String
    attribute :last_name, String
    attribute :due_date, Date
    attribute :documents_needed, Boolean
    attribute :eligibility_determinations, Array[PdfTemplates::EligibilityDetermination]
    attribute :coverage_year, String

    def other_enrollments
      enrollments.reject{|enrollment| enrollments.index(enrollment).zero? }
    end

    def shop?
      false
    end

    def verified_individuals
      individuals.select{|individual| individual.verified }
    end

    def unverified_individuals
      individuals.reject{|individual| individual.verified }
    end

    def ssn_unverified
      individuals.reject{|individual| individual.ssn_verified}
    end

    def citizenship_unverified
      individuals.reject{|individual| individual.citizenship_verified}
    end

    def residency_unverified
      individuals.reject{|individual| individual.residency_verified}
    end

    def indian_conflict
      individuals.select{|individual| individual.indian_conflict}
    end

    def incarcerated
      individuals.select{|individual| individual.incarcerated}
    end

    def cover_all?
      enrollments.select{|enrollment| enrollment.kind == "coverall"}.present?
    end

    def current_health_enrollments
      enrollments.select{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def assisted_enrollments
      current_health_enrollments.select{|enrollment| enrollment.is_receiving_assistance == true}
    end

    def csr_enrollments
      current_health_enrollments.select{|enrollment| enrollment.plan.is_csr ==  true}
    end

    def current_dental_enrollments
      enrollments.select{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def renewal_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def renewal_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def magi_medicaid_eligible
      individuals.select{ |individual| individual.is_medicaid_chip_eligible == true }
    end

    def aqhp_individuals
      individuals.select{ |individual| individual.is_ia_eligible == true  }
    end

    def uqhp_individuals
      individuals.select{ |individual| individual.is_without_assistance == true  }
    end

    def ineligible_applicants
      individuals.select{ |individual| individual.is_totally_ineligible == true  }
    end

    def non_magi_medicaid_eligible
      individuals.select{ |individual| individual.is_non_magi_medicaid_eligible == true  }
    end

    def aqhp_enrollments
      enrollments.select{ |enrollment| enrollment.is_receiving_assistance == true}
    end

    #FIX ME
    def tax_hh_with_csr
      tax_households.select { |thh| thh.csr_percent_as_integer != 100}
    end

    def enrollment_notice_subject
      if current_health_enrollments.present? && assisted_enrollments.present?
        if current_dental_enrollments.present?
          subject = "Your Health Plan, Cost Savings, and Dental Plan"
        else
          subject = "Your Health Plan and Cost Savings"
        end
      elsif current_health_enrollments.present? && assisted_enrollments.nil?
        if current_dental_enrollments.present?
          subject = "Your Health and Dental Plan"
        else
          subject = "Your Health Plan"
        end
      else
        subject = "Your Dental Plan"
      end
    end

    def eligibility_notice_display_medicaid(ivl)
      (ivl.is_medicaid_chip_eligible) || (ivl.is_non_magi_medicaid_eligible) || ((ivl.is_medicaid_chip_eligible || ivl.is_non_magi_medicaid_eligible) && !(ivl.is_totally_ineligible))
    end

    def eligibility_notice_display_aptc(ivl)
      (ivl.tax_household.max_aptc > 0) || ivl.no_aptc_because_of_income || ivl.is_medicaid_chip_eligible || ivl.has_access_to_affordable_coverage
    end

    def eligibiltiy_notice_display_csr(ivl)
      (ivl.indian_conflict && ivl.tax_household.csr_percent_as_integer != 100) || (ivl.indian_conflict == true && (ivl.magi_as_percentage_of_fpl <= 300 || ivl.magi_as_percentage_of_fpl > 300)) || ivl.no_csr_because_of_income || ivl.is_medicaid_chip_eligible || (ivl.tax_household.csr_percent_as_integer.nil? && ivl.has_access_to_affordable_coverage)
    end
  end
end