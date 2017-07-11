$(document).ready(function() {

  if ($('#medicaid_pregnency_yes').length) {
    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace(/step(\/\d)?/, "age_18_to_26"),
      success: function (age) {
        hide_show_foster_care_related_qns(age);
      }
    });
  }
    // To hide/show the foster care related questions based on the age_of_the_applicant.
    function hide_show_foster_care_related_qns(age) {
      if ($('#pregnant_yes')){
        if (age == "false"){
          // $('#medicaid_pregnency_yes').parents(".row").next().addClass('hide');
          $('#former_foster_care_yes').parents(".row").addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().addClass('hide');
          $('#had_medicaid_during_foster_care_yes').closest(".row").addClass('hide');
        }
        else {
          // $('#medicaid_pregnency_yes').parents(".row").next().removeClass('hide');
          $('#former_foster_care_yes').closest(".row").removeClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().removeClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().removeClass('hide');
          // $('#medicaid_pregnency_yes').parents(".row").next().next().next().next().removeClass('hide');
          $('#had_medicaid_during_foster_care_yes').closest(".row").removeClass('hide');
        }
      }
    }
  }

  $('#income_kind').on('selectric-change', function(e){
    if ($(this).val() == 'wages_and_salaries')
      toggle_employer_contact_divs('show'); 
    else
      toggle_employer_contact_divs('hide');
  });

  if ($('#income_kind').val() == 'wages_and_salaries'){
    toggle_employer_contact_divs('show');
  }
  else {
    toggle_employer_contact_divs('hide');
  }


  function toggle_employer_contact_divs(hide_show) {
    if (hide_show == 'hide') {
      $("#employer_phone_full_phone_number").closest(".row").addClass('hide');
      $("#employer_address_address_2").closest(".row").addClass('hide');
      $("#employer_address_zip").closest(".row").addClass('hide');
      // $('#income_kind').parents(".row").next().next().addClass('hide');
      // $('#income_kind').parents(".row").next().next().next().addClass('hide');
      // $('#income_kind').parents(".row").next().next().next().next().addClass('hide');
    }
    else {
      $("#employer_phone_full_phone_number").closest(".row").removeClass('hide');
      $("#employer_address_address_2").closest(".row").removeClass('hide');
      $("#employer_address_zip").closest(".row").removeClass('hide');
      // $('#income_kind').parents(".row").next().next().removeClass('hide');
      // $('#income_kind').parents(".row").next().next().next().removeClass('hide');
      // $('#income_kind').parents(".row").next().next().next().next().removeClass('hide');
    }
  }

  // Clear 0 value for Income
  if ($("#income_amount").val() == 0){
   $("#income_amount").val("");
  }

  $("body").on("change", "#is_required_to_file_taxes_no", function(){
    if ($('#is_required_to_file_taxes_no').is(':checked')) {
      // $(this).parents(".row").next().addClass('hide');
      $("#is_joint_tax_filing_no").closest(".row").addClass('hide');
    }
    else{
      $("#is_joint_tax_filing_no").closest(".row").removeClass('hide');
    }
  });
  $("body").on("change", "#is_required_to_file_taxes_yes", function(){
    if ($('#is_required_to_file_taxes_yes').is(':checked')) {
      // $(this).parents(".row").next().removeClass('hide');
      $("#is_joint_tax_filing_yes").closest(".row").removeClass('hide');
    }
    else{
      $("#is_joint_tax_filing_yes").closest(".row").addClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_no", function(){
    if ($('#is_claimed_as_tax_dependent_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
    }
    else{
      $(this).parents(".row").next().next().removeClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_yes", function(){

    if ($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
      // $(this).parents(".row").next().removeClass('hide');
      $('#claimed_as_tax_dependent_by_id').closest(".row").removeClass('hide');
    }
    else{
      $(this).parents(".row").next().next().addClass('hide');
    }
  });

  $("body").on("click", ".interaction-click-control-next-step", function(e){
        var errorMsgs = [];
        var form = $(this).parents("form");
        var $requiredFieldRows = $(this).parents("form").find(".row:not(.hide):not(:last-child)");
        var totalRequiredCount = $requiredFieldRows.length - 1;  // -1 for the last row..
        var totRadioSelected = $(this).parents("form").find(".row:not(.hide) input[type='radio']:checked").length;
        var isValid = totRadioSelected == totalRequiredCount;
        $requiredFieldRows.each(function(index, element) {
            var $this = $(this);
            if($this.find("input[type='radio']").length && !$this.find("input[type='radio']:checked").length) {
                 errorMsgs.push("PLEASE SELECT * " + $this.find("span").text().replace('*', ''));
            } else {
                $this.find(".alert-error").html("");
            }
        });
        if ($(errorMsgs).length > 0){
            $(".alert-error").text(errorMsgs);
            $(".alert-error").removeClass('hide');
        }
        else{
            $(".alert-error").text("");
            $(".alert-error").addClass('hide');
            $(form).submit();

        }
        return isValid;
    });

  /* Benefit Form Related */

  /* Toggle Show/Hide of  dates row when eligible/ enrolled types are selected */
  $("#is_eligible, #is_enrolled").on('change', function() {
    if ($('#is_eligible').is(':checked')) {
      // $('#is_eligible').parents(".row").next().addClass('hide');
      // $('#is_eligible').parents(".row").next().removeClass('show');
      $('#benefit_end_on').closest(".row").addClass('hide');
      $('#benefit_end_on').closest(".row").removeClass('show');
    }
    else {
      // $('#is_eligible').parents(".row").next().addClass('show');
      // $('#is_eligible').parents(".row").next().removeClass('hide');
      $('#benefit_end_on').closest(".row").addClass('show');
      $('#benefit_end_on').closest(".row").removeClass('hide');
    }
  });


  $('#benefit_insurance_kind').on('selectric-change', function(e){
    if ($(this).val() == 'employer_sponsored_insurance') {
      toggle_employer_contact_divs_benefit('show');
    }
    else {
      toggle_employer_contact_divs_benefit('hide');
    }
  });

  /* This is to show/hide ESI fields on Page Load. Will show ESI related
   * fields if InsuranceKind is selected as 'employer_sponsored_insurance'
   * when page loads (possible on a page reload due to validation error) */

  var selectedVal = $('#benefit_insurance_kind').val();
  if (selectedVal == 'employer_sponsored_insurance') {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('show');
    },300);
  }
  else {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('hide');
    },300);
  };

  function toggle_employer_contact_divs_benefit(hide_show) {
    if (hide_show == 'show') {
      $('#benefit_employer_name').closest(".row").removeClass('hide');
      $('#employer_address_address_2').closest(".row").removeClass('hide');
      $('#employer_address_zip').closest(".row").removeClass('hide');
      $('#benefit_employer_id').closest(".row").removeClass('hide');
      $('#is_eligible_no').closest(".row").removeClass('hide');
      $('#health_plan_yes').closest(".row").removeClass('hide');


      $('#benefit_insurance_kind').parents(".row").next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().removeClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().removeClass('hide');
    }
    else {
      $('#benefit_employer_name').closest(".row").addClass('hide');
      $('#employer_address_address_2').closest(".row").addClass('hide');
      $('#employer_address_zip').closest(".row").addClass('hide');
      $('#benefit_employer_id').closest(".row").addClass('hide');
      $('#is_eligible_no').closest(".row").addClass('hide');
      $('#health_plan_yes').closest(".row").addClass('hide');

      $('#benefit_insurance_kind').parents(".row").next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().addClass('hide');
      // $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().addClass('hide');
    }
  }
  /* Benefit Form Related */

  /* Submit Application Form Related */
  $("body").on("change", "#living_outside_no", function(){
    if ($('#living_outside_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      // $(this).parents(".row").next().next().addClass('hide');
      $('#application_attestation_terms').closest(".row").addClass('hide');
    };
  });

  $("body").on("change", "#living_outside_yes", function(){
    if ($('#living_outside_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      // $(this).parents(".row").next().next().removeClass('hide');
      $('#application_attestation_terms').closest(".row").removeClass('hide');
    };
  });

  // On Load, hide by default if checked no
  if($('#living_outside_no').is(':checked')) {
    $('#living_outside_no').parents(".row").next().addClass('hide');
    $('#application_attestation_terms').closest(".row").addClass('hide');
  }

  if($('#living_outside_yes').is(':checked')) {
    $('#living_outside_yes').parents(".row").next().removeClass('hide');
  }
  /* Submit Application Form Related */
  

  /* Preference Application Form Related */

  // On Load, hide by default if checked
  if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#years_to_renew').closest(".row").addClass('hide');
      // $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  };

  $("body").on("change", "#eligibility_easier_yes", function(){
    if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#years_to_renew').closest(".row").addClass('hide');
      // $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#eligibility_easier_no", function(){
    if ($('#eligibility_easier_no').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $('#years_to_renew').closest(".row").removeClass('hide');
      // $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  if($('#eligibility_easier_yes').is(':checked')) {
    $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  }

  if($('#eligibility_easier_no').is(':checked')) {
    $('#eligibility_easier_no').parents(".row").next().removeClass('hide');
  }

/* Applicant's Tax Info Form Related */
  if($('#is_required_to_file_taxes_no').is(':checked')) {
    $("#is_joint_tax_filing_no").closest(".row").addClass('hide');
    // $('#is_required_to_file_taxes_no').parents(".row").next().addClass('hide');
  }

  if($('#is_required_to_file_taxes_yes').is(':checked')) {
    $("#is_joint_tax_filing_yes").closest(".row").addClass('hide');
    // $('#is_required_to_file_taxes_yes').parents(".row").next().removeClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_no').is(':checked')) {
    $('#is_claimed_as_tax_dependent_no').parents(".row").next().addClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
    $('#is_claimed_as_tax_dependent_yes').parents(".row").next().removeClass('hide');
  }

/* Applicant's Tax Info Form Related */


/* Applicant's Other Questions Form Related */
  $("body").on("change", "#is_pregnant_no", function(){
    if ($('#is_pregnant_no').is(':checked')) {
      $("#applicant_pregnancy_due_on").closest(".row").addClass('hide');
      $("#interaction-choice-control-applicant-student-school-kind").closest(".row").addClass('hide');
      $("#is_post_partum_period_yes").closest(".row").removeClass('hide');
      $("#applicant_pregnancy_end_on").closest(".row").removeClass('hide');
      // $(this).parents(".row").next().addClass('hide');
      // $(this).parents(".row").next().next().addClass('hide');
      // $(this).parents(".row").next().next().next().removeClass('hide');
      // $(this).parents(".row").next().next().next().next().removeClass('hide');
    };
  });

  $("body").on("change", "#is_pregnant_yes", function(){
    if ($('#is_pregnant_yes').is(':checked')) {
      $("#is_post_partum_period_yes").closest(".row").addClass('hide');
      $("#applicant_pregnancy_end_on").closest(".row").addClass('hide');
      $("#applicant_pregnancy_due_on").closest(".row").removeClass('hide');
      $("#interaction-choice-control-applicant-student-school-kind").closest(".row").removeClass('hide');
      // $(this).parents(".row").next().removeClass('hide');
      // $(this).parents(".row").next().next().removeClass('hide');
      // $(this).parents(".row").next().next().next().addClass('hide');
      // $(this).parents(".row").next().next().next().next().addClass('hide');
      // $(this).parents(".row").next().next().next().next().next().addClass('hide');
    };
  });

  if($('#is_pregnant_no').is(':checked')) {
    $("#applicant_pregnancy_due_on").closest(".row").addClass('hide');
    $("#interaction-choice-control-applicant-student-school-kind").closest(".row").addClass('hide');
    $("#is_post_partum_period_yes").closest(".row").removeClass('hide');
    $("#applicant_pregnancy_end_on").closest(".row").removeClass('hide');

    // $('#is_pregnant_no').parents(".row").next().addClass('hide');
    // $('#is_pregnant_no').parents(".row").next().next().addClass('hide');
    // $('#is_pregnant_no').parents(".row").next().next().next().removeClass('hide');
    // $('#is_pregnant_no').parents(".row").next().next().next().next().removeClass('hide');
  }

  if($('#is_pregnant_yes').is(':checked')) {
    $("#is_post_partum_period_yes").closest(".row").addClass('hide');
    $("#applicant_pregnancy_end_on").closest(".row").addClass('hide');
    $("#applicant_pregnancy_due_on").closest(".row").removeClass('hide');
    $("#interaction-choice-control-applicant-student-school-kind").closest(".row").removeClass('hide');

    // $('#is_pregnant_yes').parents(".row").next().removeClass('hide');
    // $('#is_pregnant_yes').parents(".row").next().next().removeClass('hide');
    // $('#is_pregnant_yes').parents(".row").next().next().next().addClass('hide');
    // $('#is_pregnant_yes').parents(".row").next().next().next().next().addClass('hide');
    // $('#is_pregnant_yes').parents(".row").next().next().next().next().next().addClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_yes", function(){
    if ($('#is_post_partum_period_yes').is(':checked')) {
      $("#medicaid_pregnency_yes").closest(".row").removeClass('hide');
      // $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  $("body").on("change", "#is_post_partum_period_no", function(){
    if ($('#is_post_partum_period_no').is(':checked')) {
      $("#medicaid_pregnency_yes").closest(".row").addClass('hide');
      // $(this).parents(".row").next().next().addClass('hide');
    };
  });

  if($('#is_post_partum_period_yes').is(':checked')) {
    $("#medicaid_pregnency_yes").closest(".row").removeClass('hide');
    // $('#is_post_partum_period_yes').parents(".row").next().next().removeClass('hide');
  }

  if($('#is_post_partum_period_no').is(':checked')) {
    $("#medicaid_pregnency_yes").closest(".row").addClass('hide');
    // $('#is_post_partum_period_no').parents(".row").next().next().addClass('hide');
  }

  $("body").on("change", "#former_foster_care_no", function(){
    if ($('#former_foster_care_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
      // $(this).parents(".row").next().next().next().addClass('hide');
      $('#had_medicaid_during_foster_care_yes').closest(".row").addClass('hide');
    };
  });

  $("body").on("change", "#former_foster_care_yes", function(){
    if ($('#former_foster_care_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
      // $('#former_foster_care_no').parents(".row").next().next().next().addClass('hide');
      $('#had_medicaid_during_foster_care_yes').closest(".row").removeClass('hide');
    };
  });

  if($('#former_foster_care_no').is(':checked')) {
    $('#former_foster_care_no').parents(".row").next().addClass('hide');
    $('#former_foster_care_no').parents(".row").next().next().addClass('hide');
    $('#had_medicaid_during_foster_care_yes').closest(".row").addClass('hide');
  }

  if($('#former_foster_care_yes').is(':checked')) {
    $('#former_foster_care_yes').parents(".row").next().removeClass('hide');
    $('#former_foster_care_yes').parents(".row").next().next().removeClass('hide');
    // $('#former_foster_care_yes').parents(".row").next().next().next().removeClass('hide');
    $('#had_medicaid_during_foster_care_yes').closest(".row").removeClass('hide');
  }

  $("body").on("change", "#is_student_no", function(){
    if ($('#is_student_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $('#applicant_student_status_end_on').closest(".row").addClass('hide');
      $(this).parents(".row").next().next().next().addClass('hide');
    };
  });

  $("body").on("change", "#is_student_yes", function(){
    if ($('#is_student_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $('#applicant_student_status_end_on').closest(".row").removeClass('hide');
      $(this).parents(".row").next().next().next().removeClass('hide');
    };
  });

  if($('#is_student_no').is(':checked')) {
    $('#is_student_no').parents(".row").next().addClass('hide');
    $('#applicant_student_status_end_on').closest(".row").addClass('hide');
    $('#is_student_no').parents(".row").next().next().next().addClass('hide');
  }

  if($('#is_student_yes').is(':checked')) {
    $('#is_student_yes').parents(".row").next().removeClass('hide');
    $('#applicant_student_status_end_on').closest(".row").removeClass('hide');
    $('#is_student_yes').parents(".row").next().next().next().removeClass('hide');
  }
/* Applicant's Other Questions Form Related */
                               /* Duplicate Code*/
  /* Submit Application Form Related */
  // $("body").on("change", "#living_outside_no", function(){
  //   if ($('#living_outside_no').is(':checked')) {
  //     $(this).parents(".row").next().addClass('hide');
  //     $(this).parents(".row").next().next().addClass('hide');
  //   };
  // });

  // $("body").on("change", "#living_outside_yes", function(){
  //   if ($('#living_outside_yes').is(':checked')) {
  //     $(this).parents(".row").next().removeClass('hide');
  //     $(this).parents(".row").next().next().removeClass('hide');
  //   };
  // });

  // // On Load, hide by default if checked no
  // if($('#living_outside_no').is(':checked')) {
  //   $('#living_outside_no').parents(".row").next().addClass('hide');
  //   $('#living_outside_no').parents(".row").next().next().addClass('hide');
  // }

  // if($('#living_outside_yes').is(':checked')) {
  //   $('#living_outside_yes').parents(".row").next().removeClass('hide');
  // }
  /* Submit Application Form Related */

  /* Preference Application Form Related */


/* Duplicate Code*/
  // On Load, hide by default if checked
  // if ($('#eligibility_easier_yes').is(':checked')) {
  //     $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  //     $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  // };

  // $("body").on("change", "#eligibility_easier_yes", function(){
  //   if ($('#eligibility_easier_yes').is(':checked')) {
  //     $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  //     $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  //   };
  // });

  // $("body").on("change", "#eligibility_easier_no", function(){
  //   if ($('#eligibility_easier_no').is(':checked')) {
  //     $(this).parents(".row").next().removeClass('hide');
  //     $(this).parents(".row").next().next().removeClass('hide');
  //   };
  // });

  // if($('#eligibility_easier_yes').is(':checked')) {
  //   $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  // }

  // if($('#eligibility_easier_no').is(':checked')) {
  //   $('#eligibility_easier_no').parents(".row").next().removeClass('hide');
  // }
  /* Preference Application Form Related */
/* Duplicate Code*/
});
