window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.cashflow = ysy.pro.cashflow || {};
EasyGem.extend(ysy.pro.cashflow, {
  _resetProjects: function () {
    var setting = ysy.settings.cashflow;
    var projects = ysy.data.projects.getArray();
    for (var i = 0; i < projects.length; i++) {
      delete projects[i]['_planned_expenses'];
      delete projects[i]['_planned_revenues'];
      delete projects[i]['_real_revenues'];
      delete projects[i]['_real_revenues'];
    }
    setting.setSilent({plannedLoaded: false, realLoaded: false, activeCashflow: "nothing"});
  },
  /**
   *
   * @param typeCashflow {string}
   */
  showCashflow: function (typeCashflow) {
    var setting = ysy.settings.cashflow;
    var changeDate = false;
    if (setting.activeCashflow === typeCashflow) return;
    var projects = ysy.data.projects.getArray();
    setting.setSilent("activeCashflow", typeCashflow);
    if ((!setting.plannedLoaded && setting.activeCashflow === "planned" )|| (!setting.realLoaded && setting.activeCashflow === "real" )) {
      this._handleCashflow();
    } else {
      if(!setting.open){
       changeDate = true;
      }
    }
    for (var i = 0; i < projects.length; i++) {
      var project = projects[i];
      if (changeDate){
        if (project.cashflow){
          let cashflowData = project.cashflow;
          if (cashflowData.cashflowStartDate && project.start_date.isAfter(cashflowData.cashflowStartDate)){
            project.setSilent("start_date", cashflowData.cashflowStartDate);
          }
          if (cashflowData.originEndDate && project.end_date.isBefore(cashflowData.cashflowEndDate)){
            project.setSilent("end_date", cashflowData.cashflowEndDate);
          }
        }
      }
      project._fireChanges(this, "CashFlow");
    }
    setting.setSilent("open", true);
  },
  _handleCashflow: function () {
    var projects = ysy.data.projects.getArray();
    var ids = projects.map(function (project) {
      return project.id;
    });
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.cashflow,
        {
          project_ids: ids,
          include_planned: this._loadDataFor('planned') ? 1 : 0,
          include_real: this._loadDataFor('real') ? 1 : 0
        },
        $.proxy(this._loadProjects, this),
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    );
  },
  /**
   *
   * @param type {"planned" , "real"}
   * @returns {boolean}
   * @private
   * valid type attribute is planned or real
   */
  _loadDataFor: function (type) {
    var dontLoad = null;
    if (type === 'planned') {
      dontLoad = 'real';
    } else if (type === 'real') {
      dontLoad = 'planned';
    }
    var setting = ysy.settings.cashflow;
    if (setting[type + "Loaded"]) return false;
    else return setting.activeCashflow !== dontLoad;
  },
  _loadProjects: function (json) {
    if (!json) return;
    var projects = ysy.data.projects;
    var setting = ysy.settings.cashflow;
    var addPlanned = false;
    var addReal = false;
    var ids = Object.getOwnPropertyNames(json);
    for (var i = 0; i < ids.length; i++) {
      var id = ids[i];
      var project = projects.getByID(id);
      var projectJson = json[id];
      var limits = {
        startDate: "9999-12-31",
        endDate: "0000-01-01"
      };
      if (projectJson.planned_expenses) {
        project._planned_expenses = projectJson.planned_expenses;
        this.findLimits(projectJson.planned_expenses, limits);
        addPlanned = true;
      }
      if (projectJson.planned_revenues) {
        project._planned_revenues = projectJson.planned_revenues;
        this.findLimits(projectJson.planned_revenues, limits);
        addPlanned = true;
      }
      if (projectJson.real_expenses) {
        project._real_expenses = projectJson.real_expenses;
        this.findLimits(projectJson.real_expenses, limits);
        addReal = true;
      }
      if (projectJson.real_revenues) {
        project._real_revenues = projectJson.real_revenues;
        this.findLimits(projectJson.real_revenues, limits);
        addReal = true;
      }
      var start_date = moment(limits.startDate);
      var end_date = moment(limits.endDate);
      project.cashflow =  project.cashflow || {};
      var cashflowDate = project.cashflow;
      if (project.start_date.isAfter(start_date)) {
        if (!cashflowDate.originStartDate){
          project.cashflow.originStartDate = project.start_date;
        }
        cashflowDate.cashflowStartDate = start_date;
        project.setSilent("start_date", start_date);
      }
      if (project.end_date.isBefore(end_date)) {
        end_date._isEndDate = true;
        if (!cashflowDate.originEndDate){
          project.cashflow.originEndDate = project.end_date;
        }
        cashflowDate.cashflowEndDate = end_date;
        project.setSilent("end_date", end_date);
      }
      ysy.log.debug("cashflow loaded", setting.activeCashflow);
      project._fireChanges(this, "CashFlow");
    }
    if (addPlanned) {
      setting.setSilent("plannedLoaded", true);
    }
    if (addReal) {
      setting.setSilent("realLoaded", true);
    }
  },
  findLimits: function (object, limits) {
    var dates = Object.getOwnPropertyNames(object).sort();
    if (limits.startDate > dates[0]) {
      limits.startDate = dates[0];
    }
    var positionLastDate = dates.length - 1;
    if (limits.endDate < dates[positionLastDate]) {
      limits.endDate = dates[positionLastDate];
    }
  }
});
