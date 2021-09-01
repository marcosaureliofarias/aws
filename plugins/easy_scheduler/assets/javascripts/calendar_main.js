window.EasyCalendar = window.EasyCalendar || {};
(function () {
  /**
   * @constructor CalendarMain
   * @property {Utils} utils
   * @property {EventBus} eventBus
   * @property {Loader} loader
   * @property {TaskData} taskData
   * @property {AssigneeData} assigneeData
   * @property {Saver} saver
   * @property {Repainter} repainter
   * @property {TaskDataView} tasksView
   * @property {AssigneesView} assigneesView
   * @property {ExternalDnD} externalDnD
   * @property {LogTime} logTime
   * @property {Meetings} meetings
   * @property {Logger} log
   * @property {{isManager:boolean,currentUserId:int,ignoreWeekends:boolean,
   *   selectedUserIds:Array.<int>,
   *   paths:{rootPath:string,issue_path:string,issues_path:string,timelogCreatePath:string,
   *     user_allocation_data_path:string,tasksDataPath:string,taskPath:string,
   *     modals:{newEntityPath:string,allocationModalPath:string,salesActivityModalPath:string},
   *     meeting_path:string,save_allocation_path:string,easy_attendance_path:string,easy_entity_activity_path:string,
   *     meetingModals:string},
   *   labels:{
   *     everythingSaved:string,titleRemainingTime:string,errorPermissionDeleteMissing:string,
   *     entityTitle:{meeting:string,allocation:string,attendance:string,sales_activity:string}},
   *   easyPlugins:{easy_calendar:boolean,easy_attendances:boolean,easy_entity_activities:boolean},
   *   permissions:{},
   *   templates:{
   *     allocationText:string,meetingText:string,taskSaveLog:string,salesActivityText:string,attendanceText:string
   *   }}} settings
   */
  function CalendarMain(settings) {
    this.settings = settings;
    this.scheduler = null;
    this.$container = $("#" + settings.container);
    this.$container.data("calendar", this);
    if (this.moduleInit()) return;
    this.init();
  }

  CalendarMain.prototype.init = function () {
    this.utils = new EasyCalendar.Utils(this);
    this.eventBus = new EasyCalendar.EventBus(this);
    this.loader = new EasyCalendar.Loader(this);
    this.taskData = new EasyCalendar.TaskData(this);
    this.assigneeData = new EasyCalendar.AssigneeData(this);
    this.saver = new EasyCalendar.Saver(this);
    this.repainter = new EasyCalendar.Repainter(this);
    this.assigneesView = new EasyCalendar.AssigneesView(this);
    this.tasksView = new EasyCalendar.TaskDataView(this);
    this.externalDnD = new EasyCalendar.ExternalDnD(this);
    this.log = new EasyCalendar.Logger(this);
    this.meetings = new EasyCalendar.Meetings(this);
    this.logTime = new EasyCalendar.LogTime(this);
    this.taskHandler = new EasyCalendar.TaskHandler(this);
    this.taskModal = new EasyCalendar.TaskModal(this);
    this.schedulerModal = new EasyCalendar.SchedulerModal(this);
    if (EasyCalendar.CalendarTests) {
      this.tests = new EasyCalendar.CalendarTests(this);
    }

    this.utils.showLastSaveAtMsg(this.settings.lastSaveAtMsg);
    this.eventBus.fireEvent("classesConstructed");

    EasyCalendar.manager.construct(this.settings.container, this.settings.plugins, $.proxy(this.afterScheduler, this));
  };

  CalendarMain.prototype.afterScheduler = function (instance) {
    var scheduler = this.scheduler = instance.scheduler;
    var self = this;
    var views = document.querySelectorAll(".easy-calendar__tasks-toggler input");
    this.initScheduler(scheduler, this);
    this.eventBus.fireEvent("schedulerInited", scheduler, instance);
    var selectedUserIds = [];
    if (this.settings.reloadSelectedUsers) {
      selectedUserIds = this.settings.selectedUserIds;
      selectedUserIds.push(this.assigneeData.currentId);
    } else {
      selectedUserIds = this.assigneeData.savedAssigneeIds();
    }
    this.loader.fetchEvents(selectedUserIds, true);
    this.loader.fetchTasks();
    this.repainter.start();
    this.$container.on("click", ".easy-calendar__modal-link", function () {
      var $this = $(this);
      var url = $this.data("href");
      $.get(url, function (data) {
        $("#ajax-modal").html(data);
        showModal("ajax-modal");
      });
    });

    /***
     * legenda
     */
    var availableCalendars = self.scheduler.options.availableCalendars;
    for (key in availableCalendars) {
      if (!availableCalendars.hasOwnProperty(key)) continue;
      if (!availableCalendars[key]) {
        var $target = this.$container.find("[data-legend='" + key + "']");
        $target.toggleClass("disabled", !availableCalendars[key]);
      }
    }

    this.$container.on("click", ".easy-calendar-legend__main", function (e) {
      var $target = $(e.target);
      var legend = $target.data("legend");
      if (legend === "not_legend_item") return;
      var availableCalendars = self.scheduler.options.availableCalendars;
      availableCalendars[legend] = !availableCalendars[legend];
      $target.toggleClass("disabled", !availableCalendars[legend]);
      self.scheduler.saveToStorage(legend, availableCalendars[legend]);
      self.repainter.repaintCalendar(true);
    });

    this.$container.on("click", ".easy-calendar-legend__scheduler--show_button", function () {
      var otherEntitys = self.$container.find(".easy-calendar-legend__scheduler--entity_others");
      otherEntitys.toggleClass("hidden");
    })
    /***
     * task title
     * set title from query links in heading
     */
    var data_query = scheduler.getFromStorage("filter-data-query");
    if (data_query) {
      var query = JSON.parse(data_query);
      if (query && query.id) {
        this.settings.paths.queryID = query.id;
        var $queryButton = this.$container.parent().find("[data-query-id='" + query.id + "']");
        if ($queryButton.length){
          var queryName = $queryButton.data("query-name");
          var queryCount = $queryButton.data("entity-count");
          $queryButton.addClass("active");
          this.tasksView.setTitleValues(queryName, queryCount);
        }
      }
    }
    this.afterSchedulerModuleInit();
    /***
     * toggler value
     */
    views.forEach(function (view) {
      if (view.value === self.scheduler.config.togglerValue) {
        view.checked = true;
      } else {
        view.checked = false;
      }
    })
  };
  CalendarMain.prototype.moduleInit = function () {
    var $moduleContent = this.$container.closest(".module-content");
    if (!$moduleContent.length) return false;
    if ($moduleContent.is(":visible")) return false;
    var self = this;
    $moduleContent.on("easy-module-collapse-changed", function (/*event, state*/) {
      $(this).off("easy-module-collapse-changed");
      self.init();
    });
    return true;
  };

  CalendarMain.prototype.afterSchedulerModuleInit = function () {
    var $moduleContent = this.$container.closest(".module-content");
    document.addEventListener("vueModalIssueChanged", this.taskModal.afterModalClose.bind(this));
    if (!$moduleContent.length) return false;
    var $editBtn = $moduleContent.parent().find(".module-heading-links > .icon-edit");
    var self = this;
    $moduleContent.toggleClass("w-mobile-header-toggle--active", self.scheduler.config.userIsToggled);
    $moduleContent.find(".easy-calendar__mobile-header-toggler").on("click", function (event) {
      self.scheduler.config.userIsToggled = !self.scheduler.config.userIsToggled;
      $moduleContent.toggleClass("w-mobile-header-toggle--active", self.scheduler.config.userIsToggled);
      self.scheduler.saveToStorage("userToggle", self.scheduler.config.userIsToggled);
    });
    $editBtn.on("click", function () {
      var keysToDelete = ["filter-data-path", "primary-assignee", "selected-assignees"];
      self.scheduler.saveToStorage("filter-data-query", JSON.stringify({id: "default"}));
      self.scheduler.deleteFromStorage(keysToDelete);
    });
  };
  EasyCalendar.CalendarMain = CalendarMain;
})();
