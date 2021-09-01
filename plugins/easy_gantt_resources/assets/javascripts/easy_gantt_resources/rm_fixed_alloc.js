window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  responsiveInput: function (attrs, saveFunc, validFunc) {
    var $input = $('<input ' + attrs + '>');
    $input.blur(saveFunc);
    $input.click(saveFunc);
    $input.keypress(function (e) {
      if (e.which == 13) {
        saveFunc(e);
        return false;
      }
    }).mousedown(function (e) {
      e.stopPropagation();
      return false;
    });
    $input[0].oninput = function () {
      $input.toggleClass("wrong", !validFunc($input.val()));
    };
    return $input;
  },
  allocationChange: function (e, allocations) {
    e.stopPropagation();
    ysy.log.debug("click on allocation", "resource");
    var $this = $(this);
    var resourceClass = ysy.pro.resource;
    //var $input = $('<input class="gantt-rm-allocation-input" type="text" size="2">');
    var $input;
    var last_value;
    var taskID = parseInt($this.closest(".gantt_task_line").attr("task_id"));
    var task = gantt._pull[taskID];
    if (!task) return;
    if (!task.widget || !task.widget.model) return;
    var issue = task.widget.model;
    var issueAllocations = ysy.data.allocations.getByID(issue.id);
    if (!issueAllocations) return;
    var graphOffset = $this.closest(".gantt_bars_area").offset();
    var zoom = ysy.settings.zoom.zoom;
    var dayZoom = ysy.settings.zoom.zoom === "day";
    var date = gantt.date[zoom + "_start"](moment(gantt.dateFromPos2(e.pageX - graphOffset.left)));
    if (!dayZoom) {
      var end_date = moment(date).add(1, zoom);
      if (task.end_date.isBefore(end_date)) {
        end_date = moment(task.end_date);
        end_date.add(1, "day");
      }
      if (date.isBefore(task.start_date)) {
        date = moment(task.start_date);
      }
      if (end_date.isBefore(date)) return;
    }
    var maxAllocation = dayZoom ? 24 : end_date.diff(date, "hours");
    var dateString = date.format("YYYY-MM-DD");
    var assignee = ysy.data.assignees.getByID(issue.assigned_to_id);
    if (assignee && assignee.is_group) {
      maxAllocation = Infinity;
    }
    var restEstimated = issue.getRestEstimated();
    var allocs = issueAllocations.resources;
    var fixedAllocationDates = Object.getOwnPropertyNames(allocs);
    for (var i = 0; i < fixedAllocationDates.length; i++) {
      var fixedDate = fixedAllocationDates[i];
      if (fixedDate === dateString) continue;
      if (!allocs[fixedDate].custom) continue;
      restEstimated -= allocs[fixedDate].hours;
    }
    if (maxAllocation > restEstimated) {
      if (restEstimated < 0) {
        maxAllocation = 0;
      } else {
        maxAllocation = restEstimated;
      }
    }


    var saveAllocation = function (e) {
      e.stopPropagation();
      $input.off();
      gantt.refreshTask(taskID);
      var value = $input.val();
      if (value === "") {
        var removeAllocation = true;
      } else {
        value = Math.round(parseFloat(value) * 10) / 10;
        if (isNaN(value)
            || value < 0
            || value > maxAllocation) return false;
      }

      if (!removeAllocation && dayZoom
          && allocs[dateString] && allocs[dateString].custom
          && value + resourceClass.MARGIN > last_value
          && value - resourceClass.MARGIN < last_value) return false;
      // at this point is new value validated
      var rev = {};
      for (var key in allocs) {
        if (!allocs.hasOwnProperty(key)) continue;
        rev[key] = allocs[key];
      }
      if (dayZoom) {
        if (removeAllocation) {
          delete allocs[dateString];
        } else {
          allocs[dateString] = {hours: value, custom: true};
        }
      } else {
        if (removeAllocation) {
          while (date < end_date) {
            delete allocs[date.format("YYYY-MM-DD")];
            date.add(1, "day");
          }
        } else {
          var assignee = issueAllocations.getAssignee(issue);
          var freshAllocPack = resourceClass.calculateAllocations({},
              {
                estimated: value,
                start_date: date,
                issue: issue,
                end_date: end_date.subtract(1, "day"),
                assignee: assignee,
                allocator: "evenly"
              });
          if (freshAllocPack === null) return false;
          var freshAllocations = freshAllocPack.allocations;
          for (var freshDate in freshAllocations) {
            if (!freshAllocations.hasOwnProperty(freshDate)) continue;
            allocs[freshDate] = {hours: freshAllocations[freshDate], custom: true};
          }
        }
      }
      var history = ysy.history;
      history.openBrack();
      issue.set({start_date: issue._start_date, end_date: issue._end_date});
      //issueAllocations.set("resources",rev);
      history.add({resources: rev, _changed: issueAllocations._changed}, issueAllocations);
      issueAllocations._changed = true;
      issueAllocations._fireChanges({_name: "Allocator"}, "allocation set");
      history.closeBrack();
      return false;
    };
    $input = resourceClass.responsiveInput(
        'class="gantt-rm-allocation-input" type="text"',
        saveAllocation,
        function (value) {
          if (value === "") return true;
          var parsedValue = parseFloat(value);
          return !(isNaN(parsedValue)
              || parsedValue < 0
              || parsedValue > maxAllocation)
        }
    );
    var inputLeft = gantt.posFromDate(date) - gantt.posFromDate(task.start_date);
    if (dayZoom) {
      var width = gantt._tasks.col_width;
    } else {
      width = gantt.posFromDate(end_date) - gantt.posFromDate(date);
    }
    $input.css({
      left: (inputLeft - 1) + "px",
      width: Math.max(width, 30) + "px"
    });
    if (dayZoom) {
      last_value = allocations[dateString];
    } else {
      last_value = resourceClass._simpleWeekSummer(allocations, date, end_date);
    }
    $input.val(resourceClass.roundTo1(last_value));
    $this.parent().append($input);
    $input.focus();
    return false;
  },
  _simpleWeekSummer: function (allocations, start_date, end_date) {
    start_date = moment(start_date);
    var sum = 0;
    while (start_date < end_date) {
      var allocation = allocations[start_date.format("YYYY-MM-DD")];
      if (allocation) sum += allocation;
      start_date.add(1, "day");
    }
    return sum;
  }
});