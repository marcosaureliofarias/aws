/**
 * Created by Ringael on 8. 9. 2015.
 */

window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  name: "Resource",
  doNotCloseToolPanel: true,
  features: {
    //featureName: "featurePath"          // put here declaration all additional features for RM
  },
  patch: function () {
    var resourceClass = ysy.pro.resource;
    ysy.proManager.register("close", this.close);
    ysy.proManager.register("ganttConfig", this.ganttConfig);
    ysy.proManager.register("extendGanttTask", this.extendGanttTask);

    ysy.data.assignees = new ysy.data.Array().init({_name: "AssigneeArray"});
    ysy.data.allocations = new ysy.data.Array().init({_name: "AllocationArray"});

    this.classPatch();
    this.renderer_patch();
    for (var feature in this.features) {
      if (!this.features.hasOwnProperty(feature)) continue;
      var featureCode = this[this.features[feature]];
      if (featureCode && featureCode.patch) {
        featureCode.patch();
      }
    }
    if (this.global_patch) {
      this.global_patch();
    } else {
      ysy.data.loader.register(function () {
        if (ysy.settings.resource.open) {
          this.loader.load();
        }
      }, this);
      var prevLoadSubEntity = ysy.data.loader.loadSubEntity;
      ysy.data.loader.loadSubEntity = function (type, id) {
        ysy.pro.resource.loader.loaded = false;
        prevLoadSubEntity.call(ysy.data.loader, type, id);
      };
    }
    this.decimalAllocation = ysy.settings.decimalAllocation;


    if (ysy.settings.resource_on) {
      // if you dont call this in EASY.schedule.late and open project RM, it renders gantt only
      EASY.schedule.late(() => {
        this.open();
      });
    }
    $.extend(ysy.view.AllButtons.prototype.extendees, {
      resource: {
        bind: function () {
          this.model = ysy.settings.resource;
        },
        func: function () {
          ysy.proManager.closeAll(resourceClass);
          if (ysy.settings.resource.open) {
            resourceClass.close();
          } else {
            resourceClass.open();
          }
        },
        isOn: function () {
          return ysy.settings.resource.open !== ysy.settings.resource_on
        }
      }
    });
    var oldAfterSaveSuccess = ysy.data.saver.afterSaveSuccess;
    ysy.data.saver.afterSaveSuccess = function () {
      if (ysy.settings.resource.open) {
        resourceClass.saver.save(oldAfterSaveSuccess, ysy.data.saver.afterSaveFail);
      } else {
        oldAfterSaveSuccess();
      }
    };
    var oldSelectChildren = ysy.view.GanttTasks.prototype._selectChildren;
    ysy.view.GanttTasks.prototype._selectChildren = function () {
      if (ysy.settings.resource.open) {
        var issues = this.model.getArray().slice(0);
        issues.sort(function (a, b) {
          return a._start_date - b._start_date;
        });
        var combined = ysy.data.assignees.getArray();
        if (ysy.settings.reservationEnabled) {
          combined = combined.concat(ysy.pro.resource.reservations.getRows());
        }
        if (ysy.settings.global && ysy.settings.resource.buttons.withProjects) {
          combined = combined.concat(ysy.data.resourceProjects.array);
        }
        return combined.concat(issues);
      } else {
        return oldSelectChildren.call(this);
      }
    };
    gantt._tasks_dnd._handlers[gantt.config.drag_mode.move] = function (ev, shift, drag) {
      gantt._tasks_dnd._move(ev, shift, drag);
      if (ysy.settings.resource.open
          && gantt._get_safe_type(ev.type) === "task"
          && !ev.readonly) {
        var rowHeight = gantt.config.row_height;
        ev.pos_y = Math.round(shift.y / rowHeight);
      }

    };
    var oldAllowedParent = gantt.allowedParent;
    var resourceAllowedParent = function (child, parent) {
      if (!parent
          || !ysy.settings.resource.open
          || !ysy.settings.global) return true;
      if (gantt._get_safe_type(child.type) !== "task"
          || gantt._get_safe_type(parent.type) !== "assignee") return false;
      if (!child.widget
          || !parent.widget) return false;
      var assigneeID = parent.widget.model.id;
      if (assigneeID === "unassigned") return true;
      var issue = child.widget.model;
      var project = ysy.data.projects.getByID(issue.project_id);
      if (!project || !project.members) return false;
      return (project.members.indexOf(assigneeID) >= 0);
    };
    gantt.allowedParent = function (child, parent) {
      var allowed = resourceAllowedParent(child, parent);
      if (allowed === false) return false;
      return oldAllowedParent(child, parent);
    };
    gantt.attachEvent("onBeforeTaskChanged", function (id, mode, e) {
      if (mode !== gantt.config.drag_mode.move) return;
      var task = gantt.getTask(id);
      var pos_y = task.pos_y;
      if (!pos_y) return;
      var order = gantt._order;
      task.pos_y = 0;
      var over_index = gantt.getGlobalTaskIndex(id) + pos_y;
      if (over_index < 0 || over_index >= order.length) return;
      var over = gantt.getTask(order[over_index]);
      var newParent = over.id;
      while (over && over.type !== "assignee") {
        newParent = over.parent;
        over = gantt._pull[newParent];
      }
      if (!over) return;
      var project = task.widget && ysy.data.projects.getByID(task.widget.model.project_id);
      if (!resourceAllowedParent(task, over)) {
        var message = ysy.settings.labels.errors2.assignToNonMember
            .replace("%{issue}", "\"" + task.text + "\"")
            .replace("%{assignee}", "\"" + over.text + "\"");
        if (project) {
          message = message.replace("%{project}", "\"" + project.name + "\"")
        }
        dhtmlx.message(message, "error");
        return;
      }
      if (newParent !== task.parent) {
        var projectId = "p" + project.id + over.id;
        if (gantt._pull[projectId]) {
          gantt.open(projectId);
        } else {
          ysy.data.limits.openings[projectId] = true;
        }
        gantt.open(newParent);
        gantt.moveTask(task.id, -1, newParent);
      }
    });
    // override of GanttTask function
    var oldConstructParent = ysy.view.GanttTask.prototype._constructParentUpdate;
    ysy.view.GanttTask.prototype._constructParentUpdate = function (parentId) {
      var parents = oldConstructParent(parentId);
      if (ysy.settings.resource.open) {
        if (ysy.main.startsWith(parentId, "a")) {
          if (parentId === "aunassigned") {
            return {assigned_to_id: null};
          }
          return {assigned_to_id: parseInt(parentId.substring(1))};
        }
        return {};
      }
      return parents;
    }
  },
  open: function () {
    var resource = ysy.settings.resource;
    if (resource.setSilent("open", true)) {
      $("#easy_gantt")
          .toggleClass("resource_management", true)
          .toggleClass("gantt", false);
      this.bindRenderers();
      ysy.proManager.fireEvent("ganttConfig", gantt.config);
      if (ysy.data.loader.loaded && !this.loader.loaded) {
        this.loader.load();
      }
      resource._fireChanges(this, "open");
      $("#easy_gantt_type").val('rm');
      ysy.data.loader.setHeading(false);
    }
  },
  close: function (except) {
    if (except === ysy.pro.toolPanel) return;
    var resource = ysy.settings.resource;
    if (resource.reservations) {
      resource.buttons.newReservation = false;
      ysy.pro.resource.reservations.toggle();
    }
    if (resource.setSilent("open", false)) {
      $("#easy_gantt")
          .toggleClass("resource_management", false)
          .toggleClass("gantt", true);
      ysy.pro.resource.removeRenderers();
      ysy.proManager.fireEvent("ganttConfig", gantt.config);
      resource._fireChanges(this, "close");
      $("#easy_gantt_type").val('');
      ysy.data.loader.setHeading(true);
    }
  },
  ganttConfig: function (config) {
    if (!ysy.settings.resource.open) return;
    $.extend(config, {
      allowedParent_task: ["assignee"],
      allowedParent_task_global: ["assignee"]
    })
  },
  extendGanttTask: function (issue, gantt_issue) {
    if (issue.isIssue) {
      gantt_issue.spent = issue.spent;
    }
    if (issue.isAssignee && issue.is_group) {
      gantt_issue.subtype = "group";
    }
    if( issue.id === "unassigned"){
      gantt_issue.subtype = "unassigned";
    }
  }
});
