window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  MARGIN: 0.05,
  renderStyles: {},
  compiledStyles: {},
  renderer_patch: function () {
    $.extend(gantt.templates, {
      grid_bullet_assignee: function (item, has_children) {
        if (item && item.widget && item.widget.model && item.widget.model.avatar) {
          return '<div class="gantt_tree_icon gantt-assignee-avatar-bullet">' + item.widget.model.avatar + '</div>';
        }
        return "<div class='gantt_tree_icon gantt-assignee-bullet'></div>";
      },
      superitem_after_assignee: function (item, has_children) {
        var model = item.widget && item.widget.model;
        if (model._unassigned) return "";
        var data = [];
        for (var i = 0; i < 7; i++) {
          if (model.week_hours[i] !== model.__proto__.week_hours[i]) {
            data.push(ysy.settings.labels.maxHours + ": " + JSON.stringify(model.week_hours));
            break;
          }
        }
        if (model.estimated_ratio !== 1) {
          data.push(ysy.settings.labels.estimatedRatio + ": " + model.estimated_ratio);
        }
        if (data.length === 0) return "";
        return '<span class="gantt-superitem-after">(' + data.join(", ") + ')</span>';
      }
    });
    this.compileStyles();
  },
  compileStyles: function () {
    this.renderStyles = ysy.settings.styles.resource;
    this.compiledStyles.wrong = {fontStyle: this.renderStyles.fontBold, textColor: this.renderStyles.wrong};
    this.compiledStyles.fixed = {fontStyle: this.renderStyles.fontBold, textColor: this.renderStyles.fixed};
    this.compiledStyles.normal = {fontStyle: this.renderStyles.fontNormal, textColor: this.renderStyles.normal};
  },
  bindRenderers: function () {
    ysy.view.bars.registerRenderer("assignee", this.assignee_canvas_renderer);
    ysy.view.bars.registerRenderer("project", this.projectRenderer);
    ysy.view.bars.registerRenderer("task", this.taskRenderer);
    ysy.view.bars.registerRenderer("reservation", this.taskRenderer);
  },
  removeRenderers: function () {
    ysy.view.bars.removeRenderer("assignee", this.assignee_canvas_renderer);
    ysy.view.bars.removeRenderer("project", this.projectRenderer);
    ysy.view.bars.removeRenderer("task", this.taskRenderer);
    ysy.view.bars.removeRenderer("reservation", this.taskRenderer);
  },
  taskRenderer: function taskRMRenderer(task, next) {
    var div = next().call(this, task, next);
    $(div).removeClass("gantt_parent_task-subtype");
    var resourceClass = ysy.pro.resource;
    var allodiv = $.proxy(resourceClass.issue_canvas_renderer, gantt)(task);
    if (allodiv){
      ysy.view.bars.insertCanvas(allodiv, div);
    }
    if (task.pos_y) {
      div.style.transform = "translate(0," + (task.pos_y * gantt.config.row_height || 0) + "px)";
    }
    if (ysy.settings.resource.withMilestones) {
      var milediv = $.proxy(resourceClass.milestones.milestone_renderer, gantt)(task);
      if (milediv) div.appendChild(milediv);
    }
    return div;
  },
  projectRenderer: function projectRMRenderer(task, next) {
    var div = next().call(this, task, next);
    var allodiv = $.proxy(ysy.pro.resource.project_canvas_renderer, gantt)(task);
    if (allodiv){
      ysy.view.bars.insertCanvas(allodiv, div);
    }
    return div;
  },
  issue_canvas_renderer: function (task) {
    var resourceClass = ysy.pro.resource;

    if (!task.widget) return;
    var allocPack = task.widget.model.getAllocations();
    if (allocPack === null) return;
    var canvasList = ysy.view.bars.canvasListBuilder();
    canvasList.build(task, this);
    if (ysy.settings.zoom.zoom !== "day") {
      $.proxy(resourceClass.issue_week_renderer, this)(task, allocPack, canvasList);
    } else {
      $.proxy(resourceClass.issue_day_renderer, this)(task, allocPack, canvasList);
    }
    var element = canvasList.getElement();
    var clickTimeout = null;
    element.onclick = function (e) {
      e.stopPropagation();
      var newEvent = new MouseEvent(e.type, e);
      if (clickTimeout) return;
      clickTimeout = setTimeout(function () {
        clickTimeout = null;
        element.parentNode.dispatchEvent(newEvent);
      }, 300);
    };
    if (task.widget.model.isEditable()) {
      element.ondblclick = function (e) {
        if (clickTimeout) {
          clearTimeout(clickTimeout);
          clickTimeout = null;
        }
        $.proxy(resourceClass.allocationChange, element)(e, allocPack.allocations);
      };
    }
    element = canvasList.getElement();
    element.className += " gantt-task-tooltip-area";
    return element;

  },
  project_canvas_renderer: function (task) {
    var resourceClass = ysy.pro.resource;
    var allocPack = resourceClass.countSubAllocations(this, task.widget.model);
    var canvasList = ysy.view.bars.canvasListBuilder();
    canvasList.build(task, this);
    if (ysy.settings.zoom.zoom !== "day") {
      $.proxy(resourceClass.issue_week_renderer, this)(task, allocPack, canvasList);
    } else {
      $.proxy(resourceClass.issue_day_renderer, this)(task, allocPack, canvasList);
    }
    var element = canvasList.getElement();
    element.className += " project";
    return element;
  },
  issue_day_renderer: function (task, allocPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var allocations = allocPack.allocations;
    var sourceStyles = resourceClass.compiledStyles;
    for (var allodate in allocations) {
      if (!allocations.hasOwnProperty(allodate)) continue;
      var alloMoment = moment(allodate);
      if (alloMoment.isBefore(task.start_date)) continue;
      if (task.end_date.diff(alloMoment, "days") < -1) continue;
      var allocation = allocations[allodate];
      if (allocation === undefined) continue;
      if (!canvasList.inRange(allodate)) return;
      if (allocPack.types[allodate]) {
        if (allocPack.types[allodate] === "fixed") {
          var styles = sourceStyles.fixed;
        } else {
          styles = sourceStyles.wrong;
        }
      } else {
        if (!allocation) continue;
        styles = sourceStyles.normal;
      }
      var text = resourceClass.roundTo1(allocation);
      canvasList.fillTextAt(allodate, text, styles);
    }
  },
  issue_week_renderer: function (task, allocPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var unit = ysy.settings.zoom.zoom;
    var summerPack = resourceClass._weekAllocationSummer(allocPack, unit, task.start_date, task.end_date);
    var weekAllocations = summerPack.allocations;
    var sourceStyles = resourceClass.compiledStyles;
    for (var allodate in weekAllocations) {
      if (!weekAllocations.hasOwnProperty(allodate)) continue;
      if (!canvasList.inRange(allodate)) continue;
      var allocation = weekAllocations[allodate];
      if (allocation === 0) continue;
      if (summerPack.types[allodate]) {
        if (summerPack.types[allodate] === "fixed") {
          var styles = sourceStyles.fixed;
        } else {
          styles = sourceStyles.wrong;
        }
      } else {
        styles = sourceStyles.normal;
      }
      var text = resourceClass.roundTo1(allocation);
      canvasList.fillTextAt(allodate, text, styles);
    }
  },
  assignee_canvas_renderer: function assigneeRMRenderer(task) {
    //if (ysy.settings.zoom.zoom !== "day") return null;
    var resourceClass = ysy.pro.resource;
    //task.start_date = moment(gantt._min_date);
    //task.end_date = moment(gantt._max_date);
    if (!task.widget || task.widget.model._unassigned) return;
    var assignee = task.widget.model;
    var resources_sums = assignee.resources_sums;
    var allocPack = resourceClass.countSubAllocations(this, task.widget.model);
    var allocations = allocPack.allocations;
    for (var idate in resources_sums) {
      if (!resources_sums.hasOwnProperty(idate)) continue;
      allocations[idate] = (allocations[idate] || 0) + resources_sums[idate];
    }
    if (ysy.settings.resource.buttons.hidePlanned) {
      resourceClass.planned.subtractPlanned(allocations, assignee);
    }
    //ysy.log.debug("assignee_canvas_renderer() "+JSON.stringify(allocations));
    var canvasList = ysy.view.bars.canvasListBuilder();
    canvasList.build(task, this, this._min_date, this._max_date);
    if (ysy.settings.resource.freeCapacity) {
      if (ysy.settings.zoom.zoom !== "day") {
        $.proxy(resourceClass.freeCapacity.assignee_week_renderer, this)(task, assignee, allocPack, canvasList);
      } else {
        $.proxy(resourceClass.freeCapacity.assignee_day_renderer, this)(task, assignee, allocPack, canvasList);
      }
    } else {
      if (ysy.settings.zoom.zoom !== "day") {
        $.proxy(resourceClass.assignee_week_renderer, this)(task, assignee, allocPack, canvasList);
      } else {
        $.proxy(resourceClass.assignee_day_renderer, this)(task, assignee, allocPack, canvasList);
      }
    }
    var element = canvasList.getElement();
    element.className += " assignee";
    // element.onmousedown = function (e) {
    element.onmousedown =
        $.proxy(resourceClass.events.onMouseDown, element);
    // };
    element.onclick = function (e) {
      $.proxy(resourceClass.events.onClick, element)(e, assignee);
    };
    return element;

  },
  assignee_day_renderer: function (task, assignee, allocPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var minDateValue = this._min_date.valueOf();
    var maxDateValue = moment(this._max_date).add(1, "days").valueOf();
    var allocations = allocPack.allocations;
    for (var allodate in allocations) {
      if (!allocations.hasOwnProperty(allodate)) continue;
      var alloMoment = moment(allodate);
      if (+alloMoment < minDateValue) continue;
      if (+alloMoment > maxDateValue) continue;
      resourceClass.assignee_one_day_renderer.call(this, allodate, alloMoment, assignee, allocations[allodate], assignee.getEvents(allodate), allocPack.types[allodate], canvasList);
    }
  },
  assignee_one_day_renderer: function (allodate, alloMoment, assignee, allocation, events, alloType, canvasList) {
    var resourceClass = ysy.pro.resource;
    if (allocation < resourceClass.MARGIN && allocation > -resourceClass.MARGIN && !(events && events.length)) return;

    var eventSums = null;
    if (events && events.length > 0) {
      eventSums = {};
      for (var i = 0; i < events.length; i++) {
        var event = events[i];
        if (eventSums[event.type] === undefined) {
          eventSums[event.type] = 0;
        }
        eventSums[event.type] += event.hours;
      }
    }
    if (!canvasList.inRange(allodate)) return;
    if (ysy.settings.resource.freeCapacity) {
      var overAllocated = allocation < 0;
    } else {
      var maxHours = assignee.getMaxHours(allodate, alloMoment);
      overAllocated = maxHours < allocation;
    }
    var sourceStyles = resourceClass.compiledStyles;
    if (overAllocated
        || (alloType && alloType !== "fixed")) {
      var styles = sourceStyles.wrong;
    } else if (alloType === "fixed") {
      styles = sourceStyles.fixed;
    } else {
      styles = sourceStyles.normal;
    }
    resourceClass.renderTextIn(allodate, allocation, eventSums, canvasList, maxHours, styles);
  },
  assignee_week_renderer: function (task, assignee, allocationsPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var summerPack = resourceClass._weekAllocationSummer(allocationsPack, ysy.settings.zoom.zoom, this._min_date, this._max_date, assignee);
    var weekAllocations = summerPack.allocations;
    var weekTypes = summerPack.types;
    var weekEvents = summerPack.events;
    for (var allodate in weekAllocations) {
      if (!weekAllocations.hasOwnProperty(allodate)) continue;
      resourceClass.assignee_one_week_renderer.call(this, allodate, null, assignee, weekAllocations[allodate], weekEvents[allodate], weekTypes[allodate], canvasList);
    }
  },
  assignee_one_week_renderer: function (allodate, alloMoment, assignee, allocation, eventSums, alloType, canvasList) {
    var resourceClass = ysy.pro.resource;

    if (allocation < resourceClass.MARGIN && allocation > -resourceClass.MARGIN && !eventSums) return;

    if (!canvasList.inRange(allodate)) return;

    var sourceStyles = resourceClass.renderStyles;
    if (ysy.settings.resource.freeCapacity) {
      var maxHours = assignee;
      var occupation = 1 - allocation / (maxHours || 0.001);
    } else {
      maxHours = assignee.getMaxHoursInterval(allodate, alloMoment, ysy.settings.zoom.zoom);
      occupation = allocation / (maxHours || 0.001);
    }
    var styles = {};
    if (occupation !== 0) {
      styles.backgroundColor = resourceClass.occupationToColor(occupation);
      styles.shrink = true;
    }
    if (alloType) {
      styles.fontStyle = sourceStyles.fontBold;
      if (alloType === "fixed") {
        styles.textColor = sourceStyles.fixed;
      } else {
        styles.textColor = sourceStyles.wrong;
      }
    } else {
      styles.fontStyle = sourceStyles.fontNormal;
      styles.textColor = sourceStyles.normal;
    }
    resourceClass.renderTextIn(allodate, allocation, eventSums, canvasList, maxHours, styles);
  },
  roundTo1: function (number) {
    if (!number) return "";
    // in case argument number is string, we need to parse it, because we can't call method toFixed() on string
    number = parseFloat(number);
    var modulated = number % 1;
    if (modulated < 0) {
      modulated += 1;
    }
    if (modulated < this.MARGIN || modulated > (1 - this.MARGIN)) {
      return number.toFixed();
    }
    return number.toFixed(1);
  },
  occupationToColor: function (ratio) {
    if (ratio === 0) return;
    var styles = ysy.pro.resource.renderStyles;
    if (ratio > 1) return styles.overAllocations;
    if (ratio > 0.7) return styles.fullAllocations;
    return styles.someAllocations;
  },
  renderTextIn: function (allodate, allocation, eventSums, canvasList, maxHours, styles) {
    var width = canvasList.columnWidth;
    if (eventSums) {
      const labels = ysy.settings.labels.eventTypes.symbols;
      var symbols = { easy_holiday_event: labels.easy_holiday_event_short, meeting: labels.meeting_short, nonworking_attendance: labels.nonworking_attendance_short, unapproved_nonworking_attendance: labels.unapproved_nonworking_attendance_short};
      var eventTextArray = [];
      var eventType = "meeting";
      if (eventSums[eventType]) {
        eventTextArray.push(symbols[eventType] + this.roundTo1(eventSums[eventType]));
      }
      eventType = "nonworking_attendance";
      if (eventSums[eventType]) {
        eventTextArray.push(symbols[eventType] + this.roundTo1(eventSums[eventType]));
      }
      eventType = "unapproved_nonworking_attendance";
      if (eventSums[eventType]) {
        eventTextArray.push(symbols[eventType] + this.roundTo1(eventSums[eventType]));
      }
      eventType = "easy_holiday_event";
      if (eventSums[eventType] != undefined) {
        eventTextArray.push(symbols[eventType] + (eventSums.isWeek ?  this.roundTo1(eventSums[eventType]) : ""));
      }
    }
    var withEvents = eventTextArray && eventTextArray.length;
    if (allocation > this.MARGIN || allocation < -this.MARGIN) {
      if (maxHours === undefined || width < 40) {
        var textBottom = this.roundTo1(allocation);
      } else {
        var slash = " / ";
        if (width < 55) slash = "/";
        textBottom = this.roundTo1(allocation) + slash + this.roundTo1(maxHours);
      }
    }
    if (withEvents) {
      var textUpper = eventTextArray.join(",");
    }
    canvasList.fillTwoTextAt(allodate, textUpper, textBottom, styles);
  },
  countSubAllocations: function (gantt, parent) {
    var allocations = {};
    var allocTypes = {};
    if (parent.isAssignee) {
      if (parent.is_group && parent.user_ids) {
        this._groupAllocationSummer(parent.user_ids, allocations);
      }
    }
    var issues = ysy.data.issues.getArray();
    for (var i = 0; i < issues.length; i++) {
      var issue = issues[i];
      if (parent.isProject) {
        if (issue.project_id !== parent.real_id || issue.assigned_to_id !== parent.assigned_to_id) continue;
      } else {
        if (issue.assigned_to_id !== parent.id) continue;
      }
      var issueAllocPackage = issue.getAllocations();
      if (issueAllocPackage === null) continue;
      var issueAllocations = issueAllocPackage.allocations;
      var issueAllocTypes = issueAllocPackage.types;
      for (var date in issueAllocations) {
        if (!issueAllocations.hasOwnProperty(date)) continue;
        if (issueAllocTypes[date]) {
          if (allocTypes[date] === undefined || allocTypes[date] === "fixed")
            allocTypes[date] = issueAllocTypes[date];
        }
        if (issueAllocations[date] <= 0) continue;
        if (allocations[date] === undefined) {
          allocations[date] = issueAllocations[date];
        } else {
          allocations[date] += issueAllocations[date];
        }
      }
    }
    return {allocations: allocations, types: allocTypes};
  },
  _groupAllocationSummer: function (groupIds, allocations) {
    for (var i = 0; i < groupIds.length; i++) {
      var group = ysy.data.assignees.getByID(groupIds[i]);
      if(!group) continue;
      var subAllocations = this.countSubAllocations(this, group).allocations;
      for (var date in subAllocations) {
        if (!subAllocations.hasOwnProperty(date)) continue;
        if (allocations[date] === undefined) {
          allocations[date] = subAllocations[date];
        } else {
          allocations[date] += subAllocations[date];
        }
      }
    }
  },
  _weekAllocationSummer: function (allocPack, unit, minDate, maxDate, assignee) {
    var barsClass = ysy.view.bars;
    var minDateValue = minDate.valueOf();
    var maxDateValue = moment(maxDate).add(1, "days").valueOf();
    var MARGIN = ysy.pro.resource.MARGIN;
    var weekAllocations = {};
    var weekTypes = {};
    var allocations = allocPack.allocations;
    var allocTypes = allocPack.types;
    var weekEventSums = {};
    for (var allodate in allocations) {
      if (!allocations.hasOwnProperty(allodate)) continue;
      var alloMoment = barsClass.getFromDateCache(allodate);
      if (+alloMoment < minDateValue) continue;
      if (+alloMoment > maxDateValue) continue;
      var allocation = allocations[allodate];
      //if (allocation < MARGIN && allocation > -MARGIN) continue;
      var firstMomentDate = moment(alloMoment).startOf(unit === "week" ? "isoWeek" : unit);
      var firstDate = firstMomentDate.toISOString();
      if (assignee) {
        if (assignee.getMaxHours(allodate, alloMoment) < allocation) {
          weekTypes[firstDate] = "wrong";
        }
        var events = assignee.getEvents(allodate);
        if (events && events.length > 0) {
          var eventSums = weekEventSums[firstDate];
          if (!eventSums) {
            eventSums = {isWeek: true};
            weekEventSums[firstDate] = eventSums;
          }
          for (var i = 0; i < events.length; i++) {
            var event = events[i];
            if (eventSums[event.type] === undefined) {
              eventSums[event.type] = 0;
            }
            eventSums[event.type] += event.hours;
            // if (event.type === "meeting") allocation -= event.hours;
          }
        }
      }
      if (weekAllocations[firstDate] === undefined) {
        weekAllocations[firstDate] = allocation;
      } else {
        weekAllocations[firstDate] += allocation;
      }
      if (allocTypes[allodate]) {
        if (weekTypes[firstDate] === undefined || weekTypes[firstDate] === "fixed")
          weekTypes[firstDate] = allocTypes[allodate];
      }
    }
    return {allocations: weekAllocations, types: weekTypes, events: weekEventSums};
  }
});
