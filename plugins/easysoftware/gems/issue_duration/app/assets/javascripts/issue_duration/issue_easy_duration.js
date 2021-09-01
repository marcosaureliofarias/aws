EASY.schedule.late(function () {
  $('#start_date_area').after($('#easy_duration_area'));

  $('#issue_start_date').change(function(){
    var dueDate = $('#issue_due_date');

    if (dueDate.val() === '') return false;
    calculateDuration(this.value, dueDate.val())
  });

  $('#issue_due_date').change(function(){
    var startDate = $('#issue_start_date');

    if (startDate.val() === '') return false;
    calculateDuration(startDate.val(), this.value)
  });

  function calculateDuration(startDate, endDate) {
    $.ajax({
      dataType: "json",
      url: '/calculate_issue_easy_duration',
      type: "GET",
      data: {start_date: startDate, due_date: endDate},
      success: function (data) {
        $('#issue_easy_duration').val(data);
        $('#issue_easy_duration_time_units').val('day')
      }
    });
  }

  $('#issue_easy_duration').on('change', function(){
    var startDate = $('#issue_start_date');
    var dueDate = $('#issue_due_date');
    var duratinUnit = $('#issue_easy_duration_time_units');

    if (this.value.length === 0) return false;

    if (startDate.val().length) {
      $.ajax({
        dataType: "json",
        url: '/move_date',
        type: "GET",
        data: {start_date: startDate.val(), easy_duration: this.value, easy_duration_unit: duratinUnit.val()},
        success: function (data) {
          dueDate.val(data)
        }
      });
    } else if (dueDate.val().length && startDate.val() === ''){
      $.ajax({
        dataType: "json",
        url: '/move_date',
        type: "GET",
        data: {due_date: dueDate.val(), easy_duration: this.value, easy_duration_unit: duratinUnit.val()},
        success: function (data) {
          startDate.val(data)
        }
      });
    } else {
      return false;
    }
  });

  $('#issue_easy_duration_time_units').change(function(){
    $('#issue_easy_duration').trigger("change");
  });

});
