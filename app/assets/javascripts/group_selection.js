$(document).ready(function() {
  if ( $("#find_sep_link").length ) {
    $("#find_sep_link").click(function() {
      $(this).closest('form').attr('action', '<%= find_sep_insured_families_path %>');
      $(this).closest('form').attr('method', 'get');
      $(this).closest('form').submit();
    });
  }
  $("input[type='checkbox']").change(function() {
  if ($("#coverage_kind_health").is(":checked")) {
    if($(this).is(":checked")) {
      $(this).attr( "checked", true );
    }else{
      $(this).removeProp('checked');
      $('#shop-coverage-household .dental input').removeProp('checked');
      }
    }
  });
});