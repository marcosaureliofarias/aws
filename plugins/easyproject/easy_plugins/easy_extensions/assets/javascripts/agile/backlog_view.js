EasyGem.module.part("easyAgile",['EasyWidget'],function () {
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     *
     * @param {BacklogRoot} model
     * @extends {EasyWidget}
     * @constructor
     */
    function BacklogRootWidget(model) {
        this.model = model;
        var row = new window.easyClasses.EasyRowWidget();
        row.bonusClasses = "agile__row";
        this.children = [row];
        this.repaintRequested = true;
        this.template = easyTemplates.kanbanRoot;

        var allColumn = row.addCol();
        allColumn.bonusClasses = "agile__col";
        var allColumnWidget = new easyClasses.agile.ListWidget(this.model.notAssignedIssuesCol, true, "backlog-column backlog-column-not-assigned", null, true, true);
        allColumn.setWidget(allColumnWidget);

        var backlogColumn = row.addCol();
        backlogColumn.bonusClasses = "agile__col";
        var backlogColumnWidget = new easyClasses.agile.ListWidget(this.model.backlogIssesCol, true, "backlog-column backlog-column-backlog", null, false, true);
        backlogColumn.setWidget(backlogColumnWidget);

        if (this.model.sprintBacklogIssuesCol) {
            var sprintColumn = row.addCol();
            sprintColumn.bonusClasses = "agile__col";
            var sprintColumnWidget = new easyClasses.agile.ListWidget(this.model.sprintBacklogIssuesCol, true, "backlog-column-sprint", null, false, true);
            sprintColumn.setWidget(sprintColumnWidget);
            model.settings.check_capacities = false;
        }

    }

    window.easyClasses.EasyWidget.extendByMe(BacklogRootWidget);

    /**
     * @override
     */
    BacklogRootWidget.prototype.setChildTarget = function (child, i) {
        child.$target = this.$target.find(".easy-row");
    };

    /**
     * @type {KanbanRoot}
     */
    BacklogRootWidget.prototype.model = null;

    window.easyClasses.agile.BacklogRootWidget = BacklogRootWidget;
});
