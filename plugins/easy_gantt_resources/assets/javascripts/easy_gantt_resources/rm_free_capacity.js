window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {freeCapacity: "freeCapacity"});
ysy.pro.resource.freeCapacity = ysy.pro.resource.freeCapacity || {};
EasyGem.extend(ysy.pro.resource.freeCapacity, {
  patch: function () {
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    const sett = ysy.settings.resource.buttons;
    sett.showFreeCapacity = JSON.parse(ysy.data.storage.getPersistentData('showFreeCapacity'));
    ysy.pro.toolPanel.registerButton({
      id: "rm_free_capacity",
      bind: function () {
        this.model = ysy.settings.resource;
        this.buttons = this.model.buttons;
        if (this.buttons.showFreeCapacity) {
          this.model.setSilent({freeCapacity: !this.model.freeCapacity});
          this.model._fireChanges(this, "free capacity");
        }
      },
      func: function () {
        this.buttons.showFreeCapacity = !this.buttons.showFreeCapacity;
        ysy.data.storage.savePersistentData('showFreeCapacity', this.buttons.showFreeCapacity);
        this.model.setSilent({freeCapacity: !this.model.freeCapacity});
        this.model._fireChanges(this, "free capacity");
      },
      isOn: function () {
        return this.model.freeCapacity;
      },
      isHidden: function () {
        return !this.model.open;
      }
    });
  },
  assignee_day_renderer: function (task, assignee, allocPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var ganttLimits = resourceClass.freeCapacity.getGanttLimits();
    var unit = "day";
    var mover = ganttLimits.start_date.startOf(unit);
    var maxDate = ganttLimits.end_date.startOf(unit).add(1, unit);
    while (mover.isBefore(maxDate)) {
      var allodate = mover.format("YYYY-MM-DD");
      var allocation = allocPack.allocations[allodate] || 0;
      var maxHours = assignee.getMaxHours(allodate, mover);
      allocation = maxHours - allocation;

      resourceClass.assignee_one_day_renderer.call(this, allodate, mover, maxHours, allocation, assignee.getEvents(allodate), allocPack.types[allodate], canvasList);

      mover.add(1, "days");
    }
  },
  assignee_week_renderer: function (task, assignee, allocationsPack, canvasList) {
    var resourceClass = ysy.pro.resource;
    var unit = ysy.settings.zoom.zoom;
    var summerPack = resourceClass._weekAllocationSummer(allocationsPack, unit, this._min_date, this._max_date, assignee);
    var weekAllocations = summerPack.allocations;
    var weekTypes = summerPack.types;
    var weekEvents = summerPack.events;
    var ganttLimits = resourceClass.freeCapacity.getGanttLimits();
    var mover = ganttLimits.start_date.startOf(unit === "week" ? "isoWeek" : unit);
    // var preMover = moment(mover).add(1, unit);
    // var maxDate = moment(ganttLimits.end_date).startOf(isoUnit).add(1, unit);
    while (mover.isBefore(ganttLimits.end_date)) {
      // for (var allodate in weekAllocations) {
      //   if (!weekAllocations.hasOwnProperty(allodate)) continue;
      var allodate = mover.toISOString();
      var maxHours = assignee.getMaxHoursInterval(allodate, mover, unit);
      var allocation = maxHours - (weekAllocations[allodate] || 0);
      resourceClass.assignee_one_week_renderer.call(this, allodate, mover, maxHours, allocation, weekEvents[allodate], weekTypes[allodate], canvasList);
      mover.add(1, unit);
    }
  },
  getGanttLimits: function () {
    var ganttLimits = ysy.data.limits;
    var start_date = ganttLimits.start_date;
    var end_date = ganttLimits.end_date;
    if (ganttLimits.start_date.isBefore(gantt._min_date)) {
      start_date = moment(gantt._min_date);
    } else {
      start_date = moment(ganttLimits.start_date);
    }
    if (ganttLimits.end_date.isAfter(gantt._max_date)) {
      end_date = moment(gantt._max_date);
    } else {
      end_date = moment(ganttLimits.end_date);
    }
    return {start_date: start_date, end_date: end_date};
  }
});
