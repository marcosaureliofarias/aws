EasyCalendar.manager.registerAddOn("scheduler", function (instance) {
  var scheduler = instance.scheduler;
  scheduler.get_elements = function () {
    //get all child elements as named hash
    var els = Array.prototype.slice.call(this._obj.getElementsByTagName("DIV"));
    var aEls = Array.prototype.slice.call(this._obj.getElementsByClassName("dhx_cal_navline")[0].getElementsByTagName("A"));
    els = els.concat(aEls);
    for (var i = 0; i < els.length; i++) {
      var class_name = scheduler._getClassName(els[i]);
      var attr_value = els[i].getAttribute("name") || "";
      if (class_name) class_name = class_name.split(" ")[0];
      if (!this._els[class_name]) this._els[class_name] = [];
      this._els[class_name].push(els[i]);

      //check if name need to be changed
      var label = scheduler.locale.labels[attr_value || class_name];
      if (typeof label !== "string" && attr_value && !els[i].innerHTML)
        label = attr_value.split("_")[0];
      if (label) {
        this._waiAria.labelAttr(els[i], label);
        els[i].innerHTML = label;
      }
    }
  };
  var old_calc_scale_sizes = scheduler._calc_scale_sizes;
  scheduler._calc_scale_sizes = function (ignoredWidth, from, to) {
    var width = scheduler._els["dhx_cal_data"][0].offsetWidth;
    if (scheduler._mode === "day" || scheduler._mode === "week") {
      width -= scheduler.xy.scale_width + 4;
    }
    old_calc_scale_sizes.call(scheduler, width, from, to);
  };
  var _clickButtons = scheduler._click.buttons;
  scheduler._click.buttons.delete = function (id) {
    var event = scheduler.getEvent(id);
    if (scheduler.config["confirm_delete_" + event.type]) {
      var c = scheduler.locale.labels.confirm_deleting;
      scheduler._dhtmlx_confirm(c, scheduler.locale.labels.title_confirm_deleting, function () {
        scheduler.deleteEvent(id);
      });
    } else {
      scheduler.deleteEvent(id);
    }
  };
  _clickButtons.delete_further = function (id) {
    var first = scheduler.getEvent(id);
    if (scheduler.config["confirm_delete_" + first.type]) {
      var c = scheduler.locale.labels.confirm_deleting;
      scheduler._dhtmlx_confirm(c, scheduler.locale.labels.title_confirm_deleting, function () {
        scheduler.deleteFurtherEvents(first);
      });
    } else {
      scheduler.deleteFurtherEvents(first);
    }
  };
  scheduler.deleteFurtherEvents = function (first) {
    var start = first.start_date.valueOf();
    var events = scheduler.get_visible_events();
    for (var i = 0, event; i < events.length, event = events[i]; i++) {
      if (event.start_date <= start) continue;
      if (!scheduler.isSimilar(event, first)) continue;
      scheduler.deleteEvent(event.id);
    }
  };
  // _clickButtons.make_room = function (id) {
  //   var main = scheduler.getEvent(id);
  //   var start = main.start_date.valueOf();
  //   var end = main.end_date.valueOf();
  //   var events = scheduler.get_visible_events();
  //
  //   for (var i = 0, event; i < events.length, event = events[i]; i++) {
  //     if (event === main) continue;
  //     if (event.start_date >= end) continue;
  //     if (event.end_date <= start) continue;
  //     if (!scheduler.makeRoomFilter(event, main)) continue;
  //     if (event.start_date >= start) { // 1 4
  //       if (event.end_date <= end) { // 1
  //         scheduler.deleteEvent(event.id);
  //       } else { // 4
  //         scheduler.setEventStartDate(event.id, new Date(end));
  //       }
  //     } else { // 2 3
  //       if (event.end_date <= end) { // 3
  //         scheduler.setEventEndDate(event.id, new Date(start));
  //       } else {  // 2
  //         var copy = scheduler._lame_copy({}, event);
  //         scheduler.addEvent(new Date(end), new Date(event.end_date), event.text, null, copy);
  //         scheduler.setEventEndDate(event.id, new Date(start));
  //       }
  //     }
  //   }
  //
  // };
  // scheduler.makeRoomFilter = function (event, main) {
  //   if (event.type === "meeting") return false;
  //   return true
  // };
  _clickButtons.copy_calendar_url = function (id) {
    var event = scheduler.getEvent(id);
    window.easyUtils.clipboard.copy(event.icalUrl);
  };
  var ignoredNodeClasses = ["dhx_cal_data", "dhx_cal_header", "dhx_cal_navline easy-calendar__calendar-navs", "dhx_multi_day"];
  scheduler.set_xy = function (node, w, h, x, y) {
    if (ignoredNodeClasses.indexOf(node.className) > -1) return;
    node.style.width = Math.max(0, w) + "px";
    node.style.height = Math.max(0, h) + "px";
    if (!node.data) {
      node.data = {};
    }
    if (arguments.length > 3) {
      node.style.left = x + "px";
      node.style.top = y + "px";
      node.data.x = x;
      node.data.y = y
    }
    node.data.width = w;
    node.data.height = h;
  };
  scheduler._render_v_bar = function (ev, x, y, w, h, style, contentA, contentB, bottom) {
    let attendanceActivities, activity, renderDragMarker;
    if (ev.type === "easy_attendance") {
      attendanceActivities = this.main.settings._settings.easy_attendance_activities || [];
      activity = attendanceActivities.find(attendance => attendance.id === ev.easyAttendanceActivityId);
      renderDragMarker = activity ? activity.use_specify_time : false;
    }
    var d = document.createElement("DIV");
    var id = ev.id;
    var cs = (bottom) ? "dhx_cal_event dhx_cal_select_menu" : "dhx_cal_event";

    var cse = scheduler.templates.event_class(ev.start_date, ev.end_date, ev);
    if (cse) cs = cs + " " + cse;

    var html = '<div event_id="' + id + '" class="' + cs + '" style="position:absolute; top:' + y + 'px; left:' + x + 'px; width:' + w + 'px; height:' + (h - 1) + 'px;' + (style || "") + '"></div>';
    d.innerHTML = html;

    var container = d.cloneNode(true).firstChild;

    if (!bottom && scheduler.renderEvent(container, ev, w, h, contentA, contentB)) {
      return container;
    } else {
      container = d.firstChild;

      var inner_html = '<div class="dhx_event_move dhx_title">' + contentA + '</div>';
      inner_html += '<div class="dhx_body">' + contentB; // +2 css specific, moved from render_event

      if (ev.type === "meeting") {
        ev.confirmed ? inner_html += '<span class="easy-calendar__event_body-action"><i class="icon easy-calendar__event-icon-meeting--confirmed"></i></span>' :
                      inner_html += '<span class="easy-calendar__event_body-action"><i class="icon easy-calendar__event-icon-meeting--canceled"></i></span>';
      } else if (ev.type === 'easy_attendance') {
        if (ev.confirmed) {
          inner_html += '<span class="easy-calendar__event_body-action"><i class="icon easy-calendar__event-icon-meeting--confirmed"></i></span>';
        } else {
          ev.approvable ? inner_html += '<span class="easy-calendar__event_body-action"><i class="icon easy-calendar__event-icon-meeting--approvable"></i></span>' :
                          inner_html += '<span class="easy-calendar__event_body-action"><i class="icon easy-calendar__event-icon-meeting--rejected"></i></span>';
        }

      }
      inner_html += '</div>';
      if (ev.type !== "easy_attendance" || renderDragMarker) {
        var footer_class = "dhx_event_resize dhx_footer";
        if (bottom)
          footer_class = "dhx_resize_denied " + footer_class;

        inner_html += '<div class="' + footer_class + '" ></div>';
      }

      container.innerHTML = inner_html;

    }
    return container;
  };
  scheduler._reset_month_scale = function (b, dd, sd, rows) {
    //recalculates rows height and redraws month layout
    var ed = scheduler.date.add(dd, 1, "month");

    //trim time part for comparation reasons
    var cd = scheduler._currentDate();
    this.date.date_part(cd);
    this.date.date_part(sd);

    rows = rows || Math.ceil(Math.round((ed.valueOf() - sd.valueOf()) / (60 * 60 * 24 * 1000)) / 7);

    var height = this.xy.month_cell_height - this.xy.month_head_height;

    this._colsS.height = height + this.xy.month_head_height;
    this._colsS.heights = [];

    return scheduler._render_month_scale(b, dd, sd, rows);

  };
});
EasyCalendar.manager.registerAddOn("year_view", function (instance) {
  var scheduler = instance.scheduler;
  var to_attr = scheduler.date.date_to_str("%Y/%m/%d");
  var dateDates = {};
  var dateEventsHours = {};
  scheduler._pre_render_year_events = function (evs) {
    dateEventsHours = {};
    if (evs.length > 1) {
      return;
    }
    if (!evs.length) return;
    var bannedId = evs[0].id.toString();
    for (var date in dateEventsHours) {
      if (!dateEventsHours.hasOwnProperty(date)) continue;
      var eventHours = dateEventsHours[date];
      delete eventHours[bannedId];
    }
  };
  scheduler._mark_year_date = function (d, ev) {
    var date = to_attr(d);
    dateDates[date] = d;
    var hours = (ev.end_date - ev.start_date);
    if (dateEventsHours[date] === undefined) {
      dateEventsHours[date] = {};
    }
    dateEventsHours[date][ev.id] = hours;
  };
  scheduler._showToolTip = function(date, pos, e, src) {
    if (this._tooltip) {
      if (this._tooltip.date.valueOf() == date.valueOf()) return;
      this._tooltip.innerHTML = "";
    } else {
      var t = this._tooltip = document.createElement("DIV");
      t.className = "dhx_year_tooltip";
      document.body.appendChild(t);
      t.onclick = scheduler._click.dhx_cal_data;
    }
    var evs = this.getEvents(date, this.date.add(date, 1, "day"));
    var html = "";

    evs.sort(function (a,b) {
      return a.start_date - b.start_date;
    });

    for (var i = 0; i < evs.length; i++) {

      var ev = evs[i];
      if(!this.filter_event(ev.id, ev))
        continue;

      var bg_color = (ev.color ? ("background:" + ev.color + ";") : "");
      var color = (ev.textColor ? ("color:" + ev.textColor + ";") : "");
      var cse = scheduler.templates.event_class(ev.start_date, ev.end_date, ev);

      html += "<div class='dhx_tooltip_line dhx_cal_event " + cse + "' style='" + bg_color + "" + color + "' event_id='" + evs[i].id + "'>";
      html += "<div class='dhx_tooltip_date' style='" + bg_color + "" + color + "'>" + (evs[i]._timed ? this.templates.event_date(evs[i].start_date) : "") + "</div>";
      html += "<div class='dhx_event_icon icon_details'>&nbsp;</div>";
      html += this.templates.year_tooltip(evs[i].start_date, evs[i].end_date, evs[i]) + "</div>";
    }

    this._tooltip.style.display = "";
    this._tooltip.style.top = "0px";


    if (document.body.offsetWidth - pos.left - this._tooltip.offsetWidth < 0)
      this._tooltip.style.left = pos.left - this._tooltip.offsetWidth + "px";
    else
      this._tooltip.style.left = pos.left + src.offsetWidth + "px";

    this._tooltip.date = date;
    this._tooltip.innerHTML = html;

    if (document.body.offsetHeight - pos.top - this._tooltip.offsetHeight < 0)
      this._tooltip.style.top = pos.top - this._tooltip.offsetHeight + src.offsetHeight + "px";
    else
      this._tooltip.style.top = pos.top + "px";
  };
  scheduler._post_render_year_events = function () {
    var dates = Object.keys(dateEventsHours);
    for (var i = 0; i < dates.length; i++) {
      var date = dates[i];
      var c = this._get_year_cell(dateDates[date]);
      c.className = "dhx_month_head dhx_year_event ";
      var eventHours = dateEventsHours[date];
      var hours = Object.keys(eventHours).reduce(function (previousValue, id) {
        return previousValue + eventHours[id];
      }, 0);
      var ratio = hours / scheduler.getHoursForDay(date);
      if (ratio <= 0.65) {
        c.className += "easy-calendar__event_year--low";
      } else if (ratio <= 1) {
        c.className += "easy-calendar__event_year--high";
      } else {
        c.className += "easy-calendar__event_year--over";
      }
      if (!scheduler._year_marked_cells[date]) {
        c.setAttribute("date", date);
        scheduler._year_marked_cells[date] = c;
      }
    }
  };
});
EasyCalendar.manager.registerAddOn("key_nav", function (instance) {
  var scheduler = instance.scheduler;
  scheduler.focus = function () {
  };
});
EasyCalendar.manager.registerAddOn("active_links", function (instance) {
  var scheduler = instance.scheduler;
  scheduler._active_link_click = function (e) {
    var start = e.target || event.srcElement;
    var to = start.getAttribute("jump_to");
    var s_d = scheduler.date.str_to_date(scheduler.config.api_date);
    if (to) {
      if (scheduler.config.default_zoom === "year" || scheduler.config.default_zoom === "month") {
        scheduler.setCurrentView(s_d(to), scheduler.config.active_link_view);
      }
      if (e && e.preventDefault){
        e.preventDefault();
      }
      return false;
    }
  };
});
