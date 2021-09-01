window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.relations = {
  name: "Relation mover",
  connectedTasks: {},
  connectedForAsc: {},
  patch: function () {
    this.execute();
  },
  makeDelayFixedForSave: function (relation) {
    var delay = this.getMinimizedDelay(relation);
    let unfixRelations = false;
    if (ysy.settings.hasOwnProperty("unfixRelations")){
      unfixRelations = ysy.settings.unfixRelations.active;
    }
    if (!relation._unlocked && delay <= relation.delay || unfixRelations) return;
    if (relation.set({delay: delay, _unlocked: false})) {
      relation._fireChanges(this, "makeDelayFixedForSave()");
    }
  },
  getMinimizedDelay: function (relation) {
    var delay = relation.getActDelay();
    if (delay === 0) return relation.delay;
    if (delay < 0) return -1;
    var target = relation.getTarget();
    if (!target) return relation.delay;
    if (relation.type === "precedes" || relation.type === "start_to_start") {
      if (delay > 0) {
        var mover = moment(target.start_date).subtract(1, "days");
        while (!gantt._working_time_helper.is_working_day(mover)) {
          delay--;
          mover.subtract(1, "days");
          if (delay <= relation.delay) return relation.delay;
        }
      }
    } else {
      if (delay > 0) {
        mover = moment(target.end_date).subtract(1, "days");
        if (!gantt._working_time_helper.is_working_day(mover)) {
          delay -= 2;
          mover.subtract(1, "days");
          if (delay <= relation.delay) return relation.delay;
        }
        while (!gantt._working_time_helper.is_working_day(mover)) {
          delay--;
          mover.subtract(1, "days");
          if (delay <= relation.delay) return relation.delay;
        }
      }
    }
    return delay;
  },
  freezeAllRelations: function (linksToUpdate) {
    var relations = ysy.data.relations;
    for (var id in linksToUpdate) {
      if (!linksToUpdate.hasOwnProperty(id)) continue;
      ysy.pro.relations.makeDelayFixedForSave(relations.getByID(id));
    }
  },
  clearRelationData: function () {
    var taskIds = Object.getOwnPropertyNames(this.connectedTasks);
    for (var i = 0; i < taskIds.length; i++) {
      var task = this.connectedTasks[taskIds[i]];
      delete task._parent_offset;
      delete task._limits;
    }
    this.connectedTasks = {};
    this.connectedForAsc = {};
  },
  findConnectedForAsc: function (task, direction) {
    this.connectedForAsc[task.id] = task;
    for (var i = 0; i < task.$source.length; i++) {
      var lid = task.$source[i];
      var link = gantt._lpull[lid];
      if (link.isSimple) continue;
      var desc = gantt.getTask(link.target);
      this.findConnectedForAsc(desc);
    }
    if (direction !== "notDown") {
      var branch = gantt._branches[task.id];
      if (branch) {
        for (i = 0; i < branch.length; i++) {
          var childId = branch[i];
          var child = gantt.getTask(childId);
          this.findConnectedForAsc(child, "notUp");
        }
      }
    }
    if (direction !== "notUp") {
      var parentId = gantt.getParent(task.id);
      var parent = gantt.getTask(parentId, false);
      if (parent && gantt._get_safe_type(parent.type) === "task") {
        this.findConnectedForAsc(parent, "notDown");
      }
    }
  },
  moveByCreatedLink: function (link, relation, created) {
    var source = gantt.getTask(relation.source_id);
    this.findConnectedForAsc(source);
    gantt.prepareStop(source, "all");
    ysy.history.openBrack();
    if (created) {
      ysy.data.relations.push(relation);
      this.makeDelayFixedForSave(relation);
      link.delay = relation.delay;
    }
    gantt.moveDependent(source);
    this.clearRelationData();
    gantt.updateAllTask(source);
    ysy.history.closeBrack();
  }
};
//##################################################################################################
/** @typedef {{soonestStart?:Moment,latestStart?:Moment,soonestEnd?:Moment,latestEnd?:Moment}} StopOptions */
ysy.pro.relations.execute = function () {

  var getTask = function (taskId, options) {
    if (options.central.id === taskId) return options.central;
    return gantt._pull[taskId];
  };

  gantt.prepareParentOffset = function (task) {
    if (!ysy.settings.parentIssueDates){
      if (task.$open) return;
    }
    if (!gantt._branches[task.id]) return;
    var branch = gantt._branches[task.id];
    for (var j = 0; j < branch.length; j++) {
      var child = gantt._pull[branch[j]];
      if (!child) continue;
      child._parent_offset = gantt._working_time_helper.get_work_units_between(task.start_date, child.start_date, "day");
    }
    ysy.pro.relations.connectedTasks[task.id] = task;
  };
  /**
   *
   * @param {Object} central
   * @return {StopOptions|null}
   */
  gantt.prepareMultiStop = function (central) {
    if (central.type === "project") return null;
    if (central.type === "milestone") {
      if (ysy.settings.milestonePush) return null;
      var issues = gantt.getIssuesOfMilestone(central);
      var limit;
      for (var i = 0; i < issues.length; i++) {
        var issue = issues[i];
        var child = gantt._pull[issue.id];
        if (!child) continue;
        var date = child.end_date;
        if (!limit || limit.isBefore(date)) {
          limit = date;
        }
      }
      central._limits = {soonestStart: limit};
    }
    ysy.pro.relations.findConnectedForAsc(central);
    // console.log(Object.getOwnPropertyNames(ysy.pro.relations.connectedForAsc).map(function (id) {
    //   return gantt._pull[id].text
    // }));
    gantt.prepareStop(central, "all");
    return central._limits;
  };

  /**
   * @param {Object} task
   * @param {string} direction
   * @return {StopOptions|null}
   */
  gantt.prepareStop = function (task, direction) {
    if (task._limits) {
      return task._limits;
    } else {
      var limits;
      task._limits = limits = {};
      ysy.pro.relations.connectedTasks[task.id] = task;
    }
    // ysy.log.debug(ysy.moreDashes() + task.text);
    gantt.prepareParentOffset(task);
    if (task.soonest_start) {
      gantt.mergeStopOptions(limits, {soonestStart: task.soonest_start});
    }
    if (task.latest_due) {
      gantt.mergeStopOptions(limits, {latestEnd: task.latest_due});
    }
    gantt.mergeStopOptions(limits, gantt.ascStop(task, "all"));
    gantt.mergeStopOptions(limits, gantt.descStop(task/*, "all"*/));
    if (direction !== "notUp") {
      gantt.mergeStopOptions(limits, gantt.parentStop(task, direction));
    }
    if (direction !== "notDown") {
      gantt.mergeStopOptions(limits, gantt.childStop(task, direction));
    }
    if (ysy.settings.milestonePush) {
      var milestoneDate = gantt.milestoneDate(task);
      if (milestoneDate) {
        gantt.mergeStopOptions(limits, {latestEnd: milestoneDate});
      }
    }
    return task._limits;
  };
  /**
   *
   * @param {Object} task
   * @param {String} direction
   * @param {int|String} [rootId] - id of subtree task
   * @return {StopOptions}
   */
  gantt.ascStop = function (task, direction, rootId) {
    var global = {};
    // ASCENDANTS
    for (var i = 0; i < task.$target.length; i++) {
      var lid = task.$target[i];
      var link = gantt._lpull[lid];
      if (link.isSimple) continue;
      var asc = gantt._pull[link.source];
      if (rootId && gantt.inParentTree(asc, rootId)) continue;
      if (ysy.pro.relations.connectedForAsc[asc.id]) {
        /* You will move with this task, so don't prepare limits */
        continue;
      }
      var soonestStart, soonestEnd;
      switch (link.type) {
        case "precedes":
          soonestStart = moment(asc.end_date).add(link.delay + 1, "day");
          gantt._working_time_helper.round_date(soonestStart, "future");
          break;
        case "finish_to_finish":
          soonestEnd = moment(asc.end_date).add(link.delay, "day");
          gantt._working_time_helper.round_date(soonestEnd, "past");
          break;
        case "start_to_finish":
          soonestEnd = moment(asc.start_date).add(link.delay - 1, "day");
          gantt._working_time_helper.round_date(soonestEnd, "past");
          break;
        case "start_to_start":
          soonestStart = moment(asc.start_date).add(link.delay, "day");
          gantt._working_time_helper.round_date(soonestStart, "future");
          break;
      }
      gantt.mergeStopOptions(global, {soonestStart: soonestStart, soonestEnd: soonestEnd});
    }
    return global;
  };
  /**
   *
   * @param {Object} task
   * @param {string} direction
   * @return {StopOptions|null}
   */
  gantt.childStop = function (task, direction) {
    if (!ysy.settings.parentIssueDates){
      if (task.$open) return null;
    }
    if (direction === "notDown" || !gantt._branches[task.id]) return null;
    var branch = gantt._branches[task.id];
    /** @type {StopOptions} */
    var parentStopOptions = {};
    for (var i = 0; i < branch.length; i++) {
      var childId = branch[i];
      var child = gantt.getTask(childId);
      var otherStopOptions = gantt.prepareStop(child, "notUp");
      var updatedDate;
      if (otherStopOptions.soonestStart) {
        updatedDate = gantt._working_time_helper.add_worktime(otherStopOptions.soonestStart, -child._parent_offset, "day", false);
        gantt.mergeStopOptions(parentStopOptions, {soonestStart: updatedDate});
      }
      if (otherStopOptions.soonestEnd) {
        updatedDate = gantt._working_time_helper.add_worktime(otherStopOptions.soonestEnd, -child._parent_offset - child.duration, "day", false);
        gantt.mergeStopOptions(parentStopOptions, {soonestStart: updatedDate});
      }
      if (otherStopOptions.latestStart) {
        updatedDate = gantt._working_time_helper.add_worktime(otherStopOptions.latestStart, task.duration - child._parent_offset, "day", true);
        gantt.mergeStopOptions(parentStopOptions, {latestEnd: updatedDate});
      }
      if (otherStopOptions.latestEnd) {
        updatedDate = gantt._working_time_helper.add_worktime(otherStopOptions.latestEnd, task.duration - child._parent_offset - child.duration, "day", true);
        gantt.mergeStopOptions(parentStopOptions, {latestEnd: updatedDate});
      }
    }
    return parentStopOptions;
  };
  gantt.parentStop = function (task) {
    if (!ysy.settings.parentIssueDates && gantt.isTaskVisible(task.id)) return null;
    var parentId = gantt.getParent(task.id);
    var parent = gantt.getTask(parentId, false);
    if (parent && gantt._get_safe_type(parent.type) === "task") {
      var limits = gantt.prepareStop(parent, "notDown");
      if (limits.soonestEnd) {
        var branch = gantt._branches[parentId];
        var endDate;
        for (var i = 0; i < branch.length; i++) {
          var childId = branch[i];
          if (ysy.pro.relations.connectedForAsc[childId]) continue;
          var child = gantt.getTask(childId);
          if (!endDate || endDate.isBefore(child.end_date)) {
            endDate = child.end_date;
          }
        }
        if (!endDate || !endDate.isBefore(limits.soonestEnd)) {
          delete limits.soonestEnd;
        }
      }
      return limits;
    }
  };
  /**
   * @param {Object} task
   * @param {int|string} targetParentId
   * @return {boolean}
   */
  gantt.inParentTree = function (task, targetParentId) {
    if (!task || task.parent === gantt.config.root_id) return false;
    if (task.parent === targetParentId) return true;
    return gantt.inParentTree(gantt._pull[task.parent], targetParentId);
  };
  gantt.milestoneDate = function (task) {
    var issue = task.widget && task.widget.model;
    if (!issue) {
      task = gantt.getTask(task.id);
      issue = task.widget && task.widget.model;
      if (!issue) return;
    }
    var milestone = ysy.data.milestones.getByID(issue.fixed_version_id);
    if (!milestone || milestone._noDate) return;
    var ganttMilestone = gantt._pull[milestone.getID()];
    if (ganttMilestone) {
      var milestoneDate = ganttMilestone.end_date;
    } else {
      milestoneDate = milestone.start_date;
    }
    return milestoneDate;
  };
  /**
   * @param {Object} task
   // * @param {String} direction
   * @return {StopOptions|null}
   */
  gantt.descStop = function (task/*, direction*/) {
    /** @type {StopOptions} */
    var global = {};
    for (var i = 0; i < task.$source.length; i++) {
      var lid = task.$source[i];
      var link = gantt._lpull[lid];
      if (link.isSimple) continue;
      var desc = gantt.getTask(link.target);
      var descLimits = gantt.prepareStop(desc, "all");
      var updatedDate;
      if (descLimits.latestStart) {
        switch (link.type) {
          case "precedes":
            updatedDate = moment(descLimits.latestStart).subtract(link.delay + 1, "days");
            updatedDate._isEndDate = true;
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestEnd: updatedDate});
            break;
          case "finish_to_finish":
            updatedDate = gantt._working_time_helper.add_worktime(descLimits.latestStart, desc.duration, "day", true);
            updatedDate.subtract(link.delay + 1, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestEnd: updatedDate});
            break;
          case "start_to_finish":
            updatedDate = gantt._working_time_helper.add_worktime(descLimits.latestStart, desc.duration, "day", true);
            updatedDate.subtract(link.delay - 1, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestStart: updatedDate});
            break;
          case "start_to_start":
            updatedDate = moment(descLimits.latestStart).subtract(link.delay, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestStart: updatedDate});
            break;
          default:
            throw "unprepared type of link " + link.type;
        }
      }
      if (descLimits.latestEnd) {
        switch (link.type) {
          case "precedes":
            updatedDate = gantt._working_time_helper.add_worktime(descLimits.latestEnd, -desc.duration, "day", true);
            updatedDate.subtract(link.delay, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestEnd: updatedDate});
            break;
          case "finish_to_finish":
            updatedDate = moment(descLimits.latestEnd).subtract(link.delay, "days");
            updatedDate._isEndDate = true;
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestEnd: updatedDate});
            break;
          case "start_to_finish":
            updatedDate = moment(descLimits.latestEnd).subtract(link.delay - 1, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestStart: updatedDate});
            break;
          case "start_to_start":
            updatedDate = gantt._working_time_helper.add_worktime(descLimits.latestEnd, -desc.duration, "day", false);
            updatedDate.subtract(link.delay, "days");
            gantt._working_time_helper.round_date(updatedDate, "past");
            gantt.mergeStopOptions(global, {latestStart: updatedDate});
            break;
          default:
            throw "unprepared type of link " + link.type;
        }
      }
    }
    return global;
  };
  /**
   *
   * @param {Object} ev
   * @param {Moment} new_start
   * @param {Moment} new_end
   * @param {StopOptions} limits
   */
  gantt.multiStop = function (ev, new_start, new_end, limits) {
    if (!limits) {
      limits = ev._limits;
      if (!limits) return;
    }
    var startDiff, endDiff, limiter;
    if (new_start) {
      if (limits.soonestStart && new_start.isBefore(limits.soonestStart)) {
        limiter = limits.soonestStart;
      } else if (limits.latestStart && new_start.isAfter(limits.latestStart)) {
        limiter = limits.latestStart;
      }
      if (limiter) {
        startDiff = limiter - new_start; // in milliseconds
        new_start.add(startDiff, "milliseconds");
        if (new_end) {
          endDiff = gantt._working_time_helper.add_worktime(new_start, ev.duration, "day", true) - new_end;
          new_end.add(endDiff, "milliseconds");
        }
        limiter = null;
      }
    }
    if (new_end) {
      if (limits.soonestEnd && new_end.isBefore(limits.soonestEnd)) {
        limiter = limits.soonestEnd;
      } else if (limits.latestEnd && new_end.isAfter(limits.latestEnd)) {
        limiter = limits.latestEnd;
      }
      if (limiter) {
        endDiff = limiter - new_end; // in milliseconds
        new_end.add(endDiff, "milliseconds");
        if (new_start) {
          startDiff = gantt._working_time_helper.add_worktime(new_end, -ev.duration, "day", false) - new_start;
          new_start.add(startDiff, "milliseconds");
        }
      }
    }
  };
  //####################################################################################################################
  /** @typedef {{central:Object,origin:Object,visited:{}}} MoveOptions */
  /**
   *
   * @param {Object} task
   * @param {MoveOptions|null} [options]
   * @param {String} [direction]
   */
  gantt.moveDependent = function (task, options, direction) {
    direction = direction || "all";
    // ysy.log.debug(ysy.moreDashes() + "moveDependent: " + task.text + " " + direction);
    if (!options) {
      options = {
        central: task,
        origin: gantt.getTask(task.id),
        visited: {}
      }
    }
    if (ysy.settings.parentIssueDates || !task.$open) {
      if (direction !== "notDown") {
        var shouldMove = gantt.shouldMoveChildren(task);
        if (shouldMove.move) {
          gantt.moveChildren(task, options);
        } else if (shouldMove.milestoneMove) {
          gantt.moveMilestoneChildren(task, options);
        }
      }
      if (direction !== "notUp") {
        gantt.moveParent(task, options);
      }
    }
    if (direction === "left") {
      gantt.moveAscendants(task, options);
    } else {
      gantt.moveDescendants(task, options);
    }
    options.visited[task.id] = true;
    // ysy.log.debug(ysy.lessDashes() + "moveDependent: " + task.text + " " + direction);
  };
  gantt.moveDescendants = function (task, options) {
    /** DESCENDANTS */
    for (var i = 0; i < task.$source.length; i++) {
      var lid = task.$source[i];
      var link = gantt._lpull[lid];
      // if (previous.visitedLinks.indexOf(lid) > -1) continue;
      // previous.visitedLinks.push(lid);
      if (link.isSimple) continue;
      var desc = getTask(link.target, options);
      var soonestDescStart = this.moveOneDescendant(task, desc.duration, link);
      if (desc._limits) {
        /** @type {StopOptions} */
        var limits = desc._limits;
        if (limits.soonestStart && limits.soonestStart.isAfter(soonestDescStart)) {
          soonestDescStart = limits.soonestStart;
        }
        if (limits.soonestEnd) {
          var updatedDate = gantt._working_time_helper.add_worktime(limits.soonestEnd, -desc.duration, "day", false);
          if (updatedDate.isAfter(soonestDescStart)) {
            soonestDescStart = updatedDate;
          }
        }
      }
      if(link.unlocked){
        if(desc.start_date.isBefore(soonestDescStart)){
          gantt.safeMoveToStartDate(desc, soonestDescStart);
        }
      }else{
        gantt.safeMoveToStartDate(desc, soonestDescStart);
      }
      gantt.moveDependent(desc, options, "all");
    }
  };
  gantt.moveOneDescendant = function (task, descDuration, link) {
    var soonestDescStart;
    var soonestDescEnd;
    switch (link.type) {
      case "precedes":
        soonestDescStart = moment(task.end_date).add(link.delay + 1, "day");
        soonestDescStart = gantt._working_time_helper.get_closest_worktime({date: soonestDescStart, dir: "future"});
        break;
      case "finish_to_finish":
        soonestDescEnd = moment(task.end_date).add(link.delay, "day");
        if (gantt._working_time_helper.is_working_day(soonestDescEnd)) {
          soonestDescEnd.add(1, "day");
          if (!gantt._working_time_helper.is_working_day(soonestDescEnd)) {
            var timePart = soonestDescEnd - moment(soonestDescEnd).startOf("day");
            soonestDescEnd = gantt._working_time_helper.get_closest_worktime({
              date: soonestDescEnd,
              dir: "future"
            }).add(timePart, "milliseconds");
          }
        } else {
          soonestDescEnd = gantt._working_time_helper.get_closest_worktime({date: soonestDescEnd, dir: "future"});
          soonestDescEnd.add(1, "day");
        }
        soonestDescStart = gantt._working_time_helper.add_worktime(soonestDescEnd, -descDuration, "day", false);
        break;
      case "start_to_finish":
        soonestDescEnd = moment(task.start_date).add(link.delay - 1, "day");
        if (gantt._working_time_helper.is_working_day(soonestDescEnd)) {
          soonestDescEnd.add(1, "day");
          if (!gantt._working_time_helper.is_working_day(soonestDescEnd)) {
            timePart = soonestDescEnd - moment(soonestDescEnd).startOf("day");
            soonestDescEnd = gantt._working_time_helper.get_closest_worktime({
              date: soonestDescEnd,
              dir: "future"
            }).add(timePart, "milliseconds");
          }
        } else {
          soonestDescEnd = gantt._working_time_helper.get_closest_worktime({date: soonestDescEnd, dir: "future"});
          soonestDescEnd.add(1, "day");
        }
        soonestDescStart = gantt._working_time_helper.add_worktime(soonestDescEnd, -descDuration, "day", false);
        break;
      case "start_to_start":
        soonestDescStart = moment(task.start_date).add(link.delay, "day");
        gantt._working_time_helper.get_closest_worktime({date: soonestDescStart, dir: "future"});
        break;
    }
    return soonestDescStart;
  };
  gantt.moveChildren = function (task, options) {
    var branch = gantt._branches[task.id];
    if (!branch || branch.length === 0) return null;
    for (var i = 0; i < branch.length; i++) {
      var childId = branch[i];
      //if(gantt.isTaskVisible(childId)){continue;}
      var child = getTask(childId, options);
      var childNewStart = gantt._working_time_helper.add_worktime(task.start_date, child._parent_offset, "day", false);
      if (options.visited[childId]) continue;
      gantt.safeMoveToStartDate(child, childNewStart);
      child._changed = gantt.config.drag_mode.move;
      gantt.moveDependent(child, options, "notUp");
      gantt.refreshOnlyTask(childId);
    }
  };
  /**
   * @param {Object} child
   * @param {MoveOptions} options
   */
  gantt.moveParent = function (child, options) {
    var parentId = child.parent || 0;
    var parent = getTask(parentId, options);
    if (gantt._get_safe_type(parent.type) !== "task") return;
    if (!ysy.settings.parentIssueDates && parent.$open) return;
    var childDates = gantt.getChildDates(parent, child, options);
    if (!parent.start_date.isSame(childDates.start)) {
      parent.start_date.add(childDates.start - parent.start_date, "milliseconds");
      parent._changed = gantt.config.drag_mode.move;
      gantt.refreshOnlyTask(parent.id);
    }
    if (!parent.end_date.isSame(childDates.end)) {
      parent.end_date.add(childDates.end - parent.end_date, "milliseconds");
      parent._changed = gantt.config.drag_mode.move;
      gantt.refreshOnlyTask(parent.id);
    }
    gantt.moveDependent(parent, options, "notDown");
  };
  gantt.getChildDates = function (parent, sourceChild, options) {
    var branch = gantt._branches[parent.id];
    // if (!branch || branch.length === 0) return null;
    var parentStart = sourceChild.start_date,
        parentEnd = sourceChild.end_date;
    for (var i = 0; i < branch.length; i++) {
      var childId = branch[i];
      if (childId === sourceChild.id) continue;
      var child = getTask(childId, options);
      if (parentStart.isAfter(child.start_date)) {
        parentStart = child.start_date;
      }
      if (parentEnd.isBefore(child.end_date)) {
        parentEnd = child.end_date;
      }
    }
    return {start: parentStart, end: parentEnd};
  };
  gantt.shouldMoveChildren = function (task) {
    if (task.type === "milestone" && ysy.settings.milestonePush) return {milestoneMove: true};
    if (gantt._get_safe_type(task.type) === "task" && ysy.settings.parentIssueDates) return {
      move: true,
      adjust: true
    };
    if (!task.$open && gantt.isTaskVisible(task.id)) return {move: true};
    return false;
  };
  /**
   * @param {Object} task
   * @param {Moment} start_date
   * @return {number}
   */
  gantt.safeMoveToStartDate = function (task, start_date) {
    if (task.start_date.isSame(start_date)) return 0;
    var end_date = gantt._working_time_helper.add_worktime(start_date, task.duration, "day", true);
    // ysy.log.debug(ysy.sameDashes() + "safeMoveToStartDate: " + task.text + " " + start_date.format("YYYY-MM-DD"));
    task.start_date.add(start_date - task.start_date, "milliseconds");
    task.end_date.add(end_date - task.end_date, "milliseconds");
    task._changed = gantt.config.drag_mode.move;
    gantt.refreshOnlyTask(task.id);
    return 0;
  };
  gantt.moveMilestoneChildren = function (milestone, options) {
    var issues = gantt.getIssuesOfMilestone(milestone);
    if (issues.length === 0) return 0;
    for (var i = 0; i < issues.length; i++) {
      var child = getTask(issues[i].id, options);
      if (child.end_date.isAfter(milestone.end_date)) {
        child.end_date.add(milestone.end_date - child.end_date, "milliseconds");
        var childNewStart = gantt._working_time_helper.add_worktime(child.end_date, -child.duration, "day", false);
        child.start_date.add(childNewStart - child.start_date, "milliseconds");
        child._changed = gantt.config.drag_mode.move;
        gantt.refreshOnlyTask(child.id);
        gantt.moveDependent(child, options, "left");
      }
    }
    return 0;
  };
  gantt.moveAscendants = function (source, options) {
    for (var i = 0; i < source.$target.length; i++) {
      var lid = source.$target[i];
      var link = gantt._lpull[lid];
      if (link.isSimple) continue;
      var desc = getTask(link.source, options);
      var latestAscStart;
      switch (link.type) {
        case "precedes":
          latestAscStart = moment(source.start_date).subtract(link.delay, "day");
          latestAscStart = gantt._working_time_helper.add_worktime(latestAscStart, -desc.duration, "day", false);
          break;
        case "finish_to_finish":
          latestAscStart = moment(source.end_date).subtract(link.delay - 1, "day");
          latestAscStart = gantt._working_time_helper.add_worktime(latestAscStart, -desc.duration, "day", false);
          break;
        case "start_to_finish":
          latestAscStart = moment(source.end_date).subtract(link.delay - 1, "day");
          gantt._working_time_helper.get_closest_worktime({date: latestAscStart, dir: "past"});
          break;
        case "start_to_start":
          latestAscStart = moment(source.start_date).subtract(link.delay, "day");
          gantt._working_time_helper.get_closest_worktime({date: latestAscStart, dir: "past"});
          break;
      }
      if (latestAscStart.isBefore(desc.start_date)) {
        gantt.safeMoveToStartDate(desc, latestAscStart);
        gantt.moveDependent(desc, options, "left");
      }
    }
  };
  //##################################################################################################################
  gantt.attachEvent("onLinkClick", function (id/*, mouseEvent*/) {
    // if (!gantt.config.drag_links) return;
    ysy.log.debug("LinkClick on " + id, "link_config");
    var link = gantt.getLink(id);
    if (gantt._is_readonly(link)) return;
    var source = gantt._pull[link.source];
    if (!source) return;
    var target = gantt._pull[link.target];
    if (!target) return;
    if (source.readonly && target.readonly) return;
    var relation = link.widget.model;
    let unfixRelations = false;
    if (ysy.settings.hasOwnProperty("unfixRelations")) {
      unfixRelations = ysy.settings.unfixRelations.active;
    }
    if (relation._unlocked && !unfixRelations) {
      relation.set({delay: ysy.pro.relations.getMinimizedDelay(relation), _unlocked: false});
    } else {
      relation.set({delay: 0, _unlocked: true});
    }
    return false;
  });
  gantt.attachEvent("onContextMenu", function (taskId, id /*, mouseEvent*/) {
    if (taskId) return;
    if (!gantt.config.drag_links) return;
    if (!gantt.isLinkExists(id)) return;
    ysy.log.debug("LinkClick on " + id, "link_config");
    var link = gantt.getLink(id);
    if (gantt._is_readonly(link)) return;
    var source = gantt._pull[link.source];
    if (!source) return;
    var target = gantt._pull[link.target];
    if (!target) return;
    if (source.readonly && target.readonly) return;
    var linkConfigWidget = new ysy.view.LinkPopup().init(link.widget.model, link);
    linkConfigWidget.$target = $("#ajax-modal");//$dialog;
    linkConfigWidget.repaint();
    showModal("ajax-modal", "auto");
  });

};
