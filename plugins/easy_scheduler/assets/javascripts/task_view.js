(function () {
  "use strict";
  /**
   * @class
   * @param {CalendarMain} main
   * @param {jQuery} $cont
   * @param {Task} task
   * @property {jQuery} $list
   * @constructor
   */
  class TaskView {
    /**
     * @abstract
     * @param {CalendarMain} main
    */

    constructor (main, $cont, task) {
      if (new.target === TaskView) throw new TypeError("Cannot construct Abstract instances directly");
      this.main = main;
      this.task = task;
      this.$cont = $cont;
      this._firstRender = true;
      this.formatter = this.main.scheduler.templates.dMY_format;
    }

    /**
     * Round to at most 2 decimal places (only if necessary)
     * @param value
     * @returns {number|*}
     */
    formatTo2 (value) {
      return value % 1 ? Math.round((value + Number.EPSILON) * 100) / 100 : value;
    }

    lockRender () {
      this._renderLocked = true;
    }

    unlockRender () {
      this._renderLocked = false;
      this.main.repainter.redrawMe(this);
    }
  }

  EasyCalendar.TaskView = TaskView;

  class IssueView extends TaskView {
    constructor (main, $cont, task) {
      super(main, $cont, task);
      this.template = '<span class="easy-calendar__task-handle"></span>\
        {{#unread}}\
          <i class="icon icon-message red-icon unread push-left" title="Unread">&nbsp</i>\
        {{/unread}}\
        <span class="easy-calendar__task-name">{{subject}}</span>\
        {{#estimateViewable}}\
          <div class="easy-calendar__task-spent" title="' + this.main.settings.labels.titleRemainingTime + '">{{rest}}h</div>\
        {{/estimateViewable}}\
        <div class="easy-calendar__task-data">\
        <a href="javascript:void(0)" class="easy-calendar__task-start">{{startDate}}</a>\
        {{#dueDate}}\
          <span class="separate-line"></span>\
          <a href="javascript:void(0)" class="easy-calendar__task-due">{{dueDate}}</a>\
        {{/dueDate}}\
        {{#avatar_url}}\
          <span class="easy-calendar__task-avatar-container">\
            <span class="easy-calendar__task-avatar">\
              <img class="gravatar" src="{{avatar_url}}" title="{{assigneeName}}" alt="image" width="16px" height="20px">\
            </span>\
          </span>\
        {{/avatar_url}}\
        </div>';
    }

    _render () {
      const {rest, status, estimated_hours, permissions, start_date, due_date, assigned_to_id, spent_hours, unread, subject} = this.task;
      const assignee = this.main.assigneeData.getAssigneeById(assigned_to_id);
      const firstRender = this._firstRender;
      const formatter = this.formatter;
      this._firstRender = false;

      if (this._renderLocked) {
        return this.$cont.find(".easy-calendar__task-spent").html(rest + "h");
      }

      if (this.main.tasksView.isTaskUnalocable(status.is_closed, rest, estimated_hours)) {
        if (firstRender) {
          return this.$cont.hide();
        }
        return this.$cont.slideUp(300);
      }
      else {
        this.$cont.slideDown(300);
      }

      this.$cont.toggleClass("easy-calendar__task--readonly", !permissions.editable);
      this.$cont.toggleClass("easy-calendar__task--allocated", this.main.tasksView.isTaskUnalocable(status.isClosed, rest, estimated_hours));

      const cont = this.$cont[0];
      // noinspection HtmlUnknownTarget
      const data = {
        subject: subject,
        startDate: start_date ? formatter(start_date) : "",
        dueDate: due_date ? formatter(due_date) : "",
        rest: this.formatTo2(rest),
        estimated: this.formatTo2(estimated_hours),
        spent: this.formatTo2(spent_hours),
        allocated: this.formatTo2(estimated_hours - rest - spent_hours),
        assigneeName: assignee ? assignee.name : "",
        avatar_url: assignee ? assignee.avatar_url : "",
        estimateViewable: permissions.viewable_estimated_hours,
        unread: unread || false
      };
      /** @param {Number} value
       * @return {Number|string} */
      const html = Mustache.render(this.template, data);
      this.$cont.html(html);
      this.$cont.find("a").on("mousedown", (e) => {
        e.preventDefault();
      });
      this._bindEvents();
    }

    _bindEvents () {
      const self = this;
      if (this.task.permissions.editable) {
        self.main.externalDnD.mouseDownBind(this);
      }

      if (self.task.permissions.editable_estimated_hours) {
        this.editHoursBind();
      }

      this.$cont.find(".easy-calendar__task-start").on("click", () => {
        self.main.scheduler.setCurrentView(self.task.start_date);
      });
      this.$cont.find(".easy-calendar__task-due").on("click", () => {
        self.main.scheduler.setCurrentView(self.task.due_date);
      });
      this.$cont.off("no_drag_task_click").on("no_drag_task_click", (e, originalEvent) => {
        var originalEventList = originalEvent.target.classList;
        if (originalEventList.contains('easy-calendar__task-data') ||
            originalEventList.contains('easy-calendar__task') ||
            originalEventList.contains('easy-calendar__task-name')) {
          self.main.taskModal.openTaskModal(self.task.id, false);
        }
      });
    }

    editHoursBind () {
      let prevented = false;
      const self = this;
      this.$cont.find(".easy-calendar__task-spent").on("click", (event) => {
        if (prevented) return;
        const $this = $(event.target);
        prevented = true;
        const onFinish = (event) => {
          if (event.keyCode && event.keyCode !== 13) return;
          $this.removeClass("easy-calendar__task-spent--input");
          if (!self.task.set("estimated_hours", parseFloat($input.val()))) {
            self.main.eventBus.fireEvent("taskChanged", self.task);
          }
          prevented = false;
        };
        const $input = $("<input class='easy-calendar__task-spent-input' type='number' min='"
            + self.task.spent_hours + "' value='" + self.task.estimated_hours + "' step='any'>");
        $this.empty().append($input);
        $input.focus();
        $input.on("blur", onFinish).on("keydown", onFinish);
        $this.addClass("easy-calendar__task-spent--input");
      });
    }
  }

  EasyCalendar.IssueView = IssueView;

  class CrmCaseView extends TaskView {
    constructor (main, $cont, task) {
      super(main, $cont, task);
      this.template = '<span class="easy-calendar__task-handle"></span>\
        <span class="easy-calendar__task-name">{{name}}</span>\
        <div class="easy-calendar__task-price">{{price}}</div>\
        <div class="easy-calendar__task-data">\
        <span class="easy-calendar__task-label">' + this.main.scheduler.locale.labels.contract_date + '</span>\
        <a href="javascript:void(0)" class="easy-calendar__task-contract">{{contractDate}}</a>\
        {{#nextAtion}}\
          </br>\
          <span class="easy-calendar__task-label">' + this.main.scheduler.locale.labels.next_action + '</span>\
          <a href="javascript:void(0)" class="easy-calendar__task-next_action">{{nextAtion}}</a>\
        {{/nextAtion}}\
        {{#avatar_url}}\
          <span class="easy-calendar__task-avatar-container">\
            <span class="easy-calendar__task-avatar">\
              <img class="gravatar" src="{{avatar_url}}" title="{{assigneeName}}" alt="image" width="16px" height="20px">\
            </span>\
          </span>\
        {{/avatar_url}}\
        </div>';
    }

    _render () {
      const task = this.task;
      const assignee = this.main.assigneeData.getAssigneeById(task.assigned_to_id);
      this.$cont.toggleClass('easy-calendar__task--readonly', !task.permissions.editable);
      // noinspection HtmlUnknownTarget
      const cont = this.$cont[0];
      const data = {
        name: task.name,
        price: task.formattedPrice,
        contractDate: task.contract_date ? this.formatter(task.contract_date) : '',
        nextAtion: task.next_action ? this.formatter(task.next_action) : '',
        assigneeName: assignee ? assignee.name : '',
        avatar_url: assignee ? assignee.avatar_url : ''
      };

      const html = Mustache.render(this.template, data);
      this.$cont.html(html);
      this._bindEvents();
    }

    _bindEvents () {
      const self = this;
      if (this.task.permissions.editable) {
        this.editPriceBind();
        // this.main.externalDnD.mouseDownBind(this);
      }

      this.$cont.find(".easy-calendar__task-contract").on("click", () => {
        self.main.scheduler.setCurrentView(self.task.contract_date);
      });
      this.$cont.find(".easy-calendar__task-next_action").on("click", () => {
        self.main.scheduler.setCurrentView(self.task.next_action);
      });
    }

    editPriceBind () {
      const self = this;
      let prevented = false;
      this.$cont.find('.easy-calendar__task-price').on('click', (event) => {
        if (prevented) return;
        const $this = $(event.target);
        prevented = true;
        const onFinish = (event) => {
          if (event.keyCode && event.keyCode !== 13) return;
          $this.removeClass('easy-calendar__task-price--input');
          const _newPrice = parseFloat($input.val());
          self.task.formattedPrice = self.task.currency_symbol + ' ' + _newPrice;
          if (!self.task.set('price', _newPrice)) {
            self.main.eventBus.fireEvent('taskChanged', self.task);
          }
          prevented = false;
        };
        const $input = $("<input class='easy-calendar__task-price-input' type='number' value='" + self.task.price + "' >");
        $this.empty();
        $this.append($input);
        $input.focus();
        $input.on('blur', onFinish).on('keydown', onFinish);
        $this.addClass('easy-calendar__task-price--input');
      });
    }
  }

  EasyCalendar.CrmCaseView = CrmCaseView;

})();
