EasyGem.module.part("easyAgile", ['EasyWidget'], function () {
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  function AgileSprintAutocompleteWidget(model) {
    this.children = [];
    this.repaintRequested = true;
    this.template = easyTemplates.kanbanSprintSelect;
    this.rootModel = model;
    this.sprintsUrl = this.rootModel.settings.sprint_autocomplete_url;
    this.moduleId = this.rootModel.dragDomain.slice(1,-1);
    this.sprintName = this.rootModel.settings.current_sprint.name;
    this.labeSprint = this.rootModel.i18n.sprint;
  }

  easyClasses.EasyWidget.extendByMe(AgileSprintAutocompleteWidget);

  /**
   * @override
   */
  AgileSprintAutocompleteWidget.prototype.out = function () {
      return {moduleId: this.moduleId, label: this.sprintName, sprint: this.labeSprint };
  };
  /**
   * @override
   */
  AgileSprintAutocompleteWidget.prototype._functionality = function () {
    var _self = this;
    var url = _self.rootModel.url;
    var pattern = /easy_sprint_id=\d+/;
    var autocompleteModuleId =  "sprint_autocomplete_" + _self.moduleId;
    easyAutocomplete(autocompleteModuleId, _self.sprintsUrl, function (event, ui) {
      if (ui.item) {
        var newSprintUrl = url.replace(pattern, 'easy_sprint_id=' + ui.item.id);
        EasyGem.loadModule("easyAgile", function (agile) {
          agile.scrumLoader(_self.rootModel.dragDomain, newSprintUrl, '');
        })
      }
    }, "easy_sprints");
  };
  window.easyClasses.agile.AgileSprintAutocompleteWidget = AgileSprintAutocompleteWidget;
});
