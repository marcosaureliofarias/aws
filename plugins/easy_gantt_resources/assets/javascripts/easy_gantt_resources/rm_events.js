window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.events = ysy.pro.resource.events || {};
EasyGem.extend(ysy.pro.resource.events, {
  $target: null,
  template: null,
  clickPack: null,
  lastPos: {
    x: 0,
    y: 0
  },
  lastOut: null,
  show: function (e, eventData, resource_sum, working_hours) {
    var out = {
      days: eventData,
      resource_sum: resource_sum,
      working_hours: working_hours
    };
    this.lastOut = out;
    this.$target = ysy.view.tooltip.show("gantt-event-tooltip", e, ysy.view.templates.assigneeTooltip, out);
  },
  updateTooltip: function (otherAllocations, otherReservations) {
    var lastOut = this.lastOut;
    if (!lastOut) return;
    if (!lastOut.otherAllocations) lastOut.otherAllocations = [];
    if (!lastOut.otherReservations) lastOut.otherReservations = [];
    var allocations = lastOut.otherAllocations.concat(otherAllocations);
    var reservations = lastOut.otherReservations.concat(otherReservations);
    var allocationSum = 0;
    var reservationSum = 0;
    for (var i = 0; i < allocations.length; i++) {
      const allocation = allocations[i];
      allocationSum += +(allocation.hours);
      if (allocation.name) {
       allocation.subject = allocation.name;
      }
      allocation.subject = allocation.project_name ? `${allocation.project_name} / ${allocation.subject}` : `${allocation.subject}`;
    }
    for (i = 0; i < reservations.length; i++) {
      const reservation = reservations[i];
      reservationSum += reservation.hours;
      reservation.name = reservation.project_name ? `${reservation.project_name} / ${reservation.name}` : `${reservation.name}`;
    }

    $.extend(lastOut, {
      sum: parseFloat(ysy.pro.resource.roundTo1(allocationSum + reservationSum)),
      allocationSum: parseFloat(ysy.pro.resource.roundTo1(allocationSum)),
      reservationSum: parseFloat(ysy.pro.resource.roundTo1(reservationSum)),
      otherAllocations: allocations,
      otherReservations: reservations
    });
    this.$target = ysy.view.tooltip.show(null, null, null, lastOut);
  },
  onMouseDown: function (e) {
    e.stopPropagation();
    var eventsClass = ysy.pro.resource.events;
    if (eventsClass.clickPack) {
      eventsClass.clickPack.prevented = true;
      eventsClass.clickPack = null;
    }
    eventsClass.lastPos = {
      x: e.clientX,
      y: e.clientY
    };
    eventsClass.fireThrough(e);
  },
  onClick: function (event, assignee) {
    ysy.log.debug("onClick({left:" + event.pageX + ",top:" + event.pageY + "," + assignee.name + ")", "resource");
    var eventsClass = ysy.pro.resource.events;
    var lastPos = eventsClass.lastPos;
    if (Math.abs(event.clientX - lastPos.x) > 2) return;
    if (Math.abs(event.clientY - lastPos.y) > 2) return;
    var $this = $(this);
    var graphOffset = $this.closest(".gantt_bars_area").offset();
    var zoom = ysy.settings.zoom.zoom;
    var date = moment(gantt.dateFromPos2(event.pageX - graphOffset.left)).startOf(zoom === "week" ? "isoWeek" : zoom);
    var lastDate = moment(date).add(1, zoom);
    var events = eventsClass.eventWeekSummer(assignee, date, lastDate);
    var resource_sum;
    var dateString = date.format("YYYY-MM-DD");
    var lastDateString = lastDate.format("YYYY-MM-DD");
    var loadedAllocation = eventsClass.loadedAssignedAllocation(assignee.id, ysy.data.allocations, zoom, dateString, lastDateString);
    var loadedReservations = eventsClass.loadedAssignedAllocation(assignee.id, ysy.data.resourceReservations, zoom, dateString, lastDateString);
    var loaded_sum = loadedAllocation.length + loadedReservations.length;
    const working_hours = assignee.getMaxHoursInterval(dateString, null, zoom);
    if (zoom === "day") {
      if (assignee.resources_sums[dateString] > 0) {
        resource_sum = true;
      }
    } else {
      resource_sum = eventsClass.resourcesAnyInInterval(assignee.resources_sums, date, lastDate);
    }
    if (events || resource_sum || loaded_sum) {
      eventsClass.clickPack = {
        events: events
      };
      if (resource_sum) eventsClass.loadOtherAllocations(assignee, date, lastDate, eventsClass.clickPack);
      var taskPos = $(event.target).offset();
      var eventData = {
        clientX: event.clientX,
        clientY: event.clientY,
        top: taskPos.top + gantt.config.row_height
      };
      eventsClass.show(eventData, events, resource_sum, working_hours);
      if (loaded_sum) {
        eventsClass.updateTooltip(loadedAllocation, loadedReservations);
      }
    } else {
      eventsClass.fireThrough(event);
    }
  },
  fireThrough: function (event) {
    if (!this.$background) {
      this.$background = $("#gantt_cont").find(".gantt_task_bg");
    }
    var newEvent = new MouseEvent(event.type, event);
    this.$background[0].dispatchEvent(newEvent);
  },
  //#####################################################################################
  // functions for loading allocations of non-loaded issues (ex. from another project)
  loadOtherAllocations: function (assignee, firstDate, lastDate, clickPack) {
    var skippedIds = [];
    var issues = ysy.data.issues.getArray();
    for (var i = 0; i < issues.length; i++) {
      skippedIds.push(issues[i].id);
    }
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.otherAllocations, {
          except_issue_ids: skippedIds,
          user_id: assignee.id,
          from: firstDate.format("YYYY-MM-DD"),
          to: lastDate.subtract(1, "day").format("YYYY-MM-DD")
        },
        function (data) {
          var eventsClass = ysy.pro.resource.events;
          eventsClass._handleOtherAllocationsData.call(eventsClass, data, clickPack);
        },
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    );
  },
  loadedAssignedAllocation: function (assignee, entityList, zoom, firstDate, lastDate) {
    if (!entityList) return [];
    var assignedIssues = [];
    var entityArray = entityList.getArray();
    for (var j = 0; j < entityArray.length; j++) {
      var entity = entityArray[j];
      var entityData = entity;
      if (entity.issue) {
        entityData = entity.issue;
      }
      if (entityData.assigned_to_id !== assignee) continue;
      if (zoom === "day") {
        if (entity.allocPack.allocations[firstDate]) {
          var resources = entity.allocPack.allocations[firstDate];
          if (resources > 0) {
            assignedIssues.push({
              id: entityData.id,
              name: entityData.name,
              hours: parseFloat(ysy.pro.resource.roundTo1(resources))
            });
          }
        }
      } else {
        var entitySum = 0;
        for (var resourcesDate in entity.allocPack.allocations) {
          if (resourcesDate >= firstDate && resourcesDate < lastDate) {
            entitySum = entitySum + entity.allocPack.allocations[resourcesDate];
          }
        }
        if (entitySum > 0) {
          assignedIssues.push({
            id: entityData.id,
            name: entityData.name,
            hours: parseFloat(ysy.pro.resource.roundTo1(entitySum))
          });
        }
      }
    }
    return assignedIssues;
  },
  _handleOtherAllocationsData: function (data, clickPack) {
    if (clickPack.prevented) return;
    // if (this.$target.is(":hidden")) return;
    var allocations = data.easy_resources_allocations;
    var reservations = data.easy_reservations_allocations;
    if (!data || !allocations) return;
    this.updateTooltip(allocations, reservations);
  },
  //#####################################################################################
  // functions for handling holidays, meetings and vacations
  constructEventData: function (date, events) {
    var eventsCopy = [];
    var eventsLabels = ysy.settings.labels.eventTypes;
    for (var i = 0; i < events.length; i++) {
      var event = events[i];
      var copiedEvent = {
        name: event.name,
        type: eventsLabels[event.type] || eventsLabels.genericEvent,
        hours: event.hours === undefined ? undefined : ysy.pro.resource.roundTo1(event.hours),
        user: event.original_user_name
      };
      eventsCopy.push(copiedEvent);
    }
    return {
      date: date.format(gantt.config.date_format),
      events: eventsCopy
    };
  },
  constructEventMergie: function (mergie) {
    var eventsLabels = ysy.settings.labels.eventTypes;
    $.extend(mergie, {
      date: mergie.from.format(gantt.config.date_format) + " - " + mergie.to.format(gantt.config.date_format),
      events: [{
        name: mergie.name,
        type: eventsLabels[mergie.type] || eventsLabels.genericEvent,
        hours: mergie.hours === undefined ? undefined : ysy.pro.resource.roundTo1(mergie.hours),
        user: mergie.original_user_name
      }]
    });
  },
  eventWeekSummerSimple: function (assignee, firstDate, lastDate) {
    if (ysy.settings.zoom.zoom === "day") {
      var dateString = firstDate.format("YYYY-MM-DD");
      var events = assignee.getEvents(dateString);
      if (!events) return null;
      return [this.constructEventData(firstDate, events)];
    } else {
      var allEvents = [];
      var mover = moment(firstDate);
      while (mover.isBefore(lastDate)) {
        dateString = mover.format("YYYY-MM-DD");
        events = assignee.getEvents(dateString);
        if (events) {
          allEvents.push(this.constructEventData(mover, events));
        }
        mover.add(1, "day");
      }
      return allEvents;
    }
  },
  eventWeekSummer: function (assignee, firstDate, lastDate) {
    if (ysy.settings.zoom.zoom === "day") {
      var dateString = firstDate.format("YYYY-MM-DD");
      var events = assignee.getEvents(dateString);
      if (!events) return null;
      return [this.constructEventData(firstDate, events)];
    } else {
      var allEvents = [];
      var mover = moment(firstDate);
      while (mover.isBefore(lastDate)) {
        dateString = mover.format("YYYY-MM-DD");
        events = assignee.getEvents(dateString);
        if (events) {
          allEvents.push({
            date: moment(mover),
            events: events
          });
        }
        mover.add(1, "day");
      }
      allEvents = this.mergeAndConstructEvents(allEvents);
      if (allEvents.length === 0) return null;
      return allEvents;
    }
  },
  mergeAndConstructEvents: function (allEvents) {
    var allConstructed = [];
    var mergies = {};
    var previousEvents = [];
    var previousDate;
    for (var i = 0; i < allEvents.length; i++) {
      var eventsPack = allEvents[i];
      if (!eventsPack.events) continue;
      var copyEvent = [];
      for (var j = 0; j < eventsPack.events.length; j++) {
        var event = eventsPack.events[j];
        var specieKey = event.name + "_" + event.type + "_" + event.hours;
        if (event.original_user_name) {
          specieKey += "_" + event.original_user_name;
        }
        if (mergies[specieKey]) {
          var mergie = mergies[specieKey];
          mergie.to = eventsPack.date;
          mergie.hours += event.hours;
        } else {
          var merged = false;
          if (previousDate && previousDate.diff(eventsPack.date, "days") === -1) {
            for (var k = 0; k < previousEvents.length; k++) {
              var previousEvent = previousEvents[k];
              var previousKey = previousEvent.name + "_" + previousEvent.type + "_" + previousEvent.hours;
              if (specieKey === previousKey) {
                previousEvents.splice(k, 1);
                k--;
                mergie = {
                  from: previousDate,
                  to: eventsPack.date,
                  name: event.name,
                  type: event.type,
                  hours: event.hours + previousEvent.hours,
                  user: event.original_user_name
                };
                mergies[specieKey] = mergie;
                merged = true;
              }
            }
          }
          if (!merged) {
            copyEvent.push(event);
          } else {
            allConstructed.push(mergie);
          }
        }
      }
      if (previousEvents && previousEvents.length && previousDate) {
        allConstructed.push(this.constructEventData(previousDate, previousEvents));
      }
      previousEvents = copyEvent;
      previousDate = eventsPack.date;
    }
    if (previousEvents && previousEvents.length) {
      allConstructed.push(this.constructEventData(previousDate, previousEvents));
    }
    for (var key in mergies) {
      if (!mergies.hasOwnProperty(key)) continue;
      this.constructEventMergie(mergies[key]);
    }
    return allConstructed;
  },
  resourcesAnyInInterval: function (resources_sums, from, to) {
    var mover = moment(from);
    while (mover.isBefore(to)) {
      if (resources_sums[mover.format("YYYY-MM-DD")]) return true;
      mover.add(1, "day");
    }
    return false;
  }
});
