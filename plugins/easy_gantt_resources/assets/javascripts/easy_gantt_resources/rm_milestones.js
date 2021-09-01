window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {withMilestones: "milestones"});
ysy.pro.resource.milestones = ysy.pro.resource.milestones || {};
EasyGem.extend(ysy.pro.resource.milestones, {
  patch: function () {
    var resourceClass = ysy.pro.resource;
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    const sett = ysy.settings.resource.buttons;
    sett.withMilestones = JSON.parse(ysy.data.storage.getPersistentData('withMilestones'));
    ysy.pro.toolPanel.registerButton(
        {
          id: "resource_with_milestones",
          bind: function () {
            this.model = ysy.settings.resource;
            this.buttons = this.model.buttons;
            if (this.buttons.withMilestones) {
              ysy.settings.resource.setSilent("withMilestones", this.buttons.withMilestones);
              ysy.settings.resource._fireChanges(this, "button");
            }
          },
          func: function () {
            this.buttons.withMilestones = !this.buttons.withMilestones;
            ysy.proManager.closeAll(resourceClass);
            ysy.data.storage.savePersistentData('withMilestones', this.buttons.withMilestones);
            ysy.settings.resource.setSilent("withMilestones", this.buttons.withMilestones);
            ysy.settings.resource._fireChanges(this, "button");
          },
          isOn: function () {
            return this.buttons.withMilestones;
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );
  },
  milestone_renderer: function (task) {
    //var resourceClass = ysy.pro.resource;
    if (!task.widget) return;
    var issue = task.widget.model;
    var milestone = ysy.data.milestones.getByID(issue.fixed_version_id);
    if (!milestone) return;
    var mile_x = this.posFromDate(moment(milestone.start_date).add(1, "day"));
    var issue_x = this.posFromDate(task.start_date);
    var pos_x = mile_x - issue_x - gantt._get_milestone_width() / 2;
    var $element = $(
        ysy.view.templates.milestoneBlocker
            .replace("{{milestoneName}}", milestone.name)
            .replace("{{pos_x}}", pos_x.toString()));
    return $element[0];
  }

});
