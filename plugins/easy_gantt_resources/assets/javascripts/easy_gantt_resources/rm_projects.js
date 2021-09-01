window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {withProjects: "projects"});
ysy.pro.resource.projects = ysy.pro.resource.projects || {};
EasyGem.extend(ysy.pro.resource.projects, {
  patch: function () {
    var resourceClass = ysy.pro.resource;
    ysy.settings.resource.buttons = ysy.settings.resource.buttons || {};
    const sett = ysy.settings.resource.buttons;
    let withProjects = JSON.parse(ysy.data.storage.getPersistentData('withProjects'));
    sett.withProjects = withProjects ? withProjects : ysy.settings.resourceWithProjects;
    ysy.pro.toolPanel.registerButton(
        {
          id: "resource_with_projects",
          bind: function () {
            this.model = ysy.settings.resource;
            this.buttons = this.model.buttons;
            if (this.buttons.withProjects) {
              ysy.settings.resource.setSilent("withProjects", this.buttons.withProjects);
              ysy.settings.resource._fireChanges(this, "button");
            }
          },
          func: function () {
            this.buttons.withProjects = !this.buttons.withProjects;
            ysy.proManager.closeAll(resourceClass);
            ysy.data.storage.savePersistentData('withProjects', this.buttons.withProjects);
            ysy.settings.resource.setSilent("withProjects", this.buttons.withProjects);
            ysy.settings.resource._fireChanges(this, "button");
          },
          isOn: function () {
            return this.buttons.withProjects;
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );

    ysy.pro.resource.loader._loadRMProjects = function (json, userId) {
      if (!json) return;
      var projects = ysy.data.projects;
      var resourceProjects = ysy.data.resourceProjects;
      for (var i = 0; i < json.length; i++) {
        var project = new ysy.data.Project();
        project.init(json[i]);
        projects.pushSilent(project);

        var resourceProject = new ysy.data.ResourceProject();
        resourceProject.assigned_to_id = userId;
        resourceProject.realProject = project;
        resourceProject.init(json[i]);
        resourceProjects.pushSilent(resourceProject);
      }
      projects._fireChanges(this, "load");
      resourceProjects._fireChanges(this, "load");
    }
  }
});
