EasyGem.module.part("easyAgile",['EasyWidget'],function () {
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     * @param {ScrumRoot} model
     * @param {boolean} displayBacklog
     * @extends {EasyWidget}
     * @constructor
     */
    function ScrumRootWidget(model, displayBacklog) {
        this.model = model;
        this.model.register(function (event) {
            if (event === "dialDownloaded") {
                this._buildSwimlanes();
            }
            if (event === "groupBySet") {
                if (this.model.isGroupBySet()) {
                    this.backlogCol.$target.addClass("agile__col--indent");
                    this.doneCol.$target.addClass("agile__col--indent");
                } else {
                    this.backlogCol.$target.removeClass("agile__col--indent");
                    this.doneCol.$target.removeClass("agile__col--indent");
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

        if (displayBacklog) {
            this.backlogCol = row.addCol();
            var backlogWidget = new window.easyClasses.agile.ListWidget(this.model.backlogIssesCol, true, "backlog-column", null, true, true);
            this.backlogCol.bonusClasses = "agile__col agile__col--side ";
            if (this.model.isGroupBySet()) {
                this.backlogCol.bonusClasses += "agile__col--indent ";
            }
            this.backlogCol.setWidget(backlogWidget);
        }

        this._buildSwimlanes();

        this.doneCol = row.addCol();
        this.doneCol.bonusClasses = "agile__col agile__col--side ";
        if (this.model.isGroupBySet()) {
            this.doneCol.bonusClasses += "agile__col--indent ";
        }
        this.doneCol.setWidget(new window.easyClasses.agile.ListWidget(this.model.doneIssuesCol, true, "backlog-column", null, true));

        var options = this.model.settings.swimlane_categories;
        for (var i = 0; i < options.length; i++) {
            options[i]["selected"] = options[i].value === this.model.groupBy;
        }

        this.children.push(new window.easyClasses.agile.AgileGroupSelectWidget(options, model));

        if (this.model.isPageModule) {
            this.children.push(new window.easyClasses.agile.AgileSprintAutocompleteWidget(model));
        }
    }

    window.easyClasses.EasyWidget.extendByMe(ScrumRootWidget);

    ScrumRootWidget.prototype._buildSwimlanes = function () {
      this.model._sortSwimlanes();
        var agileCol = this.row.addCol(1);
        var i;
        var columns = this.model.middleColumns;
        var ordering = this.model.middleColumnsOrdering;
        agileCol.bonusClasses = "agile__main-col agile__col";
        agileCol.bonusStyle = {flexGrow: Object.keys(columns).length};

        if (this.model.isGroupBySet()) {
            var namesRow = agileCol.addRow();
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

        for (i = 0; i < this.model.swimLanes.length; i++) {
            var swimLaneRow = agileCol.addRow();
            swimLaneRow.bonusClasses += "agile__row";
            swimLaneRow.setWidget(new window.easyClasses.agile.SwimLaneWidget(this.model.swimLanes[i], null, true));
            this.swimLanesRowWidgets.push(swimLaneRow);
        }
        if (this.model.stickyLane){
            var stickyLaneRow = agileCol.addRow();
            stickyLaneRow.bonusClasses += "agile__row agile__sticky-lane";
            stickyLaneRow.setWidget(new window.easyClasses.agile.StickyLaneWidget(this.model.stickyLane));
        }
    };
    /**
     *
     * @type {Array.<EasyRowWidget>}
     */
    ScrumRootWidget.prototype.swimLanesRowWidgets = null;

    /**
     * @override
     */
    ScrumRootWidget.prototype.setChildTarget = function (child, i) {
        if(child.childTarget){
            child.$target = this.$target.find(child.childTarget);
        } else if (i === 0) {
            child.$target = this.$target.find(".easy-row");
        } else if(i === 1) {
            child.$target = this.$target.find(".agile__swimline-select");
        } else {
            child.$target = this.$target.find(".agile__sprint-select");
        }
    };

    /**
     * @type {ScrumRoot}
     */
    ScrumRootWidget.prototype.model = null;

    ScrumRootWidget.prototype.destroy = function () {
        window.easyClasses.EasyWidget.prototype.destroy.apply(this);
        window.easyView.root.remove(this);
    };

    window.easyClasses.agile.ScrumRootWidget = ScrumRootWidget;
});
