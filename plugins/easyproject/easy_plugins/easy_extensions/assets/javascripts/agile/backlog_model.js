EasyGem.module.part("easyAgile",["ActiveClass"],function () {
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
     * @extends ActiveClass
     * @constructor
     */
    function BacklogRoot(rootModel, columnsData, paramPrefix, namePrefix, settings, contextMenuUrl, reloadAgile) {
        this.paramPrefix = paramPrefix;
        this.namePrefix = namePrefix;
        this.rootModel = rootModel;
        this._onChange = [];
        this._preventSave = false;
        this.columns = this.columns || {};
        this.allIssuesMap = rootModel.allIssues.map;
        this.dragDomain = "agileBacklog";
        this.contextMenuUrl = contextMenuUrl;
        this.reloadAgile = reloadAgile;

        if (settings.issue_priorities) {
            window.easyModel = window.easyModel || {};
            window.easyModel.issue_priorities = settings.issue_priorities;
        }

        this.settings = settings;
        var issuesColumnData = columnsData[0];
        var positioned = !(issuesColumnData.hasOwnProperty("positioned") && !issuesColumnData["positioned"]);
        var issuesColumn = new easyClasses.agile.AgileColumn(issuesColumnData["name"], issuesColumnData["entity_value"], "100", settings["summable_attribute"], this, positioned, null, true, issuesColumnData["issues_count"], "issueBacklog",);

        var backlogColumnData = columnsData[1];
        positioned = !(backlogColumnData.hasOwnProperty("positioned") && !backlogColumnData["positioned"]);
        var backlogColumn = new easyClasses.agile.AgileColumn(backlogColumnData["name"], backlogColumnData["entity_value"], backlogColumnData["max_entities"], settings["summable_attribute"], this, positioned);

        var sprintColumn;
        if (columnsData[2]) {
            var sprintColumnData = columnsData[2];
            positioned = !(sprintColumnData.hasOwnProperty("positioned") && !sprintColumnData["positioned"]);
            sprintColumn = new easyClasses.agile.AgileColumn(sprintColumnData["name"], sprintColumnData["entity_value"], sprintColumnData["max_entities"], settings["summable_attribute"], this, positioned);
        }

        this.sprintBacklog = null;
        this.sprintBacklogIssuesCol = null;

        if (sprintColumn) {
            this.sprintBacklog = new window.easyClasses.Issues();
            this.sprintBacklog.init();
            this.sprintBacklogIssuesCol = new easyClasses.agile.IssuesCol(this.sprintBacklog, null, sprintColumn, this);
        }


        this.backlog = new window.easyClasses.Issues();
        this.backlog.init();
        this.backlogIssesCol = new easyClasses.agile.IssuesCol(this.backlog, null, backlogColumn, this);

        this.issues = new easyClasses.Issues();
        this.issues.init();
        this.notAssignedIssuesCol = new easyClasses.agile.IssuesCol(this.issues, null, issuesColumn, this);

        for (var key in rootModel.allIssues.map) {
            if (!rootModel.allIssues.map.hasOwnProperty(key))continue;
            var issue = rootModel.allIssues.map[key];
            if (issue["agile_column_filter_value"] == backlogColumn.entityValue) {
                this.backlog.add(issue);
            } else if (sprintColumn && issue["agile_column_filter_value"] == sprintColumn.entityValue) {
                this.sprintBacklog.add(issue);
            } else {
                this.issues.add(issue);
            }
        }

        this.columns[backlogColumn.entityValue] = backlogColumn;
        this.columns[issuesColumn.entityValue] = issuesColumn;
        if (sprintColumn) {
            this.columns[sprintColumn.entityValue] = sprintColumn;
            this.sprintBacklog.register(function (event, issue) {
                if (issue === null || issue === undefined)return;
                if (event === "add") {
                    this._sendChange({}, issue, this.sprintBacklogIssuesCol.column.entityValue);
                }
            }, this);
            sprintColumn.recalculateTimes();
        }
        issuesColumn.recalculateTimes();
        backlogColumn.recalculateTimes();

        this.backlog.register(function (event, issue) {
            if (issue === null || issue === undefined)return;
            if (event === "add") {
                this._sendChange({}, issue, this.backlogIssesCol.column.entityValue);
            }
        }, this);


        this.issues.register(function (event, issue) {
            if (issue === null || issue === undefined)return;
            if (event === "add") {
                this._sendChange({}, issue, this.notAssignedIssuesCol.column.entityValue);
            }
            issuesColumn.recalculateTimes();
        }, this);


        this.sendPositionChange = window.easyMixins.agile.root.sendPositionChange;
        this._handleChangeError = window.easyMixins.agile.root._handleChangeError;
        this.sendBulkUpdate = window.easyMixins.agile.root.sendBulkUpdate;
        this._sendChange = window.easyMixins.agile.root._sendChange;
        this.sendReorder = window.easyMixins.agile.root.sendReorder;
        this.firePossiblePhases = window.easyMixins.agile.root.firePossiblePhases;
        this.cancelPossiblePhases = window.easyMixins.agile.root.cancelPossiblePhases;

    }

    window.easyClasses.ActiveClass.extendByMe(BacklogRoot);


    BacklogRoot.prototype.isSortable = function (issue, columnId) {
        return this.columns[columnId].isSortable();
    };

    /**
     *
     * @type {{String:AgileColumn}}
     */
    BacklogRoot.prototype.columns = null;

    BacklogRoot.prototype.destroy = function () {
        window.easyClasses.EasyWidget.prototype.destroy.apply(this);
        window.easyView.root.remove(this);
    };


    /**
     *
     * @type {Issues}
     */
    BacklogRoot.prototype.backlog = null;

    window.easyClasses.agile.BacklogRoot = BacklogRoot;


});
