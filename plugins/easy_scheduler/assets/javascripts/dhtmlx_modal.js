EasyCalendar.manager.registerAddOn("scheduler", function (instance) {
  const scheduler = instance.scheduler;
  const modalId = "calendar_modal";
  /** @typedef {{getHtml:Function,bindEvents:Function,onSubmit:Function,onDelete:Function}} ModalOptions */
  /** @type {Object.<String,ModalOptions>} */
  instance.modalOptions = {};
  scheduler._click.dhx_cal_header = function (e) {
    const target = e.target;
    if (!target.closest(".dhx_scale_bar")) return;
    const link = target.tagName === "A" ? target : target.querySelector("a");
    const dateMillis = +new Date(link.getAttribute("jump_to"));

    const base = {};
    base.all_day = true;
    base.start_date = new Date(dateMillis + scheduler.config.start_time);
    base.end_date = new Date(dateMillis + scheduler.config.end_time);
    scheduler.addEventNow(base);
  };
  scheduler.showLightbox = function (id) {
    if (!id) return;
    if (!this.callEvent("onBeforeLightbox", [id])) {
      if (this._new_event) this._new_event = null;
      return;
    }
    modalClass.eventId = id;
    const event = scheduler.getEvent(id);
    modalClass.event = event;
    const eventType = event.type || 'unspecified';
    const entityModal = instance.modalOptions[eventType];
    if (!entityModal) {
      modalClass.deleteEvent();
    }
    entityModal.showModal(modalClass);
  };
  /** @namespace ModalClass */
  const modalClass = {
    $modal: null,
    event: null,

    showModal: function (html, width, title) {
      $("#calendar_modal").remove();
      this.$modal = this._prepareEmptyModal();
      window.showModal(modalId, width || "90%");
      if (typeof title !== "undefined") {
        modalClass.$modal.parent().find(".ui-dialog-title").html(title);
      }
      this.$modal.parent().show();
      this.$modal.html(html);
      const self = this;
      $(".ui-widget-overlay").on("click", self.close.bind(self));
      this.$modal.off('dialogclose').on('dialogclose', function () {
        if (self.event && !self.event.type) {
          self.deleteEvent();
        }
        $(".ui-widget-overlay").off("click");
      });
    },
    _prepareEmptyModal: function () {
      const $modal = $("<div id=" + modalId + ">");
      $("body").append($modal);
      return $modal;
    },
    /**
     * @param {string} tabId
     * @param {Function} onSubmit
     * @param {Function|null} onDelete
     */
    initEventForm: function (tabId, onSubmit, onDelete) {
      const $modal = this.$modal;
      const event = this.event;

      const $form = tabId ? $modal.find('.' + tabId + '-content').find("form") : $modal.find("form");

      const submitFunc = function () {

        // update all CKEditor elements to serialize form properly with latest data
        // temporary fix, all new entities will be replaced with new vue modal
        if (window.CKEDITOR && window.CKEDITOR.instances) {
          Object.values(window.CKEDITOR.instances).forEach(
            instance => instance.updateElement && instance.updateElement()
          );
        }

        const data = $form.serializeArray();
        const structured = {};
        for (let i = 0; i < data.length; i++) {
          structured[data[i].name] = data[i].value;
        }
        onSubmit(data, structured);
        scheduler._edit_stop_event(event, true);
        // $modal.dialog("close");
        return false;
      };
      $form.off("submit.modal").on("submit.modal", submitFunc);
      if (onDelete) {
        $form.off("delete.modal").on("delete.modal", onDelete);
      }

      this.addModalButtons(!!onDelete, !event.type, tabId);

      scheduler.callEvent("onLightbox", [event.id]);
    },
    /**
     * @param {boolean} withDelete
     * @param {boolean} fastDelete
     * @param {string} tabId
     */
    addModalButtons: function (withDelete, fastDelete, tabId) {
      const self = this;
      const $modal = modalClass.$modal;
      const $form = tabId ? $modal.find('.' + tabId + '-content').find("form") : $modal.find("form");

      this.prevented = false;
      const buttons = [];
      buttons.push(
        {
          id: "calendar_modal_button_save",
          class: "button-1 button-positive easy-calendar__modal-button",
          text: scheduler.locale.labels.icon_save,
          click: function () {
            if (self.prevented) return;
            self.setDisabledButtons(true);
            $form.submit();
          }
        }
      );
      if (withDelete && !fastDelete) {
        buttons.push({
          id: "calendar_modal_button_delete",
          class: "button-1 button-negative easy-calendar__modal-button",
          text: scheduler.locale.labels.icon_delete,
          click: function () {
            if (self.prevented) return;
            self.prevented = true;
            const c = scheduler.locale.labels.confirm_deleting;
            scheduler._dhtmlx_confirm(c, scheduler.locale.labels.title_confirm_deleting, function () {
              $form.trigger("delete");
              self.deleteEvent();
            });
            $modal.dialog("close");
          }
        });
      }
      if (tabId === "tab-easy_entity_activity"){
        buttons.push(
          {
            id: "calendar_modal_button_save-with-meeting",
            class: "button-1 button-positive easy-calendar__modal-button",
            text: scheduler.locale.labels.button_save_with_meeting,
            click: function () {
              if (self.prevented) return;
              self.event._withMeeting = true;
              $form.submit();
            }
          }
        );
      }
      buttons.push(
        {
          id: "calendar_modal_button_cancel",
          class: "button easy-calendar__modal-button",
          text: scheduler.locale.labels.icon_cancel,
          click: function () {
            // self.deleteEvent(); //is needed for close modal ?
            $modal.dialog("close");
          }
        }
      )
      $modal.dialog({ buttons: buttons });
    },
    deleteEvent: function () {
      scheduler.deleteEvent(this.eventId);
      this.eventId = null;
      this.event = null;
      scheduler._new_event = null; // clear flag, if it was unsaved event
    },
    updateEvent: function (event) {
      if (this.event.realId === event.realId) {
        event.id = this.eventId;
        this.eventId = null;
        this.event = null;
        scheduler._new_event = null; // clear flag, if it was unsaved event
      } else {
        scheduler.deleteEvent(this.eventId);
      }
      scheduler.addEvent(event);
      event._changed = false;
    },

    showFlash: function (text, type) {
      this.hideFlash();
      const $flash = $("<div>");
      $flash.addClass("easy-calendar__modal_flash");
      const $close = $('<a class="icon-close"></a>');
      $close.click(function () {
        $flash.remove();
      });
      $flash.html(text);
      $flash.append($close);
      $flash.addClass("easy-calendar__modal_flash--" + type);
      this.setDisabledButtons(false);
      this.$modal.prepend($flash);
    },
    hideFlash: function () {
      this.$modal.find(".easy-calendar__modal_flash").remove();
    },
    close: function () {
      this.$modal.dialog("close");
    },
    setDisabledButtons: function (state) {
      this.prevented = state;
      this.$modal.parent().toggleClass("easy-calendar__modal--disabled", state);
    }
  };
  scheduler.modal = modalClass;

  // ####################################################################################################################
});
