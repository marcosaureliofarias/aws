EasyGem.module.part("easyAgile", ["ActiveClass"], function () {
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   *
   * @param {RootModel} rootModel
   * @param {Array} columnsData
   * @param {String} paramPrefix
   * @param {String} namePrefix
   * @param {*} settings
   * @param {String} contextMenuUrl
   * @param {Object} epic
   * @param {Boolean} reloadAgile
   * @extends ActiveClass
   * @constructor
   */
  function EpicBacklogRoot(rootModel, columnsData, paramPrefix, namePrefix, settings, i18n, contextMenuUrl, epic, reloadAgile) {
    this.paramPrefix = paramPrefix;
    this.namePrefix = namePrefix;
    this.rootModel = rootModel;
    this._onChange = [];
    this._preventSave = false;
    this.columns = this.columns || {};
    this.allIssuesMap = rootModel.allIssues.map;
    this.dragDomain = "epicAgileBacklog";
    this.contextMenuUrl = contextMenuUrl;
    this.epic = epic;
    this.reloadAgile = reloadAgile;
    this.i18n = i18n || {};

    if (settings.issue_priorities) {
      window.easyModel = window.easyModel || {};
      window.easyModel.issue_priorities = settings.issue_priorities;
    }
    this.settings = settings;
    let issuesColumnData = columnsData[0];
    let positioned = !(issuesColumnData.hasOwnProperty("positioned") && !issuesColumnData["positioned"]);
    let issuesColumn = new easyClasses.agile.AgileColumn(issuesColumnData["name"], issuesColumnData["entity_value"], issuesColumnData["max_entities"], settings["summable_attribute"], this, positioned);

    this.sprintBacklogs = [];
    this.sprintBacklogsIssuesCol = [];
    columnsData[1].forEach((sprintColumnData, i) => {
      positioned = !(sprintColumnData.hasOwnProperty("positioned") && !sprintColumnData["positioned"]);
      const sprintColumn = new easyClasses.agile.AgileColumn(
        sprintColumnData["name"],
        sprintColumnData["entity_value"],
        sprintColumnData["max_entities"],
        settings["summable_attribute"],
        this,
        positioned,
        sprintColumnData["easy_sprint_id"]
        );
      if (sprintColumn) {
        this.sprintBacklogs[i] = new window.easyClasses.Issues();
        this.sprintBacklogs[i].init();
        this.sprintBacklogsIssuesCol[i] = new easyClasses.agile.IssuesCol(this.sprintBacklogs[i], null, sprintColumn, this);
      }

      for (const key in rootModel.allIssues.map) {
        if (!rootModel.allIssues.map.hasOwnProperty(key)) continue;
        const issue = rootModel.allIssues.map[key];
        if (sprintColumn && issue["agile_column_filter_value"] == sprintColumn.sprintId) {
          this.sprintBacklogs[i].add(issue);
        }
      }

      if (sprintColumn) {
        this.columns[sprintColumn.entityValue] = sprintColumn;
        this.sprintBacklogs[i].register(function (event, issue) {
          const data = {
            sprint_id: this.sprintBacklogsIssuesCol[i].column.sprintId
          };
          if (issue === null || issue === undefined) return;
          if (event === "add") {
            this._sendChange(data, issue, this.sprintBacklogsIssuesCol[i].column.entityValue, false, !!this.epic);
          }
        }, this);
        sprintColumn.recalculateTimes();
      }
    });

    this.issues = new easyClasses.Issues();
    this.issues.init();
    this.notAssignedIssuesCol = new easyClasses.agile.IssuesCol(this.issues, null, issuesColumn, this);

    for (const key in rootModel.allIssues.map) {
      if (!rootModel.allIssues.map.hasOwnProperty(key)) continue;
      let issue = rootModel.allIssues.map[key];
      if (!issue["agile_column_filter_value"]) {
        this.issues.add(issue);
      }
    }

    this.columns[issuesColumn.entityValue] = issuesColumn;
    issuesColumn.recalculateTimes();

    this.issues.register(function (event, issue) {
      const data = {
        sprint_id: !!issue.easy_sprint_id ? issue.easy_sprint_id : ''
      };
      if (issue === null || issue === undefined) return;
      if (event === "add") {
        this._sendChange(data, issue, this.notAssignedIssuesCol.column.entityValue, false, !!this.epic);
      }
    }, this);


    this.sendPositionChange = window.easyMixins.agile.root.sendPositionChange;
    this._handleChangeError = window.easyMixins.agile.root._handleChangeError;
    this.sendBulkUpdate = window.easyMixins.agile.root.sendBulkUpdate;
    this._sendChange = window.easyMixins.agile.root._sendChange;
    this.sendReorder = window.easyMixins.agile.root.sendReorder;
    this.firePossiblePhases = window.easyMixins.agile.root.firePossiblePhases;
    this.cancelPossiblePhases = window.easyMixins.agile.root.cancelPossiblePhases;
  }

  window.easyClasses.ActiveClass.extendByMe(EpicBacklogRoot);


  EpicBacklogRoot.prototype.isSortable = function (issue, columnId) {
    return this.columns[columnId].isSortable();
  };

  /**
   *
   * @type {{String:AgileColumn}}
   */
  EpicBacklogRoot.prototype.columns = null;


  /**
   *
   * @type {Issues}
   */
  EpicBacklogRoot.prototype.backlog = null;

  window.easyClasses.agile.EpicBacklogRoot = EpicBacklogRoot;


});
