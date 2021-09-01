/**
 * Created by Ringael on 2. 11. 2015.
 */
window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.common = ysy.pro.common || {};
EasyGem.extend(ysy.pro.common, {
  patch: function () {
    ysy.proManager.register("ganttConfig", this.ganttConfig);
    gantt.attachEvent("onGanttReady", function () {
      $(gantt.$grid_data).on("click", ".easy-gantt__project_issues", function () {
        ysy.data.loader.openIssuesOfProject($(this).data("project_id"));
      });
    });
    ysy.view.columnBuilders = ysy.view.columnBuilders || {};
    ysy.view.columnBuilders.name = function (obj) {
      var id = parseInt(obj.real_id);
      if (isNaN(id) || id > 1000000000000) return obj.text;
      if (obj.type === "project") {
        const path = ysy.settings.paths.rootPath + "projects/";
        const text = ysy.main.escapeText(obj.text);
        return "<a class='gantt-grid-row-project' href='" + path + id + "' title='" + text + "' target='_blank'>" + text + "</a>";
      }
    };
    $.extend(ysy.data.loader, {
      loadProject: function (projectID) {
        var self = this;
        ysy.gateway.polymorficGetJSON(
            ysy.settings.paths.subprojectGantt
                .replace(new RegExp('(:|\%3A)projectID', 'g'), projectID),
            null,
            function (data) {
              self._handleProjectData(data, projectID);
            },
            function () {
              ysy.log.error("Error: Unable to load data");
            }
        );
        return true;
      },
      _handleProjectData: function (data, projectID) {
        var json = data.easy_gantt_data;
        //  -- PROJECTS --
        this._loadProjects(json.projects);
        //  -- ISSUES --
        this._loadIssues(json.issues, projectID);
        //  -- RELATIONS --
        this._loadRelations(json.relations);
        //  -- MILESTONES --
        this._loadMilestones(json.versions);
        ysy.log.debug("minor data loaded", "load");
        this._fireChanges();
      },
      loadProjectIssues: function (projectID) {
        ysy.gateway.polymorficGetJSON(
            ysy.settings.paths.projectOpenedIssues
                .replace(new RegExp('(:|\%3A)projectID', 'g'), projectID),
            null,
            $.proxy(this._handleProjectData, this),
            function () {
              ysy.log.error("Error: Unable to load data");
            }
        );
        return true;
      },
      openIssuesOfProject: function (projectID) {
        var project = ysy.data.projects.getByID(projectID);
        if (!project) return;
        ysy.data.limits.openings["s" + projectID] = true;
        if (!project.issues_count) return;
        delete project.issues_count;
        gantt.open(project.getID());
        this.loadProjectIssues(projectID);
      }
    });
  },
  ganttConfig: function (config) {
    $.extend(config, {
      allowedParent_task: ["project", "milestone", "task", "empty"],
      allowedParent_task_global: ["project", "milestone", "task"]
    });
  }
});
