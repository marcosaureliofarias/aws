EasyCalendar.manager.registerPlugin("toolModal", function (instance) {
  var scheduler = instance.scheduler;
  scheduler._click.dhx_cal_data = function (e) {
    //in case of touch disable click processing
    if (scheduler._ignore_next_click) {
      if (e.preventDefault)
        e.preventDefault();
      e.cancelBubble = true;
      scheduler._ignore_next_click = false;
      return false;
    }
    var trg = e.target;
    var id = scheduler._locate_event(trg);

    if (!id) {
      scheduler.callEvent("onEmptyClick", [scheduler.getActionData(e).date, e]);
    } else {
      if (!scheduler.callEvent("onClick", [id, e])) return;
      if (scheduler._mode !== "year") {
        scheduler.openToolModal(id);
      }
    }
  };
  scheduler.openToolModal = function (id) {
    var event = scheduler.getEvent(id);
    if (event._isPrivate) return;
    if (event._isGlobalEvent) return;
    if (event._isMeeting) {
      EasyVue && EasyVue.showModal("meeting", event.realId);
    } else if (event.type === 'allocation') {
      // open task modal
      scheduler.main.taskModal.openTaskModal(event.issue_id, event);
    } else if (event.type === "ical_event") {
      // open modal from templates
      const actions = scheduler.modalActions(event);
      EasyVue && EasyVue.showModal(event.type, event.eventId, { actions });
      return;
    } else {
      const actions = scheduler.modalActions(event);
      EasyVue && EasyVue.showModal(event.type, event.realId, { actions });
      return;
    }
    // if want to decorate
    scheduler.callEvent('onAfterToolModalOpen', [id, event]);
  };
  scheduler.showModalFromTemplates = function (event) {
    var header = scheduler.templates.toolmodal_event_header(event) + this.toolModalIcons(event);
    var content = '<div class="easy-calendar__event-modal">'
        + scheduler.templates.selected_event_text(event)
        + '</div>';
    var modalClass = scheduler.modal;
    modalClass.showModal(content, 800, header);
    scheduler.initToolModalIcons(event.id);
  };
  scheduler.modalActions = function (event) {
    let actions = [];
    const nonClosingActions = ["icon_delete_further"];
    const confirmedActions = ["icon_delete_further", "icon_delete"];
    const iconTypes = event.readonly ? "icons_readonly" : "icons_editable";
    let icons = this.config[iconTypes + "_" + event.type + "_vue"] || this.config[iconTypes];
    for (var i = 0; i < icons.length; i++) {
      const mask = icons[i];
      let func = scheduler._click.buttons[mask.replace("icon_", "")];
      actions.push({
        name: this.locale.labels[mask],
        func: func,
        params: event.id,
        closeAfterEvent: !nonClosingActions.includes(mask),
        needConfirm: confirmedActions.includes(mask)
      });
    }
    return actions
  };
   scheduler.toolModalIcons = function (event) {
    var ariaAttr;
    var icon_types = event.readonly ? "icons_readonly" : "icons_editable";
    var icons = this.config[icon_types + "_" + event.type] || this.config[icon_types];
    if (!event.deletable) {
      var icons_deletable = this.config.icons_deletable;
      icons = icons.filter(function (icon) {
        return icons_deletable.indexOf(icon) === -1;
      });
    }
    var icons_str = "<div class='easy-calendar__event-icons-wrapper'><ul class='easy-calendar__event-icons'>";
    for (var i = 0; i < icons.length; i++) {
      var icon = icons[i];
      ariaAttr = this._waiAria.eventMenuAttrString(icon);
      icons_str += "<li><a href='javascript:void(0)' class='dhx_menu_icon " + icon + this.templates.icon_class(icon) + " easy-calendar__event-icon' title='" + this.locale.labels[icon] + "'" + ariaAttr + "><span class='tooltip'>" + this.locale.labels[icon] + "</span></a></li>";
    }
    return icons_str + "</ul></div>";
  };
  /**
   * @param {string|int} id
   * @param [modalClass]
   */
  scheduler.initToolModalIcons = function (id, modalClass) {
    modalClass = modalClass || scheduler.modal;
    modalClass.$modal.parent().find(".dhx_menu_icon").on("click", function () {
      var mask = scheduler._getClassName(this);
      scheduler._click.buttons[mask.split(" ")[1].replace("icon_", "")](id);
      modalClass.close();
    });
  };

  scheduler.updateEventToolModal = function (id, event) {
    if (event._isEasyAttendance) scheduler.addAttendanceModalButtons(event);
  };
  scheduler.showMeetingInfoModal = function (event) {
    var event = event || scheduler.getEvent(id);
    var url = scheduler.main.settings.paths.meetingModals.replace("__entityId", event.realId);
    $.get(url).done(function (html) {
      var modalClass = scheduler.modal;
      var header = !!event.text ? event.text : scheduler.main.settings.labels.entityTitle.meeting;
      modalClass.showModal(html, "800px", header + scheduler.main.scheduler.toolModalIcons(event));
      modalClass.$modal.addClass("easy-calendar__event-modal");
      scheduler.main.scheduler.initToolModalIcons(event.id);
      var currentAssigneeName = scheduler.main.assigneeData.getCurrentUser().name;
      scheduler.addMeetingModalButtons(event, html.match(new RegExp("positive\\W+" + currentAssigneeName)));
    });
  };
  scheduler.addMeetingModalButtons = function (event, accepted) {
    if (event.user_ids.indexOf(scheduler.main.assigneeData.currentId) <= -1) return;
    var modalClass = scheduler.modal;
    var currentUserId = scheduler.main.assigneeData.currentId;
    var path = scheduler.main.settings.paths.meetingModals;
    var buttons = [];
    buttons.push(
      {
        text: I18n.meetingAccept,
        click: function () {
          $.ajax({url: path.replace("__entityId", event.realId) + "/accept.json", method: "POST"});
          if (event._isRecurring) {
            easyScheduler.eventBus.main.loader.reload();
          } else {
            event.confirmed = true;
          }
          modalClass.close();
        },
        class: 'button-positive icon icon-checked',
        disabled: accepted
      }
    );
    buttons.push(
      {
        text: I18n.meetingDecline,
        click: function () {
          $.ajax({url: path.replace("__entityId", event.realId) + "/decline.json", method: "POST"});
          modalClass.close();
          event.user_ids = event.user_ids.filter(function (userId) {
            return userId !== currentUserId;
          });
        },
        class: 'button-negative icon icon-false'
      }
    );
    buttons.push(
      {
        text: I18n.buttonCancel,
        click: function () {
          modalClass.close();
        }, 'class': 'button'
      }
    );
    modalClass.$modal.dialog('option', {buttons: buttons});
  };
  scheduler.addAttendanceModalButtons = function (event) {
    var modalClass = scheduler.modal;
    var url = scheduler.main.settings.paths.easy_attendance_approval_save_path;
    var buttons = [];
    if (event.approvable) {
      buttons.push(
        {
          text: scheduler.locale.labels.button_approve,
          click: function () {
            $.ajax({url: url, data: {approve: 1, ids: [event.realId]}, method: 'POST', dataType: 'json'});
            event.approvable = false;
            event.confirmed = true;
            modalClass.close();
          },
          class: 'button-positive icon icon-checked',
        }
      );
      buttons.push(
        {
          text: scheduler.locale.labels.button_reject,
          click: function () {
            $.ajax({url: url, data: {approve: 0, ids: [event.realId]}, method: 'POST', dataType: 'json'});
            event.approvable = false;
            event.confirmed = false;
            modalClass.close();
          }, class: 'button-negative icon icon-false'
        }
      );
    }
     buttons.push(
        {
          text: scheduler.locale.labels.button_attendance_overview,
          click: function () {
           $.ajax(`${window.urlPrefix}/easy_attendances/approval?user_ids[]=${event.user_ids[0]}`);
           modalClass.close();
          },
          class: 'button-positive',
        }
      );
    buttons.push(
      {
        text: I18n.buttonCancel,
        click: function () {
          modalClass.close();
        }, 'class': 'button'
      }
    );

    modalClass.$modal.dialog('option', { buttons: buttons });
  }
});
