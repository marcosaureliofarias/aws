(function () {
  /**
   *
   * @param {CalendarMain} main
   * @constructor
   */
  function LogTime(main) {
    this.main = main;
  }

  /**
   * rewrites original click action on modal submit button to submit form as JSON
   */
  LogTime.prototype.initFormSubmit = function (allocation, task) {
    var $modal = $('#ajax-modal');
    this.main.scheduler.modal.$modal = $modal;
    var modalClass = this.main.scheduler.modal;
    var self = this;
    $modal.on("time_entry_form_loaded", function () {
      var $renderedModal = $('#ajax-modal');
      var $form = $renderedModal.find('form:first');
      $form.off("submit").on("submit", function () {
        var formData = $form.serializeArray();
        $.ajax($form.attr('action') + '.json', {method: 'POST', data: formData})
          .done(function (data) {
            $renderedModal.dialog('close');
            var hours = data.time_entry.hours;
            task.spent_hours = task.spent_hours + hours;
            self.main.tasksView.refreshAll();
            if (!allocation.end_date || !allocation.start_date) return;
            var allocHours = (allocation.end_date - allocation.start_date) / 3600000;
            if (allocHours <= hours) {
              self.main.scheduler.deleteEvent(allocation.id);
            } else {
              allocation.start_date.setTime(allocation.start_date.getTime() + hours * 3600000);
              self.main.scheduler.event_updated(allocation);
              self.main.scheduler.callEvent("onEventChanged", [allocation.id, allocation]);
            }
          })
          .fail(function (response) {
            if (response.responseJSON) {
              var messages = response.responseJSON.errors;
              modalClass.showFlash(messages.join('<br>'), "error");
            }
          });
      return false;
      });
    });
    $modal.trigger('time_entry_form_loaded');
  }

  /**
   * @memberOf LogTime
   * @param allocation
   */
  LogTime.prototype.openForm = function (allocation) {
    var task;
    var entryHours;
    var entryStartDate;
    if (allocation.issue_id){
      task = this.main.taskData.getTaskById(allocation.issue_id, 'issues');
      entryHours = (allocation.end_date - allocation.start_date) / 3600000;
      entryStartDate = allocation.start_date;
    } else {
      task = this.main.taskData.getTaskById(allocation, 'issues');
      entryHours = 0;
      entryStartDate = this.main.scheduler._currentDate();
    }

    if (!task) return;
    var self = this;

    var url = this.main.settings.paths.timelogNewPath + "&" + this.toUrlParams({
      'issue_id': task.id,
      'time_entry[user_id]': self.main.assigneeData.currentId,
      'time_entry[hours]': entryHours,
      'time_entry[spent_on]': entryStartDate
    });
    $.ajax(url).done(function () {
      self.initFormSubmit(allocation,task);

    });
  };
  LogTime.prototype.toUrlParams = function (map) {
    return Object.keys(map).map(function (key) {
      return key + "=" + map[key]
    }).join("&");
  };
  EasyCalendar.LogTime = LogTime;
})();