(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {int} currentId
   * @property {Array.<Assignee>} assignees
   * @property {Object.<String,Assignee>} assigneeMap
   */
  function AssigneeData(main) {
    this.main = main;
    this.currentId = main.settings.currentUserId;
    this.primaryId = main.settings.currentUserId;
    this.dominant = false;
    this.banned = false;
    this.selectedAssignees = [];
    var self = this;
    main.eventBus.register("assigneeChanged", function () {
      self.saveToStorage();
    });
    this.assignees = [];
    this.assigneeMap = {};
    Assignee.prototype.avatar_url = main.settings.paths.rootPath + "/plugin_assets/easy_scheduler/images/avatar.jpg";
  }

  AssigneeData.prototype.assignees = [];
  AssigneeData.prototype.assigneeMap = {};
  /**
   * @param {Array.<{id:number}>|null} usersData
   * @param {boolean} selectUsers
   */
  AssigneeData.prototype.load = function (usersData, selectUsers) {
    var self = this;
    if (!this.assigneeMap[0]) {
      var unassigned = new Assignee(this.main, {
        id: 0,
        name: "Unassigned",
        avatar_url: this.main.settings.paths.rootPath + "/plugin_assets/easy_extensions/images/avatar.jpg"
      });
      this.assignees.push(unassigned);
      this.assigneeMap[0] = unassigned;
    }
    this.loadUsers(usersData, true);
    var selectedIds = extractIds(self.selectedAssignees);
    selectedIds.push(this.currentId);
    if (selectUsers) {
      selectedIds = selectedIds.concat(extractIds(usersData));
    } else {
      selectedIds = selectedIds.concat(this.savedAssigneeIds());
    }
    selectedIds = selectedIds.filter(function (value, index, self) {
      return self.indexOf(value) === index;
    });
    self.selectedAssignees = [];
    selectedIds.forEach(function (assigneeId) {
      if (self.assigneeMap[assigneeId]) {
        self.selectedAssignees.push(self.assigneeMap[assigneeId]);
      }
    });
    if (this.main.settings.isManager) {
      var primaryIdFromStorage = this.main.scheduler.getFromStorage("primary-assignee");
      if (primaryIdFromStorage && this.assigneeMap[primaryIdFromStorage]) {
        this.primaryId = parseInt(primaryIdFromStorage);
        if (selectedIds.indexOf(this.primaryId) === -1) {
          this.primaryId = this.currentId;
        }
      }
    }
    var primary = this.getPrimaryUser();
    if(primary) { primary.setTimeLimits(); }

    self.assignees.forEach(function (assignee) {
      if (assignee._temporary) {
        self.deleteAssignee(assignee);
      }
    });
    this.main.eventBus.fireEvent("assigneeChanged", this);
  };
  /**
   * @memberOf AssigneeData
   * @param {Array} userArray
   * @param {boolean} silent
   */
  AssigneeData.prototype.loadUsers = function (userArray, silent) {
    if (!userArray) return;
    var self = this;
    userArray.forEach(function (userData) {
      var assignee = self.assigneeMap[userData.id];
      if (!assignee) {
        self.createAssignee(userData, silent);
      } else if (assignee._temporary) {
        delete assignee._temporary;
        $.extend(assignee, userData);
      }
    });
  };
  /**
   * @memberOf AssigneeData
   * @return {Array.<int>}
   */
  AssigneeData.prototype.savedAssigneeIds = function () {
    var selectedUserIds = this.main.settings.selectedUserIds;
    var selectedFromStorageJson = this.main.scheduler.getFromStorage("selected-assignees");
    if (!selectedFromStorageJson && selectedUserIds && selectedUserIds.length) {
      var copy = selectedUserIds.slice();
      copy.push(this.currentId);
      return copy;
    }
    if (selectedFromStorageJson) {
      selectedUserIds = JSON.parse(selectedFromStorageJson);
      selectedUserIds.push(this.currentId);
      return selectedUserIds;
    }
    return [this.currentId];
  };

  AssigneeData.prototype.createAssignee = function (assigneeData, silent) {
    /** @type {Assignee} */
    var assignee = new Assignee(this.main, assigneeData);
    this.assignees.push(assignee);
    this.assigneeMap[assignee.id] = assignee;
    if (!silent) {
      this.main.eventBus.fireEvent("assigneeChanged", this);
    }
    return assignee;
  };
  /**
   * @memberOf AssigneeData
   * @param {Assignee} assignee
   * @param {boolean} [silent]
   */
  AssigneeData.prototype.deleteAssignee = function (assignee, silent) {
    if (this.selectedAssignees.indexOf(assignee) > -1) {
      assignee.deselectAssignee();
    }
    var index = this.assignees.indexOf(assignee);
    this.assignees.splice(index, 1);
    delete this.assigneeMap[assignee.id];
    if (!silent) {
      this.main.eventBus.fireEvent("assigneeChanged", this);
    }
  };
  /**
   * @methodOf AssigneeData
   * @param {int} id
   * @return {Assignee}
   */
  AssigneeData.prototype.getAssigneeById = function (id) {
    return this.assigneeMap[id];
  };
  /**
   * @methodOf AssigneeData
   * @return {Assignee} */
  AssigneeData.prototype.getCurrentUser = function () {
    return this.assigneeMap[this.currentId];
  };
  /**
   * @methodOf AssigneeData
   * @return {Assignee} */
  AssigneeData.prototype.getPrimaryUser = function () {
    return this.assigneeMap[this.primaryId];
  };
  /**
   * @methodOf AssigneeData
   * @return {Array.<int>}
   */
  AssigneeData.prototype.getActiveUserIds = function () {
    return this.selectedAssignees.map(function (user) {
      return user.id;
    });
  };
  /**
   * @memberOf AssigneeData
   * @param newPrimary
   */
  AssigneeData.prototype.resetSelected = function (newPrimary) {
    if (!newPrimary) {
      newPrimary = this.assigneeMap[this.currentId];
    }
    var newPrimaryId = newPrimary.id;
    for (var i = 0; i < this.selectedAssignees.length; i++) {
      var assignee = this.selectedAssignees[i];
      if (assignee.id !== newPrimaryId) {
        this.main.eventBus.fireEvent("assigneeChanged", assignee);
      }
    }
    this.primaryId = newPrimaryId;
    this.selectedAssignees = [newPrimary];
    this.main.eventBus.fireEvent("assigneeChanged", newPrimary);
  };
  /**
   * @memberOf AssigneeData
   * @param assignee
   */
  AssigneeData.prototype.setPrimary = function (assignee) {
    if (!this.main.settings.isManager) return;
    if (this.selectedAssignees.indexOf(assignee) === -1) {
      return this.resetSelected(assignee);
    }
    var oldPrimary = this.primaryId;
    if (oldPrimary === assignee.id){
      this.dominant = !this.dominant;
      this.main.eventBus.fireEvent("assigneeChanged", assignee);
      return;
    }
      this.dominant = false;
      this.primaryId = assignee.id;
      assignee.setTimeLimits();
    //console.log("setPrimary: "+oldPrimary+" -> "+assignee.id);
    this.main.eventBus.fireEvent("assigneeChanged", this.assigneeMap[oldPrimary]);
    this.main.eventBus.fireEvent("assigneeChanged", assignee);
  };
  /**
   * @memberOf AssigneeData
   */
  AssigneeData.prototype.saveToStorage = function () {
    this.main.scheduler.saveToStorage("primary-assignee", this.primaryId.toString());
    this.main.scheduler.saveToStorage("selected-assignees", JSON.stringify(this.selectedAssignees.map(function (assignee) {
      return assignee.id;
    })));
  };
  /**
   * @param {Array.<{id:int}>} array
   * @return {Array.<int>}
   */
  var extractIds = function (array) {
    return array.map(function (userData) {
      return userData.id;
    });
  };


  EasyCalendar.AssigneeData = AssigneeData;

  //####################################################################################################################
  /**
   *
   * @param {CalendarMain} main
   * @param data
   * @class
   * @constructor
   * @property {int} id
   * @property {AssigneeData} _parent
   * @property {String} name
   * @property {String} avatar_url
   * @property {Array.<int>} working_days
   * @property {Array.<number>} week_hours
   * @property {number} estimated_ratio
   * @property {boolean} _active
   * @property {boolean} _temporary
   */
  function Assignee(main, data) {
    this.main = main;
    this._parent = main.assigneeData;
    $.extend(this, data);
  }

  Assignee.prototype.name = "Unnamed";
  Assignee.prototype._temporary = false;

  /**
   * @methodOf Assignee
   * @return {Array.<Task>}
   */
  Assignee.prototype.getMyTasks = function () {
    var tasks = this.main.taskData.tasks;
    var myTasks = [];
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].assigned_to_id === this.id) {
        myTasks.push(tasks[i]);
      }
    }
    return myTasks;
  };
  /**
   * @memberOf Assignee
   * @return {boolean}
   */
  Assignee.prototype.isActive = function () {
    return this._parent.primaryId === this.id || this._parent.selectedAssignees.indexOf(this) !== -1;
  };
  /**
   * @memberOf Assignee
   * @return {boolean}
   */
  Assignee.prototype.isPrimary = function () {
    return this._parent.primaryId === this.id;
  };
  /**
   * @memberOf Assignee
   * @return {boolean}
   */
  Assignee.prototype.isCurrent = function () {
    return this._parent.currentId === this.id;
  };
  /**
   * @memberOf Assignee
   */
  Assignee.prototype.selectAssignee = function () {
    if (this._parent.selectedAssignees.indexOf(this) === -1) {
      this._parent.selectedAssignees.push(this);
      this.main.eventBus.fireEvent("assigneeChanged", this);
    }
  };
  /**
   * @memberOf Assignee
   */
  Assignee.prototype.deselectAssignee = function () {
    var index = this._parent.selectedAssignees.indexOf(this);
    if (index !== -1) {
      this._parent.selectedAssignees.splice(index, 1);
      this.main.eventBus.fireEvent("assigneeChanged", this);
    }
    if (this._parent.primaryId === this.id) {
      if (this._parent.selectedAssignees.length > 0) {
        this._parent.assigneeMap[this._parent.selectedAssignees[0]].selectAssignee();
      } else {
        this.selectAssignee();
      }
    }
  };
  /**
   * @memberOf Assignee
   */
  Assignee.prototype.setTimeLimits = function () {
    const hasTime = !(!this.start_time || !this.end_time);
    var config = this.main.scheduler.config;
    if (hasTime && config.range_type === 'automatic' && this.start_time < this.end_time) {
      config.start_time = this.start_time;
      config.end_time = this.end_time;
      config.workday_duration = config.end_time - config.start_time;
    } else if (config.range_type === 'manual') {
      const isLongRange = config.last_hour - config.first_hour > 8;
      config.start_time = config.first_hour * 3600000;
      config.end_time = config.last_hour * 3600000;
      config.workday_duration = isLongRange ? 8 * 3600000 : 4 * 3600000;
    } else {
      config.start_time = 10 * 3600000;
      config.end_time = 14 * 3600000;
      config.workday_duration = 4 * 3600000;
    }
  };

  EasyCalendar.Assignee = Assignee;
})();
