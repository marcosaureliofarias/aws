EasyGem.module.part("easyAgile", ['EasyWidget'], function () {
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   *
   * @param {BacklogRoot} model
   * @extends {EasyWidget}
   * @constructor
   */
  function EpicBacklogRootWidget(model) {
    this.model = model;
    const row = new window.easyClasses.EasyRowWidget();
    row.bonusClasses = "agile__row";
    this.children = [row];
    this.repaintRequested = true;
    this.template = easyTemplates.kanbanRoot;

    const allColumn = row.addCol();
    allColumn.bonusClasses = "agile__col";
    const allColumnWidget = new easyClasses.agile.ListWidget(this.model.notAssignedIssuesCol, true, "backlog-column backlog-column-not-assigned", null, false, true);
    allColumn.setWidget(allColumnWidget);

    if (this.model.sprintBacklogsIssuesCol.length) {
      this.model.sprintBacklogsIssuesCol.forEach((sprint, i) => {
        const sprintColumn = row.addCol();
        sprintColumn.bonusClasses = "agile__col";
        const sprintColumnWidget = new easyClasses.agile.ListWidget(this.model.sprintBacklogsIssuesCol[i], true, "backlog-column-sprint", null, false, true);
        sprintColumn.setWidget(sprintColumnWidget);
        model.settings.check_capacities = false;
      });
    }
    this.children.unshift(new window.easyClasses.agile.UserBarWidget(this.model, this.model.epic.members));
  }

  window.easyClasses.EasyWidget.extendByMe(EpicBacklogRootWidget);

  /**
   * @override
   */
  EpicBacklogRootWidget.prototype.setChildTarget = function (child, i) {
    if (child.childTarget) {
      child.$target = this.$target.find(child.childTarget);
    } else {
      child.$target = this.$target.find(".easy-row");
    }
  };

  /**
   * @type {KanbanRoot}
   */
  EpicBacklogRootWidget.prototype.model = null;

  window.easyClasses.agile.EpicBacklogRootWidget = EpicBacklogRootWidget;
});
