window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  bogusAssignee: {
    getMaxHours: function (idate, mdate) {
      return ysy.data.Assignee.prototype.getMaxHours(idate, mdate);
    }
  },
  /**
   * @typedef {{issue?:ysy.data.Issue,estimated?:number,start_date?:{},end_date?:{},assignee?:ysy.data.Assignee,allocator?:String,resources?:{},today?:String}} Options
   */
  /**
   *
   * @param issueAllocations
   * @param {Options} options
   * @return {{allocations: {}, types: {}}|null}
   */
  calculateAllocations: function (issueAllocations, options) {
    var allocations = {};
    var dates = [];
    var datesToFill = [];
    var maxAllocations = {};
    var maxHours = 0;
    var dayTypes = {};
    var MARGIN = this.MARGIN;
    var max, date;
    var issue = options.issue || issueAllocations.issue;
    var estimated = (typeof(options.estimated) === "number" ? options.estimated : issue.getRestEstimated());
    var start_date = options.start_date || issue._start_date || issue.start_date;
    var end_date = options.end_date || issue._end_date || issue.end_date;
    var assignee = options.assignee || issueAllocations.getAssignee(issue) || this.bogusAssignee;
    var allocator = options.allocator || issueAllocations.allocator || issue.getAllocator();
    var fixedAllocations = options.resources || issueAllocations.resources || {};
    if (!start_date.isValid() || !end_date.isValid() || end_date.isBefore(start_date)) return null;
    if (allocator.substring(0, 7) === "future_") {
      allocator = allocator.substring(7);
      var mover = options.today ? moment(options.today) : moment().startOf("day");
      if (start_date.isBefore(mover)) {
        if (mover.isAfter(end_date)) {
          mover = moment(end_date);
        }
      } else {
        mover = moment(start_date);
      }
    } else {
      mover = moment(start_date);
    }
    var fixedAllocationDates = Object.getOwnPropertyNames(fixedAllocations);
    var startDateString = start_date.format("YYYY-MM-DD");
    var endDateString = end_date.format("YYYY-MM-DD");
    for (var i = 0; i < fixedAllocationDates.length; i++) {
      isodate = fixedAllocationDates[i];
      if(isodate < startDateString || isodate > endDateString) continue;
      dates.push(isodate);
      var issueAllocation = fixedAllocations[isodate];
      if (issueAllocation && issueAllocation.custom) {
        allocations[isodate] = issueAllocation.hours;
        estimated -= issueAllocation.hours;
        dayTypes[isodate] = "fixed";
      }
    }
    while (!mover.isAfter(end_date)) {
      var isodate = mover.format("YYYY-MM-DD");
      dates.push(isodate);
      issueAllocation = fixedAllocations[isodate];
      if (issueAllocation && issueAllocation.custom) {
        mover.add(1, "days");
        continue;
      }
      max = assignee.getMaxHours(isodate, mover);
      maxAllocations[isodate] = max;
      maxHours += max;
      if (max !== 0) {
        datesToFill.push(isodate);
      }
      allocations[isodate] = 0;
      mover.add(1, "days");
    }
    if (fixedAllocationDates.length) {
      dates.sort();
    }

    if (estimated <= MARGIN) return {allocations: allocations, types: dayTypes};

    if (estimated >= maxHours) {
      /** OVERFLOW */
      estimated = this._fullAllocator(estimated, datesToFill, allocations, maxAllocations);

      var overflowDate = this._getOverflowDate(dates, dayTypes, maxAllocations);
      if (!overflowDate) {
        overflowDate = dates[dates.length - 1];
        delete dayTypes[overflowDate];
        maxAllocations[overflowDate] = assignee.getMaxHours(isodate);
      }
      allocations[overflowDate] = (allocations[overflowDate] || 0) + estimated;
      return this.addAllocationTypes(dates, allocations, dayTypes, maxAllocations);
    }

    if (allocator === "evenly") {
      /** EVENLY */
      estimated = this._firstAllocator(estimated, datesToFill, allocations, maxAllocations);
      if (estimated > datesToFill.length) {
        estimated = this._secondAllocator(estimated, datesToFill, allocations, maxAllocations);
      }
      if (estimated !== 0) {
        this._thirdAllocator(estimated, datesToFill, allocations, maxAllocations);
      }
    } else {
      /** FROM_START or FROM_END */
      var fromStart = allocator === "from_start";
      if (maxHours === 0) {
        date = datesToFill[fromStart ? 0 : datesToFill.length - 1];
        delete dayTypes[date];
        allocations[date] += estimated;
      } else {
        estimated = this._gradualAllocator(estimated, datesToFill, allocations, maxAllocations, fromStart);
        if (estimated > 0) {
          allocations[datesToFill[fromStart ? 0 : datesToFill.length - 1]] += estimated;
        }
      }
    }

    return this.addAllocationTypes(dates, allocations, dayTypes, maxAllocations);
  },
  _fullAllocator: function (estimated, dates, allocations, maxAllocations) {
    for (var i = dates.length - 1; i >= 0; i--) {
      estimated -= allocations[dates[i]] = maxAllocations[dates[i]];
    }
    return estimated;
  },
  _firstAllocator: function (estimated, dates, allocations, maxAllocations) {
    var i, optimalHours, date;
    if (this.decimalAllocation) {
      optimalHours = Math.floor(estimated / dates.length * 10) / 10;
    } else {
      optimalHours = Math.floor(estimated / dates.length);
    }
    for (i = dates.length - 1; i >= 0; i--) {
      date = dates[i];
      if (maxAllocations[date] < optimalHours) {
        allocations[date] = maxAllocations[date];
      } else {
        allocations[date] = optimalHours;
      }
      estimated -= allocations[date];
    }
    return estimated;
  },
  _secondAllocator: function (estimated, datesToFill, allocations, maxAllocations) {
    var i, date;
    if (this.decimalAllocation) {
      var optimalHours = Math.floor(estimated / datesToFill.length * 10) / 10;
    } else {
      optimalHours = Math.floor(estimated / datesToFill.length);
    }
    if (optimalHours === 0) return estimated;
    // second allocator - disperse non-allocated time once more (again is possible that some time remain)
    // runs rarely (semi-holidays, meetings and hangovers in duration of issue)
    for (i = 0; i < datesToFill.length; i++) {
      date = datesToFill[i];
      if (maxAllocations[date] <= allocations[date]) continue;
      allocations[date] += optimalHours;
      estimated -= optimalHours;
    }
    return estimated;
  },
  _thirdAllocator: function (estimated, datesToFill, allocations, maxAllocations) {
    var i, date,
        MARGIN = this.MARGIN;
    var step = this.decimalAllocation ? 0.1 : 1;
    while (estimated > MARGIN) {
      for (i = datesToFill.length - 1; i >= 0; i--) {
        date = datesToFill[i];
        if (step > estimated) {
          step = estimated;
        }
        if (maxAllocations[date] <= allocations[date] + step) {
          var oldAllocation = allocations[date];
          allocations[date] = maxAllocations[date];
          estimated -= maxAllocations[date] - oldAllocation;
        } else {
          allocations[date] += step;
          estimated -= step;
        }
        if (estimated === 0) return;
      }
    }
  },
  _gradualAllocator: function (estimated, datesToFill, allocations, maxAllocations, fromStart) {
    var i, date, len = datesToFill.length;
    for (i = 0; i < len; i++) {
      date = datesToFill[fromStart ? i : len - i - 1];
      if (maxAllocations[date] < estimated) {
        allocations[date] = maxAllocations[date];
      } else {
        allocations[date] = estimated;
        return 0;
      }
      estimated -= allocations[date];
    }
    return estimated;
  },
  _getOverflowDate: function (dates, dayTypes, maxAllocations) {
    for (var i = dates.length - 1; i >= 0; i--) {
      if (dayTypes[dates[i]] !== "fixed" && maxAllocations[dates[i]] !== 0) {
        return dates[i];
      }
    }
  },
  addAllocationTypes: function (dates, allocations, dayTypes, maxAllocations) {
    for (var i = 0; i < dates.length; i++) {
      var date = dates[i];
      if (dayTypes[date]) continue;
      if (maxAllocations[date] < allocations[date]) {
        dayTypes[date] = "overAllocation";
      } else if (allocations[date] < 0) {
        dayTypes[date] = "negativeAllocation";
      }
    }
    return {allocations: allocations, types: dayTypes};
  },
  allocationsToFixedResources: function (allocPack) {
    var resources = {};
    var allocations = allocPack.allocations;
    var dayTypes = allocPack.types;
    for (var date in dayTypes) {
      if (!dayTypes.hasOwnProperty(date)) continue;
      if (dayTypes[date] !== "fixed" || allocations[date] === undefined) continue;
      var allocation = allocations[date];
      resources[date] = {hours: allocation, custom: "fixed"};
    }
    return resources;
  },
  resourcesToAllocations: function (issueAllocations) {
    var allocations = {};
    var dayTypes = {};
    var assignee = issueAllocations.getAssignee();
    var estimated = issueAllocations.issue.getRestEstimated();
    var resources = issueAllocations.resources;
    var dates = Object.getOwnPropertyNames(resources);
    for (var i = 0; i < dates.length; i++) {
      var date = dates[i];

      var resource = resources[date];
      allocations[date] = resource.hours;
      estimated -= resource.hours;
      if (resource.custom) {
        dayTypes[date] = "fixed";
      } else if (assignee && assignee.getMaxHours(date) < resource.hours) {
        dayTypes[date] = "overAllocation";
        // } else if (resource.hours < 0) {
        //   dayTypes[date] = "negativeAllocation";
      }
    }
    if (estimated > 0) {
      var end_date = issueAllocations.issue._end_date.format("YYYY-MM-DD");
      if (allocations[end_date] === undefined) {
        allocations[end_date] = estimated;
      } else {
        allocations[end_date] += estimated;
      }
      if (dayTypes[end_date] === "fixed") {
      } else if (assignee && assignee.getMaxHours(date) < allocations[end_date]) {
        dayTypes[end_date] = "overAllocation";
        // } else if (allocations[end_date] < 0) {
        //   dayTypes[end_date] = "negativeAllocation";
      }
    }
    return {allocations: allocations, types: dayTypes};
  },
  pseudoEvenHours: function (issueAllocations, options) {
    var dates = [], max;
    var cappedDates = {};
    var issue = options.issue || issueAllocations.issue;
    var estimated = options.estimated || issue.getRestEstimated();
    var start_date = options.start_date || issue._start_date;
    var end_date = options.end_date || issue._end_date;
    var assignee = options.assignee || issueAllocations.getAssignee(issue);
    var maxHoursPerDay = options.maxHoursPerDay || (assignee && assignee.hours) || 8;
    var fixedAllocations = issueAllocations.resources || {};
    if (start_date.isValid() && end_date.isValid() && +end_date - start_date >= 0) {
      var mover = moment(start_date);
      while (+mover - end_date <= 0) {
        var isodate = mover.format("YYYY-MM-DD");
        dates.push(isodate);
        var issueAllocation = fixedAllocations[isodate];
        if (issueAllocation === undefined || !issueAllocation.custom) {
          max = assignee.getMaxHours(isodate, mover);
          if (max > maxHoursPerDay) max = maxHoursPerDay;
          if (max !== 0) {
            if (!cappedDates[max]) {
              cappedDates[max] = 1;
            } else {
              cappedDates[max]++;
            }
          }
        }
        mover.add(1, "days");
      }
      var hourKey, i;
      var hourKeys = Object.getOwnPropertyNames(cappedDates).map(parseFloat);
      if (hourKeys.length === 0) return maxHoursPerDay;
      hourKeys.sort();
      for (i = hourKeys.length - 2; i >= 0; i--) {
        cappedDates[hourKeys[i]] += cappedDates[hourKeys[i + 1]];
      }
      for (i = 0; i < hourKeys.length; i++) {
        hourKey = hourKeys[i];
        estimated -= hourKey * cappedDates[hourKey];
        if (estimated === 0) {
          return hourKey;
        } else if (estimated < 0) {
          break;
          //return hourKey - estimated / cappedDates[hourKey];
        }
      }
      return Math.min(hourKey + estimated / cappedDates[hourKey], maxHoursPerDay);
    }
    return maxHoursPerDay;
  }
});
