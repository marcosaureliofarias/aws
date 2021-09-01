/**
 *
 * @param scheduler
 * @param {CalendarMain} main
 */
EasyCalendar.CalendarMain.prototype.initScheduler = function initScheduler (scheduler, main) {
  scheduler.main = main;
  EasyGem.extend(scheduler.config, {
    touch: true,
    touch_tooltip: true,
    use_select_menu_space: true,
    details_on_dblclick: true,
    details_on_create: true,
    xml_date: "%Y-%m-%d %H:%i",
    json_date: "%Y-%m-%d %H:%i",
    multi_day: true,
    first_hour: parseInt(main.settings.displayFrom),
    last_hour: parseInt(main.settings.displayTo),
    range_type: main.settings.range_type,
    full_day: false,
    default_date: "%D, %F %j",
    day_date: "%D, %M %j",
    api_date: "%Y-%m-%d %H:%i",
    short_day_date: "%M %j",
    short_year_date: "%j %Y",
    long_date: "%M %j %Y",
    agenda_long_date: "%D, %j %F %Y",
    buttons_left: ["dhx_delete_btn"],
    buttons_right: ["dhx_save_btn", "dhx_cancel_btn"],
    mark_now: true,
    // now_date: new Date(2018, 0, 17, 8, 42),
    time_step: 30,
    delay_render: false,
    // delay_render : true, // delayed render for better render stacking
    cascade_event_display: true, // enable rendering, default value : false
    cascade_event_count: 4, // how many events events will be displayed in cascade style (max), default value : 4
    cascade_event_margin: 40, // margin between events, default value : 30
    max_month_events: 5,
    active_link_view: "week",
    icons_readonly: ["icon_link"], // default tool icons for readonly entity
    icons_readonly_allocation: ["icon_link"],
    icons_readonly_allocation_vue: [],
    icons_editable: ["icon_link", "icon_details", "icon_delete"],
    icons_readonly_ical_event: ["icon_copy_calendar_url"],
    icons_editable_allocation: ["icon_link", "icon_details", "icon_delete", "icon_delete_further", "icon_log_time"],
    icons_editable_allocation_vue: ["icon_delete_further", "icon_delete"],
    icons_deletable: ["icon_delete", "icon_delete_further"],
    icons_editable_issue: ["icon_link", "icon_log_time"],
    icons_editable_issue_vue: ["icon_link"],
    confirm_delete_meeting: true,
    confirm_delete_attendance: true,
    confirm_delete_sales_activity: true,
    preserve_scroll: false,
    dblclick_create: false,
    drag_create: true,
    start_time: 10 * 3600000, // placeholder data
    end_time: 14 * 3600000, // placeholder data
    workday_duration: 4 * 3600000 // placeholder data
  });

  var _getLegendOptions = function (scheduler, availableCalendars) {
    var calendars = {};
    for (var key in availableCalendars) {
      if (!availableCalendars.hasOwnProperty(key)) continue;
      var value = scheduler.getFromStorage(key);
      calendars[key] = value === null ? availableCalendars[key] : JSON.parse(value);
    }
    return calendars;
  };

  if (scheduler.getFromStorage("filter-data-path") && scheduler.getFromStorage("filter-data-query")) {
    main.settings.paths.tasksDataPath = scheduler.getFromStorage("filter-data-path");
    var query = JSON.parse(scheduler.getFromStorage("filter-data-query"));
    main.taskData.taskType = query.entity_type;
  }
  scheduler.options = {
    availableCalendars: _getLegendOptions(scheduler, main.settings.availableCalendars)
  };

  if (window.ERUI && ERUI.sassData) {
    var narrowLimit = parseInt(ERUI.sassData["media-collapse-menu"]);
  }
  scheduler.config.narrowLimit = narrowLimit || 960;

  scheduler.config.userIsToggled = function () {
    if (JSON.parse(scheduler.getFromStorage("userToggle")) === null) return false;
    return JSON.parse(scheduler.getFromStorage("userToggle"));
  }();

  scheduler.config.togglerValue = function () {
    if (scheduler.getFromStorage("togglerValue") === null) return "1";
    return scheduler.getFromStorage("togglerValue");
  }();

  scheduler.config.default_zoom = function () {
    const defautlToolbarZoom = main.settings['defaultToolbarZoom'];
    if (defautlToolbarZoom) return defautlToolbarZoom ;
    if (scheduler.getFromStorage("calendarValue") === null) return "week";
    return scheduler.getFromStorage("calendarValue");
  }();

  if (window.innerWidth <= scheduler.config.narrowLimit) {
    var $legend = main.$container.find(".easy-calendar__legend--mobile .easy-calendar-legend__scheduler--entity_others");
    var $legendButton = main.$container.find(".easy-calendar__legend--mobile .easy-calendar-legend__scheduler--show_button");
    if ($legend.length !== 0 && $legendButton.length !== 0) {
      $legend.addClass("hidden");
      $legendButton.removeClass("hidden");
    }
    EasyGem.extend(scheduler.config, {
      default_zoom: "day",
      active_link_view: "day"
    });
  }

  EasyGem.extend(scheduler.xy, {
    scale_width: 35,
    bar_height: 17,
    month_cell_height: 100,
    min_event_height: 22
  });
  scheduler.skin = "classic";
  scheduler._skin_xy.nav_height[1] = 50;
  scheduler._skin_xy.bar_height[1] = 15;
  scheduler._skin_settings.hour_size_px[1] = 44;
  if (window.dhtmlXTooltip) {
    dhtmlXTooltip.config.timeout_to_display = 1000;
    dhtmlXTooltip.config.timeout_to_hide = 0;
  }


  // scheduler.config.event_duration = 40;
  scheduler.config.occurrence_timestamp_in_utc = true;
  scheduler.config.repeat_precise = true;

  scheduler.templates.init();
  // scheduler.config.limit_time_select = true;
  // scheduler.config.limit_start = Date.parse("2018-01-17");
  // scheduler.config.limit_end = Date.parse("2018-02-17");
  // scheduler.config.resize_month_events = true;
  function allow_editable (id) {
    if (!id) return true;
    var ev = this.getEvent(id);
    return !ev.readonly;
  }

  var _clickButtons = scheduler._click.buttons;
  _clickButtons.link = function (id) {
    var event = scheduler.getEvent(id);
    if (event) {
      switch (event.type) {
        case "allocation":
          var task = main.taskData.getTaskById(event.issue_id, 'issues');
          if (!task) return;
          var url = main.settings.paths.issues_path + "/" + task.id;
          return window.open(url, "_blank");
        case "meeting":
          if (!event.realId) return;
          url = main.settings.paths.rootPath + "/easy_meetings/" + event.realId;
          return window.open(url, "_blank");
        case "easy_attendance":
          if (!event.realId) return;
          url = main.settings.paths.rootPath + "/easy_attendances/" + event.realId;
          return window.open(url, "_blank");
        case "easy_entity_activity":
          if (!event.realId) return;
          if (!event.entityId || !event.entityType) return;
          var mapping = {'EasyCrmCase': '/easy_crm_cases/', 'EasyContact': '/easy_contacts/'};
          url = main.settings.paths.rootPath + mapping[event.entityType] + event.entityId;
          return window.open(url, "_blank");
      }
    } else {
      var task = main.tasksView.taskViews[id];
      if (!!task) {
        var url = main.settings.paths.issues_path + "/" + id;
        return window.open(url, "_blank");
      }
    }
  };
  _clickButtons.log_time = function (id) {
    var event = scheduler.getEvent(id);
    if (event){
      main.logTime.openForm(event); //TODO: prekopat
    } else {
      main.logTime.openForm(id);
    }
  };

  scheduler.isSimilar = function (first, second) {
    return first.type === second.type && first.issue_id === second.issue_id;
  };

  scheduler.attachEvent("onBeforeDrag", allow_editable);
  // scheduler.attachEvent("onClick", allow_editable);
  scheduler.attachEvent("onDblClick", allow_editable);
  scheduler.attachEvent("onLimitViolation", function (/*id, obj*/) {
    dhtmlx.message('The date is not allowed');
  });
  scheduler.attachEvent("onScaleAdd", function (element, date) {
    $(element).data("date", date);
  });
  var updateEvent = function (eventId, event) {
    if (typeof event !== "object") {
      event = scheduler.getEvent(eventId);
    }
    if (event) {
      event._changed = true;
      main.eventBus.fireEvent("eventChanged", event);
    }
  };
  scheduler.attachEvent("onEventAdded", updateEvent);
  scheduler.attachEvent("onEventChanged", updateEvent);
  scheduler.attachEvent("onEventDeleted", updateEvent);
  scheduler.attachEvent("onEventDrag", updateEvent);
  scheduler.attachEvent("onXLE", function () {
    main.$container.find(".easy-calendar__tasks").show();
    $(this.$container).css("visibility", "visible");
    main.eventBus.fireEvent("loaded");
  });
  var oldZoomMode;
  var $reso = main.$container.find('.easy-calendar__calendar-resolution');
  var $reso_parent = $reso.parent();
  $reso_parent.toggleable({
    content: $reso[0], openCallback: function () {
      var $reso_children = $reso.children();
      $reso_children.off('çlick').on('click', function (evnt) {
        $reso_parent.data('EASY-toggleable')._close();
      })
    }
  });

  var $schedulerParent = main.$container.parent()
  var $schedulerControlsUsers = $schedulerParent.find('.easy-calendar__control-users');
  var $schedulerControlsFullscreen = $schedulerParent.find('.easy-calendar__control-fullscreen');
  var $schedulerAssigneesWrap = main.$container.find('.easy-calendar__assignees-wrap');
  $schedulerControlsUsers.each(function (index) {
    var $users = $(this);
    $users.click(function (event) {
      event.preventDefault();
      $schedulerAssigneesWrap.toggleClass('easy-calendar__assignees-wrap--hidden');
    })
  });
  $schedulerControlsFullscreen.each(function (index) {
    var $fs = $(this);
    new EASY.utils.FullScreen($schedulerParent[0], $fs[0]).init();
  });



  // on tool modal events
  scheduler.attachEvent('onAfterToolModalOpen', scheduler.updateEventToolModal)

  scheduler.attachEvent("onViewChange", function (mode, date) {
    var $resolution = main.$container.find(".easy-calendar__calendar-resolution-wrapper");
    var text = $resolution.find("[name=\"" + mode + "_tab\"]").text();
    $resolution.find(".calendar_resolution").html(text);
    main.$container.removeClass("easy-calendar__mode--" + oldZoomMode);
    main.$container.addClass("easy-calendar__mode--" + mode);
    oldZoomMode = mode;
    main.eventBus.fireEvent("onViewChange", mode, date);
    if (main.settings['defaultToolbarZoom']) return;
    scheduler.config.default_zoom = mode;
    scheduler.saveToStorage("calendarValue", scheduler.config.default_zoom);
  });

  scheduler.templates.classBuilder("event_class", function (start, end, event) {
    if (event.issue_id) {
      var css = "easy-calendar__issue ";
      if (main.assigneeData.primaryId === event.user_id) {
        css += " easy-calendar__event--primary";
      }
      return css;
    }
  });
  scheduler.templates.event_text = function (start, end, event) {
    const txt = event._isPrivate ? scheduler.locale.labels.label_private_event : event.text;
    var text = "<span class='easy-calendar__event-name'>" + txt + "</span>";
    var hours = (event.end_date - event.start_date) / 3600000;
    text += " - "
      + (hours % 1 ? hours.toFixed(1) : hours)
      + "h";
    return text;
  };
  scheduler.templates.selected_event_text = function (event) {
    var template;
    var obj = {
      name: event.text,
      startDate: event.start_date.toLocaleString(),
      endDate: event.end_date.toLocaleString()
    };
    if (event.type === "allocation") {
      template = main.settings.templates.allocationText;
      var assignee = main.assigneeData.getAssigneeById(event.user_id);
      if (assignee) {
        obj.assigneeName = assignee.name;
        obj.avatar_url = assignee.avatar_url;
      }
    } else {
      obj.users = event.user_ids.map(function (userId) {
        var user = main.assigneeData.getAssigneeById(userId);
        if (user) {
          return {
            assigneeName: user.name,
            avatar_url: user.avatar_url
          };
        }
      });
      if (event._isMeeting) {
        template = main.settings.templates.meetingText;
        $.extend(obj, {
          location: event.location
          // duration: (event.end_date-event.start_date) / 3600000 + " h",
        });
      } else if (event._isEntityActivity) {
        template = main.settings.templates.salesActivityText;
      } else if (event._isIcalEvent) {
        template = main.settings.templates.icalEventText;
        $.extend(obj, {
          location: event.location,
          allDay: event.allDay ? scheduler.locale.labels.text_yes : scheduler.locale.labels.text_no,
          icalName: event.icalName,
          syncDate: event.syncDate ? event.syncDate.toLocaleString() : '',
          icalSyncUrl: main.settings.paths.icalSyncUrl.replace("__entityId", event.icalId),
          icalSyncClass: event.icalId ? '' : 'hidden'
        });
      } else {
        template = main.settings.templates.attendanceText;
      }
    }
    if (event.allDay) {
      var end_date = (event.isOneDay) ? event.start_date : event.end_date;
      $.extend(obj, {
        startDate: scheduler.templates.Ymd_format(event.start_date),
        endDate: scheduler.templates.Ymd_format(end_date)
      });
    }
    return Mustache.render(template, obj);
  };
  // scheduler.makeRoomFilter = function (event, main) {
  //   if (event.type === "meeting") return false;
  //   if (event.user_ids) {
  //     if (main.user_ids) {
  //       return event.user_ids.any(function (id) {
  //         return main.user_ids.indexOf(id) > -1;
  //       });
  //     }
  //     return event.user_ids.indexOf(main.user_id) > -1;
  //   }
  //   if (main.user_ids) {
  //     return main.user_ids.indexOf(event.user_id) > -1;
  //   }
  //   return event.user_id === main.user_id;
  // };

  scheduler.templates.event_header = function (start, end, event) {
    let text;
    if (end - start > scheduler.date.millisecondsInHalfHour) {
      text = scheduler.templates.event_date(start) + " - " + scheduler.templates.event_date(end);
    } else {
      text = event._isPrivate ? scheduler.locale.labels.label_private_event : event.text;
    }
    text = '<span class="easy-calendar__event-title">' + text + '</span>';
    text += "<div class='easy-calendar__avatars'>";
    const userIds = event._isGenericMeeting ? event.user_ids : [event.user_id];
    userIds.forEach(function (assignee_id) {
      const assignee = main.assigneeData.assigneeMap[assignee_id];
      if (!assignee) return;
      text += '<img class="gravatar easy-calendar__avatar" src="' + assignee.avatar_url + '" title="' + assignee.name + '">';
    });
    text += "</div>";
    return text;
  };

  scheduler.templates.toolmodal_event_header = function (event) {
    return !!event.text ? event.text : main.settings.labels.entityTitle[event.type];
  };
  scheduler.templates.agenda_text = function (start_date, end_date, event) {
    var text = '<span>';
    var assignee = event.type === "allocation" ? [event.user_id] : event.user_ids;
    assignee.forEach(function (assignee_id) {
      var assignee = main.assigneeData.assigneeMap[assignee_id];
      if (!assignee || !assignee.avatar_url) return;
      text += '<img class="gravatar easy-calendar__avatar easy-calendar__avatar__agenda" src="' + assignee.avatar_url + '" title="' + assignee.name + '">';
    });
    text += '</span>';
    return text + '<span>&nbsp' + event.text + '</span>';
  };
  scheduler.templates.agenda_time = function (start, end, ev) {
    if (ev._timed) {
      return this.event_date(start) + " &ndash; " + this.event_date(end);
    } else {
      return this.event_date(start) + "&nbsp" + scheduler.templates.short_day_date(start) + " &ndash; " + scheduler.templates.short_day_date(end);
    }
  };
  var primaryUserFilter = function (id, event) {
    if (event.user_ids) {
      return event.user_ids.indexOf(main.assigneeData.primaryId) > -1;
    }
    return event.user_id === main.assigneeData.primaryId;
  };
  var activeUserFilter = function (id, event) {
    if (event.user_ids) {
      if (event.user_ids.indexOf(main.assigneeData.primaryId) > -1) return true;
      return main.assigneeData.selectedAssignees.some(function (assignee) {
        return event.user_ids.indexOf(assignee.id) > -1;
      });
    }
    if (event._created) return true;
    return main.assigneeData.selectedAssignees.some(function (assignee) {
      return assignee.id === event.user_id;
    });
  };
  scheduler.filter_day = activeUserFilter;
  scheduler.filter_week = activeUserFilter;
  scheduler.filter_month = activeUserFilter;
  scheduler.filter_year = primaryUserFilter;
  scheduler.filter_agenda = activeUserFilter;

  scheduler.attachEvent("onEventCreated", function (id/*, mouseEvent*/) {
    var event = scheduler.getEvent(id);
    event._created = true;
  });

  scheduler.attachEvent("onContextMenu", function (eventId, mouseEvent) {
    if (!eventId) return;
    mouseEvent.preventDefault();
    var event = scheduler.getEvent(eventId);
    if (!event || event.readonly) return;
    scheduler.showLightbox(eventId);
  });
  /**
   * @param {Date} date
   * @return {boolean}
   */
  scheduler.isWorkingDay = function (date) {
    var user = main.assigneeData.getPrimaryUser();
    if (!user) return date.getDay() !== 0 && date.getDay() !== 6;
    return user.working_days.indexOf(date.getDay()) > -1;
  };
  if (main.settings.ignoreWeekends) {
    var ignoreWeekend = function (date) {
      return !scheduler.isWorkingDay(date);
    };
    scheduler.ignore_week = ignoreWeekend;
    scheduler.ignore_month = ignoreWeekend;
    scheduler.ignore_year = ignoreWeekend;
  }

  scheduler.attachEvent("onBeforeEventDelete", function (id, event) {
    if (!event) return false;
    if (!event.type) return true;
    if (event._isGenericMeeting) {
      if (event.editable) return true;
    } else return true;
    main.utils.showError(main.settings.labels.errorPermissionDeleteMissing, 2000);
    return false;
  });

  var $calendarContainer = main.$container.find(".dhx_cal_container");
  scheduler.init($calendarContainer[0], null, scheduler.config.default_zoom);
  // scheduler.load("/plugin_assets/easy_scheduler/data/events.json","json");

  scheduler.fill_agenda_tab = function () {
    //get current date
    var date = scheduler._date;
    var tabDateFormatter = scheduler.date.date_to_str(scheduler.config.agenda_long_date);
    //select events for which data need to be printed
    var tabDate;
    var events = scheduler.get_visible_events();
    events.sort(function (a, b) { return a.start_date > b.start_date ? 1 : -1;});

    var tableAttr = scheduler._waiAria.agendaDataAttrString();
    var agendaEventAttrString;
    //generate html for the view
    var html = "<div class='dhx_agenda_area' " + tableAttr + ">";
    for (var i = 0; i < events.length; i++) {
      var ev = events[i];
      if (!scheduler.renderableEvent(ev)) continue;
      var bg_color = (ev.color ? ("background:" + ev.color + ";") : "");
      var color = (ev.textColor ? ("color:" + ev.textColor + ";") : "");
      var ev_class = scheduler.templates.event_class(ev.start_date, ev.end_date, ev);

      agendaEventAttrString = scheduler._waiAria.agendaEventAttrString(ev);

      var agendaDetailsButtonAttr = scheduler._waiAria.agendaDetailsBtnString();

      if (tabDate !== tabDateFormatter(ev.start_date)) {
        tabDate = tabDateFormatter(ev.start_date);

        html += "<div class='dhx_agenda_line easy-calendar__date-separator'>";
        html += "<div class='dhx_agenda_event_time'>" + tabDate + "</div></div>";
      }

      html += "<div " + agendaEventAttrString + " class='dhx_agenda_line" + (ev_class ? ' ' + ev_class : '') + "' event_id='" + ev.id + "' style='" + color + "" + bg_color + "" + (ev._text_style || "") + "'><div class='dhx_agenda_event_time'>" + scheduler.templates.agenda_time(ev.start_date, ev.end_date, ev) + "</div>";
      html += "<div " + agendaDetailsButtonAttr + " class='dhx_event_icon icon_details'>&nbsp</div>";
      html += "<span>" + scheduler.templates.agenda_text(ev.start_date, ev.end_date, ev) + "</span></div>";
    }
    html += "<div class='dhx_v_border'></div></div>";

    //render html
    scheduler._els["dhx_cal_data"][0].innerHTML = html;
    scheduler._els["dhx_cal_data"][0].childNodes[0].scrollTop = scheduler._agendaScrollTop || 0;

    // setting up dhx_v_border size
    var agenda_area = scheduler._els["dhx_cal_data"][0].childNodes[0];
    var v_border = agenda_area.childNodes[agenda_area.childNodes.length - 1];
    v_border.style.height = (agenda_area.offsetHeight < scheduler._els["dhx_cal_data"][0].offsetHeight) ? "100%" : (agenda_area.offsetHeight + "px");

    var t = scheduler._els["dhx_cal_data"][0].firstChild.childNodes;
    scheduler._els["dhx_cal_date"][0].innerHTML = scheduler.templates.agenda_date(scheduler._min_date, scheduler._max_date, scheduler._mode);

    scheduler._rendered = [];
    for (var i = 0; i < t.length - 1; i++)
      scheduler._rendered[i] = t[i];

  };
};
