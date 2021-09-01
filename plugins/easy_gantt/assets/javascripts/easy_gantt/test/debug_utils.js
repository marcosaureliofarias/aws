ysy.testMove = function (days) {
  (function (days) {
    if (!days) days = 2;
    // var issue = ysy.data.issues.getByID(#{issue.id});
    var task = gantt._pull[11];
    var copy = dhtmlx.mixin({}, task);
    var limits = gantt.prepareMultiStop(task);
    var new_start = moment(task.start_date).add(days, 'days');
    var new_end = gantt._working_time_helper.add_worktime(new_start, task.duration, 'day', true);
    gantt.multiStop(copy, new_start, new_end, limits);
    // var old_start = task.start_date;
    copy.start_date = new_start;
    copy.end_date = new_end;
    gantt.moveDependent(copy/*, {old_start: old_start}*/);
    // task.widget.update(copy);
    task.start_date = copy.start_date;
    task.end_date = copy.end_date;
    task._changed = true;
    gantt.updateAllTask();
  })(days)
};
ysy.reset = function () {
  (function () {
    ysy.history.revert();
  })()
};
ysy.exportForTest = function () {
  var issues = [];
  var milestones = [];
  var relations = [];
  var milestoneMap = {};
  var issueMap = {};
  for (var i = 0; i < gantt._order.length; i++) {
    var id = gantt._order[i];
    if (ysy.main.startsWith(id, "m")) {
      var milestone = ysy.data.milestones.getByID(id.substring(1));
      milestoneMap[milestone.id] = milestones.length;
      milestones.push({
        // id: milestone.id,
        name: milestone.name,
        due_date: milestone.start_date.format("YYYY-MM-DD")
      });
    } else if (typeof(id) === "number") {
      var issue = ysy.data.issues.getByID(id);
      issueMap[issue.id] = issues.length;
      issues.push({
        // id: issue.id,
        subject: issue.name,
        start_date: issue.start_date.format("YYYY-MM-DD"),
        due_date: issue.end_date.format("YYYY-MM-DD"),
        milestone: milestoneMap[issue.fixed_version_id],
        parent_issue: issueMap[issue.parent_issue_id]
      });
    }
  }
  for (i = 0; i < ysy.data.relations.array.length; i++) {
    var relation = ysy.data.relations.get(i);
    relations.push({
      source: issueMap[relation.source_id],
      target: issueMap[relation.target_id],
      type: relation.type,
      delay: relation.delay
    });
  }

  var data = {issues: issues, milestones: milestones, relations: relations};
  return JSON.stringify(data);
};

ysy.insertTestModel = function (data) {
  if (typeof data === "string") {
    data = JSON.parse(data);
  }
  var idPool = 10;
  ysy.data.loader.issueIdListMap = {};
  var issues = ysy.data.issues;
  var milestones = ysy.data.milestones;
  var relations = ysy.data.relations;
  issues.clear();
  milestones.clear();
  relations.clear();
  var expandedMilestones = [];
  var expandedIssues = [];
  var expandedRelations = [];
  var milestoneMap = {};
  var issuesMap = {};
  for (var i = 0; i < data.milestones.length; i++) {
    var milestoneData = data.milestones[i];
    var expandedMilestone = {
      id: idPool++,
      name: milestoneData.name,
      start_date: milestoneData.due_date,
      project_id: ysy.settings.projectID
    };
    expandedMilestones.push(expandedMilestone);
    milestoneMap[i] = expandedMilestone;
  }
  for (i = 0; i < data.issues.length; i++) {
    var issueData = data.issues[i];
    var expandedIssue = {
      id: idPool++,
      project_id: ysy.settings.projectID,
      name: issueData.subject,
      start_date: issueData.start_date,
      due_date: issueData.due_date,
      fixed_version_id: issueData.milestone !== undefined ? milestoneMap[issueData.milestone].id : null,
      parent_issue_id: issueData.parent_issue !== undefined ? issuesMap[issueData.parent_issue].id : null
    };
    expandedIssues.push(expandedIssue);
    issuesMap[i] = expandedIssue;
  }
  for (i = 0; i < data.relations.length; i++) {
    var relationData = data.relations[i];
    var expandedRelation = {
      id: idPool++,
      type: relationData.type,
      delay: relationData.delay,
      source_id: issuesMap[relationData.source].id,
      target_id: issuesMap[relationData.target].id
    };
    expandedRelations.push(expandedRelation);
  }
  ysy.data.loader._loadMilestones(expandedMilestones);
  ysy.data.loader._loadIssues(expandedIssues, "root");
  ysy.data.loader._loadRelations(expandedRelations);
  ysy.data.loader._fireChanges();
  ysy.history.clear();
  ysy.data.loader.loaded = true;
};

ysy.loadTestProject = function () {
  var text = '{"issues":[{"subject":"Ascendant","start_date":"2017-11-20","due_date":"2017-11-20"},{"subject":"Parent task","start_date":"2017-11-21","due_date":"2017-11-30"},{"subject":"Second subtask","start_date":"2017-11-21","due_date":"2017-11-24","parent_issue":1},{"subject":"First subtask","start_date":"2017-11-21","due_date":"2017-11-21","parent_issue":1},{"subject":"Third subtask","start_date":"2017-11-23","due_date":"2017-11-24","parent_issue":1},{"subject":"Forth subtask","start_date":"2017-11-23","due_date":"2017-11-30","parent_issue":1},{"subject":"Middle man","start_date":"2017-12-01","due_date":"2017-12-01"},{"subject":"Descendant","start_date":"2017-12-01","due_date":"2017-12-01","milestone":0}],"milestones":[{"name":"Milestone","due_date":"2017-12-05"}],"relations":[{"source":0,"target":1,"type":"precedes","delay":0},{"source":1,"target":7,"type":"precedes","delay":0},{"source":3,"target":5,"type":"precedes","delay":1},{"source":2,"target":6,"type":"precedes","delay":2}]}';
  ysy.insertTestModel(JSON.parse(text));
  setTimeout(function () {
    var exported = ysy.exportForTest();
    if (text !== exported) {
      for (var i = 0; i < text.length; i++) {
        if (text.substring(0, i) !== exported.substring(0, i)) {
          console.log("difference: " + text.substr(Math.max(i - 5, 0), 15) + " vs " + exported.substr(Math.max(i - 5, 0), 15));
          return;
        }
      }
    }
    console.log("Same");
  }, 500);
};
ysy.renderWaiter = {
  lastCounter: 0,
  orderedCounter: 0,
  init: function () {
    var self = this;
    $("body").append("<div id='render_waiter'></div>");
    ysy.view.onRepaint.push(function () {
      if (self.lastCounter!==self.orderedCounter) {
        self.lastCounter = self.orderedCounter;
        $("#render_waiter").text("Render Waiter: << "+self.lastCounter + " >>");
      }
    });
  },
  set: function (counter) {
    $("render_waiter").empty();
    ysy.renderWaiter.orderedCounter = counter;
  }
};
