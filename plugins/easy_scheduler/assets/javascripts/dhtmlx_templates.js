EasyCalendar.manager.registerAddOn("scheduler", function (instance) {
  var scheduler = instance.scheduler;
  var classArrays = {};
  scheduler.templates.init = function () {
    var d = scheduler.date.date_to_str;
    var c = scheduler.config;
    scheduler.templates.short_day_date = d(c.short_day_date);
    scheduler.templates.short_year_date = d(c.short_year_date);
    scheduler.templates.long_date = d(c.long_date);
  };
  scheduler.templates.classBuilder = function (templateName, callback) {
    if (!classArrays[templateName]) {
      var calls = classArrays[templateName] = [];
      if (scheduler.templates[templateName]) {
        calls.push(scheduler.templates[templateName]);
      }
      scheduler.templates[templateName] = function () {
        var args = arguments;
        return calls.map(function (callback) {
          return callback.apply(scheduler.templates, args);
        }).join(" ");
      };
    }
    classArrays[templateName].push(callback);
    return callback;
  };
  scheduler.templates.removeClassBuilder = function (templateName, callback) {
    if (!classArrays[templateName]) return;
    var array = classArrays[templateName];
    var index = array.indexOf(callback);
    if (index > -1) {
      array.splice(index, 1);
    }
  };
  scheduler.templates.event_class = function (start, end, event) {
    var css = "";
    if (event.id.toString() === scheduler._select_id) {
      css = "selected";
    }
    if (event.readonly) {
      css += " easy-calendar__event--read-only";
    }
    if (end - start <= scheduler.date.millisecondsInHalfHour) {
      css += " easy-calendar__event--half-hour";
    }
    return css;
  };
  scheduler.templates.week_date_class = function (date, today) {
    var css = "easy-calendar__day-cell";
    if (!scheduler.isWorkingDay(date)) return css + " easy-calendar__day-cell--nonworking";
    return css;
  };
  scheduler.templates.month_date_class = function (date, today) {
    var css = "easy-calendar__month-cell";
    if (!scheduler.isWorkingDay(date)) return css + " easy-calendar__month-cell--nonworking";
    return css;
  };
  scheduler.templates.hour_scale = function (date) {
    return date.getHours();
  };
  scheduler.templates.icon_class = function (icon) {
    switch (icon) {
      case "icon_details":
        return " icon--edit";
      case "icon_delete":
        return " icon--remove-event";
      case "icon_link":
        return " icon--link";
      case "icon_copy_calendar_url":
        return " icon--link";
      case "icon_delete_further":
        return " icon--remove-all-further";
      case "icon_log_time":
        return " icon--time-add";
      default:
        return "";
    }
  };
  scheduler.templates.tooltip_date_format = scheduler.date.date_to_str("%Y-%m-%d %H:%i");
  scheduler.templates.dMY_time_format = scheduler.date.date_to_str("%d %M %Y %H:%i");
  scheduler.templates.Ymd_format = scheduler.date.date_to_str("%Y-%m-%d");
  scheduler.templates.dMY_format = scheduler.date.date_to_str("%d %M %Y");
  scheduler.templates.event_bar_date = function (start, end, event) {
    var date = new Date(start);
    scheduler.date.date_part(date);
    var left = (start - date - scheduler.config.start_time) / scheduler.config.workday_duration * 100;
    var width = (end - start) / scheduler.config.workday_duration * 100;
    var bar = '<div class="easy-calendar__event_month-bar"></div>' +
        '<div class="easy-calendar__event_month-indicator" style="left: ' + left + '%;width:' + width + '%"></div>';
    return bar + scheduler.templates.event_date(start) + " ";
  };
  scheduler.templates.event_bar_text = function (start, end, event) {
    if (event._timed) return event.text;
    return '<div class="easy-calendar__event_month-bar"></div>' +
        '<div class="easy-calendar__event_month-indicator easy-calendar__event_month-indicator--full"></div>' + event.text;
  };

  scheduler.templates.week_date = function (d1, d2) {
    var d2Decreased = scheduler.date.add(d2, -1, "day");

    if (d1.getFullYear() !== d2Decreased.getFullYear()) {
      return scheduler.templates.long_date(d1) + " &ndash; " + scheduler.templates.long_date(d2Decreased);
    }
    if (d1.getMonth() !== d2Decreased.getMonth()) {
      return scheduler.templates.short_day_date(d1) + " &ndash; " + scheduler.templates.long_date(d2Decreased);
    } else {
      return scheduler.templates.short_day_date(d1) + " &ndash; " + scheduler.templates.short_year_date(d2Decreased);
    }
  };
});
