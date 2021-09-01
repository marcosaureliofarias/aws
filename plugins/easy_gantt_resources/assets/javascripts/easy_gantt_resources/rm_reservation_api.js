ysy.pro.resource.reservations = ysy.pro.resource.reservations || {};
EasyGem.extend(ysy.pro.resource.reservations, {
  apiPatch: function () {
    ysy.pro.resource.loader._loadReservations = this.load;
  },
  load: function (json) {
    if (!json) return;
    var reservations = ysy.data.resourceReservations;
    var createdReservations = [];
    for (var i = 0; i < json.length; i++) {
      ysy.main._resourcesObjectToFloat(json[i].resources);
      var reservation = new ysy.data.Reservation();
      reservation.init(json[i]);
      reservations.pushSilent(reservation);
      createdReservations.push(reservation);
    }
    this._removeAllocationsFromSums(createdReservations);
    reservations._fireChanges(this, "load");
  },
  save: function () {
    var reservations = ysy.data.resourceReservations.array;
    var saverClass = ysy.pro.resource.saver;
    var deleteIds = [];
    var packs = [];
    for (var i = 0; i < reservations.length; i++) {
      var reservation = reservations[i];
      if (!reservation._changed) continue;
      if (reservation._deleted) {
        if (!reservation._created) {
          deleteIds.push(reservation.id);
        }
        continue;
      }
      var pack = this.preparePack(reservation);
      if (pack) {
        packs.push(pack);
      }
    }

    if (deleteIds.length > 0) {
      saverClass.startRequest();
      $.ajax({
        url: ysy.settings.paths.reservationBulkDestroyUrl,
        method: "DELETE",
        contentType: 'application/json',
        dataType: "text",
        data: JSON.stringify({reservation_ids: deleteIds})
      }).done(saverClass.onSuccess).fail(function (response) {
        // console.log(response);
        saverClass.onFail(["Destroy reservations with ids " + deleteIds + " failed:" + response.status + " " + response.statusText]);
      });
    }
    if (packs.length > 0) {
      saverClass.startRequest();
      $.ajax({
        url: ysy.settings.paths.reservationUpdateOrCreateUrl,
        method: "POST",
        dataType: "json",
        contentType: 'application/json',
        data: JSON.stringify({reservations: packs})
      }).done(function (data) {
        if (data.unsaved && data.unsaved.length) {
          var messages = [];
          // "Update reservation " + names + " failed: " + response.statusText
          data.unsaved.forEach(function (unsaved) {
            reservation = ysy.data.resourceReservations.getByID(unsaved.id);
            var reason = "Update reservation " + (reservation ? reservation.name + " " : "") + "failed";
            if (unsaved.errors) {
              reason += ": ";
              for (var key in unsaved.errors) {
                if (!unsaved.errors.hasOwnProperty(key)) continue;
                reason += key + " " + unsaved.errors[key];
              }
            }
            messages.push(reason);
          });
          saverClass.onFail(messages);
        } else {
          saverClass.onSuccess();
        }
      }).fail(function (response) {
        // console.log(response);
        var names = packs.map(function (pack) {
          return pack.name;
        });
        saverClass.onFail(["Update reservations " + names + " failed: " + response.status + " " + response.statusText]);
      });
    }
  },
  allowedAttributes: ["allocator", "assigned_to_id", "end_date", "estimated_hours", "name", "start_date", "project_id", "description"],
  preparePack: function (reservation) {
    var copy = {};
    var keys = Object.keys(reservation);
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      if (this.allowedAttributes.indexOf(key) === -1) continue;
      copy[key] = reservation[key];
    }
    if (copy.start_date) {
      copy.start_date = copy.start_date.format("YYYY-MM-DD");
    }
    if (copy.end_date) {
      copy.due_date = copy.end_date.format("YYYY-MM-DD");
      delete copy.end_date;
    }
    if (!reservation._created) {
      copy = reservation.getDiff(copy);
      if (!copy) return copy;
      copy.id = reservation.id;
    }
    copy.resources = this.prepareResources(reservation.allocPack);
    return copy;
  },
  prepareResources: function (allocPack) {
    var resources = [];
    var allocations = allocPack.allocations;
    var dates = Object.keys(allocations);
    for (var i = 0; i < dates.length; i++) {
      var date = dates[i];
      resources.push({date: date, hours: allocations[date]});
    }
    return resources;
  },
  loadReservationSums: function (type, assigneeId) {
    var userIds = [];
    this.type = type;
    var sumsType = type === 'onlyReservation' ? 'reservationSums' : 'taskSums';
    if (assigneeId === undefined) {
      var users = ysy.data.assignees.getArray();
      for (var i = 0; i < users.length; i++) {
        userIds.push(users[i].id);
        delete users[i][sumsType];
      }
    } else {
      userIds.push(assigneeId);
      var user = ysy.data.assignees.getByID(assigneeId);
      if (user) delete user[sumsType];
    }
    var bannedIssueIds = [];
    var bannedReservationIds = [];
    var issues = ysy.data.issues.getArray();
    var reservations = ysy.data.resourceReservations.getArray();
    for (i = 0; i < issues.length; i++) {
      if (assigneeId && assigneeId !== issues[i].assigned_to_id) continue;
      if (issues[i].id > 1e12) continue;
      bannedIssueIds.push(issues[i].id);
    }
    for (i = 0; i < reservations.length; i++) {
      if (assigneeId && assigneeId !== reservations[i].assigned_to_id) continue;
      if (reservations[i].id > 1e12) continue;
      bannedReservationIds.push(reservations[i].id);
    }
    var start_date = ysy.data.limits.start_date;
    var end_date = ysy.data.limits.end_date;
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.usersSumsUrl
            .replace(":projectID", ysy.settings.projectID)
            .replace(":variant", this.type)
            .replace(":start", start_date.format("YYYY-MM-DD"))
            .replace(":end", end_date.format("YYYY-MM-DD")),
        {
          user_ids: userIds,
          except_issue_ids: bannedIssueIds,
          except_reservation_ids: bannedReservationIds
        },
        $.proxy(this._handleReservationSumsData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
          //ysy.pro.resource.loader.loading = false;
        }
    );
  },
  _handleReservationSumsData: function (data) {
    var json = data.easy_resource_data;
    this._loadReservationSums(json.users);

    ysy.settings.resource._fireChanges(this, "reservation loaded");
  },
  _loadReservationSums: function (json) {
    if (!json) return;
    var type = this.type;
    var sumsType = type === 'onlyReservation' ? 'reservationSums' : 'taskSums';
    var assignees = ysy.data.assignees;
    for (var i = 0; i < json.length; i++) {
      var user = json[i];
      ysy.main._resourcesStringToFloat(user.resources_sums);
      var assignee = assignees.getByID(user.id);
      if (!assignee) continue;
      assignee.resources_sums = user.resources_sums;
    }
  }
});
