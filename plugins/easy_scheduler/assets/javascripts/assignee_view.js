(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   */
  function AssigneesView(main) {
    var self = this;
    this.main = main;
    this.$frame = main.$container.find(".easy-calendar__user-select");
    this.$cont = main.$container.find(".easy-calendar__assignees");
    this.assigneeData = main.assigneeData;
    this.assigneeViews = {};
    var refreshAllOn = ["eventsLoaded"];
    for (var i = 0; i < refreshAllOn.length; i++) {
      this.main.eventBus.register(refreshAllOn[i], function () {
        self.refreshAll();
      });
    }
    // this.filterFor = null;
    // main.eventBus.register("startExternalDnD", function (task) {
    //   self.filterFor = task;
    //   self.refreshAll();
    // });
    // main.eventBus.register("endExternalDnD", function () {
    //   self.filterFor = null;
    //   self.refreshAll();
    // });
  }

  AssigneesView.prototype.refreshAll = function () {
    this._refreshAllRequested = true;
    this.main.repainter.redrawMe(this);

  };
  AssigneesView.prototype.refreshAssignee = function (assigneeId) {
    if (this._redrawRequested) return;
    this.main.repainter.redrawMe(this.assigneeViews[assigneeId]);
  };
  AssigneesView.prototype._render = function () {
    if (!this._refreshAllRequested) return;
    this._refreshAllRequested = false;
    // var shown = this.main.settings.isManager;
    // if (!shown) {
    //   this.$cont.empty();
    //   this.$frame.hide();
    //   return;
    // }
    var self = this;
    this.$frame.show();
    var ac = this.main.$container.find(".easy-calendar__user-select-input").easymultiselect({
      multiple: false,
      select_first_value: false,
      rootElement: 'users',
      preload: false,
      source: this.main.settings.paths.usersPath
    });
    ac.off("autocompleteselect").on("autocompleteselect", function (event, ui) {
      var assignee = self.assigneeData.assigneeMap[ui.item.id];
      if (!assignee) {
        assignee = self.assigneeData.createAssignee({id: ui.item.id, name: ui.item.value});
        assignee._temporary = true;
        self.main.loader.fetchEvents([ui.item.id], true);
      }
      assignee.selectAssignee();
      self.refreshAll();
      var $this = $(this);
      setTimeout(function () {
        $this.val("");
      }, 0);
      return false;
    });
    $("#clear-all-assignees").on("click", function (event) {
      self.assigneeData.selectedAssignees.forEach(function (assignee) {
        if ( !assignee.isCurrent() && !assignee.isPrimary() ) {
          self.assigneeData.deleteAssignee(assignee);
        }
      });
      self.refreshAll();
      event.stopPropagation();
    });
    var $newCont = $("<div class=\"entity-array easy-calendar__assignees\">");
    let assignees = this.assigneeData.selectedAssignees;
    const curentID = this.main.assigneeData.currentId;
    const sortCallback = (a, b) => {
      if (a.id === curentID) return false;
      if (b.id === curentID) return true;
      return a.name.localeCompare(b.name);
    };
    assignees.sort(sortCallback);
    self.main.utils.objectValues(this.assigneeViews).forEach(function (view) {
      view.destroy();
    });
    for (var i = 0; i < assignees.length; i++) {
      var assignee = assignees[i];
      if (!assignee) continue;
      var $assigneeCont = $('<span>').addClass("easy-calendar__assignee");
      $assigneeCont.data("assignee", assignee);
      $newCont.append($assigneeCont);
      var assigneeView = new AssigneeView(this.main, $assigneeCont, assignee);
      this.assigneeViews[assignee.id] = assigneeView;
      assigneeView._render();
    }
    this.$cont.after($newCont);
    this.$cont.remove();
    this.$cont = $newCont;
  };
  EasyCalendar.AssigneesView = AssigneesView;

  //############################################################
  /**
   * @class
   * @param {CalendarMain} main
   * @param {jQuery} $cont
   * @param {Assignee} assignee
   * @constructor
   */
  function AssigneeView(main, $cont, assignee) {
    var self = this;
    this.main = main;
    this.$cont = $cont;
    this.assignee = assignee;
    this.onChange = function (assignee) {
      if (self.assignee === assignee) {
        self.main.assigneesView.refreshAssignee(assignee.id);
      }
    };
    this.main.eventBus.register("assigneeChanged", this.onChange);
  }

  /** @type {jQuery} */
  AssigneeView.prototype.$cont = null;
  /** @type {Assignee} */
  AssigneeView.prototype.assignee = null;
  AssigneeView.prototype._render = function () {
    // if (!myTasks) {
    //   myTasks = this.assignee.getMyTasks();
    // }
    if (!this.assignee.isActive()) {
      this.$cont.remove();
      return;
    }
    this.isPrimary = this.assignee.id === this.main.assigneeData.primaryId;
    this.isCurrent = this.assignee.id === this.main.assigneeData.currentId;

    if (!this.main.settings.isManager && this.isPrimary) {
      this.$cont.remove();
      return;
    }
    this.$cont
        .html('<img class="easy-calendar__meeting-attendee gravatar" src="' + this.assignee.avatar_url + '"/> ' + this.assignee.name)
        .attr("data-user_id", this.assignee.id);
    if (this.isPrimary) {
      var $starIcon = $('<span class="icon icon-checked">&nbsp;</span>');
      this.$cont.prepend($starIcon);
      this.$cont.toggleClass("easy-calendar__assignee--dominant", this.assignee._parent.dominant);
    } else if (!this.isCurrent) {
      this.$deleteIcon = $('<span class="icon icon-del">&nbsp;</span>');
      this.$cont.append(this.$deleteIcon);
      this.$cont.toggleClass("easy-calendar__assignee--dominant", false);
    } else if (this.isCurrent) {
      this.$bannIcon = $('<span class="icon icon-eye">&nbsp;</span>');
      this.$cont.append(this.$bannIcon);
      this.$cont.toggleClass("easy-calendar__assignee--dominant", false);
    }

    this.$cont.toggleClass("easy-calendar__assignee--primary", this.isPrimary);
    // if (myTasks.length > 0) {
    //   this.$cont.append('<div class="easy-calendar__assignee-counter">' + myTasks.length + '</div>');
    // }
    this._bindEvents();

  };
  /**
   * @memberOf AssigneeView
   */
  AssigneeView.prototype.destroy = function () {
    this.$cont.remove();
    this.main.eventBus.unregister("assigneeChanged", this.onChange);
  };
  AssigneeView.prototype._bindEvents = function () {
    var self = this;
    if (this.main.settings.isManager) {
      this.$cont.off("click").on("click", function (event) {
        self.main.assigneeData.setPrimary(self.assignee);
        if (this.isCurrent === this.isPrimary) {
          self.assignee._parent.banned = false;
          self.$cont.toggleClass("disabled" , self.assignee._parent.banned);
        }
      });
    }
    if (!this.isPrimary && !this.isCurrent) {
      this.$deleteIcon.off("click").on("click", function (event) {
        self.assignee.deselectAssignee();
        event.stopPropagation();
        return false;
      });
    }
    if (this.isCurrent && !this.isPrimary) {
      this.$bannIcon.off("click").on("click", function (event) {
        self.assignee._parent.banned = !self.assignee._parent.banned;
        self.$cont.toggleClass("disabled" , this.isCurrent);
        self.main.eventBus.fireEvent("assigneeChanged", self.assignee);
        event.stopPropagation();
      });
    }
  };
})();
