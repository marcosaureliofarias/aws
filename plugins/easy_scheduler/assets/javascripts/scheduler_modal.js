(function () {
  "use strict";

  const _noop = function () {
  };

  class SchedulerModal {
    /**
     * @param {CalendarMain} main
     * @property {CalendarMain} main
     */
    constructor(main) {
      this.main = main;
      main.eventBus.register("schedulerInited", (scheduler, instance) => {
        this.schedulerInstance = instance;
        this.scheduler = scheduler;

        const availableModalClasses = {};
        availableModalClasses['unspecified'] = CombinedModal;
        availableModalClasses['allocation'] = AllocationModal;
        availableModalClasses['issue'] = NewIssueModal;

        if (main.settings.easyPlugins.easy_calendar) {
          availableModalClasses['meeting'] = MeetingModal
        }
        if (main.settings.easyPlugins.easy_attendances) {
          availableModalClasses['easy_attendance'] = AttendanceModal
        }
        if (main.settings.easyPlugins.easy_entity_activities) {
          availableModalClasses['easy_entity_activity'] = SalesActivityModal
        }
        this.registerAvailableModalsToSchedulerInstance(availableModalClasses);
      });
    }

    registerAvailableModalsToSchedulerInstance(availableModalClasses) {
      for (const key in availableModalClasses) {
        if (availableModalClasses.hasOwnProperty(key)) {
          this.schedulerInstance.modalOptions[key] = new availableModalClasses[key](this.main);
        }
      }
    };
  }

  EasyCalendar.SchedulerModal = SchedulerModal;

  // ###################################################################################################################

  class CombinedModal {
    /**
     * @param {CalendarMain} main
     */
    constructor(main) {
      this.main = main;
    }

    showModal(modalClass) {
      const event = modalClass.event;
      if (!event.all_day) {
        event.all_day = !event._timed;
        if (event.all_day) {
          const delta = (event._length == 1 ? 0 : event._length - 1); // eslint-disable-line eqeqeq
          const dateMillisStart = +new Date(event.start_date);
          const startDate = event.start_date;
          startDate.setDate(startDate.getDate() + delta);
          const dateMillisEnd = +new Date(startDate);
          event.start_date = new Date(dateMillisStart + this.main.scheduler.config.start_time);
          event.end_date = new Date(dateMillisEnd + this.main.scheduler.config.end_time);
        }
      }
      $.ajax({
        url: this.main.settings.paths.modals.newEntityPath,
        dataType: 'json',
        data: { event: event, user_id: this.main.assigneeData.primaryId }
      }).done((html) => {
        modalClass.showModal(html.content, "800px", html.title);
        EntityTabs.init('easy_scheduler_modal_tabs');

        this.afterTabRender(EntityTabs.lastTab(modalClass.$modal.find(EntityTabs.linksContext)), modalClass);
        this.afterTabSwitch(modalClass);
      })
    }

    afterTabSwitch(modalClass) {
      const tabsContext = modalClass.$modal.parent().find(EntityTabs.linksContext);

      tabsContext.on('entity-tabs:after-tab-switch', (e, linksContainer, link/*, id */) => {
        this.afterTabRender($(link).data('tab-id'), modalClass);
      });
    }

    afterTabRender(tabId, modalClass) {
      const $content = modalClass.$modal.find('.' + tabId + '-content');

      if ($content.data("loaded")) {
        this.chooseType(tabId, modalClass, true);
      } else {
        $content.on('easy_entitytab_new_dom', () => {
          if (!modalClass.$modal.is(":visible")) return;
          this.chooseType(tabId, modalClass, false);
        });
      }
    };

    /**
     * @param {string} tabId
     * @param {ModalClass} modalClass
     * @param {boolean} loaded
     */
    chooseType(tabId, modalClass, loaded) {
      this.active = tabId.replace(/tab-/, '');
      const availableModals = this.main.schedulerModal.schedulerInstance.modalOptions;

      if (availableModals[this.active]) {
        availableModals[this.active].init(modalClass, tabId, loaded);
      } else {
        const html = "form for " + this.active;
        modalClass.$modal.find(".easy-calendar__modal_content").html(html);
      }
    };
  }

  // ###################################################################################################################

  class BaseModal {
    /**
     * @abstract
     * @param {CalendarMain} main
     */
    constructor(main) {
      if (new.target === BaseModal) throw new TypeError("Cannot construct Abstract instances directly");
      this.main = main;
    }

    /**
     * @param {ModalClass} modalClass
     * @param {string} [tabId]
     * @param {boolean} [loaded]
     */
    init(modalClass, tabId, loaded) {
      if (loaded) {
        this.initEventForm(modalClass, tabId);
        return;
      }
      this.modalClass = modalClass;
      if (window.initEasyAutocomplete) {
        window.initEasyAutocomplete();
      }
      this.initEventForm(modalClass, tabId);
    }

    /**
     * @param {ModalClass} modalClass
     * @param {string} [tabId]
     */
    initEventForm(modalClass, tabId) {
      modalClass.initEventForm(
        tabId,
        this.onSubmit.bind(this),
        this.eventDeletable(modalClass.event) ? _noop : null // Dont know what this means
      );
    }

    eventDeletable(event) {
      return true
    }

    /**
     * @param {String} tabId
     * @param {ModalClass} modalClass
     * @param {Object} data
     * @description Set tab by data-tab-id end add data to tab ajax url
     */
    setTab(tabId, modalClass, data = {}) {
      const $targetTab = this.modalClass.$modal.find('[data-tab-id="' + tabId + '"]');
      const targetTab = $targetTab.get(0);
      if (!targetTab) return;

      const $content = EntityTabs.panelContainer($targetTab).find(`.${tabId}-content`);
      $content.removeData('loaded');

      const url = new URL(window.location.origin + targetTab.dataset.ajaxUrl);
      for (const key in data) {
        if (data.hasOwnProperty(key)) url.searchParams.set(key, data[key]);
      }

      EntityTabs.showAjaxTab(targetTab, url.href);
    };
  }

  class AllocationModal extends BaseModal {
    showModal(modalClass) {
      const event = modalClass.event;
      this.modalClass = modalClass;
      const url = this.main.settings.paths.modals.allocationModalPath;
      const data = {
        start_time: event.start_date,
        end_time: event.end_date,
        issue_id: event.issue_id,
        user_id: event.assigned_to_id || event.user_id
      };
      if (window.EasyVue && EasyVue.showModal) {
        EasyVue.showModal("allocation", event.id, { data: data });
        return;
      }
      $.ajax({ url: url, data: data }).done((html) => {
        modalClass.showModal(html, "800px", event.text);
        this.init(modalClass);
      });
    }

    onSubmit(data, structured) {
      const event = this.modalClass.event;
      if (!structured.allocation_issue_id) {
        this.modalClass.showFlash(this.main.settings.labels.errorIssueRequired, "error");
        return;
      }
      const issueId = parseInt(structured.allocation_issue_id);
      const task = this.main.taskData.getTaskById(issueId, 'issues');

      if (!task) {
        this.modalClass.showFlash(this.main.settings.labels.errorIsNotInFiltered, "error");
        return;
      }

      if (!task.dateInDuration(new Date(structured.allocation_date))) {
        this.modalClass.showFlash(this.main.settings.labels.errorOutOfTaskLimits, "error");
        return;
      }
      const day = new Date();
      const yesterday = day.setDate(day.getDate() - 1);
      if (new Date(structured.allocation_date) < yesterday) {
        this.modalClass.showFlash(this.main.settings.labels.issueErrors.errorInThePast, "error"); // TODO: translate
        return;
      }
      event.issue_id = issueId;
      event.start_date = new Date(structured.allocation_date + "T" + structured.allocation_start_time);
      event.end_date = new Date(structured.allocation_date + "T" + structured['allocation_end_time']);
      event.user_id = task.assigned_to_id;
      event.assigned_to_id = task.assigned_to_id;
      event.type = "allocation";
      event.text = task.subject;
      this.main.scheduler.event_updated(event, true);
      this.modalClass.close();
    }
  }

  class MeetingModal extends BaseModal {
    eventDeletable(event) {
      return this.main.meetings.canDelete(event);
    }

    initEventForm(modalClass, tabId) {
      modalClass.$modal.find('.' + tabId + '-content').find('h2').remove();
      super.initEventForm(modalClass, tabId);
    }

    showModal(modalClass) {
      const event = modalClass.event;
      this.modalClass = modalClass;
      const url = window.urlPrefix + "/easy_meetings/" + event.realId + "/edit";
      $.ajax({ url: url }).done((html) => {
        const regex = /<h2.*?>(.*?)<\/h2>/;
        const result = regex.exec(html);
        let self = this;
        modalClass.showModal(html.replace(result[0], ""), "800px", event.text);
        const deleteButtons = document.querySelectorAll(".easy-delete-meeting");
        this.init(modalClass);
        deleteButtons.forEach((btn) => {
          btn.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            const url = $(e.target).prop('href');
            self.deleteRecurring(modalClass, url);
          }, { once: true });
        });
      })
    }

    deleteRecurring(modalClass, url) {
      const scheduler = this.main.scheduler;
      const labels = scheduler.locale.labels;
      const self = this;
      scheduler._dhtmlx_confirm(labels.confirm_deleting, labels.title_confirm_deleting, function () {
        $.ajax({ url: url, type: 'DELETE' }).done(() => {
          modalClass.close();
          self.main.loader.reload();
        })
      });
    }

    getSubmitUrl(event) {
      const url = window.urlPrefix + "/easy_meetings";
      if (event && event.realId) {
        return url + '/' + event.realId + '.json';
      } else {
        return url + '.json';
      }
    }

    onSubmit(data) {
      const event = this.modalClass.event;
      const url = this.getSubmitUrl(event);
      $.ajax({
        url: url,
        method: "POST",
        data: data
      }).done((meetingData) => {
        if (meetingData.easy_meeting.easy_is_repeating) {
          this.main.loader.reload();
        }
        meetingData.easy_meeting.id = "easy_meeting-" + meetingData.easy_meeting.id;
        meetingData.easy_meeting.eventType = "meeting";
        meetingData.easy_meeting.confirmed = true;
        meetingData.easy_meeting.allDay = meetingData.easy_meeting.all_day;
        const meeting = this.main.meetings.createMeeting(meetingData.easy_meeting);
        this.modalClass.updateEvent(meeting);
        this.modalClass.close();
      }).fail((response) => {
        if (response.responseJSON) {
          const messages = response.responseJSON.errors;
          this.modalClass.showFlash(messages.join("<br>"), "error");
        }
      });
    }
  }

  class AttendanceModal extends BaseModal {
    eventDeletable(event) {
      return this.main.meetings.canDelete(event);
    }

    initEventForm(modalClass, tabId) {
      if (tabId !== undefined) {
        const $tabContent = modalClass.$modal.find('.' + tabId + '-content');
        $tabContent.find('.form-actions, .clear:last, h3').remove();
        $tabContent.find('form').wrapInner("<div class='easy_scheduler_attendance_center_box'></div>");
      }
      super.initEventForm(modalClass, tabId);
    }

    showModal(modalClass) {
      const event = modalClass.event;
      this.modalClass = modalClass;
      const url = window.urlPrefix + "/easy_attendances/" + event.realId + "/edit.html";
      $.ajax({ url: url }).done((html) => {
        html = html.replace(/<div class="clear">[\s\S]*<\/form>/, "</form>");
        const regex = /<h3.*?>(.*?)<\/h3>/;
        const result = regex.exec(html);
        modalClass.showModal(html.replace(result[0], ""), "800px", event.text);
        modalClass.$modal.find('form').addClass('form-box');
        this.init(modalClass);
      })
    }

    getSubmitUrl(event) {
      const url = window.urlPrefix + "/easy_attendances";
      if (event && event.realId) {
        return url + '/' + event.realId + '.json';
      } else {
        return url + '.json';
      }
    }

    onSubmit(data) {
      const event = this.modalClass.event;
      const url = this.getSubmitUrl(event);

      $.ajax({
        url: url,
        method: "POST",
        data: data
      }).done((attendanceData) => {
        const data = attendanceData.easy_attendance;
        if (data.approval_status === 2) data.confirmed = true; /* :( */
        const attendance = this.createAttendance(data);
        this.modalClass.updateEvent(attendance);
        if (data.factorized_attendances) {
          for (let i = 0; i < data.factorized_attendances.length; i++) {
            const otherData = data.factorized_attendances[i];
            const otherAttendance = this.createAttendance(otherData);
            this.main.scheduler.addEvent(otherAttendance);
            otherAttendance._changed = false;
          }
        }
        this.modalClass.close();
      }).fail((response) => {
        if (response.responseJSON) {
          const messages = response.responseJSON.errors;
          this.modalClass.showFlash(messages.join("<br>"), "error");
        }
      });
    }

    createAttendance(data) {
      EasyGem.extend(data, {
        id: "easy_attendance-" + data.id,
        user_ids: [data.user.id],
        start_time: data.arrival,
        end_time: data.departure,
        eventType: "easy_attendance",
        name: data.easy_attendance_activity.name + (data.description ? " - " + data.description : ""),
        needApprove: data.need_approve
      });
      return this.main.meetings.createMeeting(data);
    }
  }

  class SalesActivityModal extends BaseModal {
    eventDeletable(event) {
      return this.main.meetings.canDelete(event)
    }

    showModal(modalClass) {
      const event = modalClass.event;
      this.modalClass = modalClass;
      const url = this.main.settings.paths.modals.salesActivityModalPath;
      $.ajax({ url: url, data: { id: event.realId } }).done((html) => {
        modalClass.showModal(html, "800px", event.text);
        modalClass.$modal.find('form').addClass('form-box');
        this.init(modalClass);
      })
    }

    getSubmitUrl(event) {
      const url = window.urlPrefix + "/easy_entity_activities";
      if (event && event.realId) {
        return url + '/' + event.realId + '.json';
      } else {
        return url + '.json';
      }
    }

    onSubmit(data, structured) {
      const event = this.modalClass.event;
      const url = this.getSubmitUrl(event);

      const date = structured['easy_entity_activity[start_time][date]'];
      const startTime = date + ' ' + structured['easy_entity_activity[start_time][time]'];
      const endTime = date + ' ' + structured['easy_entity_activity[end_time][time]'];

      data.push({ name: 'easy_entity_activity[start_time]', value: startTime });
      data.push({ name: 'easy_entity_activity[end_time]', value: endTime });

      $.ajax({
        url: url,
        method: "POST",
        data: data
      }).done((salesActivityData) => {
        const data = salesActivityData.easy_entity_activity;
        EasyGem.extend(data, {
          id: "easy_entity_activity-" + data.id,
          eventType: "easy_entity_activity",
          allDay: data.all_day,
          name: data.category.name + ' - ' + data.entity.name,
          realId: data.id,
          _isGenericMeeting: true,
          _isEntityActivity: true,
          user_ids: data.users_attendees.map(function (u) {
            return u.id;
          }),
          editable: data.editable,
          entityId: data.entity.id,
          entityType: data.entity.type,
          readonly: !data.editable
        });
        const meeting = this.main.meetings.createMeeting(data);
        this.modalClass.updateEvent(meeting);
        if (event._withMeeting === true) {
          this.setTab("tab-meeting");
          const $salesForm = this.modalClass.$modal.find('#new_easy_entity_activity').find('.box');
          $salesForm.append(`<p class="warning easy-calendar__modal__warning--scheduler"><i>${this.main.settings.labels.warnings.salesActivityWarning}</i></p>`);
          document.querySelector("#calendar_modal").scrollTop = 0;
        } else {
          this.modalClass.close();
        }
      }).fail((response) => {
        if (response.responseJSON) {
          event._withMeeting = false;
          const messages = response.responseJSON.errors;
          this.modalClass.showFlash(messages.join("<br>"), "error");
        }
      });
    }
  }

  class NewIssueModal extends BaseModal {
    getSubmitUrl(event) {
      return this.main.settings.paths.issues_path + '.json';
    }

    validateTaskForm(structured, event) {
      const errors = [];
      if (!(parseFloat(structured['issue[estimated_hours]']) > 0)) errors.push('estimatedHours');

      const startDate = new Date(structured['issue[start_date]']);
      const endDate = new Date(structured['issue[due_date]']);
      if (!startDate.getDate() && !endDate.getDate()) {
        errors.push('invalidDate');
      } else if (startDate > event.start_date) {
        errors.push('invalidStartDate');
      } else if (endDate < event.start_date) {
        errors.push('invalidDueDate');
      } else if (event.start_date < new Date) {
        errors.push('errorInThePast');
      }

      if (errors.length > 0) {
        const errorLocale = this.main.settings.labels.issueErrors;

        const errorMessages = errors.map(value => errorLocale[value]);
        this.modalClass.showFlash(errorMessages.join('<br />'), "error");
        return false;
      }

      return true;
    }

    createAllocation(issue) {
      const issuesDataPath = this.main.settings.paths.issuesDataPath;
      $.ajax({
        url: issuesDataPath,
        data: { issue_ids: [issue.id] }
      }).done((data) => {
        this.main.loader._handleTasks(data, true);
        const event = this.modalClass.event;
        const task = this.main.taskData.getTaskById(issue.id, 'issues');

        if (!task.dateInDuration(event.start_date)) {
          this.modalClass.showFlash(this.main.settings.labels.errorOutOfTaskLimits, "error"); // TODO: translate
          return;
        }
        if (event.start_date < new Date) {
          this.modalClass.showFlash(this.main.settings.labels.issueErrors.errorInThePast, "error"); // TODO: translate
          return;
        }

        event.issue_id = issue.id;
        event.user_id = task.assigned_to_id;
        event.type = "allocation";
        event.text = task.subject;
        event.deletable = this.main.meetings.canDelete(event);

        // not sure if all are needed
        this.main.scheduler.event_updated(event, true);
        this.main.scheduler.callEvent("onEventChanged", [event.id, event]);
        this.main.eventBus.fireEvent("eventChanged", event);
        this.main.repainter.repaintCalendar(false);

        this.modalClass.close();
      });
    }

    onSubmit(data, structured) {
      const event = this.modalClass.event;
      const url = this.getSubmitUrl(event);

      if (!this.validateTaskForm(structured, event)) return;

      $.ajax({
        url: url,
        method: "POST",
        data: data
      }).done((response) => {
        const issue = response.issue;
        let message = this.main.settings.labels.notice_issue_successfully_created;
        message = message.replace(/__issueSubject__/, `<a target='_blank' href='issues/${issue.id}'>${issue.subject}</a>`);
        showFlashMessage('notice', message);
        this.createAllocation(issue);
      }).fail((response) => {
        if (response.responseJSON) {
          const messages = response.responseJSON.errors;
          this.modalClass.showFlash(messages.join("<br>"), "error");
        }
      });
    }
  }
})();
