(function () {
  "use strict";
  /**
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   * @property {String} taskType
   * @property {Array.<Task>} tasks only backlog
   * @property {Object.<String,Task>} taskMap
   * @property {int} offset
   * @property {boolean} noMoreToLoad
   */
  class TaskData {
    /**
     * @param {CalendarMain} main
    */
    constructor (main) {
      this.main = main;
      this.taskType = main.settings.taskType;
      this.tasks = [];
      this.taskMap = {};
      this.taskClasses = {};
      this.registerTaskTypes();
    }
    /**
     * @methodOf TaskData
     */
    registerTaskTypes () {
      this.taskClasses['issues'] = EasyCalendar.Issue;
      if (this.main.settings.easyPlugins.easy_crm) {
        this.taskClasses['easy_crm_cases'] = EasyCalendar.CrmCase
      }
      this.prepareTaskMap();
    }

    prepareTaskMap () {
      for (const key in this.taskClasses) {
        if (this.taskClasses.hasOwnProperty(key)) {
          this.taskMap[key] = {};
        }
      }
    }
    /**
     * @methodOf TaskData
     * @param {boolean} full
     */
    clear (full) {
      this.tasks = [];
      this.noMoreToLoad = false;
      this.offset = 0;
      if (full) {
        this.prepareTaskMap();
      }
    }
    /**
     * @methodOf TaskData
     * @param {Object} data
     */
    load (data) {
      const tasks = this.taskClasses[this.taskType].getObjectsByType(data);
      if (!tasks) return;
      for (let i = 0; i < tasks.length; i++) {
        const task = this.createOrUpdate(tasks[i]);
        this.tasks.push(task);
        this.taskMap[this.taskType][task.id] = task;
      }
      this.offset += tasks.length;
      this.noMoreToLoad = data.no_more_tasks;
      // this.main.tasksView.refreshAll();
    }
    /**
     * @methodOf TaskData
     * @param {Object} data
     */
    loadHidden (data) {
      const tasks = data.issues;
      if (!tasks) return;
      const self = this;
      tasks.forEach( (taskData) => {
        const task = self.createOrUpdate(taskData, 'issues');
        task._haveAllocations = true;
        self.taskMap['issues'][task.id] = task;
      });
    }
    /**
     * @methodOf TaskData
     * @param taskData
     * @return {Task}
     */
    createOrUpdate (taskData, task_type) {
      task_type = task_type || this.taskType;
      const taskId = taskData.id;
      /** @type {Task} */
      let task = this.getTaskById(taskId, task_type);
      if (!task) {
        task = new this.taskClasses[task_type](this.main);
      }
      task.update(taskData);
      return task;
    }
    /**
     * @methodOf TaskData
     * @param {int} id
     * @return {Task}
     */
    getTaskById (id, task_type) {
      task_type = task_type || this.taskType;
      return this.taskMap[task_type][id];
    }
  } 

  EasyCalendar.TaskData = TaskData;
})();
