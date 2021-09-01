window.ysy = window.ysy || {};
ysy.data = ysy.data || {};
ysy.data.loader = ysy.data.loader || {};
ysy.data.loader.checkIntegrity = function (json) {
  var minLimit;
  var maxLimit;
  var limit = 2980;
  // var limit = 6;
  var today = moment().format("YYYY-MM-DD");
  var checkMinMax = function (array) {
    var minDate;
    var maxDate;
    for (var i = 0; i < array.length; i++) {
      var task = array[i];
      var startDate = moment(task.start_date);
      var endDate = moment(task.due_date);
      if (!minDate || minDate.isAfter(startDate)) {
        minDate = startDate;
      }
      if (!maxDate || maxDate.isBefore(endDate)) {
        maxDate = endDate;
      }
    }
    if (!maxDate || !minDate) return false;
    return maxDate.diff(minDate, "days") > limit;
  };
  /**
   * @typedef {{name:string,start_date:string,due_date:string,project_id:int,id:int}} UnparsedGanttEntity
   * @typedef {{entity:UnparsedGanttEntity,isLeft:boolean}} UnparsedGanttEntityWithFlag
   */
  /**
   * @param {{projects:Array.<UnparsedGanttEntity>,issues:Array.<UnparsedGanttEntity>,versions:Array.<UnparsedGanttEntity>}} json
   * @return {{projects:Array.<UnparsedGanttEntityWithFlag>,issues:Array.<UnparsedGanttEntityWithFlag>,versions:Array.<UnparsedGanttEntityWithFlag>}}
   */
  var filterOutliers = function (json) {
    var issues = json.issues || [];
    var projects = json.projects || [];
    var versions = json.versions || [];
    var startDate, dueDate, i;

    var innerIssues = [];
    var innerVersions = [];
    /** @type {Array.<UnparsedGanttEntityWithFlag>} */
    var outerIssues = [];
    /** @type {Array.<UnparsedGanttEntityWithFlag>} */
    var outerVersions = [];
    var outerProjectIds = {};
    /** @type {Array.<UnparsedGanttEntityWithFlag>} */
    var outerProjects = [];
    /** @type {UnparsedGanttEntity} */
    var entity;
    /** @type {Array.<String>} */
    var allDates = [];
    /**
     * @param {UnparsedGanttEntity} entity
     */
    var extractDate = function (entity) {
      if (entity.start_date) {
        allDates.push(entity.start_date);
      }
      if (entity.due_date) {
        allDates.push(entity.due_date);
      }
    };
    issues.forEach(extractDate);
    projects.forEach(extractDate);
    versions.forEach(extractDate);
    if (allDates.length === 0) {
      return {issues: outerIssues, versions: outerVersions, projects: outerProjects}
    }
    allDates.sort();
    var middle = moment(allDates[Math.floor(allDates.length / 2)]);
    minLimit = moment(middle - limit / 2 * 24 * 60 * 60 * 1000).format("YYYY-MM-DD");
    maxLimit = moment(middle + limit / 2 * 24 * 60 * 60 * 1000).format("YYYY-MM-DD");
    // console.log(minLimit + " " + maxLimit);
    for (i = 0; i < issues.length; i++) {
      entity = issues[i];
      startDate = safeStartDate(entity);
      if (minLimit > startDate) {
        outerIssues.push({entity: entity, isLeft: true});
        outerProjectIds[entity.project_id] = true;
        continue;
      }
      dueDate = safeDueDate(entity);
      if (maxLimit < dueDate) {
        outerIssues.push({entity: entity, isLeft: false});
        outerProjectIds[entity.project_id] = true;
        continue;
      }
      innerIssues.push(entity);
    }
    for (i = 0; i < versions.length; i++) {
      entity = versions[i];
      startDate = safeStartDate(entity);
      if (minLimit > startDate) {
        outerVersions.push({entity: entity, isLeft: true});
        outerProjectIds[entity.project_id] = true;
        continue;
      }
      dueDate = safeDueDate(entity);
      if (maxLimit < dueDate) {
        outerVersions.push({entity: entity, isLeft: false});
        outerProjectIds[entity.project_id] = true;
        continue;
      }
      innerVersions.push(entity);
    }
    for (i = 0; i < projects.length; i++) {
      entity = projects[i];
      var isLeft = true;
      startDate = safeStartDate(entity);
      if (minLimit <= startDate) {
        isLeft = false;
        dueDate = safeDueDate(entity);
        if (maxLimit >= dueDate) {
          if (!outerProjectIds[entity.id]) {
            continue;
          } else {
            isLeft = true;
          }
        }
      }
      outerProjects.push({entity: $.extend({}, entity), isLeft: isLeft});
      if (isLeft) {
        entity.start_date = minLimit;
        if (entity.due_date < minLimit) {
          entity.due_date = minLimit;
        } else {
          if (entity.due_date > maxLimit) {
            entity.due_date = maxLimit;
          }
        }
      } else {
        entity.due_date = maxLimit;
        if (entity.start_date < maxLimit) {
          entity.start_date = maxLimit;
        }
      }
    }
    json.issues = innerIssues;
    json.versions = innerVersions;
    return {issues: outerIssues, versions: outerVersions, projects: outerProjects};
  };
  /**
   * @param {UnparsedGanttEntity} entity
   * @return {string}
   */
  var safeStartDate = function (entity) {
    if (entity.start_date) return entity.start_date;
    if (entity.due_date && entity.due_date < today) return entity.due_date;
    return today;
  };
  /**
   * @param {UnparsedGanttEntity} entity
   * @return {string}
   */
  var safeDueDate = function (entity) {
    if (entity.due_date) return entity.due_date;
    if (entity.start_date && entity.start_date > today) return entity.start_date;
    return today;
  };
  /**
   * @param {{projects:Array.<UnparsedGanttEntityWithFlag>,issues:Array.<UnparsedGanttEntityWithFlag>,versions:Array.<UnparsedGanttEntityWithFlag>}} outliers
   * @return {Object}
   */
  var enhanceOutliers = function (outliers) {
    var dateFormat = ysy.main.toMomentFormat(ysy.settings.dateFormat);
    $.extend(outliers, {
      limit: limit,
      minLimit: moment(minLimit).format(dateFormat),
      maxLimit: moment(maxLimit).format(dateFormat)
    });

    outliers.issues.forEach(function (flagged) {
      if (flagged.isLeft) {
        // noinspection JSUndefinedPropertyAssignment
        flagged.date = moment(safeStartDate(flagged.entity)).format(dateFormat);
      } else {
        // noinspection JSUndefinedPropertyAssignment
        flagged.date = moment(safeDueDate(flagged.entity)).format(dateFormat);
      }
    });
    outliers.versions.forEach(function (flagged) {
      // noinspection JSUndefinedPropertyAssignment
      flagged.date = moment(safeStartDate(flagged.entity)).format(dateFormat);
    });
    outliers.projects.forEach(function (flagged) {
      if (flagged.isLeft) {
        // noinspection JSUndefinedPropertyAssignment
        flagged.date = moment(safeStartDate(flagged.entity)).format(dateFormat);
      } else {
        // noinspection JSUndefinedPropertyAssignment
        flagged.date = moment(safeDueDate(flagged.entity)).format(dateFormat);
      }
    });
    return outliers;
  };
  var overLimit = checkMinMax(json.projects);
  if (overLimit) {
    var outliers = filterOutliers(json);
    var enhancedOutliers = enhanceOutliers(outliers);
    if (enhancedOutliers.issues.length !== 0 || enhancedOutliers.versions.length !== 0) {
      dhtmlx.message(Mustache.render(ysy.view.templates.integrityCheck, enhancedOutliers), "error");
    }
    return false;
  }
  return true;
};