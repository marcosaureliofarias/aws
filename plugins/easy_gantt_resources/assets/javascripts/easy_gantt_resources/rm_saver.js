window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.saver = ysy.pro.resource.saver || {};
EasyGem.extend(ysy.pro.resource.saver, {
  temp: {},
  save: function (successCallback, failCallback) {
    var self = this;
    this.temp = {
      successCallback: successCallback,
      failCallback: failCallback,
      fails: 0,
      failMessages: [],
      successes: 0,
      requests: 0
    };
    var issueAllocationsList = ysy.data.allocations.getArray();
    var issues = ysy.data.issues;
    var packet = [];
    var allocators = [];
    for (var i = 0; i < issueAllocationsList.length; i++) {
      var issueAllocations = issueAllocationsList[i];
      var issue = issues.getByID(issueAllocations.id);
      if (!issue) continue;
      if (!issue.start_date && !issue.end_date) continue; // issues with missing start_date and end_date cannot save
      if (!issueAllocations._changed) continue;
      // issueAllocations is changed if they have to be reloaded after first load
      if (!issueAllocations.allocatable()) continue;
      // do not send allocations for unassigned and closed
      if (issueAllocations._oldAllocator) {
        allocators.push({
          issue_id: issue.id,
          // max_allocation: issueAllocations.max_allocation,
          allocator: issueAllocations.allocator
        });
        issueAllocations._oldAllocator = null;
      }
      var allocPac = issueAllocations.allocPack;
      // var resources = ysy.pro.resource.allocationsToResources(issueAllocations.allocPack,false);
      var allocations = allocPac.allocations;
      var dayTypes = allocPac.types;
      for (var date in allocations) {
        if (!allocations.hasOwnProperty(date)) continue;
        var issueAllocationData = {
          issue_id: issue.id,
          user_id: issue.assigned_to_id,
          hours: allocations[date],
          date: date,
          custom: dayTypes[date] === "fixed"
        };
        packet.push(issueAllocationData);
      }
    }
    if (ysy.settings.reservationEnabled) {
      ysy.pro.resource.reservations.save();
    }
    if (packet.length > 0 || allocators.length > 0) {
      this.temp.requests++;
      ysy.gateway.polymorficPut(
          ysy.settings.paths.updateResourceUrl,
          null,
          {resources: packet, allocators: allocators},
          this.onSuccess,
          function (response) {
            var messages = [];
            try {
              var json = JSON.parse(response.responseText);
            } catch (e) {
              if (response.responseText === "") return failCallback([response.statusText]);
              return failCallback([response.responseText]);
            }
            var errors = json.errors;
            if (!errors) {
              return failCallback([response.responseText]);
            }
            if (errors.length === 1 && response.status === 403) return failCallback([errors[0]])
            var issuesErrors = {};
            for (var i = 0; i < errors.length; i++) {
              var error = errors[i];
              if (!error) continue;
              if (!issuesErrors[error.issue_id]) issuesErrors[error.issue_id] = [];
              issuesErrors[error.issue_id].push(error);
            }
            var ids = Object.getOwnPropertyNames(issuesErrors);
            var template = ysy.view.templates.resourceSaveErrors;
            var assignees = ysy.data.assignees;
            for (i = 0; i < ids.length; i++) {
              var issueErrors = issuesErrors[ids[i]];
              var allocations = [];
              var firstError = issueErrors[0];
              var reason = firstError.reason || "Unknown reason";
              var assignee = assignees.getByID(firstError.user_id);
              var issue = issues.getByID(firstError.issue_id);
              for (var j = 0; j < Math.min(issueErrors.length, 11); j++) {
                allocations.push(issueErrors[j].hours);
              }
              if (issueErrors.length > 11) {
                allocations.push("...");
              }
              var message = Mustache.render(template, {
                name: issue ? issue.name : ("#" + firstError.issue_id),
                allocations: allocations,
                assignee: (assignee ? assignee.name : "Unassigned"),
                reason: reason
              });
              messages.push(message);
            }
            self.onFail(messages);
          }
      );
    }
    return this.finishSaving();
  },
  startRequest: function () {
    ysy.pro.resource.saver.temp.requests++;
  },
  onSuccess: function () {
    var temp = ysy.pro.resource.saver.temp;
    temp.successes++;
    ysy.pro.resource.saver.finishSaving();
  },
  onFail: function (messages) {
    var temp = ysy.pro.resource.saver.temp;
    temp.fails++;
    temp.failMessages = temp.failMessages.concat(messages);
    ysy.pro.resource.saver.finishSaving();
  },

  finishSaving: function () {
    var temp = ysy.pro.resource.saver.temp;
    if (temp.successes + temp.fails !== temp.requests) return;
    if (temp.fails > 0) return temp.failCallback(temp.failMessages);
    return temp.successCallback();
  }
});
