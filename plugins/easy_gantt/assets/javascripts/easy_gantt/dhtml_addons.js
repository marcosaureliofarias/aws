/* dhtml_addons.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.addGanttAddons = function () {
  gantt.getLinkSourceDate = function (source, type) {
    if (type === "precedes") return source.end_date;
    if (type === "finish_to_finish") return source.end_date;
    if (type === "start_to_start") return source.start_date;
    if (type === "start_to_finish") return source.start_date;
    return null;
  };
  gantt.getLinkTargetDate = function (target, type) {
    if (type === "precedes") return target.start_date;
    if (type === "finish_to_finish") return target.end_date;
    if (type === "start_to_start") return target.start_date;
    if (type === "start_to_finish") return target.end_date;
    return null;
  };
  gantt.getLinkCorrection = function (type) {
    if (type === "precedes") return 1;
    if (type === "start_to_finish") return -1;
    return 0;
  };
  gantt.refreshOnlyTask = function (taskId) {
    this.refresher.refreshTask(taskId);
  };
  /**
   *
   * @param {StopOptions} main
   * @param {StopOptions|null} second
   * @return {StopOptions}
   */
  gantt.mergeStopOptions = function (main, second) {
    if (!second) return main;
    if (second.soonestStart) {
      if (!main.soonestStart || second.soonestStart.isAfter(main.soonestStart)) {
        main.soonestStart = second.soonestStart;
      }
    }
    if (second.soonestEnd) {
      if (!main.soonestEnd || second.soonestEnd.isAfter(main.soonestEnd)) {
        main.soonestEnd = second.soonestEnd;
      }
    }
    if (second.latestStart) {
      if (!main.latestStart || second.latestStart.isBefore(main.latestStart)) {
        main.latestStart = second.latestStart;
      }
    }
    if (second.latestEnd) {
      if (!main.latestEnd || second.latestEnd.isBefore(main.latestEnd)) {
        main.latestEnd = second.latestEnd;
      }
    }
    return main;
  };
  gantt.updateAllTask = function (seed_task) {
    ysy.history.openBrack();
    var toUpdate = {};
    var linksToUpdate = {};
    ysy.pro.relations.clearRelationData();
    // sort + reverse in order to process milestones before tasks
    var pullIds = Object.getOwnPropertyNames(gantt._pull).sort().reverse();
    for (var i = 0; i < pullIds.length; i++) {
      var task = gantt._pull[pullIds[i]];
      if (task._changed) {
        //gantt._tasks_dnd._fix_dnd_scale_time(task,{mode:task._changed});
        gantt._tasks_dnd._fix_working_times(task, {mode: task._changed});
        gantt._update_parents(task.id, false);
        var parentId = gantt.getParent(task.id);
        while (parentId) {
          var parent = gantt._pull[parentId];
          if (!parent || parent.type !== "task") break;
          toUpdate[parentId] = parent;
          parentId = gantt.getParent(parentId);
        }

        toUpdate[task.id] = task;
        for (var j = 0; j < task.$source.length; j++) {
          linksToUpdate[task.$source[j]] = true;
        }
        for (j = 0; j < task.$target.length; j++) {
          linksToUpdate[task.$target[j]] = true;
        }
        // var issue = task.widget.model;
        // if (issue.getMoveRequest) {
        //   var request = issue.getMoveRequest(allRequests);
        //   request.setPosition(task.start_date, task.end_date, true);
        // }
        task._changed = false;
      }
    }
    // var allRequests = {};
    // var request;
    // for (var id in allRequests) {
    //   if (!allRequests.hasOwnProperty(id)) continue;
    //   request = allRequests[id];
    //   request.entity.correctPosition(allRequests);
    // }
    // for (id in allRequests) {
    //   if (!allRequests.hasOwnProperty(id)) continue;
    //   request = allRequests[id];
    //   task = toUpdate[id];
    //   if (task) {
    //     $.extend(task, {start_date: request.softStart, end_date: request.softEnd});
    //   } else {
    //     if (!request.entity.set({start_date: request.softStart, end_date: request.softEnd})) {
    //       request.entity._fireChanges({_name: "UpdateAll"}, "updateAll");
    //     }
    //   }
    // }
    for (var id in toUpdate) {
      if (!toUpdate.hasOwnProperty(id)) continue;
      task = toUpdate[id];
      ysy.log.debug("UpdateAllTask update " + task.text, "task_drag");
      task.widget.update(task);
    }
    if (!ysy.settings.milestonePush) {
      gantt.updateMilestoneByChildren(toUpdate);
    }
    ysy.pro.relations.freezeAllRelations(linksToUpdate);
    ysy.history.closeBrack();
  };
  gantt.applyMoveRequests = function (allRequests) {
    for (var id in allRequests) {
      if (!allRequests.hasOwnProperty(id)) continue;
      var request = allRequests[id];
      if (!request.entity.set({start_date: request.softStart, end_date: request.softEnd})) {
        request.entity._fireChanges({_name: "applyMoveRequests"}, "applyMoveRequests");
      }
    }
  };
  gantt.checkLoopedLink = function (source, direction, previous, bannedId) {
    if (previous.indexOf(source.id) > -1) return false;
    var current = previous.concat([source]);
    if (source.id === bannedId) return current;
    // ASCENDANTS
    for (var i = 0; i < source.$target.length; i++) {
      var link = gantt.getLink(source.$target[i]);
      var nextSource = gantt._pull[link.source];
      if (!nextSource) continue;
      var next = gantt.checkLoopedLink(nextSource, "all", current, bannedId);
      if (next) return next;
    }
    if (ysy.settings.parentIssueDates) {
      // PARENT
      if (direction !== "notUp") {
        var parent = gantt._pull[source.parent];
        if (parent && gantt._get_safe_type(parent.type) === "task") {
          next = gantt.checkLoopedLink(parent, "notDown", current, bannedId);
          if (next) return next;
        }
      }
      // CHILDREN
      if (direction !== "notDown") {
        var branch = gantt._branches[source.id];
        if (branch) {
          for (i = 0; i < branch.length; i++) {
            var child = gantt._pull[branch[i]];
            if(!child) continue;
            next = gantt.checkLoopedLink(child, "notUp", current, bannedId);
            if (next) return next;
          }
        }
      }
    }
    return false;
  };
  gantt.isSpaceForLink = function (type, source, target) {
    var targetLimits = gantt.prepareStop(target, "all");
    ysy.pro.relations.clearRelationData();
    if (!targetLimits.latestStart && !targetLimits.latestEnd) return true;
    var sourceDate;
    if (type === "precedes" || type === "finish_to_finish") {
      sourceDate = source.end_date;
    } else {
      sourceDate = source.start_date;
    }
    if (type === "precedes" || type === "start_to_start") {
      var targetLatestStart = targetLimits.latestStart
          || gantt._working_time_helper.add_worktime(targetLimits.latestEnd, -target.duration, "day", false);
      return targetLatestStart.diff(sourceDate, "days") >= gantt.getLinkCorrection(type);
    }
    if (type === "finish_to_finish" || type === "start_to_finish") {
      var targetLatestEnd = targetLimits.latestEnd
          || gantt._working_time_helper.add_worktime(targetLimits.latestStart, target.duration, "day", true);
      return targetLatestEnd.diff(sourceDate, "days") >= gantt.getLinkCorrection(type);
    }
    return true;
  };
  gantt.updateMilestoneByChildren = function (toUpdate) {
    var milestoneDates = {};
    for (var id in toUpdate) {
      if (!toUpdate.hasOwnProperty(id)) continue;
      var issue = toUpdate[id].widget.model;
      if (!issue.fixed_version_id) continue;
      if (!milestoneDates[issue.fixed_version_id]) {
        var milestone = ysy.data.milestones.getByID(issue.fixed_version_id);
        if (!milestone) continue;
        milestoneDates[milestone.id] = milestone.start_date;
      }
      if (milestoneDates[issue.fixed_version_id].isBefore(issue.end_date)) {
        milestoneDates[issue.fixed_version_id] = issue.end_date;
      }
    }
    for (var milestoneId in milestoneDates) {
      if (!milestoneDates.hasOwnProperty(milestoneId)) continue;
      milestone = gantt._pull["m" + milestoneId];
      if (!milestone) continue;
      milestone.start_date.add(milestoneDates[milestoneId] - milestone.start_date);
      milestone.widget.update(milestone);
    }
  };
  //###############################################################################
  gantt.render_delay_element = function (link, pos) {
    var setting = ysy.settings;
    if (setting.resource_on) return false;
    if (setting.resource.ggrm) return false;
    if (link.widget && link.widget.model.isSimple) return null;
    //if(link.delay===0){return null;}
    var sourceDate = gantt.getLinkSourceDate(gantt._pull[link.source], link.type);
    var targetDate = gantt.getLinkTargetDate(gantt._pull[link.target], link.type);
    var actualDelay = targetDate.diff(sourceDate, "hours") / 24;
    actualDelay = Math.round(actualDelay) - gantt.getLinkCorrection(link.type);
    var text = (link.delay ? link.delay : '') + (actualDelay !== link.delay ? ' (' + actualDelay + ')' : '');
    return $('<div>')
        .css({position: "absolute", left: pos.x, top: pos.y})
        // .html(link.delay+" ("+actualDelay + ")")[0];
        .html(text)[0];
  };
  //##############################################################################
  /*
   * Přepsané funkce z dhtmlxganttu, kvůli efektivnějšímu napojení či kvůli odstranění bugů
   */
  //##########################################################################################
  gantt.allowedParent = function (child, parent) {
    if (child === parent) return false;
    var type = child.type;
    if (!type) {
      type = "task";
    }
    var allowed = gantt.config["allowedParent_" + type];
    if (!allowed) return false;
    if (parent.real_id > 1000000000000) return false;
    var parentType = parent.type || "task";
    return allowed.indexOf(parentType) >= 0;
  };
  gantt.getShowDate = function () {
    var pos = gantt._restore_scroll_state();
    if (!pos) return null;
    return this.dateFromPos(pos.x + this.config.task_scroll_offset);
  };
  gantt.silentMoveTask = function (task, parentId) {
    ysy.log.debug("silentMoveTask", "move_task");
    var id = task.id;
    var sourceId = this.getParent(id);
    if (sourceId == parentId) return;

    this._replace_branch_child(sourceId, id);
    var tbranch = this.getChildren(parentId);
    tbranch.push(id);

    this.setParent(task, parentId);
    this._branches[parentId] = tbranch;

    var childTree = this._getTaskTree(id);
    for (var i = 0; i < childTree.length; i++) {
      var item = this._pull[childTree[i]];
      if (item)
        item.$level = this.calculateTaskLevel(item);
    }
    task.$level = gantt.calculateTaskLevel(task);
    this.refreshData();

  };
  gantt.getCachedScroll = function () {
    if (!gantt._cached_scroll_pos) return {x: 0, y: 0};
    return {x: gantt._cached_scroll_pos.x || 0, y: gantt._cached_scroll_pos.y || 0};
  };
  gantt.reconstructTree = function () {
    var tasks = gantt._pull;
    var ids = Object.getOwnPropertyNames(tasks);
    for (var i = 0; i < ids.length; i++) {
      var task = tasks[ids[i]];
      if (task.realParent === undefined) continue;
      gantt.silentMoveTask(task, task.realParent);
      delete task.realParent;
    }
  };
  gantt.getIssuesOfMilestone = function (milestone) {
    return ysy.data.issues.array.filter(function (issue) {
      return issue.fixed_version_id === milestone.real_id;
    });
  }
};
