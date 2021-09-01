window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.emptyGantt = {
  name: "emptyGantt",

  patch: function() {
    ysy.data.loader.register(this.newGantt, this)
  },
  newGantt: function() {
    if (this.isEmpty() && !ysy.settings.resource_on) {
      var addTask = ysy.settings.addTask;
      addTask.setSilent("open", true);
      addTask._fireChanges(this, "toggle");
    }
  },

  isEmpty: function() {
    var data = ysy.data;
    if (data.projects.array.length > 1) return false;
    if (data.issues.array.length > 0) return false;
    if (data.milestones.array.length > 0) return false;
    return true;
  }

};
