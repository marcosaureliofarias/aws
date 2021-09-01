(function () {
  /**
   *
   * @param {CalendarMain} main
   * @property {CalendarMain} main
   * @property {Object.<String,UserMeetings>} userMeetingsMap
   * @constructor
   */
  function Meetings(main) {
    this.main = main;
    this.userMeetingsMap = {};
    var self = this;
    main.eventBus.register("schedulerInited", function (scheduler) {
      scheduler.templates.classBuilder("event_class", function (start, end, event) {
        if (event._isGenericMeeting) {
          switch (event.type) {
            case "meeting":
              var css = "easy-calendar__meeting";
              break;
            case "easy_entity_activity":
              css = "easy-calendar__entity-activity";
              break;
            case "easy_attendance":
              css = "easy-calendar__attendance";
              break;
            case "ical_event":
              css = "easy-calendar__ical-event";
              break;
            case "easy_holiday_event":
              css = "easy-calendar__holiday-event";
              break;
            default:
              css = "easy-calendar__generic-meeting";
              break;
          }
          if (event.user_ids.indexOf(main.assigneeData.primaryId) > -1) {
            css += " easy-calendar__event--primary";
          }
          return css;
        }
      });
    });
    if (!main.settings.easyPlugins.easy_calendar) return;
    var changeEvents = ["onViewChange", "eventsLoaded", "assigneeChanged"];
    for (var i = 0; i < changeEvents.length; i++) {
      main.eventBus.register(changeEvents[i], function () {
        self.loadMissing();
      });
    }
    main.eventBus.register("eventChanged", function (event) {
      if (!event._isGenericMeeting) return;
      main.eventBus.fireEvent("genericMeetingChanged", event);
    });
  }

  Meetings.prototype.clearAll = function () {
    this.userMeetingsMap = {};
  };

  /**
   * @memberOf Meetings
   */
  Meetings.prototype.loadMissing = function () {
    var self = this;
    var userIds = this.main.assigneeData.getActiveUserIds();
    var start = this.main.scheduler._min_date.valueOf();
    var end = this.main.scheduler._max_date.valueOf();
    userIds.forEach(function (userId) {
      var user = self.main.assigneeData.getAssigneeById(userId);
      if (user && user._temporary) return;
      var userMeetings = self.userMeetingsMap[userId];
      if (!userMeetings) {
        self.userMeetingsMap[userId] = userMeetings = new UserMeetings(self.main, userId);
      }
      userMeetings.loadMissing(start, end);
    });
    this.main.loader.fetchHolidays(start, end);
  };
  /**
   * @memberOf Meetings
   * @param source
   */
  Meetings.prototype.createMeeting = function (source) {
    var idSplit = source.id.split("-");
    var type = source.eventType.match(/meeting/) ? "meeting" : source.eventType;
    if (source.editable === undefined) source.editable = true;
    var start_date = this.main.utils.parseDate((source.start || source.start_time));
    source.user_ids = source.user_ids || [];
    var data = {
      id: source.id,
      realId: parseInt(idSplit[idSplit.length - 1]),
      start_date: start_date,
      end_date: this.main.utils.parseDate((source.end || source.end_time)),
      allDay: source.allDay || false,
      _isMeeting: type === "meeting",
      _isGenericMeeting: true,
      _isEntityActivity: type === "easy_entity_activity",
      _isIcalEvent: type === "ical_event",
      _isEasyAttendance: type === 'easy_attendance',
      _isRecurring: source.easy_is_repeating || false,
      _isPrivate: source.isPrivate || false,
      text: source.title || source.name,
      type: type,
      editable: source.editable,
      deletable: source.editable,
      url: source.url,
      location: source.location,
      readonly: !source.editable,
      user_ids: source.user_ids,
      confirmed: source.confirmed
    };

    if (type === 'easy_attendance') {
      data.approvable = source.needApprove || false;
      data.easyAttendanceActivityId = source.easyAttendanceActivityId;
    }
    if (type === "easy_entity_activity") {
      data.entityId = source.entityId;
      data.entityType = source.entityType;
    }

    if (type === "ical_event") {
      data.icalName = source.icalName;
      data.icalId = source.icalId;
      data.syncDate = source.syncDate ? new Date(source.syncDate) : null;
      data.eventId = source.eventId || null;
    }

    data.isOneDay = this.main.scheduler.isOneDayEvent(data);
    if (source.allDay && data.isOneDay) {
      start_date.setHours(0,0,0,0);
      data.start_date = start_date;

      var clone_start_date = new Date(source.start || source.start_time);
      clone_start_date.setDate(start_date.getDate() + 1);
      clone_start_date.setHours(0,0,0,0);
      data.end_date = clone_start_date;
    }

    return data
  };
  /**
   * @memberOf Meetings
   * @param event
   * @return {boolean}
   */
  Meetings.prototype.canDelete = function (event) {
    if (!event.realId) return true;
    return event.deletable;
  };
  /**
   * @memberOf Meetings
   * @param event
   * @return {boolean}
   */
  Meetings.prototype.canEdit = function (event) {
    if (!event.realId) return true;
    return event.editable;
  };

  window.EasyCalendar.Meetings = Meetings;


  //####################################################################################################################
  /**
   *
   * @param {CalendarMain} main
   * @param {int} userId
   * @property {CalendarMain} main
   * @property {Assignee} user
   * @constructor
   */
  function UserMeetings(main, userId) {
    this.main = main;
    this.user = main.assigneeData.getAssigneeById(userId);
    this.start = Infinity;
    this.end = -Infinity;
  }

  UserMeetings.prototype.loadMissing = function (start, end) {
    if (start >= this.start && end <= this.end) return;
    if (start < this.start && end > this.end) {
      this.start = start;
      this.end = end;
    } else if (start >= this.start && end > this.end) {
      start = this.end;
      this.end = end;
    } else if (start < this.start && end <= this.end) {
      end = this.start;
      this.start = start;
    }
    // console.log("Start: " + moment(start) + " End: " + moment(end) + " User" + this.user.name);
    this.main.loader.fetchMeetings(start, end, this.user.id);
  }

})();
