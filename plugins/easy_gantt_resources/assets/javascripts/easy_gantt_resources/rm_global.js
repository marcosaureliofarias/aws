/**
 * Created by Ringael on 3. 11. 2015.
 */
window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
EasyGem.extend(ysy.pro.resource, {
  global_patch: function () {
    ysy.settings.resource_on = true;
    ysy.data.resourceProjects = new ysy.data.Array().init({_name: "ResourceProjectArray"});
    if (ysy.settings.openedUser) {
      ysy.data.limits.openings["a" + ysy.settings.openedUser] = true;
    }
    this.open();
    //ysy.settings.resource.withProjects=true;
    this.loader.register(function () {
      ysy.data.loader.loaded = true;
      ysy.data.loader._fireChanges(this, "RM load");
    }, this);
    ysy.data.loader.load = function () {
      this.loaded = false;
      ysy.data.issues.clear();
      ysy.log.debug("load()", "load");
      ysy.pro.resource.loader.globalLoad();
    };
    ysy.pro.resource.loader.load = ysy.pro.resource.loader.globalLoad;
    ysy.data.loader.loadSubEntity = function (type, id) {
      if (type === "project") {
        return ysy.data.loader.loadProject(id);
      }
      if (type === "assignee") {
        return ysy.pro.resource.loader.loadAssignee(id);
      }
    };
    ysy.settings.sample.init = function () {
      this.active = 0;
    }
  }
});
EasyGem.extend(ysy.pro.resource.loader, {
  globalLoad: function () {
    const variant = ysy.settings.resource.buttons.onlyTask && "onlyTask" || ysy.settings.resource.buttons.onlyReservation && "onlyReservation" || "allData";
    ysy.gateway.polymorficGetJSON(
        ysy.settings.paths.globalResourceUrl,
        {
          variant: variant
        },
        $.proxy(this._handleResourceGlobalData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
          ysy.pro.resource.loader.loading = false;
        }
    );
  },
  _handleResourceGlobalData: function (data) {
    if (!data.easy_resource_data) return;
    var json = data.easy_resource_data;
    //  -- LIMITS --
    this._loadResourceLimits(json);
    json.columns.forEach(col => {
      col.name = col.name.replace(/\./g, '_');
    });
    ysy.data.columns = json.columns;
    ysy.log.debug("_handleResourceData()", "load");
    //  -- ISSUES --
    ysy.data.issues.clear();
    //  -- MILESTONES --
    ysy.data.milestones.clear();
    //  -- PROJECTS --
    ysy.data.projects.clear();
    ysy.data.resourceProjects.clear();
    //  -- ASSIGNEES --
    ysy.data.assignees.clear();
    ysy.data.allocations.clear();
    if (ysy.data.resourceReservations) {
      ysy.data.resourceReservations.clear();
    }
    // ARRAY FILLING
    //  -- ASSIGNEES --
    this._loadAssignees(json.users);
    this._packAssignees();

    ysy.log.debug("resource data loaded", "load");
    ysy.log.message("resource JSON loaded");
    this._fireChanges();
    ysy.history.clear();
    this.loaded = true;
  },
  _packAssignees: function () {
    var assignees = ysy.data.assignees.getArray();
    for (var i = 0; i < assignees.length; i++) {
      assignees[i].needLoad = true;
      assignees[i]._fireChanges(this, "packing");
    }
    var openings = ysy.data.limits.openings;
    if (assignees.length === 1) {
      openings["a" + assignees[0].id] = true;
    }
    for (var id in openings) {
      if (!openings.hasOwnProperty(id)) continue;
      if (ysy.main.startsWith(id, "a")) {
        var realId = id.substring(1);
        var assignee = ysy.data.assignees.getByID(realId);
        if (!assignee) continue;
        if (!assignee.needLoad) continue;
        assignee.needLoad = false;
        this.loadAssignee(realId);
      }
    }
  }
});
