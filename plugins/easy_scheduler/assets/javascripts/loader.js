(function () {
  /**
   * @constructor
   * @param {CalendarMain} main
   * @property {CalendarMain} main
   * @property {Object} scheduler
   */
  function Loader (main) {
    this.main = main;
    var self = this;
    var $query_tooltip = this.main.$container.closest('.easy-page__module').find('.query_tooltip');
    main.eventBus.register("schedulerInited", function (scheduler) {
      self.scheduler = scheduler;
    });

    this.main.$container.siblings(".easy-calendar__tagged_queries").on("click", ".tagged_query", function () {
      var $this = $(this);
      var queryName = $this.data("query-name");
      var queryId = $this.data("query-id");
      var issueDataPath = $this.data("scheduler-data-path");
      var calendarUsers = $this.data("selectedPrincipalIds");
      var entityType = $this.data("entity-type");

      $this.siblings().removeClass("active");
      $this.addClass("active");

      self.main.tasksView.setTitleValues(queryName, $this.data("entityCount"));
      $query_tooltip.toggleClass("hidden", !$this.data('editable'));

      self.main.settings.paths.tasksDataPath = issueDataPath;
      self.main.taskData.taskType = entityType;
      self.main.taskData.clear(true);

      main.scheduler.saveToStorage("filter-data-path", issueDataPath);
      main.scheduler.saveToStorage("filter-data-query", JSON.stringify({
        id: queryId,
        name: queryName,
        entity_type: entityType
      }));
      main.settings.paths.queryID = queryId;

      main.assigneeData.resetSelected();

      self.fetchEvents(calendarUsers, true);
      self.fetchTasks();
    });

    $query_tooltip.on("click", "a", function () {
      const $activeQuery = main.$container.siblings(".easy-calendar__tagged_queries").find('.active');
      const queryId = $activeQuery.data('queryId');
      if (!queryId) return;
      let url;
      if (this.dataset.action === 'edit') {
        url = main.settings.paths.queries['edit'].replace("__queryId__", queryId);
        url += '?back_url=' + window.location.pathname + window.location.search;
        window.location = url;
      } else if (this.dataset.action === 'destroy') {
        url = main.settings.paths.queries['destroy'].replace("__queryId__", queryId);
        url += '.json';
        const target = this;
        $.ajax(url, { type: 'DELETE' }).done(function () {
          showFlashMessage('notice', main.scheduler.locale.labels.successful_delete, 1500);
          $activeQuery.remove();
          $(target).closest('.query_tooltip').addClass("hidden");
        }).fail(function (response) {
          if (response.responseJSON) showFlashMessage('error', response.responseJSON.errors.join('<br />'), 1500);
        })
      } else {
        url = main.settings.paths.queries['load_users_for_query'].replace("__queryId__", queryId);
        url += '.js';
        $.ajax(url, { data: { back_url: window.location.pathname + window.location.search } })
      }
    })
  }

  /**
   * @methodOf Loader
   * @param {int} [offset]
   */
  Loader.prototype.fetchTasks = function (offset) {
    var url = this.main.settings.paths.tasksDataPath;
    this.main.eventBus.fireEvent("tasksLoading");
    var self = this;
    $.ajax({ url: url, dataType: "JSON", data: { offset: offset } })
      .done(function (data) {
        self._handleTasks(data, offset)
      });
  };
  Loader.prototype._handleTasks = function (data, offset) {
    if (!offset) {
      // clear
      this.main.taskData.clear(false);
    }
    this.main.taskData.load(data);
    this.main.assigneeData.load(data.users);
    this.main.eventBus.fireEvent("tasksLoaded");
  };
  /**
   * @methodOf Loader
   * @param {Array.<int>} userIds
   * @param {boolean} [selectUsers]
   */
  Loader.prototype.fetchEvents = function (userIds, selectUsers) {
    this.main.eventBus.fireEvent("eventsLoading");
    var self = this;
    $.ajax({
      url: this.main.settings.paths.user_allocation_data_path,
      dataType: "JSON",
      data: { user_ids: userIds }
    })
      .done(function (data) {
        self._handleEvents(data, selectUsers);
      });
  };

  Loader.prototype.fetchHolidays = function (start, end) {
    if (!this.main.settings.easyPlugins.easy_calendar) return;
    var self = this;
    $.ajax({
      url: this.main.settings.paths.holidayFeed,
      method: "GET",
      data: {
        start: start / 1000,
        end: end / 1000,
      }
    }).done(function (data) {
      self._handleGlobalEvents(data);
    });
  };

  Loader.prototype._handleEvents = function (data, selectUsers) {
    // clear
    // this.scheduler.clearAll();
    this.main.taskData.loadHidden(data);
    this.main.assigneeData.load(data.users, selectUsers);
    this._loadEvents(data);
    this.main.eventBus.fireEvent("eventsLoaded");
  };
  Loader.prototype._loadEvents = function (data) {
    var startTime = this.scheduler.config.start_time;
    var allocations = data.allocations;
    if (!allocations) {
      allocations = [];
    }
    for (var i = 0; i < allocations.length; i++) {
      var alloc = allocations[i];
      var startDate = alloc.full_date ? moment(alloc.full_date) : moment(alloc.date).add(startTime);
      alloc.start_date = this.main.utils.parseDate(startDate.format());
      alloc.end_date = this.main.utils.parseDate(moment(startDate).add(alloc.hours, "hours").format());
      delete alloc.date;
      delete alloc.start;
      var task = this.main.taskData.getTaskById(alloc.issue_id, 'issues');
      if (task) {
        alloc.text = task.subject;
        alloc.readonly = !task.permissions.editable;
        alloc.deletable = task.permissions.editable;
      } else {
        alloc.text = this.main.settings.labels.entityTitle.allocation;
        alloc.readonly = true;
      }
      alloc.type = "allocation";
    }
    this.scheduler.parse(allocations, "json");
  };
  /**
   * @methodOf Loader
   * @param {int} start
   * @param {int} end
   * @param {int} userId
   */
  Loader.prototype.fetchMeetings = function (start, end, userId) {
    if (!this.main.settings.easyPlugins.easy_calendar) return;
    var self = this;
    $.ajax({
      url: this.main.settings.paths.meetingFeed,
      method: "GET",
      data: {
        user_id: userId,
        start: start / 1000,
        end: end / 1000,
        with_easy_entity_activities: true,
        with_ical: true,
        ical_ids: self.main.settings._settings.icalendars
      }
    }).done(function (data) {
      self._handleMeetings(data, userId);
    });
  };

  Loader.prototype._handleMeetings = function (array, userId) {
    var meetings = [], other;
    for (var i = 0; i < array.length; i++) {
      var source = array[i];
      if (other = this.scheduler.getEvent(source.id)) {
        if (other.user_ids.indexOf(userId) === -1) {
          other.user_ids.push(userId);
          this.main.eventBus.fireEvent("eventChanged", other);
        }
      } else {
        var meeting = this.main.meetings.createMeeting(source);
        meeting.user_ids.push(userId);
        meetings.push(meeting);
      }
    }
    if (meetings.length === 0) {
      this.main.repainter.repaintCalendar(false);
    } else {
      this.scheduler.parse(meetings, "json");
    }
  };

  Loader.prototype._handleGlobalEvents = function (array) {
    var events = [];
    for (var i = 0; i < array.length; i++) {
      var source = array[i];
      if (!this.scheduler.getEvent(source.id)) {
        var event = this.main.meetings.createMeeting(source);
        event._isGlobalEvent = true;
        event.editable = false;
        event.readonly = true;
        events.push(event);
      }
    }
    if (events.length > 0) this.scheduler.parse(events, "json");
  };

  Loader.prototype.reload = function () {
    this.scheduler.clearAll();
    this.main.meetings.clearAll();
    var userIds = this.main.assigneeData.getActiveUserIds();
    this.fetchEvents(userIds);
    this.main.taskData.clear(true);
    this.fetchTasks();
  };

  EasyCalendar.Loader = Loader;
})();
