(function () {
    window.easyMixins = window.easyMixins || {};
    window.easyMixins.agile = window.easyMixins.agile || {};
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};
    var agile = window.easyMixins.agile;

    agile.root = {
        settings: null,
        allIssuesMap: null,
        namePrefix: null,
        columnsData: null,
        changeInProgress: false,
        dragDomain: null,
        isPageModule: false,
        _preventSave: false,
        middleColumnsOrdering: [],
        i18n: {},
        _loadFromParams: function (params) {
            this.columnsData = params.columnsData;
            this.paramPrefix = params.update_params_prefix;
            this.namePrefix = params.assign_param_name;
            this.settings = params.settings;
            this.url = params.url;
            this.allIssuesMap = params.allIssuesMap;
            this.allMembersMap = params.allMembersMap;
            this.contextMenuUrl = params.contextMenuUrl;
            this.rootModel = params.rootModel;
            this.dragDomain = params.dragDomain;
            this.isPageModule = params.isPageModule;
            this.localStorageKey = params.localStorageKey;
            this.reloadAgile = params.reloadAgile;
            this.i18n = params.i18n || {};

            if (this.settings.issue_priorities) {
                window.easyModel = window.easyModel || {};
                window.easyModel.issue_priorities = this.settings.issue_priorities;
            }

            var options = this.settings.swimlane_categories;
            this.settings.swimlane_categories = options;

            var groupBy = null;
            try {
                groupBy = window.localStorage.getItem(this.localStorageKey);
            } catch (e) {
                console.log("local storage error");
            }
            if (params.swimlane){
                groupBy = params.swimlane;
            }
            var isOption = function (option) {
                return option.value === groupBy;
            };
            if (groupBy && options.some(isOption)) {
                this.groupBy = groupBy;
            } else {
                this.groupBy = "none";
            }

            var columnsData = this.columnsData;
            var settings = this.settings;
            var allIssuesMap = this.allIssuesMap;

            var haveBacklogColumn = !$.isEmptyObject(columnsData[0]);
            this.isBacklog = haveBacklogColumn;

            var haveDoneColumn = !$.isEmptyObject(columnsData[2]);
            this.isDone = haveDoneColumn;
            this._onChange = [];
            this.columns = this.columns || {};
            this.middleColumns = {};
            this.dials = {};

            var middleIssuesList = [];
            var backlogColumn;
            if (haveBacklogColumn) {
                var backlogColumnData = columnsData[0];
                var positioned = !(backlogColumnData.hasOwnProperty("positioned") && !backlogColumnData["positioned"]);
                backlogColumn = new easyClasses.agile.AgileColumn("backlog", backlogColumnData["entity_value"], backlogColumnData["max_entities"], settings["summable_attribute"], this, positioned);
                this.backlog = new window.easyClasses.Issues();
                this.backlog.init();
                this.backlogIssesCol = new easyClasses.agile.IssuesCol(this.backlog, null, backlogColumn, this);

                this.backlog.register(function (operation, issue) {
                    if (issue === null || issue === undefined)return;
                    if (operation === "add") {
                        this._sendChange({}, issue, this.backlogIssesCol.column.entityValue);
                    }
                }, this);
            }

            if (haveDoneColumn) {
                var doneColumnData = columnsData[2];
                positioned = !(doneColumnData.hasOwnProperty("positioned") && !doneColumnData["positioned"]);
                var doneColumn = new easyClasses.agile.AgileColumn(doneColumnData["name"], doneColumnData["entity_value"], doneColumnData["max_entities"], settings["summable_attribute"], this, positioned);
                this.done = new window.easyClasses.Issues();
                this.done.init();
                this.doneIssuesCol = new easyClasses.agile.IssuesCol(this.done, null, doneColumn, this);

                this.done.register(function (operation, issue) {
                    if (issue === null || issue === undefined)return;
                    if (operation === "add") {
                        this._sendChange({}, issue, this.doneIssuesCol.column.entityValue);
                    }
                }, this);
            }

            for (var key in allIssuesMap) {
                if (!allIssuesMap.hasOwnProperty(key))continue;
                var issue = allIssuesMap[key];
                if (haveBacklogColumn && issue["agile_column_filter_value"] == backlogColumn.entityValue) {
                    this.backlog.map[issue.id] = issue;
                    issue.issues = this.backlog;
                } else if (haveDoneColumn && issue["agile_column_filter_value"] == doneColumn.entityValue) {
                    this.done.map[issue.id] = issue;
                    issue.issues = this.done;
                } else {
                    middleIssuesList.push(issue);
                    issue.issues = middleIssuesList;
                }
            }

            this.middleColumnsData = columnsData[1]["children"];
            var middleIssues = new window.easyClasses.Issues();
            middleIssues.fromList(middleIssuesList);
            this.issues = middleIssues;

            if (haveBacklogColumn) {
                backlogColumn.issuesList = [this.backlog];
                backlogColumn.recalculateTimes();
                this.backlogColumn = backlogColumn;
                this.columns[backlogColumn.entityValue] = backlogColumn;
            }

            if (haveDoneColumn) {
                doneColumn.issuesList = [this.done];
                this.doneColumn = doneColumn;
                doneColumn.recalculateTimes();
                this.columns[doneColumn.entityValue] = doneColumn;
            }

            this.resolveSwimLanes();
        },
        _resetColumns: function (settings) {
            this.columns = this.columns || {};
            this.middleColumnsOrdering = [];
            for (var i = 0; i < this.middleColumnsData.length; i++) {
                var column = this.middleColumnsData[i];
                this.middleColumnsOrdering.push(column.entity_value);
                this.columns[column.entity_value] = new easyClasses.agile.AgileColumn(column["name"], column["entity_value"], column["max_entities"], this.settings["summable_attribute"], this, true);
                this.middleColumns[column.entity_value] = this.columns[column.entity_value];
            }
        },
        destroy: function () {
            this.columns = null;
            this.settings = null;
            this.saveQueue = null;
            this.saveInProgress = true;
            this.destroyed = true;
            this.dials = null;
            if (this.done) this.done.unRegister(this);
            if (this.backlog) this.backlog.unRegister(this);
        },
        setGroupBy: function (groupBy) {
            if (this.changeInProgress)return;
            if (groupBy) {
                this.groupBy = groupBy;
            } else {
                this.groupBy = "none";
            }
            try {
                window.localStorage.setItem(this.localStorageKey, this.groupBy);
            } catch (e) {
                console.log("swimlanes grouping cannot be saved to local storage");
            }
            this.resolveSwimLanes(groupBy);
            this._fireChanges("groupBySet");
        },
        _localStorageExpandedCache: null,
        /**
         *
         * @param {String} key
         */
        isExpanded: function(key){
            try {
                var map;
                if(this._localStorageExpandedCache == null){
                    map = window.localStorage.getItem(this.localStorageKey+"_expanded");
                    if(map == null || map == "undefined") {
                        this._localStorageExpandedCache = {};
                        return true;
                    }else{
                        map = JSON.parse(map);
                        this._localStorageExpandedCache = map;
                    }
                }else{
                    map = this._localStorageExpandedCache;
                }
                return !map.hasOwnProperty(key);
            } catch (e) {
               return true;
            }
        },
        /**
         *
         * @param {String} key
         * @param {boolean} isExpanded
         */
        setIsExpanded: function(key, isExpanded){
            try {
                var map = window.localStorage.getItem(this.localStorageKey+"_expanded");
                if(map == null || map == "undefined"){
                   map = {};
                }else{
                    map = JSON.parse(map);
                }
                if(isExpanded){
                    delete map[key];
                }else{
                    map[key] = false;
                }
                window.localStorage.setItem(this.localStorageKey+"_expanded", JSON.stringify(map));
                this._localStorageExpandedCache = map;
            } catch (e) {
            }
        },
        /**
         *
         * @return {boolean}
         */
        isGroupBySet: function () {
            return this.groupBy !== null && this.groupBy !== "none";
        },

        isSortable: function (issue, columnId) {
            if (!this.doneColumn || !this.backlogColumn) {
                // kanban output
                return false;
            }
            if (columnId === this.doneColumn.entityValue || columnId === this.backlogColumn.entityValue) {
                return true;
            }
            if (this.isGroupBySet()) {
                return false;
            }
            return this.columns[columnId].isSortable();
        },

        resolveSwimLanes: function () {
            if (this.changeInProgress)return;
            this.swimLanes = [];
            this.stickyLane = null;
            this._resetColumns();
            this._getIssuesGroupedByColumn();
            if (this.isGroupBySet()) {
                this._group();
            } else {
                this._oneSwimLane();
            }
        },
        _oneSwimLane: function () {
            if (this.changeInProgress)return;
            var swimLane = this.addSwimLane();
            swimLane.name = "";
            for (var i = 0; i < this.middleColumnsOrdering.length; i++) {
                var issues = new easyClasses.Issues();
                var column = this.middleColumns[this.middleColumnsOrdering[i]];
                issues.fromList(column.issueList);
                issues.firstInGlobalColumn = true;
                issues.register(function (operation, issue, column) {
                    if (issue === null || issue === undefined)return;
                    if (operation === "add") {
                        var data = {};
                        this._sendChange(data, issue, column.entityValue);
                    }
                }, this, column);
                swimLane.addCol(issues, column);
                column.issuesList = [issues];
            }
            for (i = 0; i < this.middleColumnsOrdering.length; i++) {
                this.middleColumns[this.middleColumnsOrdering[i]].recalculateTimes();
            }
        },
        _group: function () {
            if (this.changeInProgress)return;
            var key, columnKey, i;
            var groupList = {};

            if (this.dials.hasOwnProperty(this.groupBy)) {
                var allValues = this.dials[this.groupBy];
                for (var valueId in allValues) {
                    if (allValues.hasOwnProperty(valueId)) {
                        groupList[valueId] = allValues[valueId]
                    }
                }
            } else {
                this._fillDial();
                return;
            }

            for (columnKey in this.middleColumns) {
                if (!this.middleColumns.hasOwnProperty(columnKey))continue;
                this.middleColumns[columnKey].issuesList = [];
            }

            var first = true;
            for (key in groupList) {
                var swimLane = this.addSwimLane();
                swimLane.name = groupList[key].name;
                swimLane.order = groupList[key].order;
                swimLane.value = key;
                swimLane.iconType = this._getMemberType(groupList[key].id);
                swimLane.oneOfGroup = true;
                for (i = 0; i < this.middleColumnsOrdering.length; i++) {
                    var column = this.middleColumns[this.middleColumnsOrdering[i]];
                    var issues = new easyClasses.Issues();
                    issues.filterBy = this.groupBy;
                    issues.filterValue = key;
                    issues.firstInGlobalColumn = first;
                    issues.filterAndAdd(column.issueList);
                    issues.register(function (event, issue, columnAndIssues) {
                        if (issue === null || issue === undefined)return;
                        if (event === "add") {
                            var data = {};
                            data[this.groupBy] = columnAndIssues[1].filterValue;
                            this._sendChange(data, issue, columnAndIssues[0].entityValue);
                        }
                    }, this, [column, issues]);
                    column.issuesList.push(issues);
                    swimLane.addCol(issues, column);
                }
                first = false;
            }

            for (columnKey in this.middleColumns) {
                if (!this.middleColumns.hasOwnProperty(columnKey))continue;
                this.middleColumns[columnKey].recalculateTimes();
            }
            this.addStickyLane(groupList);
            this._sortSwimlanes();
        },
        _getMemberType: function (key) {
            var members = this.settings.project_members;
            for (var index in members){
                if (members[index].id == key) return members[index].type;
            }
            return "";

        },

        _sortSwimlanes: function () {
            var sorter = function (a, b) {
                return a.order - b.order;
            };

            var emptySwimlanes = [];
            var sortedBySorter = [];
            for (var i = 0; i < this.swimLanes.length; i++) {
                var swimlane = this.swimLanes[i];
                var found = false;
                for (var j = 0; j < swimlane.cols.length; j++) {
                    if (!$.isEmptyObject(swimlane.cols[j].issues.map)) {
                        found = true;
                        break;
                    }
                }
                if (found) {
                    sortedBySorter.push(swimlane);
                } else {
                    emptySwimlanes.push(swimlane);
                }
            }
            sortedBySorter.sort(sorter);
            emptySwimlanes.sort(sorter);
            sortedBySorter.push.apply(sortedBySorter, emptySwimlanes);
            this.swimLanes = sortedBySorter.slice(0, 100);
        },

        /**
         *
         * @private
         */
        _getIssuesGroupedByColumn: function () {
            var key, column;
            var issueMap = this.allIssuesMap;
            for (var clearKey in this.middleColumns) {
                if (!this.middleColumns.hasOwnProperty(clearKey))continue;
                this.middleColumns[clearKey].issueList = [];
            }

            for (key in issueMap) {
                if (!issueMap.hasOwnProperty(key))continue;
                var issue = issueMap[key];
                if (this.middleColumns.hasOwnProperty(issue["agile_column_filter_value"])) {
                    this.middleColumns[issue["agile_column_filter_value"]].issueList.push(issue);
                }
            }
            for (key in this.middleColumns) {
                if (!this.middleColumns.hasOwnProperty(key))continue;
                this.middleColumns[key].recalculateTimes();
            }
        },
        _fillDial: function () {
            var filterName = this.groupBy;
            if (!filterName.endsWith("_id")) {
                filterName += "_id";
            }
            this.changeInProgress = true;
            //noinspection JSUnresolvedVariable
            $.ajax(this.settings.available_values_url, {
                method: "GET",
                data: {
                    filter_name: filterName,
                    format: "json"
                }
            }).done($.proxy(function (data) {
                var dial = {};
                var i, key;
                function fillDialWithData() {
                  for (i = 0; i < data.length; i++) {
                    dial[data[i][1]] = {name: data[i][0], order: i}
                  }
                }

                if (this.groupBy === "assigned_to_id") {
                    fillDialWithData();
                    dial["undefined"] = {name: this.i18n.not_assigned};
                } else if (this.groupBy === "fixed_version_id") {
                    fillDialWithData();
                    dial["undefined"] = {name: this.i18n.issue_no_in_milestone};
                } else if (this.groupBy === "parent_id") {
                    var issueId;
                    var parentsMap = [];
                    var issuesMap = this.allIssuesMap;

                    for (key in issuesMap) {
                        if (!issuesMap.hasOwnProperty(key) || issuesMap[key].parent_id === null) continue;
                        parentsMap.push(issuesMap[key].parent_id.toString());
                    }
                    for (i = 0; i < data.length; i++) {
                        issueId = data[i][1];
                        if (parentsMap.indexOf(issueId) === -1) continue;
                        dial[data[i][1]] = {name: data[i][0], order: i}
                    }
                    dial["undefined"] = {name: this.i18n.issue_without_parent};
                } else if (this.groupBy === "author_id") {
                    for (i = 0; i < data.length; i++) {
                      // id "me" is not valid id
                      if (["author_id"].indexOf(filterName) !== -1 && data[i][1] === "me") continue;
                      dial[data[i][1]] = {name: data[i][0], order: i}
                    }
                } else if (this.groupBy === "category_id") {
                  fillDialWithData();
                  dial["undefined"] = {name: this.i18n.without_category};
                } else {
                    fillDialWithData();
                }
                this.dials[this.groupBy] = dial;
                this.changeInProgress = false;
                this._group();
                this._fireChanges("dialDownloaded");
            }, this)).fail($.proxy(function () {
                this.groupBy = "none";
                this._oneSwimLane();
                this._fireChanges("dialDownloaded");
            }, this));


        },
        _sendChange: function (data, issue, columnId, assigneeChanged = false, isEpic = false, additionalData = null) {
            if (this._preventSave)return;
            let editPath;
            var i;
            this.issue = issue;
            this.additionalData = additionalData;
            this.saveQueue = this.saveQueue || [];
            if (this.saveInProgress) {
                this.saveQueue.push([data, issue, columnId]);
                return;
            }
            this.saveInProgress = true;
            var out = {};
            var _self = this;
            data[this.namePrefix] = columnId;
            if (this.isSortable(issue, columnId)) {
                data["next_item_id"] = issue.next_item_id;
                data["prev_item_id"] = issue.prev_item_id;
                // out["issues"] = issue.issues.getPositions();
            }
            if (data.hasOwnProperty(_self.groupBy)) {
                if (data[_self.groupBy] == "undefined") {
                    data[_self.groupBy] = "";
                }
            }
            if (!assigneeChanged)  {
                out[_self.paramPrefix] = data;
            }
            out["format"] = "json";
            if (isEpic) {
                const sprintId = !!data.sprint_id ? data.sprint_id: null;
                editPath = `${issue.edit_path}?id=${sprintId}`;
                const reqBody = {
                    issue_easy_sprint_relation: {
                        phase: -1,
                        assigned_to_id: data.assigned_to_id
                    }
                };
                if (assigneeChanged) {
                    out = Object.assign(out, reqBody);
                }
            } else {
                editPath = issue.edit_path;
            }
            $.ajax(editPath, {
                method: 'PATCH',
                data: out
            }).done(function (data) {
                if (_self.destroyed)return;
                _self.saveInProgress = false;
                if (_self.saveQueue.length > 0) {
                    var first = _self.saveQueue.shift();
                    _self._sendChange(first[0], first[1], first[2]);
                }

                if (!data){
                    _self.issue.error = false;
                    _self.issue._fireChanges();
                    return;
                }

                if (!assigneeChanged) {
                    var changedIssue = _self.issue;
                    changedIssue.error = false;
                    if (data.issue.easy_sprint){
                        changedIssue.easy_sprint_id = data.issue.easy_sprint.id;
                    }
                    if (_self.rootModel && _self.rootModel.allUsers) {
                        changedIssue.newData(data["issue"], _self.rootModel.allUsers);
                    }
                    _self._fireChanges("issue", changedIssue.id);

                    if (data.positions && _self.isSortable(issue, columnId)) {
                        for (i = 0; i < data.positions.length; i++) {
                            var position = data.positions[i];
                            var issue = _self.allIssuesMap[position.issue_id];
                            if (!issue) continue;
                            issue.agile_column_position = position.position;
                        }
                    }
                    _self._fireChanges("sort");
                } else {
                    if ( !_self.additionalData && !_self.additionalData.issue && !data.issue ) return;
                    const assignee = !!data.issue.assigned_to ? data.issue.assigned_to : {};
                    const avatarUser = {
                        avatar:  !!assignee.avatar ? assignee.avatar : null,
                        id: !!assignee.id ? assignee.id : null,
                        name: !!assignee.name ? assignee.name : ""
                    };

                    _self.additionalData.issue.avatar = avatarUser.avatar;
                    _self.additionalData.issue.assigned_to = avatarUser.name;
                    _self.additionalData.issue.assigned_to_id = avatarUser.id;
                    _self.additionalData.issue.assignedUser = avatarUser;

                    _self.additionalData._repaintCore();
                }
            })
                .fail(function (e) {
                    _self._handleChangeError(issue, e);
                });
        },
        _handleChangeError: function (issue, errorObject) {
            this.saveInProgress = false;
            if (this.saveQueue.length > 0) {
                var first = this.saveQueue.shift();
                this._sendChange(first[0], first[1], first[2]);
            }
            if (errorObject.status === 200) {
                issue.error = false;
                issue._fireChanges();
                return;
            }
            issue.error = true;
            if (errorObject.status === 403) {
                issue.errorMessage = this.i18n.not_authorized;
                showFlashMessage("error", this.i18n.not_authorized);
                return;
            }
            if ([422, 404 /* place error codes with error body here!!! */].indexOf(errorObject.status) === -1) {
                if (!window.navigator.onLine) {
                  showFlashMessage("error", this.i18n.you_are_offline);
                } else {
                  showFlashMessage("error", this.i18n.internal_error);
                }
                return;
            }
            var data = errorObject.responseJSON;
            if (!data) {
                issue.errorMessage = "Unknown error on issue #" + issue.id;
                showFlashMessage("error", issue.errorMessage);
                return;
            }
            if (data.error) {
                data.errors = [data.error];
            }
            if (data.errors) {
                for (var i = 0; i < data.errors.length; i++) {
                    issue.errorMessage = data.errors[i] + " issue #" + issue.id;
                    showFlashMessage("error", issue.errorMessage);
                }
                if (issue.undo) {
                    this._preventSave = true;
                    var lastIssues = issue.issues;
                    issue.undo();
                    this._fireChanges("issues", issue.issues);
                    this._fireChanges("issues", lastIssues);
                    this._preventSave = false;
                }
            }
        },

        sendReorder: function (issues, column) {
            var _self = this;
            $.ajax(this.settings["reorder_path"], {
                method: 'POST',
                data: {
                    phase: column.entityValue,
                    issue_ids: issues.getPositions(),
                    format: "json"
                }
            }).done($.proxy(function (data) {
                if (data.positions) {
                    for (var i = 0; i < data.positions.length; i++) {
                        var position = data.positions[i];
                        var issue = _self.allIssuesMap[position.issue_id];
                        if (!issue)continue;
                        issue.agile_column_position = position.position;
                    }
                    _self._fireChanges("sort");
                }
            }, this))
                .fail($.proxy(function () {
                    showFlashMessage("warning", "Reorder failed - issues may jump vertical");
                }, this));
        },

        /**
         *
         * @param {String} href
         * @param {Function} onDone
         */
        sendBulkUpdate: function (href, onDone) {
            var _self = this;
            var i, issue;
            $.ajax(href, {
                method: "POST",
                data: {
                    "format": "json"
                }
            }).done($.proxy(function (data) {
                onDone();
                this.reloadAgile();
            }, _self)).fail($.proxy(function (data) {
                if (data.status === 200) {
                    this.reloadAgile();
                } else {
                    var json = data && data.responseJSON;
                    if (json.errors) {
                        for (var i = 0; i < json.errors.length; i++) {
                            showFlashMessage("error", json.errors[i]);
                        }
                    }
                }
                onDone();
            }, _self));
        },

        /**
         *
         * @param {Issue} issue
         * @param {String} columnId
         */
        sendPositionChange: function (issue, columnId) {
            const data = !!this.epic ? { sprint_id: issue.easy_sprint_id } : {};
            this._sendChange(data, issue, columnId, false, !!this.epic);
        },

        /**
         *
         * @param {int} [maxIssues]
         * @return {SwimLane}
         */
        addSwimLane: function (maxIssues) {
            var sl = new window.easyClasses.agile.SwimLane(this);
            if (this.swimLanes.length == 0) {
                sl.first = true;
            }
            sl.maxIssues = maxIssues;
            this.swimLanes.push(sl);
            return sl;
        },
        /**
         * @param {Object} groupList
         * @return {StickyLane}
         */
        addStickyLane: function (groupList) {
          var sl = new window.easyClasses.agile.StickyLane(this,groupList);
          this.stickyLane = sl;
          return sl;
        },

        /**
         * @param {Issue} issue
         */
        firePossiblePhases: function (issue) {
            this._fireChanges("possiblePhases", issue);
        },

        cancelPossiblePhases: function () {
            this._fireChanges("cancelPossiblePhases");
        }
    };

    /**
     *
     * @constructor
     * @param {KanbanRoot} kanbanRoot
     */
    function SwimLane(kanbanRoot) {
        this.cols = [];
        this.kanbanRoot = kanbanRoot;
        this.oneOfGroup = false;
    }

    /**
     *
     * @type {boolean}
     */
    SwimLane.prototype.first = false;

    /**
     *
     * @type {KanbanRoot}
     */
    SwimLane.prototype.kanbanRoot = null;

    /**
     *
     * @param {Issues} issues
     * @param {AgileColumn} column
     */
    SwimLane.prototype.addCol = function (issues, column) {
        this.cols.push(new IssuesCol(issues, this, column, this.kanbanRoot));
    };


    /**
     *
     * @type {Array.<IssuesCol>}
     */
    SwimLane.prototype.cols = null;

    /**
     * @return {Array}
     */
    SwimLane.prototype.getData = function () {
        var out = [];
        for (var i = 0; i < this.cols.length; i++) {
            out.push(this.cols[i].getData());
        }
        return out;
    };


    /**
     *
     * @type {string}
     */
    SwimLane.prototype.name = "";


    window.easyClasses.agile.SwimLane = SwimLane;


    /**
     *
     * @constructor
     * @param {Issues} issues
     * @param {SwimLane} [parent]
     * @param {AgileColumn} column
     * @param {KanbanRoot} agileRootModel
     */
    function IssuesCol(issues, parent, column, agileRootModel) {
        this.issues = issues;
        this.parent = parent;
        this.column = column;
        this.agileRootModel = agileRootModel;
    }

    /**
     *
     * @type {AgileColumn}
     */
    IssuesCol.prototype.column = null;

    /**
     * @param {Issue} issue
     * @return {boolean}
     */
    IssuesCol.prototype.issueCanBePlacedHere = function (issue) {
        var isInPhase = issue.getPossiblePhases().indexOf(this.column.entityValue) !== -1;
        if (this.parent === null && isInPhase) {
            // done, backlog, no swimlanes
            return true;
        }
        if (this.parent !== null) {
            // swimlanes
            if (this.parent.value === "undefined") {
                // swimlane with no value
                if (issue.getRequiredAttributeNames().indexOf(this.parent.value) !== -1) {
                    // value is required
                    return false;
                }
                return isInPhase;
            }

            if (issue.getReadOnlyAttributeNames().indexOf(this.agileRootModel.groupBy) !== -1) {
                return issue[this.agileRootModel.groupBy] == this.parent.value && isInPhase;
            }

            return isInPhase;
        }
    };


    /**
     *
     * @type {KanbanRoot}
     */
    IssuesCol.prototype.agileRootModel = null;

    /**
     *
     * @param {Issue} issue
     */
    IssuesCol.prototype.sendPositionChange = function (issue) {
        var swimlaneOneOfGroup = this.parent && this.parent.oneOfGroup;
        if (this.column.isSortable() && !swimlaneOneOfGroup) {
            $.proxy(this.agileRootModel.sendPositionChange(issue, this.column.entityValue), this.agileRootModel);
        }
    };

    /**
     *
     * @type {KanbanRoot}
     */
    IssuesCol.prototype.agileRootModel = null;

    /**
     *
     * @type {SwimLane}
     */
    IssuesCol.prototype.parent = null;


    /**
     *
     * @returns {Array}
     */
    IssuesCol.prototype.getData = function () {
        return this.issues.getData();
    };
    /**
     *
     * @type {Issues}
     */
    IssuesCol.prototype.issues = null;

    window.easyClasses.agile.IssuesCol = IssuesCol;


    /**
     *
     * @param {String} name
     * @param {int} entityValue
     * @param {int} maxEntities
     * @param {*} summable
     * @param {KanbanRoot} agileRootModel
     * @param {boolean} isSortable
     * @constructor
     */
    function AgileColumn(name, entityValue, maxEntities, summable, agileRootModel,
                         isSortable, sprintId, showIssuesCount, issuesCount, phase) {
        this.name = name;
        this.entityValue = entityValue;
        this.maxEntities = Number(maxEntities);
        this.issueList = [];
        this.summableString = "";
        this.issuesList = [];
        this.agileRootModel = agileRootModel;
        this.summable = summable;
        this._isSortable = isSortable;
        this.sprintId = sprintId;
        this.showIssuesCount = showIssuesCount;
        this.issuesCount = issuesCount;
        this.phase = phase
    }

    AgileColumn.prototype.isSortable = function () {
        return this._isSortable;
    };


    AgileColumn.prototype.recalculateTimes = function () {
        if (!this.summable)return;
        var key, issue, allIssues;

        var totalNumerator = 0; // čitatel
        var totalDenominator = 0; // jmenovatel

        var numeratorAttr = this.summable["numerator"]["attr"];
        var denominatorAttr;
        var showDenominator = this.summable["denominator"] && this.summable["denominator"]["attr"];

        if (showDenominator) {
            denominatorAttr = this.summable["denominator"]["attr"];
        }

        if (this.showIssuesCount) {
            let firstCondition;
            let seccondConditon;
            let useBothCondtion;
            if (this.phase === "issueBacklog"){
                firstCondition = "0";
                seccondConditon = null;
                useBothCondtion = true;
            } else {
                firstCondtion = this.phase;
                useBothCondtion = false;
                seccondConditon = false;
            }
            totalDenominator = Number(this.issuesCount);
            allIssues = this.agileRootModel.allIssuesMap;
            for (key in allIssues) {
                if (!allIssues.hasOwnProperty(key)) continue;
                issue = allIssues[key];
                if (issue.hasOwnProperty("agile_column_filter_value") &&( issue.agile_column_filter_value === firstCondition || (useBothCondtion && issue.agile_column_filter_value === seccondConditon ))) {
                    totalNumerator ++;
                }
            }
            if (totalDenominator > this.maxEntities){
               const diffNumber = totalNumerator - this.maxEntities;
                totalDenominator += diffNumber
            } else {
                totalDenominator = totalNumerator
            }
        } else {

            for (var j = 0; j < this.issuesList.length; j++) {
                var issueMap = this.issuesList[j].map;
                for (key in issueMap) {
                    if (!issueMap.hasOwnProperty(key)) continue;
                    issue = issueMap[key];

                    if (showDenominator) {
                        if (issue.hasOwnProperty(denominatorAttr)) {
                            totalDenominator += issue[denominatorAttr];
                        }
                }

                if (issue.hasOwnProperty(numeratorAttr)) {
                    totalNumerator += issue[numeratorAttr];
                }
            }
        }

        if (this.summable["numerator"]["scope"] && this.summable["numerator"]["scope"] === "all") {
            allIssues = this.agileRootModel.allIssuesMap;
            totalNumerator = 0;
            for (key in allIssues) {
                if (!allIssues.hasOwnProperty(key))continue;
                issue = allIssues[key];
                if (issue.hasOwnProperty(numeratorAttr)) {
                    totalNumerator += issue[numeratorAttr];
                }
            }
        }

            if (this.summable["denominator"]["scope"] && this.summable["denominator"]["scope"] === "all") {
                allIssues = this.agileRootModel.allIssuesMap;
                totalDenominator = 0;
                for (key in allIssues) {
                    if (!allIssues.hasOwnProperty(key)) continue;
                    issue = allIssues[key];
                    if (issue.hasOwnProperty(denominatorAttr)) {
                        totalDenominator += issue[denominatorAttr];
                    }
                }
            }
        }


        if (showDenominator) {
            this.summableString = Math.round(totalNumerator) + " / " + Math.round(totalDenominator);
        } else {
            this.summableString = Math.round(totalNumerator);
        }
    };

    /**
     *
     * @type {Array.<Issue>}
     */
    AgileColumn.prototype.issueList = null;
    /**
     *
     * @type {Array.<Issues>}
     */
    AgileColumn.prototype.issuesList = null;

    /**
     *
     * @type {string}
     */
    AgileColumn.prototype.name = "";

    /**
     *
     * @type {String}
     */
    AgileColumn.prototype.entityValue = null;

    /**
     *
     * @type {int}
     */
    AgileColumn.prototype.maxEntities = null;


    window.easyClasses.agile.AgileColumn = AgileColumn;
})();
