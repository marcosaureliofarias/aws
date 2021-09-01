ysy.pro.resource.reservations = ysy.pro.resource.reservations || {};
ysy.pro.resource.features.reservations = "reservations";
EasyGem.extend(ysy.pro.resource.reservations, {
  patch: function () {
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    const sett = ysy.settings.resource.buttons;
    sett.onlyTask = JSON.parse(ysy.data.storage.getPersistentData('onlyTask'));
    sett.onlyReservation = JSON.parse(ysy.data.storage.getPersistentData('onlyReservation'));
    sett.newReservation = JSON.parse(ysy.data.storage.getPersistentData('newReservation'));
    if (!ysy.settings.reservationEnabled) return;

    ysy.pro.toolPanel.registerButton(
        {
          id: "resource_reservations",
          bind: function () {
            this.model = ysy.settings.resource;
            this.buttons = this.model.buttons;
            if (!this.buttons.onlyTask) {
              this.buttons.newReservation = true;
              ysy.settings.resource.setSilent("reservations", !this.model.reservations);
              self.toggle();
              ysy.settings.resource._fireChanges(this, "button");
            }
            if (!ysy.settings.resource_on) {
              this.buttons.newReservation = false;
              self.toggle();
            }
          },
          func: function () {
            this.buttons.newReservation = !this.model.reservations;
            ysy.proManager.closeAll(resourceClass);
            ysy.settings.resource.setSilent("reservations", !this.model.reservations);
            ysy.data.storage.savePersistentData('newReservation', this.buttons.newReservation);
            self.toggle();
            // hide reservation
            this.buttons.onlyTask = !this.model.reservations;
            ysy.data.storage.savePersistentData('onlyTask', this.buttons.onlyTask);
            ysy.pro.resource.reservations.updateRegistration(this.buttons.onlyTask);
            if (this.buttons.onlyTask) {
              if (this.model.hasOwnProperty('hidePlanned')) {
                this.buttons.hidePlanned = false;
                ysy.data.storage.savePersistentData('hidePlanned', this.buttons.hidePlanned);
              }
              this.buttons.onlyReservation = false;
              ysy.data.storage.savePersistentData('onlyReservation', this.buttons.onlyReservation);
              ysy.pro.resource.reservations.loadReservationSums('onlyTask');
            }
            else {
              if (!this.buttons.onlyReservation) {
                ysy.pro.resource.reservations.loadReservationSums('allData');
                if (!ysy.data.resourceReservations.array.length) {
                  ysy.pro.resource.loader.load()
                }
              }
            }
            ysy.settings.resource._fireChanges(this, "button");
          },
          isOn: function () {
            return this.model.reservations;
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );

    ysy.pro.toolPanel.registerButton(
        {
          id: "hide_tasks",
          _name: "HideTasks",
          bind: function () {
            this.model = ysy.settings.resource;
            this.buttons = this.model.buttons;
            if (!this.buttons.onlyTask) {
              this.buttons.onlyTask = false;
              ysy.settings.resource.setSilent("onlyTask", !this.buttons.onlyReservation);
              this.model._fireChanges(this, "click");
            }
          },
          func: function () {
            this.buttons.onlyReservation = !this.buttons.onlyReservation;
            ysy.pro.resource.reservations.updateRegistration(this.buttons.onlyReservation);
            ysy.data.storage.savePersistentData('onlyReservation', this.buttons.onlyReservation);
            if (this.buttons.onlyReservation) {
              if (this.model.hasOwnProperty('hidePlanned')) {
                this.buttons.hidePlanned = false;
                ysy.data.storage.savePersistentData('hidePlanned', this.buttons.hidePlanned);
              }
              this.buttons.onlyTask = false;
              this.buttons.newReservation = true;
              ysy.settings.resource.setSilent("reservations", true);
              ysy.data.storage.savePersistentData('onlyTask', this.buttons.onlyTask);
              ysy.pro.resource.reservations.loadReservationSums('onlyReservation');
              ysy.data.storage.savePersistentData('newReservation', this.buttons.newReservation);
              self.toggle();
            }
            else {
              if (!this.buttons.onlyTask) {
                ysy.pro.resource.reservations.loadReservationSums('allData');
                if (!ysy.data.issues.array.length) {
                  ysy.gateway.loadGanttdata(
                    $.proxy(ysy.data.loader._handleMainGantt, ysy.data.loader),
                    function () {
                      ysy.log.error("Error: Unable to load data");
                    }
                  );
                }
              }
            }
            this.model._fireChanges(this, "click");
          },
          isOn: function () {
            return !this.buttons.onlyReservation;
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );
    var self = this;
    var resourceClass = ysy.pro.resource;
    ysy.data.resourceReservations = new ysy.data.Array().init({_name: "ResourceReservationArray"});
    ysy.proManager.register("extendGanttTask", this.extendGanttTask);
    EasyGem.extend(gantt.config, {
      controls_reservation: {show_progress: false, resize: true},
      allowedParent_reservation: ["assignee"]
    });
    ysy.proManager.register("RmLegendOut", function (json) {
      if (!json.backColors) {
        json.backColors = [];
      }
      json.backColors.push({label: ysy.settings.labels.eventTypes.reservation, colorName: "reservation"});
    });

    ysy.data.Reservation = function () {
      ysy.data.Data.call(this);
    };
    ysy.main.extender(ysy.data.Data, ysy.data.Reservation, {
      _name: "Reservation",
      isReservation: true,
      ganttType: "reservation",
      allocator: "evenly",
      estimated_hours: 0,
      permissions: {editable: true},
      allocPack: null,
      _postInit: function () {
        this.start_date = moment(this.start_date);
        this.end_date = moment(this.due_date);
        this.end_date._isEndDate = true;
        delete this.due_date;
        if (this.resources && this.resources.length) {
          this.allocPack = this.allocPackFromResources(this.resources);
        } else {
          this.allocPack = ysy.pro.resource.calculateAllocations(this, {issue: this});
        }
        delete this.resources;
        this.register(function () {
          this.allocPack = ysy.pro.resource.calculateAllocations(this, {issue: this});
        }, this);
      },
      getID: function () {
        return "rr" + this.id;
      },
      getParent: function () {
        var assigneeId = this.assigned_to_id || "unassigned";
        if (ysy.settings.global && ysy.settings.resource.buttons.withProjects) {
          var resourceProjectId = this.project_id + "a" + assigneeId;
          if (ysy.data.resourceProjects.getByID(resourceProjectId)) {
            return "p" + resourceProjectId;
          }
        }
        if (ysy.data.assignees.getByID(assigneeId)) {
          return "a" + assigneeId;
        }
        return false;
      },
      getAllocator: function () {
        var project = ysy.data.projects.getByID(this.project_id);
        if (project && project.allocator) {
          return project.allocator;
        }
        return ysy.settings.defaultAllocator || "from_end";
      },
      pushFollowers: function () {
      },
      isOpened: function () {
        return true;
      },
      getRestEstimated: function () {
        return this.estimated_hours;
      },
      getAssignee: function () {
        return ysy.data.assignees.getByID(this.assigned_to_id);
      },
      getProblems: function () {
        return false;
      },
      getAllocations: function () {
        return this.allocPack;
      },
      getAllocationInstance: function () {
        return this;
      },
      allocPackFromResources: function (resources) {
        var allocations = {};
        for (var i = 0; i < resources.length; i++) {
          var resource = resources[i];
          allocations[resource.date] = resource.hours;
        }
        return {allocations: allocations, types: {}};
      }
    });
    this.apiPatch();
    gantt.templates.grid_bullet_reservation = function () {
      return "<div class='gantt_tree_icon'><div class='gantt_drag_handle gantt_subtask_arrow'></div></div>";
    };
    this.oldCountSubAllocations = ysy.pro.resource.countSubAllocations;
    ysy.pro.resource.countSubAllocations = this.countSubAllocations;
  },
  toggle: function () {
    if (ysy.settings.resource.reservations && ysy.settings.resource.buttons.newReservation) {
      ysy.proManager.register("onDragStart", this.onDragStart);
      ysy.proManager.register("onDragMove", this.onDragMove);
      ysy.proManager.register("onDragEnd", this.onDragEnd);
    } else {
      ysy.proManager.unregister("onDragStart", this.onDragStart);
      ysy.proManager.unregister("onDragMove", this.onDragMove);
      ysy.proManager.unregister("onDragEnd", this.onDragEnd);
    }
  },
  extendGanttTask: function (issue, gantt_issue) {
    if (issue.isReservation) {
      gantt_issue.end_date = moment(issue.end_date);
      gantt_issue.end_date._isEndDate = true;
      gantt_issue.estimated = issue.estimated_hours;
      // gantt_issue.text = "Reservation " + issue.estimated_hours + " h";
    }
  },

  getRows: function () {
    return ysy.data.resourceReservations.getArray();
  },
  onDragStart: function (temp, dnd) {
    temp.addReservation = ysy.settings.resource.reservations;
    if (!temp.addReservation) return false;
    temp.startDate = gantt.dateFromPos(dnd.getRelativePos().x);
    temp.lastScroll = gantt.getCachedScroll();
    return true;
  },
  onDragMove: function (temp, dnd) {
    if (!temp.addReservation) return false;
    temp.endDate = gantt.dateFromPos(dnd.getRelativePos().x);
    temp.line = ysy.pro.addTask.modifyIssueMarker(
        dnd.config.marker,
        {start_date: moment(temp.startDate), end_date: moment(temp.endDate), type: "reservation"},
        dnd.config.offset,
        temp.lastScroll
    );
    return true;
  },
  onDragEnd: function (temp, dnd) {
    if (!temp.addReservation) return false;
    if (dnd.config.started) {
      ysy.log.debug("start: " + temp.startDate.toString() + " end: " + temp.endDate.toString(), "taskModal");
      var task = {start_date: moment(temp.startDate), end_date: moment(temp.endDate)};
      ysy.pro.addTask.roundDates(task, temp.addType !== "milestone");
      temp.addType = "reservation";
      var parentLine = ysy.pro.addTask.getParentByLine(temp.line, temp.addType);
      if (!parentLine) return null;
      const regexAssignee = /[a](\d+)/gm;
      const regexProject = /[p](\d+)/gm;
      const id = parentLine.id;
      matchAssignee = regexAssignee.exec(id);
      matchProject = regexProject.exec(id);
      var assigneeID = matchAssignee ?  matchAssignee[1] : parentLine.real_id;
      if (ysy.settings.project) {
        var projectID = ysy.settings.project.id;
      } else {
        var projectID = matchProject ? matchProject[1] : "";
      }
      var preFill = {
        start_date: task.start_date.format("YYYY-MM-DD"),
        due_date: task.end_date.format("YYYY-MM-DD"),
        assigned_to_id: assigneeID,
        project_id: projectID,
        estimated_hours: 5
      };
      ysy.log.debug("line=" + temp.line, "taskModal");
      //preFill.parent=ysy.pro.addTask.getMilestoneByLine(temp.line);
      if (assigneeID.includes("unassigned")) {
        showFlashMessage("warning", ysy.settings.labels.warnings.reservation_for_unassignee);
        return;
      }
      ysy.pro.resource.reservations.openModal(preFill);
    }
    return true;
  },
  openModal: function (preFill, issueAllocations, reservation) {
    var self = this;
    var $target = ysy.main.getModal("form-modal", "90%");
    var data = {reservation: preFill};
    if (ysy.settings.project) {
      data.fixed_project = true;
    }
    if (!!issueAllocations) data.show_delete = true;
    $.ajax(`${window.urlPrefix}/easy_gantt_reservations/new`, {
      data: data
    }).done(function (html) {
      $target.html(html);
      showModal("form-modal");
      $target.find("form").on('submit', function () {
        if (window.fillFormTextAreaFromCKEditor) {
          window.fillFormTextAreaFromCKEditor("easy_gantt_reservation_description");
        }
        // noinspection JSValidateTypes
        /** @type {Array.<{name:String,value:*}>} */
        var array = $(this).serializeArray();
        var structured = ysy.main.formToJson(array);
        var dataArray = structured.easy_gantt_reservation || {};
        const existingProjects = [];
        Object.keys(gantt._pull).forEach(el => {
            if (el.startsWith(`p${dataArray.project_id}`)) {
              existingProjects.push(el)
            }
        });
        if (!existingProjects.length && dataArray.project_id && !ysy.settings.project) {
          $.ajax(`${window.urlPrefix}/easy_gantt_reservations/unpersisted_reservation_info.json`, {
            data: { reservation: dataArray }
          }).done(function(data) {
            const { project: projectData } = data.easy_reservation_data;
            const userId = +dataArray.assigned_to_id;
            ysy.pro.resource.loader._loadRMProjects([ projectData ], userId);
            if (!!issueAllocations) {
              self.updateReservation(dataArray, issueAllocations, reservation);
            } else {
              self.createReservation(array);
            }
          });
        } else {
          if (!!issueAllocations) {
            self.updateReservation(dataArray, issueAllocations, reservation);
          } else {
            self.createReservation(array);
          }
        }
        $target.dialog('close');
        return false;
      });

      // percent converting
      self.$target = $target;
      self.assignee = ysy.data.assignees.getByID(parseInt($target.find("#easy_gantt_reservation_assigned_to_id").val()));
      delete self.defaultEstimater;
      delete self.startDate;
      delete self.dueDate;
      delete self.maxAllocation;

      self.percentConvert("estimated_hours", self);
      $target.find("#easy_gantt_reservation_start_date")
          .on("change",function () {self.percentConvert("start_date", self)});
      $target.find("#easy_gantt_reservation_due_date")
          .on("change",function () {self.percentConvert("due_date", self)});
      $target.find("#easy_gantt_reservation_estimated_hours")
          .on("keyup change",function () {self.percentConvert("estimated_hours", self)});
      $target.find("#easy_gantt_reservation_estimated_percent")
          .on("keyup change",function () {self.percentConvert("estimated_percent", self)});


      $target.find(".reservation_close").on('click', function () {
        $target.dialog('close');
      });
      $target.find(".reservation_delete").on('click', function () {
        $target.dialog('close');
        reservation.remove();
      });
    });
  },
  /***
   *
   * @param changer {String}
   * @param modalData {Object}
   */
  percentConvert: function (changer, modalData){
    const start = modalData.$target.find("#easy_gantt_reservation_start_date").val();
    const end = modalData.$target.find("#easy_gantt_reservation_due_date").val();
    let dateChanged = false;
    if (!modalData.startDate || changer === "start_date" || modalData.startDate !== start){
      modalData.startDate = start;
      dateChanged = true;
    }
    if (!modalData.dueDate || changer === "due_date" || modalData.dueDate !== end){
      modalData.dueDate = end;
      dateChanged = true;
    }
    if (dateChanged || !modalData.maxAllocation){
      var mover = moment(modalData.startDate);
      modalData.maxAllocation = 0;
      let dueDate = moment(modalData.dueDate);
      while (!mover.isAfter(dueDate)) {
        const isodate = mover.format("YYYY-MM-DD");
        const max = modalData.assignee.getMaxHours(isodate, mover);
        modalData.maxAllocation += max;
        mover.add(1, "days");
      }
      modalData.$target.find("#easy_gantt_reservation_max_allocation").text(modalData.maxAllocation);
    }
    if (changer === "estimated_hours"){
      modalData.changeByTime(modalData);
    } else if (changer === "estimated_percent"){
      modalData.changeByPercent(modalData);
    } else {
      if (modalData.defaultEstimater === "estimated_hours" ) {
        modalData.changeByTime(modalData);
      } else {
        modalData.changeByPercent(modalData);
      }
    }
  },
  /***
   *
   * @param modalData {Object}
   */
  changeByTime: function (modalData) {
    let estimatedTime = parseInt(modalData.$target.find("#easy_gantt_reservation_estimated_hours").val());
    modalData.defaultEstimater = "estimated_hours";
    if (isNaN(estimatedTime)) estimatedTime = 0;
    let estimatedPercent = estimatedTime / (modalData.maxAllocation / 100);
    estimatedPercent = estimatedPercent.toFixed(0);
    modalData.$target.find("#easy_gantt_reservation_estimated_percent").val(estimatedPercent);
  },
  /***
   *
   * @param modalData {Object}
   */
  changeByPercent: function (modalData) {
    let estimatedPercent = parseInt(modalData.$target.find("#easy_gantt_reservation_estimated_percent").val());
    modalData.defaultEstimater = "estimated_percent";
    if (isNaN(estimatedPercent)) estimatedPercent = 0;
    let estimatedTime = modalData.maxAllocation * (estimatedPercent / 100);
    estimatedTime = estimatedTime.toFixed(0);
    modalData.$target.find("#easy_gantt_reservation_estimated_hours").val(estimatedTime);
  },
  /**
   * @param {Array.<{name:String,value:*}>} dataArray
   */
  createReservation: function (dataArray) {
    var structured = ysy.main.formToJson(dataArray);
    var data = structured.easy_gantt_reservation || {};
    data.id = new Date().valueOf().toString();
    data.estimated_hours = parseFloat(data.estimated_hours);
    data.assigned_to_id = parseInt(data.assigned_to_id);
    dataArray.forEach(el => {
      if(el.name.includes("description")){
        return data.description = el.value
      }
    });
    var reservation = new ysy.data.Reservation();
    reservation.init(data);
    ysy.data.resourceReservations.push(reservation);
    var assignee = gantt._pull["a" + (data.assigned_to_id || "unassigned")];
    if (assignee) {
      gantt.open(assignee.id);
    }
  },
  updateReservation: function (data, issueAllocations, reservation) {
    if (!data) return;
    ysy.history.openBrack();
    issueAllocations.set({allocator: data.allocator, _oldAllocator: issueAllocations.allocator});
    reservation.set({
      estimated_hours: Number(data.estimated_hours),
      description: data.description,
      name: data.name,
      start_date: moment(data.start_date),
      end_date: moment(data.due_date),
      project_id: data.project_id
    });
    ysy.history.closeBrack();
  },
  // prepareAssigneeOptions: function (userId) {
  //   var users = ysy.data.assignees.getArray();
  //   return users.map(function (user) {
  //     return {id: user.id, name: user.name, selected: user.id === userId ? "selected" : ""};
  //   })
  // },
  countSubAllocations: function (gantt, parent) {
    var allocPack = {};
    const regexAssignee = /[a](\d+)/gm;
    const isParentProject = parent.realProject;
    allocPack.allocations = {};
    allocPack.types = {};
    if (!ysy.settings.resource.buttons.onlyReservation) {
      allocPack = ysy.pro.resource.reservations.oldCountSubAllocations.call(ysy.pro.resource, gantt, parent);
    }
    if (ysy.settings.resource.buttons.onlyTask) return allocPack;
    var allocations = allocPack.allocations;
    var reservations = ysy.data.resourceReservations.getArray();
    var assigneeId = regexAssignee.exec(parent.id);
    assigneeId = assigneeId ? +assigneeId[1] : parent.id;
    for (var i = 0; i < reservations.length; i++) {
      var reservation = reservations[i];
      if (isParentProject && (!reservation.project_id || reservation.project_id !== isParentProject.id)) continue;
      if (reservation.assigned_to_id !== assigneeId) continue;
      var subAllocations = reservation.allocPack.allocations;
      for (var date in subAllocations) {
        if (!subAllocations.hasOwnProperty(date)) continue;
        if (!subAllocations[date]) continue;
        if (allocations[date]) {
          allocations[date] += subAllocations[date];
        } else {
          allocations[date] = subAllocations[date];
        }
      }
    }
    return allocPack;
  },

  updateRegistration: function (isOn) {
    if (isOn) {
      ysy.proManager.register("filterTask", this.filterTask);
    } else {
      ysy.proManager.unregister("filterTask", this.filterTask);
    }
  },
  filterTask: function (id, task) {
    if (task.type === "task") {
      if (ysy.settings.resource.buttons.onlyReservation) return false;
    }
    if (task.type === "reservation") {
      if (ysy.settings.resource.buttons.onlyTask) return false;

    }
    return true;
  },
});
