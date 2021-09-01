window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  classPatch: function () {
    ysy.data.Assignee = function () {
      ysy.data.Data.call(this);
      this.resources_sums = {};
      this.dateHours = {};
      this.events = {};
    };
    ysy.main.extender(ysy.data.Data, ysy.data.Assignee, {
      _name: "Assignee",
      ganttType: "assignee",
      isAssignee: true,
      dateHours: {},
      estimated_ratio: 1,
      group_ids: null,
      user_ids: null,
      week_hours: ysy.settings.hoursOnWeek,
      _postInit: function () {
        var old_events = this.events;
        //old_events["2015-12-24"] = [{"name": "Štědrý den", "type": "easy_holiday_event"}];
        //old_events["2016-02-05"] = [{"name": "BlaBla", "type": "sick",hours:4}];
        for (var idate in old_events) {
          if (!old_events.hasOwnProperty(idate)) continue;
          this.applyResourceEvents(idate, old_events[idate]);
        }
      },
      applyResourceEvents: function (idate, events) {
        var barsClass = ysy.view.bars;
        for (var i = 0; i < events.length; i++) {
          var event = events[i];
          switch (event.type) {
            case "meeting":
            case "nonworking_attendance":
            case "easy_holiday_event":
              if (event.hours === undefined) {
                this.dateHours[idate] = 0;
                event.hours = this.week_hours[(barsClass.getFromDateCache(idate).day() + 6) % 7];
              } else {
                var hours = this.week_hours[(barsClass.getFromDateCache(idate).day() + 6) % 7];
                if (this.dateHours[idate] !== undefined) {
                  hours = this.dateHours[idate];
                }
                this.dateHours[idate] = Math.max(hours - event.hours, 0);
              }
              this.resources_sums[idate] = this.resources_sums[idate] || 0;
              break;
          }
        }
      },
      getID: function () {
        return "a" + this.id;
      },
      getParent: function () {
        return false;
      },
      pushFollowers: function () {
      },
      isOpened: function () {
        var opened = ysy.data.limits.openings[this.getID()];
        if (opened === undefined) return !ysy.settings.global;
        return opened;
      },
      getProblems: function () {
        return false;
      },
      getEvents: function (idate) {
        return this.events[idate];
      },
      getMaxHours: function (idate, mdate) {
        if (this.dateHours[idate] !== undefined) return this.dateHours[idate];
        if (!mdate) {
          mdate = ysy.view.bars.getFromDateCache(idate);
        }
        return this.week_hours[(mdate.day() + 6) % 7];
      },
      getMaxHoursInterval: function (idate, mdate, unit) {
        mdate = mdate || idate;
        var end_date = moment(mdate).add(1, unit + "s");
        var mover = moment(mdate);
        var sum = 0;
        while (mover.isBefore(end_date)) {
          sum += this.getMaxHours(mover.format("YYYY-MM-DD"), mover);
          mover.add(1, "days");
        }
        return sum;
      }
    });
    //########################################################################
    ysy.data.IssueAllocations = function () {
      this.resources = null;
      this.allocPack = null;
      this.changesLock = false;
      ysy.data.Data.call(this);
    };
    ysy.main.extender(ysy.data.Data, ysy.data.IssueAllocations, {
      _name: "IssueAllocation",
      init: function (json, parent) {
        this.resources = json.resources;
        this.issue = json.issue;
        this.id = json.id;
        this.allocator = json.allocator;
        this.allocPack = ysy.pro.resource.resourcesToAllocations(this);
        this._parent = parent;
        this._postInit();
      },
      _postInit: function () {
        if (this.issue._changed)
          this.recalculate();
        this.issue.register(function (reason) {
          ysy.log.debug(this.issue.name + "._fireChanges(" + reason + ")", "allocate");
          if (reason === "set" || reason === "revert") {
            if (this.changesLock) return;
            this.recalculate();
            var assignee = this.getAssignee(this.issue);
            if (assignee && assignee.group_ids) {
              var assignees = ysy.data.assignees;
              for (var i = 0; i < assignee.group_ids.length; i++) {
                var group = assignees.getByID(assignee.group_ids[i]);
                if (!group) continue;
                group._fireChanges(this, reason);
              }
            }
          }
        }, this);
      },
      allocatable: function () {
        return !this.issue.closed;
      },
      recalculate: function (toHistory) {
        if (!this.allocatable()) return;
        // do not calculate allocation for unassigned tasks and closed tasks
        var newAllocPack = ysy.pro.resource.calculateAllocations(this, {});
        if (this._compareAllocPacks(newAllocPack, this.allocPack)) return;
        ysy.log.debug("recalculate for " + this.issue.name, "allocate");
        if (toHistory) {
          var rev = {
            allocPack: this.allocPack,
            resources: this.resources,
            _changed: this._changed
          };
        }
        this.allocPack = newAllocPack;
        this.resources = ysy.pro.resource.allocationsToFixedResources(this.allocPack);
        this._changed = true;
        this.changesLock = true;
        this._fireChanges(this, "recalculate");
        this.changesLock = false;
        if (toHistory) {
          ysy.history.add(rev, this);
        }

      },
      getAssignee: function (issue) {
        issue = issue || this.issue;
        if (!issue) return null;
        return ysy.data.assignees.getByID(issue.assigned_to_id /*|| "unassigned"*/);
      },
      getLimitResourceDates: function () {
        var resourceDates = Object.getOwnPropertyNames(this.resources).sort();
        if (!resourceDates.length) return null;
        return {start_date: moment(resourceDates[0]), end_date: moment(resourceDates[resourceDates.length - 1])};
      },
      _fireChanges: function (who, reason) {
        ysy.log.debug(this.issue.name + "Alloc._fireChanges(" + reason + ")", "allocate");
        this.__proto__.__proto__._fireChanges.call(this, who, reason);
        if (!this.changesLock && reason !== "revert") {
          this.recalculate();
        }
        var issue = this.issue;
        this.changesLock = true;
        if (issue) issue._fireChanges(who, reason);
        this.changesLock = false;
      },
      _compareAllocPacks: function (pack1, pack2) {
        if (!pack1 || !pack2) return false;
        var keys = ["allocations", "types"];
        for (var ikey = 0; ikey < keys.length; ikey++) {
          var pack1Value = pack1[keys[ikey]];
          var pack2Value = pack2[keys[ikey]];
          if (!pack1Value && !pack2Value) continue;
          if (!pack1Value || !pack2Value) return false;
          var pack1Keys = Object.getOwnPropertyNames(pack1Value).filter(function (key) {
            return pack1Value[key];
          }).sort();
          var pack2Keys = Object.getOwnPropertyNames(pack2Value).filter(function (key) {
            return pack2Value[key];
          }).sort();
          if (pack1Keys.length !== pack2Keys.length) return false;
          for (var i = 0; i < pack1Keys.length; i++) {
            if (pack1Keys[i] !== pack2Keys[i]) return false;
            var date = pack2Keys[i];
            if (pack1Value[date] !== pack2Value[date]) return false;
          }
        }
        return true;
      }
    });
    //########################################################################
    $.extend(true, ysy.data.Issue.prototype, {
      getAllocations: function () {
        if (this.closed) return null;
        var issueAllocations = ysy.data.allocations.getByID(this.id);
        if (!issueAllocations) {
          return null;
        }
        return issueAllocations.allocPack;
      },
      getAllocationInstance: function () {
        var issueAllocations = ysy.data.allocations.getByID(this.id);
        if (!issueAllocations) {
          var allocations = ysy.data.allocations;
          issueAllocations = new ysy.data.IssueAllocations();
          issueAllocations.init({
            id: this.id,
            resources: {},
            issue: this,
            allocator: this.custom_resource_allocator_name
          }, allocations);
          allocations.pushSilent(issueAllocations);
          allocations._fireChanges(this, "init for new");
        }
        return issueAllocations;
      },
      _oldGetParent: ysy.data.Issue.prototype.getParent,
      getParent: function () {
        if (ysy.settings.resource.open) {
          var assigneeId = this.assigned_to_id || "unassigned";
          if (ysy.settings.global && ysy.settings.resource.buttons.withProjects) {
            var resourceProjectId = this.project_id + "a" + assigneeId;
            if (ysy.data.resourceProjects.getByID(resourceProjectId)) {
              return "p" + resourceProjectId;
            }
          }
          if (ysy.data.assignees.getByID(assigneeId)) {
            return "a" + assigneeId;
          }
          return null;
        }
        return this._oldGetParent();
      },
      getRestEstimated: function () {
        var assignee = ysy.data.assignees.getByID(this.assigned_to_id);
        if (assignee && assignee.estimated_ratio !== 1) {
          return (this.estimated_hours || 0) * assignee.estimated_ratio - (this.spent || 0);
        }
        return (this.estimated_hours || 0) - (this.spent || 0);
      },
      // getNonFixedEstimated: function () {
      //   var issueAllocations = this.getAllocationInstance();
      //   var estimated = this.getRestEstimated();
      //   // var dates=Object.getOwnPropertyNames(this)
      //   return estimated;
      // },
      problems: {
        checkEstimated: function () {
          var estimated = this.getRestEstimated();
          if (estimated < 0) {
            return ysy.settings.labels.problems.underEstimated.replace("%{over}", (-estimated).toFixed(2).toString());
          }
          var allocPack = this.getAllocations();
          if (!allocPack) return;
          var dayTypes = allocPack.types;
          for (var date in dayTypes) {
            if (!dayTypes.hasOwnProperty(date)) continue;
            if (dayTypes[date] && dayTypes[date] !== "fixed") {
              return ysy.settings.labels.problems[dayTypes[date]]
                  .replace("%{date}", moment(date).format(gantt.config.date_format));
            }
          }
        }
      },
      _dateSetHelper: function (nObj) {
        var rm = ysy.settings.resource.open;
        if (nObj.start_date) {
          if (!rm && nObj.start_date.isSame(this._start_date)) {
            delete nObj.start_date;
          } else {
            nObj._start_date = nObj.start_date
          }
        }
        if (nObj.end_date) {
          if (!rm && nObj.end_date.isSame(this._end_date)) {
            delete nObj.end_date;
          } else {
            nObj._end_date = nObj.end_date
          }
        }
        return nObj;
      },
      getAllocator: function () {
        var project = ysy.data.projects.getByID(this.project_id);
        if (project && project.allocator) {
          return project.allocator;
        }
        return "from_end";
      }
    });
    //############################################
    if (ysy.view.Legend) {
      var oldLegendOut = ysy.view.Legend.prototype.out;
      var oldLegendPostInit = ysy.view.Legend.prototype._postInit;
      $.extend(ysy.view.Legend.prototype, {
        _postInit: function () {
          var templ = ysy.view.getTemplate(this.templateName);
          this.template = ysy.view.templates.resourceLegend.replace("{{nonResourceLegend}}", templ);
          oldLegendPostInit.call(this);
          this._register(ysy.settings.resource);
          this._register(ysy.settings.zoom);
          if (ysy.settings.labels.legend_symbols.length === undefined) {
            ysy.settings.labels.legend_symbols = objectToArray(ysy.settings.labels.legend_symbols);
            ysy.settings.labels.legend_colors = objectToArray(ysy.settings.labels.legend_colors);
          }
        },
        out: function () {
          if (ysy.settings.resource.open) {
            var json = {resources: true};
            if (ysy.settings.zoom.zoom !== "day") {
              json.backColors = ysy.settings.labels.legend_colors.slice();
              for (var i = 0; i < json.backColors.length; i++) {
                var backColor = json.backColors[i];
                if (backColor.color) continue;
                var sourceColor = ysy.pro.resource.renderStyles[backColor.colorName];
                if (!sourceColor) continue;
                backColor.color = sourceColor;
              }
            }
            json.symbols = ysy.settings.labels.legend_symbols.slice();
            for (i = 0; i < json.symbols.length; i++) {
              var symbol = json.symbols[i];
              if (symbol.color) continue;
              sourceColor = ysy.pro.resource.renderStyles[symbol.colorName];
              if (!sourceColor) continue;
              symbol.color = sourceColor;
            }
            ysy.proManager.fireEvent("RmLegendOut",json);
            return json;
          } else {
            return oldLegendOut.call(this);
          }
        }
      });
    }

    //########################################################################
    ysy.data.ResourceProject = function () {
      ysy.data.Project.call(this);
      this.allocPack = null;
    };
    ysy.main.extender(ysy.data.Project, ysy.data.ResourceProject, {
      _name: "ResourceProject",
      _postInit: function () {
        this.assigned_to_id = this.assigned_to_id || "unassigned";
        this.real_id = this.id;
        this.id = this.id + "a" + this.assigned_to_id;
        this.__proto__.__proto__._postInit();
      },
      getParent: function () {
        if (ysy.data.assignees.getByID(this.assigned_to_id)) {
          return "a" + this.assigned_to_id;
        }
        return false;
      },
      getAllocations: function () {
        return null;
      },
      getProgress: function () {
        var issues = ysy.data.issues.getArray();
        if (issues.length === 0) {
          return 0;
        }
        var sumHours = 0.0;
        var workedHours = 0.0;
        var estimated;
        for (var i = 0; i < issues.length; i++) {
          var issue = issues[i];
          if (issue.project_id !== this.real_id) continue;
          if (issue.estimated_hours) {
            estimated = issue.estimated_hours;
          } else {
            estimated = issue.getDuration("hours");
          }
          sumHours += estimated;
          workedHours += estimated * issue.done_ratio / 100.0;
        }
        return workedHours / sumHours;
      }
    });
    var objectToArray = function (object) {
      var array = [];
      var keys = Object.getOwnPropertyNames(object).sort();
      for (var i = 0; i < keys.length; i++) {
        array.push(object[keys[i]]);
      }
      return array;
    };
  }
});
