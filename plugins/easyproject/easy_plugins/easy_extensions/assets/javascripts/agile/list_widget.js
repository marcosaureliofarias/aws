EasyGem.module.part("easyAgile",['EasyWidget'],function () {
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     *
     * @constructor
     * @param {IssuesCol} model
     * @param {bool} showName
     * @param {String} [bonusClasses]
     * @param {String} [template]
     * @param {boolean} [showTimes]
     * @param {boolean} [showSortButton]
     * @param {int} [dropPriority]
     * @extends {EasyWidget}
     */
    function ListWidget(model, showName, bonusClasses, template, showTimes, showSortButton, dropPriority) {
        this.nameWidget = null;
        this.model = model;
        this.showTimes = showTimes;
        this.showName = showName;
        this.showSortButton = showSortButton;
        this.customSort = false;
        this.repaintRequested = true;
        this.template = template;
        bonusClasses = bonusClasses ? bonusClasses : "";
        this.bonusClasses = bonusClasses;
        if (!this.template) {
            this.template = easyTemplates.kanbanList;
        }

        this.model.issues.register(function (event) {
            if (event === "sort") {
                this.model.issues.resolvePositions();
                this.repaintRequested = true;
            }
            if (event === "add" || event === "remove") {
                this._createChildren();
                this.repaintRequested = true;
            }
        }, this);

        var _self = this;

        this.model.agileRootModel.register(
            /**
             *
             * @param event
             * @param {Issue} issue
             */
            function (event, issue) {
                if (event === "possiblePhases") {
                    if (_self.isAnySelectedPossible()) {
                        this.$cont.addClass("agile__list--drop-valid");
                    } else {
                        this.$cont.addClass("agile__list--drop-invalid");
                    }
                }
                if (event === "cancelPossiblePhases") {
                    this.dropValid = false;
                    this.$cont.removeClass("agile__list--drop-valid");
                    this.$cont.removeClass("agile__list--drop-invalid");
                }
                if (event === "sort") {
                    this.model.issues.resolvePositionsNeeded = true;
                    this.model.issues.resolvePositions();
                    this.repaintRequested = true;
                }
            }, this);

        this._hover = false;
        this._createChildren();
        window.easyView.root.addItemToDragCollection(this.model.agileRootModel.dragDomain, this, dropPriority || 1);
    }

    window.easyClasses.EasyWidget.extendByMe(ListWidget);

    /**
     * Obtain position of widget inside issues, increase position of all issue after widget and return free issue
     * @param widget
     * @return issue
     */
    ListWidget.prototype.insertBefore = function (widget) {
        var index = this.model.issues.temporarySortedList.indexOf(widget.issue);
        if (index === -1) {
            return null;
        }
        var out = this.model.issues.temporarySortedList[index];
        for (var i = index; i < this.children.length; i++) {
            this.children[i].issue.agile_column_position++;
        }
        return out;
    };

    ListWidget.prototype.setDropHover = function (state) {
        this._hover = state;
        if (state && this.isAnySelectedPossible()) {
            this.$cont.addClass("agile__list--drop-valid-hover");
        } else {
            this.$cont.removeClass("agile__list--drop-valid-hover");
        }
    };

    ListWidget.prototype._getDraggedListItemWidget = function () {
        var view = window.easyView.root;
        // duck typing evil start
        if (view.draggedItem.listWidget) {
            return view.draggedItem;
        }
        return null;
        // duck typing evil end
    };

    ListWidget.prototype._createChildren = function () {
        if (this.showName) {
            this.nameWidget = new window.easyClasses.agile.ColNameWidget(this.model, this.model.agileRootModel, null, true, this.showTimes, this.showSortButton);
            this.children = [this.nameWidget];
        } else {
            this.children = [];
        }
        this.model.issues.resolvePositions();
        var issues = this.model.issues.temporarySortedList;
        for (var i = 0; i < issues.length; i++) {
            var issue = issues[i];
            this.children.push(new window.easyClasses.agile.IssueItemWidget(issue, this));
        }
    };

    ListWidget.prototype.destroy = function () {
        window.easyClasses.EasyWidget.prototype.destroy.apply(this);
        this.model.issues.unRegister(this);
        this.model.agileRootModel.unRegister(this);
    };

    ListWidget.prototype.setChildrenTarget = function () {
        var i = 0;
        if (this.showName) {
            this.nameWidget.$target = this.$target.find(".agile__col__title");
            i = 1;
        }
        for (i; i < this.children.length; i++) {
            this.children[i].$target = this.$target.find(".item_" + this.children[i].issue.id);
        }
    };

    /**
     * @override
     */
    ListWidget.prototype.out = function () {
        var out = {};
        out.bonusClasses = this.bonusClasses;
        out.columnName = this.model.column.name;
        out.totalSpentTime = this.model.column.totalSpentTime;
        out.totalEstimatedTime = this.model.column.totalEstimatedTime;
        out.showName = this.showName;
        out.items = this.model.issues.temporarySortedList;
        return out;
    };

    ListWidget.prototype._functionality = function () {
        this.$cont = this.$target.find(".agile__list");
        this.setDropHover(this._hover);
    };

    ListWidget.prototype.cancelPossiblePhases = function () {
        this.model.agileRootModel.cancelPossiblePhases();
    };

    /**
     *
     * @type {string}
     */
    ListWidget.prototype.bonusClasses = "";

    /**
     * @return {Array<IssueItemWidget>}
     */
    ListWidget.prototype.getSelectedIssueListWidgets = function () {
        var out = [];
        var selected = window.easyView.root.mapOfPossibleSelectedIssueItemWidgets;
        for (var key in selected) {
            if (!selected.hasOwnProperty(key))continue;
            if (selected[key].selected) {
                out.push(selected[key]);
            }
        }
        return out;
    };

    /**
     * @return {boolean}
     */
    ListWidget.prototype.isAnySelectedPossible = function () {
        var selected = this.getSelectedIssueListWidgets();
        var dragged = window.easyView.root.draggedItem;
        if (dragged && dragged.issue && dragged.listWidget) {
            selected.push(dragged);
        }
        for (var i = 0; i < selected.length; i++) {
            if (this.model.issueCanBePlacedHere(selected[i].issue)) {
                return true;
            }
        }
        return false;
    };

    window.easyClasses.agile.ListWidget = ListWidget;

});