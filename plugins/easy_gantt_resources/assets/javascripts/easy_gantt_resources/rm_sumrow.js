window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {allocationSumRow: "sumRow"});
ysy.pro.resource.sumRow = EasyGem.extend(ysy.pro.resource.sumRow, {
  opened: false,
  patch: function () {
    if (!ysy.settings.showTotalProjectAllocations || ysy.settings.isResourceManagement && ysy.settings.global) return;
    ysy.pro.sumRow.summers.allocations = {
      day: function (date, issue) {
        if (issue._start_date.isAfter(date)) return 0;
        if (issue._end_date.isBefore(date)) return 0;
        var issueAllocations = issue.getAllocations();
        if (!issueAllocations || !issueAllocations.allocations) return 0;
        var allocation = issueAllocations.allocations[date.format("YYYY-MM-DD")];
        if (allocation > 0) return parseFloat(allocation.toFixed(0));
        return 0;
      },
      week: function (first_date, last_date, issue) {
        if (issue._start_date.isAfter(last_date)) return 0;
        if (issue._end_date.isBefore(first_date)) return 0;
        var issueAllocations = issue.getAllocations();
        if (!issueAllocations || !issueAllocations.allocations) return 0;
        var sum = 0;
        var mover = moment(first_date);
        while (mover.isBefore(last_date)) {
          var allocation = issueAllocations.allocations[mover.format("YYYY-MM-DD")];
          if (allocation > 0) sum += allocation;
          mover.add(1, "day");
        }
        return parseFloat(sum.toFixed(0));
      },
      unit: "h",
      title: "Allocations"
    };
    ysy.settings.resource.register(function () {
      if (this.opened !== ysy.settings.resource.open) {
        this.opened = ysy.settings.resource.open;
        if (this.opened) {
          ysy.settings.sumRow.setSummer("allocations");
        } else {
          ysy.settings.sumRow.removeSummer("allocations");
        }
      }
    }, this);
  }
});