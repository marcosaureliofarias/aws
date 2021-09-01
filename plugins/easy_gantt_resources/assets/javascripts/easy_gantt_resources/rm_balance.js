ysy.pro.resource.balance = ysy.pro.resource.balance || {};
ysy.pro.resource.features.balance = "balance";

EasyGem.extend(ysy.pro.resource.balance, {
  patch: function () {
  const self = this;
  ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
  ysy.settings.priorities = ysy.settings.priorities || [];
    ysy.pro.toolPanel.registerButton(
      {
        id: "rm_balance",
        bind: function () {
          this.model = ysy.settings.resource;
          this.buttons = this.model.buttons;
        },
        func: function () {
          this.buttons.balance = !this.model.balance;
          ysy.settings.resource._fireChanges(this, "button");
          self.balanceTasks();
        },
        isOn: function () {
          return this.model.balance;
        },
        isHidden: function () {
          return !this.model.open;
        }
      }
    );
  },
  balanceTasks: async function () {
    const issues = ysy.data.allocations.array;
    const self = this;
    if (!issues) return;
    let allocationStash = 0;
    await this.getPriorities();
    let overage;
    const currentAssignees = ysy.data.assignees.array.filter(el => {
      const assignee = gantt._pull[`a${el.id}`];
      if (assignee) {
        return assignee.$open;
      }
    });
    // make a changes for opened assignees by one
    currentAssignees.forEach(assignee => {
      const weekWorkingHours = assignee.week_hours;
      const events = assignee.events;
      let currentAllocations = [];
      const prioritiesOrder = ysy.settings.priorities;
      let dayWorkHours = {};
      const allocations = issues;
      let sortedAllocations = [];
      let allocSum = {};
      // sort allocations by assignees + by priories + if they are planned
      currentAllocations = self.allocationSort(allocations, sortedAllocations, prioritiesOrder, assignee);
      if (!currentAllocations || !currentAllocations.length) return;
      //  count sum of allocated hours for each day
      currentAllocations.forEach(current => {
        self.setAllocatorToFutureEvenly(current);
        // For deleting history
        ysy.history.clear();
        self.addToHistory(current.issue);
        allocationStash = 0;
        let localAllocations = current.allocPack.allocations;
        if (!Object.keys(localAllocations).length) return;
        let lastDay;
        const countData = {
          localAllocations,
          dayWorkHours,
          weekWorkingHours,
          allocSum,
          overage,
          allocationStash,
          lastDay,
          events
        };
        // Very hard AI counting of hours per day for every issue allocation
        self.countAllocationsHours(countData);
        allocationStash = countData.allocationStash;
        lastDay = countData.lastDay;
        if (allocationStash) {
          const spreadStashData = {
            localAllocations,
            dayWorkHours,
            weekWorkingHours,
            allocSum,
            allocationStash,
            lastDay
          };
          // If there is some extra hours spread it between free capacity
          self.spreadTheStashedHours(spreadStashData);
          localAllocations = spreadStashData.localAllocations;
          allocSum = spreadStashData.allocSum;
          allocationStash = spreadStashData.allocationStash;
        }
        const saveIssueData = {
          localAllocations,
          current,
          sortedAllocations,
          lastDay,
          assignee
        };
        // Applying issue changes
        self.saveIssueChanges(saveIssueData);
        current = saveIssueData.current;
        sortedAllocations = saveIssueData.sortedAllocations;
        //Small change for history to be able to save changes
        ysy.history.openBrack();
        current._changed = true;
        current.balanced = true;
        ysy.history.closeBrack();
        gantt.refreshTask(current.id);
      });
    });
  },
  addToHistory: function (issue) {
    let rev = {
      balanced: issue.balanced,
      _changed: issue._changed
    };
    ysy.history.add(rev, issue);
  },
  setAllocatorToFutureEvenly: function (allocation) {
    if(allocation.allocator === "future_evenly") return;
    if (allocation.resources && Object.keys(allocation.resources).length) {
      Object.keys(allocation.resources).forEach(key => {
        allocation.resources[key].custom = false;
      });
    }
    allocation.set({allocator: "future_evenly", _oldAllocator: allocation.allocator});
    ysy.settings.resource._fireChanges(allocation, "set");
  },
  getPriorities: async function () {
    if (ysy.settings.priorities.length > 0) return;
    let priorities = [];
    const request = new Request(`${window.urlPrefix}/easy_autocompletes/issue_priorities`);
    const response = await fetch(request);
    let data = await response.json();
    await data.forEach(elem => {
      priorities.push(elem.text);
    });
    //Reverse priority to use in sort function in a right order
    ysy.settings.priorities = priorities.reverse();
  },
  assigneeFilter: function (element) {
    const assignee = gantt._pull[`a${this.id}`];
    const project = gantt._pull[`p${this.id}`];

    if ((assignee && !assignee.$open) || (project && project.$open)) return false;
    if (element.issue && element.issue.assigned_to_id === this.id) return true;
  },
  allocationSort: function (allocations, sortedAllocations, prioritiesOrder, assignee) {
    let currentAllocations = [];
    // get allocations for opened user
    allocations.filter(this.assigneeFilter, assignee).forEach(element => {
      sortedAllocations.push(element);
    });
    if (ysy.settings.resource.buttons.hidePlanned){
      sortedAllocations = sortedAllocations.filter(el => !el.issue.is_planned);
    }
    if (sortedAllocations.length > 0 && prioritiesOrder.length > 0) {
      if (sortedAllocations[0].issue.columns.priority) {
        this.prioritySort(sortedAllocations, prioritiesOrder, currentAllocations);
      } else {
        currentAllocations = sortedAllocations;
      }
      // Get allocations just which has end date after today
      currentAllocations = currentAllocations.filter(el => el.issue.end_date >= new Date().setHours(0, 0, 0, 0));
      return currentAllocations;
    }
  },
  countAllocationsHours: function (data) {
    Object.keys(data.localAllocations).sort().forEach(allocKey => {
      this.countWorkingHours(data, allocKey);
      if (!data.allocSum[allocKey] && data.localAllocations[allocKey] <= data.dayWorkHours[allocKey]) {
        // fill the sums array with first allocations hours by days, so the first allocation always has priority and won't change
        data.allocSum[allocKey] = data.localAllocations[allocKey];
      } else {
        data.allocSum[allocKey] = data.allocSum[allocKey] ? data.allocSum[allocKey] : 0;
        // count the extra hours for allocation, overage = (hours from the top allocations + own hours ) - working hours for a day
        data.overage = (data.allocSum[allocKey] + data.localAllocations[allocKey]) - data.dayWorkHours[allocKey];
        data.overage = data.overage > data.localAllocations[allocKey] ? data.localAllocations[allocKey] : data.overage;
        // add hours to get sum of all allocations for a day
        data.allocSum[allocKey] += data.localAllocations[allocKey];
        // if more then free capacity put extra hours into stash
        if (data.allocSum[allocKey] >= data.dayWorkHours[allocKey]) {
          data.allocationStash += data.overage;
          // count how many hours can be left in a day not to exceed max hours capacity
          data.localAllocations[allocKey] = data.dayWorkHours[allocKey] - (data.allocSum[allocKey] - data.localAllocations[allocKey]);
          // can be negative if a free hours > allocated hours so set to zero
          data.localAllocations[allocKey] = data.localAllocations[allocKey] < 0 ? 0 : data.localAllocations[allocKey];
        }
      }
      // need to check bc allocation can ends on day with no working hours
      if (data.dayWorkHours[allocKey] !== 0) {
        // set the last day of current allocation
        data.lastDay = allocKey;
      }
    });
  },
  spreadTheStashedHours: function (data) {
    // set new object to hold the days with a free space
    let freeSpaceDays = {};
    // go through the sum array to set a free space days
    Object.keys(data.allocSum).sort().forEach((allocSumKey) => {
      // last condition is because a day can has a 0 allocated hours so be a free space day
      if (data.allocSum[allocSumKey] < data.dayWorkHours[allocSumKey] && data.localAllocations[allocSumKey] != undefined) {
        freeSpaceDays[allocSumKey] = data.allocSum[allocSumKey];
        // if a day has more then max hours and not a last day leave it for next function
      } else if (data.allocSum[allocSumKey] && data.allocSum[allocSumKey] >= data.dayWorkHours[allocSumKey] && allocSumKey !== data.lastDay){
        return;
        // if no free space put all extra hours to the last day
      } else if(allocSumKey === data.lastDay && !Object.keys(freeSpaceDays).length){
        data.localAllocations[data.lastDay] += data.allocationStash;
        data.allocationStash = 0;
        return;
      }
    });
    // go through free days and spread extra hours between them
    Object.keys(freeSpaceDays).forEach(freeDaysKey => {
      if (data.localAllocations[freeDaysKey] < data.dayWorkHours[freeDaysKey]) {
        let diff = data.dayWorkHours[freeDaysKey] - data.allocSum[freeDaysKey];
        if (data.allocationStash >= diff) {
          data.allocationStash -= diff;
          data.localAllocations[freeDaysKey] += diff;
          data.allocSum[freeDaysKey] += diff;
        }
      }
    });
    // put all other extra hours into the last day
    if (data.allocationStash && data.allocationStash > 0) {
      data.localAllocations[data.lastDay] += data.allocationStash;
    }
  },
  prioritySort: function(sortedAllocations, prioritiesOrder, currentAllocations) {
  const sortedIssue = sortedAllocations.filter(el => el.issue);
    prioritiesOrder.forEach(priority => {
      sortedIssue.forEach(el => {
        if (el.issue.columns.priority && el.issue.columns.priority === priority) {
          currentAllocations.push(el);
        } else {
          return;
        }
      });
    });
  },
  saveIssueChanges: function (data) {
    data.sortedAllocations
      .filter(element => element.issue && element.issue.assigned_to_id === data.assignee.id)
      .sort((a,b) => a.issue.name > b.issue.name)
      // go through all issue allocations and apply changes
      .forEach(element => {
        if (element.issue.name === data.current.issue.name) {
          Object.keys(data.localAllocations).forEach(key => {
            if (!element.issue.resources){
              // create a deep copy of object
              element.issue.resources = JSON.parse(JSON.stringify(element.resources));
            }
            if (!element.resources[key]) {
              element.resources[key] = {};
              element.issue.resources[key] = {};
            }
            if (!element.allocPack.types) {
              element.allocPack.types = {};
            }
            element.allocPack.types[key] = "fixed";
            element.issue.resources[key].hours = data.localAllocations[key];
            element.issue.resources[key].custom = true;
            if (element.resources[data.lastDay] === element.issue.resources[key]) {
              // set a last day as not custom to be able to expand allocation hours for other days
              element.resources[data.lastDay].custom = false;
              element.issue.resources[key].custom = false;
              delete element.allocPack.types[data.lastDay];
            }
          });
          data.current.issue.balanced = true;
          data.current.issue._changed = true;
        }
    });
  },
  countWorkingHours: function (data, allocKey) {
    const date = new Date(allocKey);
    const { events, weekWorkingHours, dayWorkHours } = data;
    const dayEventsHours = (events && events[allocKey]) ? events[allocKey] : [{ hours: 0 }];
    // a day with 0 index is Sunday but we need it to be with index 6.
    let dayIndex = date.getDay() === 0 ? 6: date.getDay() - 1;
    const possibleDayCapacity = weekWorkingHours[dayIndex];
    let eventHours = 0;
    // get event hours for a day
    if (events && dayEventsHours) {
      dayEventsHours.forEach(event => {
        eventHours += event.hours;
      });
    }
    // count capacity for each day according to events as vacations, meeting etc.
    // set amount of possible working hours for a day
    const resultHours = possibleDayCapacity - eventHours;
    dayWorkHours[allocKey] = resultHours < 0 ? 0 : resultHours;
  }
});
