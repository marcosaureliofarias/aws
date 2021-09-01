(function () {
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   */
  class TaskDataView {
    constructor (main) {
      const self = this;
      this.main = main;
      this.$cont = main.$container.find(".easy-calendar__tasks");
      this.titleElement = this.$cont.find(".easy-calendar__tasks-title").get(0);
      this.$list = this.$cont.find(".easy-calendar__task-list");
      this.$toggler = main.$container.find(".easy-calendar__tasks-toggler");
      this.taskData = main.taskData;
      this.taskViews = {};
      this.options = {};
      this._refreshHeaderRequested = true;

      const refreshAllOn = ["tasksLoaded"];
      for (let i = 0; i < refreshAllOn.length; i++) {
        this.main.eventBus.register(refreshAllOn[i], () => {
          self.refreshAll();
        });
      }
      this.main.eventBus.register("taskChanged", (task) => {
        self.refreshTask(task.id);
      });
      this.$toggler.on("change", (event) => {
        main.scheduler.config.togglerValue =  event.target.value;
        const togglerValue = event.target.value;
        main.scheduler.saveToStorage("togglerValue", main.scheduler.config.togglerValue);
        if (togglerValue === "1") self.main.scheduler.setCurrentView(self.main.scheduler._date, "day");
        self.refreshHeader();
      });
    }

    setTitleValues (title, entityCount) {
      this.options.title = title;
      this.options.entityCount = entityCount;
      this.refreshTitle();
    }

    refreshTitle () {
      if (!this.titleElement) return;

      let title = this.options.title;
      if (this.options.entityCount) {
        title +=' <span class="easy-calendar__tasks-count">(' + this.options.entityCount + ')</span>';
      }
      this.titleElement.innerHTML = title;
    }

    refreshAll () {
      this._refreshAllRequested = true;
      this.main.repainter.redrawMe(this);
      this.$cont.show();
    }

    refreshHeader () {
      this._refreshHeaderRequested = true;
      this.main.repainter.redrawMe(this);
    }

    refreshTask (taskId) {
      if (this._redrawRequested) return;
      this.main.repainter.redrawMe(this.taskViews[taskId]);
    }

    _render () {
      if (this._refreshAllRequested) {
        this._refreshAllRequested = false;
        this.$list.empty();
        const tasks = this.taskData.tasks;
        this.unalocable = 0;

        for (let i = 0; i < tasks.length; i++) {
          const task = tasks[i];
          const { included_in_query, id, estimated_hours, status } = task;
          if (task.hasOwnProperty("included_in_query") && !included_in_query){
            this.unalocable ++;
            continue;
          }
          let taskView = this.createNewTaskView(task);
          const rest = task.getRestEstimated();
          this.taskViews[id] = taskView;
          this.taskViews[id].task.rest = rest;
          const statusClosed = status.is_closed;
          if (this.isTaskUnalocable(statusClosed, rest, estimated_hours)) {
            this.unalocable ++;
          }
          taskView._render();
        }


        if (!this.taskData.noMoreToLoad) {
          const self = this;
          const $moreButton = $('<a>', {
            "class": "button easy-calendar__tasks_more-button",
            text: this.main.settings.labels.more
          }).on("click", () => {
            const offset = self.main.taskData.offset;
            self.main.loader.fetchTasks(offset);
          });
          this.$list.append($moreButton);
        }
      }

      if (this.unalocable > 0){
        this.createUnalocableDeclaimer();
      }

      if (this._refreshHeaderRequested) {
        this._refreshHeaderRequested = false;
        this.showTab(this.main.scheduler.config.togglerValue);
      }
    }

    createNewTaskView (task) {
      const taskDiv = '<div class="easy-calendar__task ' + (!!task.scheme ? task.scheme : "") + ' "></div>';
      const $taskCont = $(taskDiv);
      this.$list.append($taskCont);
      const view_class = this.taskData.taskClasses[this.taskData.taskType].getTaskViewClass();
      const view = new view_class(this.main, $taskCont, task);
      return view;
    }

    showTab (openTab) {
      switch (openTab) {
        case '0':
          this.main.$container.addClass("easy-calendar--tasks-hidden");
          this.main.$container.removeClass("easy-calendar--tasks-only");
          return;
        case '1':
          this.main.$container.removeClass("easy-calendar--tasks-hidden");
          this.main.$container.removeClass("easy-calendar--tasks-only");
          return;
        case '2':
          this.main.$container.removeClass("easy-calendar--tasks-hidden");
          this.main.$container.addClass("easy-calendar--tasks-only");
          return;
      }
    }

    createUnalocableDeclaimer (){
      const unalocableDeclaimer = document.createElement("H4");
      unalocableDeclaimer.innerHTML = `+ ${this.unalocable} ${this.main.settings.labels.unalocableDeclaimer}`;
      this.$list.append(unalocableDeclaimer);
    }

    isTaskUnalocable (statusClosed, rest, estimated_hours) {
      return (statusClosed || rest <= 0 && estimated_hours > 0);
    }
  }
  EasyCalendar.TaskDataView = TaskDataView;
})();
