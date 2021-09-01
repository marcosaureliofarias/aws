/**
 * Created by zdenek on 2016.09.07..
 */

EasyGem.module.part("easyAgile",['EasyWidget'],function () {
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     *
     * @param {KanbanRoot} model
     * @extends {EasyWidget}
     * @constructor
     */
    function KanbanRootWidget(model) {
        this.model = model;
        this.model.register(function (event) {
            if (event === "dialDownloaded") {
                this._buildSwimlanes();
            }
            if (event === "groupBySet") {
                if (this.model.isGroupBySet()) {
                    if (this.backlogCol) {
                        this.backlogCol.$target.addClass("agile__col--indent");
                    }
                    if (this.doneCol) {
                        this.doneCol.$target.addClass("agile__col--indent");
                    }
                } else {
                    if (this.backlogCol) {
                        this.backlogCol.$target.removeClass("agile__col--indent");
                    }
                    if (this.doneCol) {
                        this.doneCol.$target.removeClass("agile__col--indent");
                    }
                }
                this._buildSwimlanes();
            }
        }, this);
        var row = new window.easyClasses.EasyRowWidget();
        this.row = row;
        row.bonusClasses = "agile__row";
        this.children = [row];
        this.repaintRequested = true;
        this.template = window.easyTemplates.kanbanRoot;
        this.swimLanesRowWidgets = [];

        if (model.isBacklog) {
            this.backlogCol = row.addCol();
            var backlogWidget = new window.easyClasses.agile.ListWidget(this.model.backlogIssesCol, true, "backlog-column", null, true, true);
            this.backlogCol.bonusClasses = "agile__col agile__col--side ";
            if (this.model.isGroupBySet()) {
                this.backlogCol.bonusClasses += "agile__col--indent ";
            }
            this.backlogCol.setWidget(backlogWidget);
        }

        this._buildSwimlanes();

        if (model.isDone) {
            this.doneCol = row.addCol();
            this.doneCol.bonusClasses = "agile__col agile__col--side ";
            if (this.model.isGroupBySet()) {
                this.doneCol.bonusClasses += "agile__col--indent ";
            }
            this.doneCol.setWidget(new window.easyClasses.agile.ListWidget(this.model.doneIssuesCol, true, "backlog-column", null, true));
        }

        var options = this.model.settings.swimlane_categories;

        for (var i = 0; i < options.length; i++) {
            options[i]["selected"] = options[i].value === this.model.groupBy;
        }

        this.children.push(new window.easyClasses.agile.AgileGroupSelectWidget(options, model));
    }

    window.easyClasses.EasyWidget.extendByMe(KanbanRootWidget);

    KanbanRootWidget.prototype._buildSwimlanes = function () {
        var columnIndex = 0;
        var i;
        if (this.model.isBacklog) {
            columnIndex = 1;
        }
        var columns = this.model.middleColumns;
        var ordering = this.model.middleColumnsOrdering;
        var kanbanCol = this.row.addCol(columnIndex);
        kanbanCol.bonusClasses = "agile__main-col agile__col";
        kanbanCol.bonusStyle = {flexGrow: Object.keys(columns).length};

        if (this.model.isGroupBySet()) {
            var namesRow = kanbanCol.addRow();
            namesRow.isSticky = true;
            namesRow.bonusClasses += "agile__row";
            // add name of every column
            for (i = 0; i < ordering.length; i++) {
                /** @type {AgileColumn} */
                var column = columns[ordering[i]];
                /** @type {EasyColWidget} */
                var col = namesRow.addCol();
                col.bonusClasses = "agile__col";
                col.setWidget(new window.easyClasses.agile.ColNameWidget(column, this.model, null, false, true));
            }
        }

        this.swimLanesRowWidgets.push(swimLaneRow);
        for (i = 0; i < this.model.swimLanes.length; i++) {
            var swimLaneRow = kanbanCol.addRow();
            swimLaneRow.bonusClasses += "agile__row";
            swimLaneRow.setWidget(new window.easyClasses.agile.SwimLaneWidget(this.model.swimLanes[i], null, true));
            this.swimLanesRowWidgets.push(swimLaneRow);
        }

        if (this.model.stickyLane) {
            var stickyLaneRow = kanbanCol.addRow();
            stickyLaneRow.bonusClasses += "agile__row agile__sticky-lane";
            stickyLaneRow.setWidget(new window.easyClasses.agile.StickyLaneWidget(this.model.stickyLane));
        }
    };

    /**
     *
     * @type {Array.<EasyRowWidget>}
     */
    KanbanRootWidget.prototype.swimLanesRowWidgets = null;

    /**
     * @override
     */
    KanbanRootWidget.prototype.setChildTarget = function (child, i) {
        if (i === 0) {
            child.$target = this.$target.find(".easy-row");
        } else {
            child.$target = this.$target.find(".agile__group-select");
        }
    };

    /**
     * @type {KanbanRoot}
     */
    KanbanRootWidget.prototype.model = null;

    KanbanRootWidget.prototype.destroy = function () {
        window.easyClasses.EasyWidget.prototype.destroy.apply(this);
        window.easyView.root.remove(this);
    };

    window.easyClasses.agile.KanbanRootWidget = KanbanRootWidget;
});
