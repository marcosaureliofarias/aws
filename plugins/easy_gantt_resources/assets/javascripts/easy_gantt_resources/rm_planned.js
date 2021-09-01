window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {hidePlanned: "planned"});
ysy.pro.resource.planned = ysy.pro.resource.planned || {};
EasyGem.extend(ysy.pro.resource.planned, {
  loaded: false,
  patch: function () {
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    const sett = ysy.settings.resource.buttons;
    sett.hidePlanned = JSON.parse(ysy.data.storage.getPersistentData('hidePlanned'));
    ysy.proManager.register("extendGanttTask", this.extendGanttTask);
    ysy.pro.toolPanel.registerButton(
        {
          id: "hide_planned_tasks",
          _name: "HidePlannedButton",
          bind: function () {
            this.model = ysy.settings.resource;
            this.buttons = this.model.buttons;
            this.model.setSilent("hidePlanned",this.buttons.hidePlanned);
            ysy.pro.resource.loader.register(function () {
              this.loaded = false;
              if (this.buttons.hidePlanned) {
                ysy.pro.resource.planned.loadPlannedSums();
              }
            }, this);
          },
          func: function () {
            this.buttons.hidePlanned = !this.buttons.hidePlanned;
            this.model.setSilent("hidePlanned",this.buttons.hidePlanned);
            ysy.data.storage.savePersistentData('hidePlanned', this.buttons.hidePlanned);
            if (this.buttons.hidePlanned) {
              if (ysy.settings.reservationEnabled){
                this.buttons.onlyReservation = false;
                this.buttons.newReservation = true;
                this.buttons.onlyTask = false;
                ysy.settings.resource.setSilent("reservations", this.buttons.newReservation);
                ysy.data.storage.savePersistentData('newReservation', this.buttons.newReservation);
                ysy.data.storage.savePersistentData('onlyTask', this.buttons.onlyTask);
                ysy.pro.resource.reservations.loadReservationSums('allData');
              }
              ysy.pro.resource.planned.countPresentPlannedSums();
              ysy.pro.resource.planned.loadIfNotLoaded();
            }
            this.model._fireChanges(this, "click")
          },
          isOn: function () {
            return !this.buttons.hidePlanned;
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );
  },
  extendGanttTask: function (issue, gantt_issue) {
    if (ysy.settings.resource.buttons.hidePlanned && issue.is_planned) {
      gantt_issue.$ignore = true;
    }
  },
  loadPlannedSums: function (assigneeId) {
    var userIds = [];
    if (assigneeId === undefined) {
      var users = ysy.data.assignees.getArray();
      for (var i = 0; i < users.length; i++) {
        userIds.push(users[i].id);
        delete users[i].plannedSums;
      }
    } else {
      userIds.push(assigneeId);
      var user = ysy.data.assignees.getByID(assigneeId);
      if (user) delete user.plannedSums;
    }
    var bannedIssueIds = [];
    var issues = ysy.data.issues.getArray();
    for (i = 0; i < issues.length; i++) {
      var issue = issues[i];
      if (!issue.is_planned) continue;
      if (assigneeId && assigneeId !== issues[i].assigned_to_id) continue;
      bannedIssueIds.push(issues[i].id);
    }
    var start_date = ysy.data.limits.start_date;
    var end_date = ysy.data.limits.end_date;
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.usersSumsUrl
            .replace(":projectID", ysy.settings.projectID)
            .replace(":variant", "planned")
            .replace(":start", start_date.format("YYYY-MM-DD"))
            .replace(":end", end_date.format("YYYY-MM-DD")),
        {
          user_ids: userIds,
          except_issue_ids: bannedIssueIds
        },
        $.proxy(this._handlePlannedSumsData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
          //ysy.pro.resource.loader.loading = false;
        }
    );
  },
  _handlePlannedSumsData: function (data) {
    this.loaded = true;
    var json = data.easy_resource_data;
    this._loadPlannedSums(json.users);
    this.countPresentPlannedSums();

    ysy.settings.resource._fireChanges(this, "plannedSums loaded");
  },
  _loadPlannedSums: function (json) {
    if (!json) return;
    var assignees = ysy.data.assignees;
    for (var i = 0; i < json.length; i++) {
      var user = json[i];
      var assignee = assignees.getByID(user.id);
      if (!assignee) continue;
      assignee.plannedSums = user.resources_sums;
    }
  },
  loadIfNotLoaded: function () {
    if (this.loaded) return;
    this.loadPlannedSums();
  },
  subtractPlanned: function (allocations, assignee) {
    var planned = assignee.plannedSums;
    var presentPlanned = assignee.presentPlannedSums;
    if (planned) {
      for (var date in planned) {
        if (!planned.hasOwnProperty(date)) continue;
        if (allocations[date] === undefined) {
          allocations[date] = 0;
        }
        allocations[date] -= planned[date];
      }
    }
    if (presentPlanned) {
      for (date in presentPlanned) {
        if (!presentPlanned.hasOwnProperty(date)) continue;
        if (allocations[date] === undefined) {
          allocations[date] = 0;
        }
        allocations[date] -= presentPlanned[date];
      }
    }
  },
  assigneeAfterLoad: function (userId) {
    this.loaded = false;
    if (!ysy.settings.resource.buttons.hidePlanned) return;
    this.loadPlannedSums(userId);
  },
  countPresentPlannedSums: function () {
    var assignees = ysy.data.assignees;
    var assigneesArray = ysy.data.assignees.getArray();
    var issues = ysy.data.issues.getArray();

    for (var i = 0; i < assigneesArray.length; i++) {
      assigneesArray[i].presentPlannedSums = {};
    }

    for (i = 0; i < issues.length; i++) {
      var issue = issues[i];
      if (!issue.is_planned) continue;
      var assignee = assignees.getByID(issue.assigned_to_id || "unassigned");
      var allocations = issue.getAllocations();
      if (!allocations) continue;
      var dates = Object.getOwnPropertyNames(allocations.allocations);
      for (var j = 0; j < dates.length; j++) {
        var date = dates[j];
        if (assignee.presentPlannedSums[date] === undefined) {
          assignee.presentPlannedSums[date] = 0;
        }
        assignee.presentPlannedSums[date] += allocations.allocations[date];
      }
    }
  }
});
