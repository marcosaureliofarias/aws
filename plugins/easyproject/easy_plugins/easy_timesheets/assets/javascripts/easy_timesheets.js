$(document).on("focus, mouseup, click", ".easy-timesheet-table .cell-data input", function (event) {
  $(event.target).select();
})
$(document).on("change", ".easy-timesheet-table .cell-data input, .easy-timesheet-table .cell-data select", function (event) {
  var input = $(event.target);
  var cell = input.closest("td");
  var row = input.closest("tr");
  var easyTimesheet = input.closest("table.easy-timesheet-table");
  var timeEntryId = input.data().timeEntryId;
  if (input.is('select')) {
    var value = input.find('option:selected').val();
  } else {
    var value = input.val();
  }
  switch (input.data().column) {
    case 'hours':
      var hours = value;
      hours = hours.replace(",", "."); // localize issue
      // Update exists 1 time_entry
      if (timeEntryId) {
        var hoursFloat = parseFloat(hours);
        if (hoursFloat === 0.0) {
          if (confirm(easyTimesheet.data().textConfirmDestroyCell)) {
            console.log(toString(timeEntryId) + " was destroyed");
            $.ajax({url: easyTimesheet.data().cellPath, type: 'DELETE', dataType: 'script', data: {time_entry_id: timeEntryId, row_id: row.attr("id")}});
          }
        } else {
          $.ajax({url: easyTimesheet.data().cellPath, type: "PUT", dataType: 'script', data: {time_entry_id: timeEntryId, time_entry: {hours: hours}, row_id: row.attr("id")}});
        }
      } else {
        // Else prepare TimeEntry attributes
        var easy_timesheet_row_params = {};
        var rowData = row[0].dataset;
        for (var key in rowData) {
          if (!rowData.hasOwnProperty(key)) continue;
          var newName = key.replace(/[A-Z]/g, "_$&").toLowerCase();
          easy_timesheet_row_params[newName] = rowData[key];
        }
        // Overwrite attributes by inputs
        $.each(row.find('input:hidden, select').serializeArray(), function (index, item) {
          easy_timesheet_row_params[item.name] = item.value;
        });
        // Do post - create - request for TimeEntry
        $.post(easyTimesheet.data().cellPath, {
          row_id: row.attr("id"),
          easy_timesheet_row: easy_timesheet_row_params,
          time_entry: {
            spent_on: cell.data().day,
            hours: hours}
        })
      }
          break;
    case 'comments':
      var comments = value;
      $.ajax({url: easyTimesheet.data().cellPath, type: "PUT", dataType: 'script', data: {time_entry_id: timeEntryId, time_entry: {comments: comments}, row_id: row.attr("id")}});
      break;
  }
});

function easyTimesheetOnChangeRowAttribute(rowId, type) {
  var row = $('#' + rowId);
  var currentField = row.find("." + type).find("input:hidden, select");
  var params = row.find('input:hidden, select').serializeArray();

  switch (type) {
    case "project":
      params.push({name: "focus", value: "issue"});
      break;
    case "issue":
      params.push({name: "focus", value: "activity"});
      break;
    case "activity":
      params.push({name: "focus", value: "cell-data"});
      break;
  }
  $.post(row.closest("table").data().rowPath, params);
}
function changeEasyTimesheetPeriodField(startDate, period) {
  if (period === 'week') $("#easy_timesheet_end_date").val(moment(startDate).add(7, 'd').format("YYYY-MM-DD"));
}
function timesheetComputeSums() {
  var column_sums_hash = [];
  var total_sum = 0;

  $('.table-monthly tbody tr').each(function(){
    var tr  = $(this);
    var tds = tr.find('td.cell-day:not(.row-sum, .row-overtime)');
    var   sum = 0;

    tds.each(function(i, v){
      var td = $(this);
      if(td.hasClass('column-sum')) {
        td.html(column_sums_hash[i]);
      } else {
        sum += parseFloat(td.data('hours'));

        if (typeof column_sums_hash[i] === 'undefined') {
          column_sums_hash[i] = parseFloat(td.data('hours'));
        } else {
          column_sums_hash[i] += parseFloat(td.data('hours'));
        }
      }
    });
    total_sum += sum;
    tr.find('.cell-day.row-sum').html(sum);
  });
  $('.table-monthly td.big-sum').html(total_sum);
}

EASY.schedule.late(function() {
    timesheetComputeSums();
});

function easyMonthlyTimesheetOnChangeRowAttribute(rowId, type, that) {
  var row = $('#' + rowId);
  var params = row.find('input:hidden, select').serializeArray();

  params.push({name: 'over_time', value: that.checked ? that.value : '0' });
  params.push({name: "focus", value: "cell-data"});

  $.post(row.closest("table").data().rowPath, params);
}
