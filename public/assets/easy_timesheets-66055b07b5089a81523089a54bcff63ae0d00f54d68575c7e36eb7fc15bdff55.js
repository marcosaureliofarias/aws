function easyTimesheetOnChangeRowAttribute(e,t){var a=$("#"+e),s=(a.find("."+t).find("input:hidden, select"),a.find("input:hidden, select").serializeArray());switch(t){case"project":s.push({name:"focus",value:"issue"});break;case"issue":s.push({name:"focus",value:"activity"});break;case"activity":s.push({name:"focus",value:"cell-data"})}$.post(a.closest("table").data().rowPath,s)}function changeEasyTimesheetPeriodField(e,t){"week"===t&&$("#easy_timesheet_end_date").val(moment(e).add(7,"d").format("YYYY-MM-DD"))}function timesheetComputeSums(){var e=[],t=0;$(".table-monthly tbody tr").each(function(){var a=$(this),s=a.find("td.cell-day:not(.row-sum, .row-overtime)"),i=0;s.each(function(t){var a=$(this);a.hasClass("column-sum")?a.html(e[t]):(i+=parseFloat(a.data("hours")),"undefined"==typeof e[t]?e[t]=parseFloat(a.data("hours")):e[t]+=parseFloat(a.data("hours")))}),t+=i,a.find(".cell-day.row-sum").html(i)}),$(".table-monthly td.big-sum").html(t)}function easyMonthlyTimesheetOnChangeRowAttribute(e,t,a){var s=$("#"+e),i=s.find("input:hidden, select").serializeArray();i.push({name:"over_time",value:a.checked?a.value:"0"}),i.push({name:"focus",value:"cell-data"}),$.post(s.closest("table").data().rowPath,i)}$(document).on("focus, mouseup, click",".easy-timesheet-table .cell-data input",function(e){$(e.target).select()}),$(document).on("change",".easy-timesheet-table .cell-data input, .easy-timesheet-table .cell-data select",function(e){var t=$(e.target),a=t.closest("td"),s=t.closest("tr"),i=t.closest("table.easy-timesheet-table"),l=t.data().timeEntryId;if(t.is("select"))var o=t.find("option:selected").val();else o=t.val();switch(t.data().column){case"hours":var r=o;if(r=r.replace(",","."),l){0===parseFloat(r)?confirm(i.data().textConfirmDestroyCell)&&(console.log(toString(l)+" was destroyed"),$.ajax({url:i.data().cellPath,type:"DELETE",dataType:"script",data:{time_entry_id:l,row_id:s.attr("id")}})):$.ajax({url:i.data().cellPath,type:"PUT",dataType:"script",data:{time_entry_id:l,time_entry:{hours:r},row_id:s.attr("id")}})}else{var n={},d=s[0].dataset;for(var c in d)if(d.hasOwnProperty(c)){var u=c.replace(/[A-Z]/g,"_$&").toLowerCase();n[u]=d[c]}$.each(s.find("input:hidden, select").serializeArray(),function(e,t){n[t.name]=t.value}),$.post(i.data().cellPath,{row_id:s.attr("id"),easy_timesheet_row:n,time_entry:{spent_on:a.data().day,hours:r}})}break;case"comments":var h=o;$.ajax({url:i.data().cellPath,type:"PUT",dataType:"script",data:{time_entry_id:l,time_entry:{comments:h},row_id:s.attr("id")}})}}),EASY.schedule.late(function(){timesheetComputeSums()});