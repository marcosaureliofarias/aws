EasyCalendar.manager.registerAddOn("scheduler", function (instance) {
  var scheduler = instance.scheduler;
  scheduler.date.millisecondsInHalfHour = 0.5 * 60 * 60 * 1000;
  scheduler.date.date_to_str = function (format, utc) {
    format = format.replace(/%[a-zA-Z]/g, function (a) {
      switch (a) {
        case "%d":
          return "\"+this.s.date.to_fixed(date.getDate())+\"";
        case "%m":
          return "\"+this.s.date.to_fixed((date.getMonth()+1))+\"";
        case "%j":
          return "\"+date.getDate()+\"";
        case "%n":
          return "\"+(date.getMonth()+1)+\"";
        case "%y":
          return "\"+this.s.date.to_fixed(date.getFullYear()%100)+\"";
        case "%Y":
          return "\"+date.getFullYear()+\"";
        case "%D":
          return "\"+this.s.locale.date.day_short[date.getDay()]+\"";
        case "%l":
          return "\"+this.s.locale.date.day_full[date.getDay()]+\"";
        case "%M":
          return "\"+this.s.locale.date.month_short[date.getMonth()]+\"";
        case "%F":
          return "\"+this.s.locale.date.month_full[date.getMonth()]+\"";
        case "%h":
          return "\"+this.s.date.to_fixed((date.getHours()+11)%12+1)+\"";
        case "%g":
          return "\"+((date.getHours()+11)%12+1)+\"";
        case "%G":
          return "\"+date.getHours()+\"";
        case "%H":
          return "\"+this.s.date.to_fixed(date.getHours())+\"";
        case "%i":
          return "\"+this.s.date.to_fixed(date.getMinutes())+\"";
        case "%a":
          return "\"+(date.getHours()>11?\"pm\":\"am\")+\"";
        case "%A":
          return "\"+(date.getHours()>11?\"PM\":\"AM\")+\"";
        case "%s":
          return "\"+this.s.date.to_fixed(date.getSeconds())+\"";
        case "%W":
          return "\"+this.s.date.to_fixed(this.s.date.getISOWeek(date))+\"";
        default:
          return a;
      }
    });
    if (utc) format = format.replace(/date\.get/g, "date.getUTC");
    return $.proxy(new Function("date", "return \"" + format + "\";"), {s: scheduler});
  };
  scheduler._dhtmlx_confirm = function (message, title, callback) {
    if (window.confirm(message)) {
      callback();
    }
  };
  /**
   * @param {Date} start
   * @param {Date} end
   * @return {Date|undefined}
   */
  scheduler.findZoomDate = function (start, end) {
    var today = new Date();
    if (!start && !end) return today;
    var min = this._min_date;
    var max = this._max_date;
    // function compare(date1,date2){return date1<date2?"<":">=";}
    // console.log(min+compare(min,start)+start+compare(start,today)+today+compare(today,end)+end+compare(end,max)+max);
    if (!start) {
      if (end < min) return end;
      if (max < end) {
        if (end < today) return end;
        if (today < end && max <= today) return today;
      }
      return;
    }
    if (!end) {
      if (min < start && start < max) return;
      if (start < min && min < today) return;
      if (start < today) return today;
      return start;
    }
    if (end < min || max <= start) {
      if (start < today && today < end) return today;
      return start;
    }
    if (max <= today && today < end) return today;
  };
  scheduler.findFirstVisibleEvent = function (date, except) {
    var firstDate = Infinity;
    var firstEvent;
    var events = scheduler.get_visible_events();
    for (var i = 0; i < events.length; i++) {
      var event = events[i];
      if (event === except) continue;
      var eventDate = event.start_date.getTime();
      if (eventDate > date && eventDate < firstDate) {
        firstDate = eventDate;
        firstEvent = event;
      }
    }
    // console.log({firstDate: new Date(firstDate), date: new Date(date), firstEvent: firstEvent});
    return firstEvent;
  };
  scheduler.prepareEmptySpaces = function (filter, limits) {
    var dates = [];
    var lastDate = new Date(scheduler._max_date);
    lastDate.setDate(lastDate.getDate() - 1);
    var events = scheduler.get_visible_events();
    for (var i = 0; i < events.length; i++) {
      var event = events[i];
      if (filter && !filter(event)) continue;
      var end = event.end_date.getTime();
      var start = event.start_date.getTime();
      dates.push(start + "b");
      dates.push(end + "e");
    }
    var min = scheduler._min_date.valueOf() + scheduler.config.start_time;
    var max = lastDate.valueOf() + scheduler.config.end_time;
    dates.push(min + "e");
    dates.push(max + "b");
    var level = 1;
    if (limits && limits.start) {
      level++;
      dates.push(limits.start.valueOf() + "e");
    }
    if (limits && limits.end) {
      dates.push(limits.end.valueOf() + "b");
    }
    var mover = new Date(scheduler._min_date);
    while (mover < lastDate) {
      dates.push(mover.valueOf() + scheduler.config.end_time + "b");
      mover.setDate(mover.getDate() + 1);
      dates.push(mover.valueOf() + scheduler.config.start_time + "e");
    }
    dates.sort();
    var frees = [];
    for (i = 0; i < dates.length; i++) {
      var date = dates[i];
      if (date.charAt(date.length - 1) === "b") {
        level++;
      } else {
        if (level > 0) level--;
        // if (level === 0) {
        frees.push({ start: parseInt(date), end: parseInt(dates[i + 1]) });
        // }
      }
    }
    // console.log(dates.map(function (value) { return value.charAt(value.length-1).toUpperCase()+" "+new Date(parseInt(value)); }));
    // console.log(frees.map(function (value) { return {b:new Date(value.start),e:new Date(value.end)} }));
    // debugger;
    return frees;
  };
  /**
   *
   * @param {int} pointer
   * @param {Array.<{start:int,end:int}>} frees
   * @return {{start:int,end:int}|null}
   */
  scheduler.findNextEmptySpace = function (pointer, frees) {
    for (var i = 0; i < frees.length; i++) {
      var free = frees[i];
      // console.log({dateDate:new Date(parseInt(date)),date: date,level:level,pointer:new Date(pointer)});
      if (free.end <= pointer) continue;
      if (free.start < pointer) {
        return {start: pointer, end: free.end};
      }
      return free;
    }
    return null;
  };
  /**
   * @param {Date} date
   * @return {boolean}
   */
  scheduler.isWorkingDay = function (date) {
    return date.getDay() !== 0 && date.getDay() !== 6
  };
  /**
   * @param {String} date
   * @return {int}
   */
  scheduler.getHoursForDay = function (date) {
    return scheduler.config.workday_duration;
  };
});
