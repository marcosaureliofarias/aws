(function () {
  "use strict";

  class Task {
    /**
     * @abstract
     * @param {CalendarMain} main
    */

    constructor (main) {
      if (new.target === Task) throw new TypeError("Cannot construct Abstract instances directly");
      this.main = main;
    }
    /**
     * @methodOf Task
     * @param {String} key
     * @param {*} value
     * @return {boolean}
     */
    set (key, value) {
      if (this[key] === value) return false;
      if (!this._old) this._old = {};
      this._old[key] = this[key];
      this[key] = value;
      this._changed = true;
      this.main.eventBus.fireEvent("taskChanged", this, key, value);
      return true;
    }
    /**
     * @methodOf Task
     * @param data
     */
    update (data) {
      $.extend(this, data);
    }
    /**
     *
     * @methodOf Task
     * @return {{}} extra parameters for saver
     */
    extraParams () {
      // TODO
      return {};
    }
    /**
     *
     * @methodOf Task
     * @param {Array} events
     * @return {{}}
     */
    toSaveMap (events) {
      // TODO
      return {};
    }
  }

  //####################################################################################################################
  /**
   *
   * @class
   * @constructor
   * @property {int} id
   * @property {String} subject
   * @property {int} assigned_to_id
   * @property {Object} _old
   * @property {int} estimated_hours
   * @property {int} spent_hours
   * @property {boolean} _changed
   * @property {Array.<int>} possible_assignee_ids
   * @property {boolean} _haveAllocations
   * @property {int} custom_allocated_hours
   * @property {{editable:boolean}} permissions
   * @property {Array.<{id:String}>|null} _exceptEventIds
   */
  class Issue extends Task {
    constructor (main) {
      super(main);
      this.estimated_hours = 0;
      this.spent_hours = 0;
      this.custom_allocated_hours = 0;
      this._exceptEventIds = null;
      this.params_key = 'issue';
    }
    /**
     * @staticMethodOf Issue
     * @param {Object} data
     */
    static getObjectsByType (data) {
      return data.issues;
    }
    /**
     * @staticMethodOf Issue
     */
    static getTaskViewClass () {
      return EasyCalendar.IssueView;
    }
    /**
     * @methodOf Issue
     * @param data
     */
    update (data) {
      super.update(data);
      if (typeof data.start_date === "string") {
        this.start_date = new Date(data.start_date);
      }
      if (typeof data.due_date === "string") {
        this.due_date = new Date(data.due_date);
      }
      this.assigned_to_id = data.assigned_to_id || 0;
      this.subject = data.subject;
    }
    /**
     * @methodOf Issue
     * @return {Number}
     */
    getRestEstimated () {
      const taskId = this.id;
      let estimated = this.estimated_hours - this.spent_hours;
      const excepts = this._exceptEventIds;
      if (this._haveAllocations) {
        const events = this.main.scheduler._events;
        let ids = Object.getOwnPropertyNames(events);
        if (excepts) {
          ids = ids.filter(id => excepts.indexOf(id) === -1)
        }
        for (let i = 0; i < ids.length; i++) {
          const event = events[ids[i]];
          if (event.issue_id === taskId) {
            estimated -= (event.end_date - event.start_date) / 3600000;
          }
        }
      } else {
        estimated -= this.custom_allocated_hours;
      }
      estimated = Math.round(estimated * 100) / 100;
      return estimated;
    }
    /**
     * @methodOf Issue
     * @return {boolean}
     */
    fixRestEstimated () {
      const rest = this.getRestEstimated();
      if (rest < 0) {
        return this.set("estimated_hours", this.estimated_hours - rest);
      }
      return false;
    }
    /**
     * @methodOf Issue
     * @param {Array} [events]
     * @return {Array}
     */
    getMyEvents (events, _taskID) {
      const taskId = this.id || _taskID;
      if (!events) {
        events = this.main.utils.objectValues(this.main.scheduler._events);
      }
      return events.filter(event => event.issue_id === taskId);
    }
    /**
     * @methodOf Issue
     * @param {Date} date
     * @return {boolean}
     */
    datetimeInDuration (date) {
      if (this.start_date && date < this.start_date) return false;
      return !(this.due_date && date > this.due_date);
    }
    /**
     * @methodOf Issue
     * @param {Date} date
     * @return {boolean}
     */
    dateInDuration (date) {
      date = new Date(date);
      date.setHours(12);
      if (this.start_date && date < this.start_date) return false;
      date.setDate(date.getDate() - 1);
      return !(this.due_date && date > this.due_date);
    }
    /**
     *
     * @methodOf Issue
     * @param {Array} events
     * @return {{id: int, allocations}}
     */
    toSaveMap (events) {
      const taskId = this.id;
      const returnAlloc = (event) => {
        const startDate = moment(event.start_date);
        return {
          "date": startDate.format("YYYY-MM-DD"),
          "start": startDate.format("HH:mm"),
          "hours": (event.end_date - event.start_date) / 3600000
        };
      };
      return {
        "id": taskId,
        "allocations": events.filter(event => event.issue_id === taskId).map(returnAlloc)
      };
    }
  }

  EasyCalendar.Issue = Issue;

  //####################################################################################################################
  /**
   *
   * @class
   * @constructor
   * @property {int} id
   * @property {String} name
   * @property {int} assigned_to_id
   * @property {Date} contract_date
   * @property {Date} next_action
   * @property {Object} _old
   * @property {String} currency
   * @property {String} currency_symbol
   * @property {boolean} _changed
   * @property {Array.<int>} possible_assignee_ids
   * @property {Float} price
   * @property {{editable:boolean}} permissions
   */
  class CrmCase extends Task {
    constructor (main) {
      super(main);
      this.params_key = 'easy_crm_case';
    }
    /**
     * @staticMethodOf CrmCase
     * @param {Object} data
     */
    static getObjectsByType (data) {
      return data.crm_cases;
    }
    /**
     * @staticMethodOf CrmCase
     */
    static getTaskViewClass () {
      return EasyCalendar.CrmCaseView;
    }
    /**
     * @methodOf CrmCase
     * @param data
     */
    update (data) {
      super.update(data);
      if (typeof data.contract_date === "string") {
        this.contract_date = new Date(data.contract_date);
      }
      if (typeof data.next_action === "string") {
        this.next_action = new Date(data.next_action);
      }
      this.assigned_to_id = data.assigned_to_id || 0;
      this.price = parseFloat(data.price || 0);
      this.formattedPrice = data.currency_symbol + ' ' + this.price;
    }
    /**
     *
     * @methodOf Crmcase
     * @return {{'currency': task.currency}} extra parameters for saver
     */
    extraParams () {
      return $.extend(super.extraParams(), {'currency': this.currency});
    }
  }

  EasyCalendar.CrmCase = CrmCase;
})();
