(function () {
    window.easyClasses = window.easyClasses || {};

    /**
     * @constructor
     * @extends ActiveClass
     * @name Issue
     */
    function Issue() {
        this.error = false;
        this.errorMessage = null;
    }

    window.easyClasses.ActiveClass.extendByMe(Issue);

    /**
     * some properties changed, check for references
     * @param {*} data
     * @param {*} allUsers
     * @param {*} [workFlowSettings]
     */
    Issue.prototype.newData = function (data, allUsers, workFlowSettings) {
        if (data.assigned_to && data.assigned_to.id) {
            this.assigned_to_id = data.assigned_to.id;
        } else {
            this.assigned_to_id = null;
        }

        if (this.assignedUser !== null && this.assignedUser !== undefined) {
            if (this.assignedUser.id != this.assigned_to_id) {
                this.assignedUser = allUsers[this.assigned_to_id];
            }
        } else if (this.assigned_to_id !== null && this.assigned_to_id !== undefined) {
            this.assignedUser = allUsers[this.assigned_to_id];
        }
        if (data.sprint && data.sprint.id){
            this.easy_sprint_id = data.easy_sprint.id;
        }
        this.parent_id = data.parent_id;

        this.priority_id = data.priority.id;
        this.priority = data.priority.name;

        this.tracker_id = data.tracker.id;
        this.tracker = data.tracker.name;

        this.author_id = data.author.id;
        this.author = data.author.name;

        if(data.status){
            this.status_id = data.status.id;
            this.status = data.status.name;
        }

        if (data.css_classes) {
            this.css_classes = data.css_classes;
        }

        if (workFlowSettings) {
            if (workFlowSettings.possible_phases) {
                this.possible_phases = workFlowSettings.possible_phases;
            }
            if (workFlowSettings.read_only_attribute_names) {
                this.read_only_attribute_names = workFlowSettings.read_only_attribute_names;
            }
            if (workFlowSettings.required_attribute_names) {
                this.required_attribute_names = workFlowSettings.required_attribute_names;
            }
        }

        this._fireChanges("newData", this);
    };

    /**
     *
     * @return {String}
     */
    Issue.prototype.avatarHtml = function () {
        if (this.assignedUser !== null) {
            if (this.assignedUser !== undefined) {
                return this.assignedUser.avatarHtml;
            } else {
                return "user data missing for issue " + this.id;
            }
        } else {
            return easyTemplates.kanbanNoAssigneeAvatar;
        }
    };
    /**
     *
     * @return {String}
     */
    Issue.prototype.authorAvatarHtml = function () {
        if (this.assignedUser !== null) {
            if (this.assignedUser !== undefined) {
                return this.assignedUser.avatarHtml;
            } else {
                return "user data missing for issue " + this.id;
            }
        } else {
            return easyTemplates.kanbanNoAssigneeAvatar;
        }
    };

    /**
     *
     * @return {String}
     */
    Issue.prototype.assigneeName = function () {
        if (this.assignedUser !== null) {
            if (this.assignedUser !== undefined) {
                return this.assignedUser.name;
            } else {
                return "user data missing for issue " + this.id;
            }
        } else {
            return "no user";
        }
    };

    /**
     * @return {Array<String>}
     */
    Issue.prototype.getPossiblePhases = function () {
        if (typeof this.possible_phases === "undefined") {
            return null;
        }
        return this.possible_phases;
    };

    /**
     * @return {Array<String>}
     */
    Issue.prototype.getRequiredAttributeNames = function () {
        if (typeof this.required_attribute_names === "undefined") {
            return null;
        }
        return this.required_attribute_names;
    };

    /**
     * @return {Array<String>}
     */
    Issue.prototype.getReadOnlyAttributeNames = function () {
        if (typeof this.read_only_attribute_names === "undefined") {
            return null;
        }
        return this.read_only_attribute_names;
    };

    /**
     *
     * @type {Issues}
     */
    Issue.prototype.issues = null;

    /**
     *
     * @type {String}
     */
    Issue.prototype.edit_path = null;


    /**
     *
     * @type {number}
     */
    Issue.prototype.id = null;

    /**
     *
     * @type {String}
     */
    Issue.prototype.status_id = null;

     /**
     *
     * @type {number}
     */
    Issue.prototype.easy_sprint_id = null;
    /**
     *
     * @type {String}
     */
    Issue.prototype.status = null;

    /**
     *
     * @type {number}
     */
    Issue.prototype.agile_column_position = null;

    /**
     *
     * @type {number}
     */
    Issue.prototype.next_item_id = null;

    /**
     *
     * @type {String}
     */
    Issue.prototype.name = null;

    /**
     * @type {String}
     */
    Issue.prototype.assigned_to_id = null;

    /**
     * @type {User}
     */
    Issue.prototype.assignedUser = null;

    window.easyClasses.Issue = Issue;

    /**
     * @name Issues
     * @constructor
     * @extends ActiveCollection
     */
    function Issues() {
        this.map = {};
        this.temporarySortedList = null;
        this._onChange = [];
        this.uuid = Issues.uuid++;
        this.sorting = "position";
        this.resolvePositionsNeeded = true;
    }

    window.easyClasses.ActiveClass.extendByMe(Issues);

    /**
     *
     * @param {Issue} issue
     * @param {*} [event]
     */
    Issues.prototype.add = function (issue, event) {
        var different = false;
        var prev = this.map[issue.id];
        if (prev === undefined) {
            this.map[issue.id] = issue;
            issue.issues = this;
            different = true;
        } else {
            for (var key in issue) {
                if (!issue.hasOwnProperty(key))continue;
                if (issue[key] !== prev[key]) {
                    different = true;
                    prev[key] = issue[key];
                }
            }
        }
        if (!different) {
            return;
        } else {
            issue.issues = this;
        }
        if (event === null || event === undefined) {
            event = "add";
        }
        if (this.sorting === "position") {
            this.resolvePositionsNeeded = true;
        }
        this._fireChanges(event, issue);
    };

    /**
     *
     * @param {Issue} issue
     * @param {*} [event]
     */
    Issues.prototype.remove = function (issue, event) {
        delete this.map[issue.id];
        if (event === null || event === undefined) {
            event = "remove";
        }
        if (this.sorting === "position") {
            this.resolvePositionsNeeded = true;
        }
        this._fireChanges(event, issue);
    };

    Issues.uuid = 0;

    /**
     *
     * @param {Array} list
     */
    Issues.prototype.fromList = function (list) {
        for (var i = 0; i < list.length; i++) {
            this.add(list[i]);
        }
    };


    /**
     * @return Array
     */
    Issues.prototype.getPositions = function () {
        this.resolvePositions();
        var out = [];
        for (var i = 0; i < this.temporarySortedList.length; i++) {
            out.push(this.temporarySortedList[i].id);
        }
        return out;
    };

    /**
     *
     * @param issue
     * @param targetIssue
     * @return boolean target issue is now previous
     */
    Issues.prototype.moveIssueOntoThisIssue = function (issue, targetIssue) {
        var i;
        var sourceIssues = issue.issues;
        var sorted = this.temporarySortedList;
        if (this !== targetIssue.issues) {
            throw "issue is not in this";
        }
        if (sourceIssues === this) {
            var fromIndex = sorted.indexOf(issue);
            var toIndex = sorted.indexOf(targetIssue);
            this.resolvePositionsNeeded = true;
            if (fromIndex < toIndex) {
                var topPosition = targetIssue.agile_column_position;
                for (i = fromIndex; i <= toIndex; i++) {
                    sorted[i].agile_column_position--;
                }
                issue.agile_column_position = topPosition;
                this.resolvePositions();
                return true;
            } else {
                var bottomPosition = targetIssue.agile_column_position;
                for (i = toIndex; i <= fromIndex; i++) {
                    sorted[i].agile_column_position++;
                }
                issue.agile_column_position = bottomPosition;
                this.resolvePositions();
                return false;
            }
        } else {
            // inserted new issue
            var index = sorted.indexOf(targetIssue);
            var bottomIndex = targetIssue.agile_column_position;
            if (index === -1) {
                throw "issue not in list";
            }
            for (i = index; i < sorted.length; i++) {
                sorted[i].agile_column_position++;
            }
            issue.agile_column_position = bottomIndex;
            return false;
        }

    };


    /**
     *
     * @type {RootModel}
     */
    Issues.prototype.rootModel = null;

    /**
     *
     * @type {AgileColumn}
     */
    Issues.prototype.column = null;

    /**
     *
     * @type {boolean}
     */
    Issues.prototype.firstInGlobalColumn = false;

    /**
     *
     * @param {Array} data
     * @param {*} allUsers
     * @return {*} inputed data
     */
    Issues.prototype.loadFromJson = function (data, allUsers) {
        var loadedMap = {};
        for (var i = 0; i < data.length; i++) {
            var issue = new window.easyClasses.Issue();
            issue.init(data[i]);
            var userId = data[i]["assigned_to_id"];
            if (userId !== null && userId !== undefined) {
                issue.assignedUser = allUsers[userId];
            }
            issue.orderBy = i;
            this.add(issue);
            loadedMap[issue.id] = issue;
        }
        return loadedMap;
    };

    Issues.prototype.resolvePositions = function () {
        if (!this.resolvePositionsNeeded)return;
        this.resolvePositionsNeeded = false;
        this.sort(function (/**@type {Issue}*/a, /**@type {Issue}*/b) {
            if (!a.agile_column_position && !b.agile_column_position) return a.orderBy - b.orderBy;
            return a.agile_column_position - b.agile_column_position;
        });
    };

    Issues.prototype.sort = function (callback) {
        this.temporarySortedList = [];
        for (var key in this.map) {
            if (!this.map.hasOwnProperty(key))continue;
            this.temporarySortedList.push(this.map[key]);
        }
        this.temporarySortedList.sort(callback);
    };


    /**
     *
     * @type {String}
     */
    Issues.prototype.filterBy = null;

    /**
     *
     * @type {*}
     */
    Issues.prototype.filterValue = null;

    /**
     *
     * @param {Array.<Issue>} issueList
     */
    Issues.prototype.filterAndAdd = function (issueList) {
        if (this.filterBy == null || this.filterValue == null) {
            throw "set filter params before filtering";
        }
        for (var i = 0; i < issueList.length; i++) {
            var issue = issueList[i];
            if (issue.hasOwnProperty(this.filterBy)) {
                var value = issue[this.filterBy];
            } else {
                value = "undefined";
            }
            if (value === null || value === "null") {
                value = "undefined";
            }
            if (value + "" == this.filterValue) {
                this.map[issue.id] = issue;
                issue.issues = this;
            }
        }
        this._fireChanges("addFiltered");
    };

    window.easyClasses.Issues = Issues;
})();
