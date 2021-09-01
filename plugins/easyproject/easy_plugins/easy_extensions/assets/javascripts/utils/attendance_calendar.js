$(document).on("click", ".easy-attendance-calendar-item[data-can-edit='true']", function() {
  var link = $(this).find('.easy-attendance-calendar-item-link-to-edit');
  $.get(link.attr("href"), {format: 'js'});
});


$(document).on('change', ".easy-attendance-range-half-day-radio input:radio", function(event) {
  $(".easy-attendance-time-dropper").remove();

  var radio = $(event.target);
  var span = $("<span/>").attr({"class": "easy-attendance-time-dropper nowrap", "title": radio.data().infoText});
  span.append($("<label/>").attr({"for": "non_work_start_time_time"}).text(radio.data().labelFrom));

  var i = $("<input/>").attr({"type": "time", "size": "3", "name": "non_work_start_time[time]", "id": "non_work_start_time_time", "value": radio.data().startTime});
  i.on("input", function(e) {
    var info = i.next("label.easy-attendance-time-to-info");
    var time = moment(i.val(), "HH:mm");
    info.text(radio.data().labelTo + " " + time.add("hours", radio.data().halfDayHours).format("HH:mm"));
  });

  span.append(i);
  span.append($("<label/>").attr({"class": "easy-attendance-time-to-info"}));
  span.insertAfter(radio);
});

EASY.initEasyAttendanceActivityChanger = function() {
  $(".easy-attendance-advanced-datetime-fields .easy-attendance__activity-select select").change(function(event) {
    $.post($(event.target).data().url, $('.easy-attendance-advanced-datetime-fields input, .easy-attendance-advanced-datetime-fields select').serialize());
  });
  $(".easy-attendance-range-half-day-radio input:checked").change();
};
