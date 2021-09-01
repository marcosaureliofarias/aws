window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.loader = ysy.pro.resource.loader || {};
EasyGem.extend(ysy.pro.resource.loader, {
  _name: "Resource Loader",
  loaded: false,
  inited: false,
  _onChange: [],
  load: function () {
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    this.buttons = ysy.settings.resource.buttons;
    if (this.loading) return;
    this.loaded = false;
    this.loading = true;
    ysy.log.debug("load()", "load");
    var issues = ysy.data.issues.getArray();
    var projects = ysy.data.projects.getArray();
    var start_date;
    var end_date;
    var issueIds = [];
    var projectIds = [];
    for (var i = 0; i < issues.length; i++) {
      var issue = issues[i];
      if (!issue._start_date || !issue._end_date) {
        ysy.log.warning("issue " + issue.name + " have missing" + (issue._start_date ? "" : " _start_date") + (issue._end_date ? "" : " _end_date"));
        continue;
      }
      if (issue.id < 1e12) {
        issueIds.push(issue.id);
      }
      if (!start_date || issue._start_date.isBefore(start_date)) {
        start_date = issue._start_date;
      }
      if (!end_date || issue._end_date.isAfter(end_date)) {
        end_date = issue._end_date;
      }
    }
    if (projects.length !== 0) {
      for (i = 0; i < projects.length; i++) {
        var project = projects[i];
        if (!project.needLoad) {
          projectIds.push(project.id);
        }
        if (!project.start_date || !project.end_date) continue;
        if (!start_date || project.start_date.isBefore(start_date)) {
          start_date = project.start_date;
        }
        if (!end_date || project.end_date.isAfter(end_date)) {
          end_date = project.end_date;
        }
      }
    }
    start_date = moment(start_date).subtract(1, "months");
    end_date = moment(end_date).add(1, "months");
    const variant = this.buttons.onlyTask && "onlyTask" || this.buttons.onlyReservation && "onlyReservation" || "allData";
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.projectResourceUrl
            .replace(":projectID", ysy.settings.projectID)
            .replace(":start", start_date.format("YYYY-MM-DD"))
            .replace(":end", end_date.format("YYYY-MM-DD")),
        {
          variant: variant,
          issue_ids: issueIds,
          project_ids: projectIds
        },
        $.proxy(this._handleResourceData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
          ysy.pro.resource.loader.loading = false;
        }
    );
  },
  _handleResourceData: function (data) {
    if (!data.easy_resource_data) return;
    var json = data.easy_resource_data;
    ysy.log.debug("_handleResourceData()", "load");
    //  -- LIMITS --
    this._loadResourceLimits(json);
    //  -- ASSIGNEES --
    ysy.data.assignees.clear();
    //  -- ALLOCATIONS --
    ysy.data.allocations.clear();
    if (ysy.data.resourceReservations) {
      ysy.data.resourceReservations.clear();
    }
    // ARRAY FILLING
    //  -- ASSIGNEES --
    this._loadAssignees(json.users);
    //  -- PROJECT --
    this._enhanceProjects(json.projects);
    //  -- ISSUES --
    this._loadRMIssues(json.issues);
    //  -- RELATIONS --
    ysy.data.relations._fireChanges(this, "resources loaded");
    if (this._loadReservations) {
      // -- RESERVATIONS
      this._loadReservations(json.reservations);
      // ysy.data.issues
    }

    this._removeProjectAllocationsFromSums();

    ysy.log.debug("resource data loaded", "load");
    ysy.log.message("resource JSON loaded");
    this._fireChanges();
    this.loading = false;
    this.loaded = true;
  },
  loadAssignee: function (userID) {
    var start_date = ysy.data.limits.start_date;
    var end_date = ysy.data.limits.end_date;
    ysy.gateway.polymorficGetJSON(
        ysy.settings.paths.globalResourceUrl,
        {
          assigned_to_id: userID,
          resources_start_date: start_date ? moment(start_date).format("YYYY-MM-DD") : undefined,
          resources_end_date: end_date ? moment(end_date).format("YYYY-MM-DD") : undefined,
        },
        $.proxy(this._handleAssigneeData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    )
  },
  _handleAssigneeData: function (data) {
    if (!data.easy_resource_data) return;
    var json = data.easy_resource_data;
    var userId = "unassigned";
    if (json.issues.length) {
      userId = json.issues[0].assigned_to_id;
    } else if(json.reservations && json.reservations.length) {
      userId = json.reservations[0].assigned_to_id;
    }
    if (this._loadRMProjects) {
      this._loadRMProjects(json.projects, userId);
    }
    if (this._loadReservations) {
      this._loadReservations(json.reservations);
    }
    ysy.data.loader._loadIssues(json.issues, userId);
    ysy.data.loader._loadMilestones(json.versions);
    var createdAllocations = this._loadRMIssues(json.issues);
    this._removeAllocationsFromSums(createdAllocations);
    if (ysy.pro.resource.planned) {
      ysy.pro.resource.planned.assigneeAfterLoad(userId);
    }
    ysy.log.debug("minor data loaded", "load");
    //this._fireChanges();
  },
  register: function (func, ctx) {
    this._onChange.push({func: func, ctx: ctx});
  },
  _fireChanges: function (who, reason) {
    for (var i = 0; i < this._onChange.length; i++) {
      var ctx = this._onChange[i].ctx;
      if (!ctx || ctx.deleted) {
        this._onChange.splice(i, 1);
        continue;
      }
      ysy.log.log("-- changes to " + ctx.name + " widget");
      $.proxy(this._onChange[i].func, ctx)();
    }
  },
  _loadAssignees: function (json) {
    var assignees = ysy.data.assignees;
    var assignee = new ysy.data.Assignee();
    if (!ysy.settings.withoutUnassigned) {
      assignee.init({
        id: "unassigned",
        name: ysy.settings.labels.titles.unassigned,
        _unassigned: true
      }, assignees);
      assignees.pushSilent(assignee);
    }
    for (var i = 0; i < json.length; i++) {
      var jsonUser = json[i];
      ysy.main._resourcesStringToFloat(jsonUser.resources_sums);
      assignee = new ysy.data.Assignee();
      assignee.init(jsonUser, assignees);
      assignees.pushSilent(assignee);
    }
    assignees._fireChanges(this, "load");
  },
  _loadRMIssues: function (json) {
    if (!json) return;
    var issues = ysy.data.issues;
    var allocations = ysy.data.allocations;
    var createdAllocations = [];
    for (var i = 0; i < json.length; i++) {
      var jsonIssue = json[i];
      var issue = issues.getByID(jsonIssue.id);
      if (!issue) continue;
      this._enhanceIssue(issue, jsonIssue);
      if (jsonIssue.closed) continue;
      jsonIssue.issue = issue;
      var allocation = new ysy.data.IssueAllocations();
      ysy.main._resourcesObjectToFloat(jsonIssue.resources);
      allocation.init(jsonIssue, allocations);
      // allocation.register(function(alloc){return function(){this._fireChanges(alloc,"issueAllocation changed")}}(allocation),issue);
      allocations.pushSilent(allocation);
      createdAllocations.push(allocation);
      if (!issue.start_date || !issue.end_date) {
        var dates = allocation.getLimitResourceDates();
      }
      if (dates) {
        if (!issue.start_date && dates.start_date.isBefore(issue._start_date)) {
          issue._start_date = dates.start_date;
        }
        if (!issue.end_date && dates.end_date.isAfter(issue._end_date)) {
          issue._end_date = dates.end_date;
        }
      }
      issue._fireChanges(this, "load spent");
    }
    allocations._fireChanges(this, "load");
    return createdAllocations;
  },
  _enhanceIssue: function (issue, jsonIssue) {
    issue.spent = jsonIssue.spent;
    if (jsonIssue.permissions) {
      $.extend(issue.permissions, jsonIssue.permissions);
    }
  },
  _enhanceProjects: function (json) {
    if (!json) return;
    var projects = ysy.data.projects;
    for (var i = 0; i < json.length; i++) {
      var project = projects.getByID(json[i].id);
      if (!project) continue;
      project.setSilent(json[i]);
      project._fireChanges(this, "project RM enhance");
    }
  },
  _removeProjectAllocationsFromSums: function () {
    var allocations = ysy.data.allocations.getArray();
    this._removeAllocationsFromSums(allocations);
  },
  _removeAllocationsFromSums: function (allocations) {
    //var allocations = ysy.data.allocations.getArray();
    for (var i = 0; i < allocations.length; i++) {
      var issueAllocation = allocations[i];
      var assignee = issueAllocation.getAssignee();
      if (!assignee) continue;
      var groups = this._getGroupsOfUser(assignee);
      if (groups) {
        var allocs = issueAllocation.allocPack.allocations;
        for (var date in allocs) {
          if (!allocs.hasOwnProperty(date)) continue;
          if (!assignee.resources_sums[date]) continue;
          var hours = allocs[date];
          if (hours <= 0) continue;
          assignee.resources_sums[date] -= hours;
          for (var j = 0; j < groups.length; j++) {
            var group = groups[j];
            group.resources_sums[date] -= hours;
          }
        }
      } else {
        allocs = issueAllocation.allocPack.allocations;
        for (date in allocs) {
          if (!allocs.hasOwnProperty(date)) continue;
          if (!assignee.resources_sums[date]) continue;
          if (allocs[date] <= 0) continue;
          assignee.resources_sums[date] -= allocs[date];
        }
      }
    }
  },
  _getGroupsOfUser: function (user) {
    var groupIds = user.group_ids;
    if (!groupIds) return null;
    var groups = [];
    for (var i = 0; i < groupIds.length; i++) {
      var group = ysy.data.assignees.getByID(groupIds[i]);
      if (group) {
        groups.push(group);
      }
    }
    return groups;
  },
  _loadResourceLimits: function (json) {
    var limit_end_date = moment(json.resources_end_date, "YYYY-MM-DD");
    limit_end_date._isEndDate = true;
    var changed = ysy.data.limits.setSilent({
      start_date: moment(json.resources_start_date, "YYYY-MM-DD"),
      end_date: limit_end_date
    });
    if (changed) {
      ysy.data.limits._fireChanges(this, "resourceLimits")
    }
  }
});
