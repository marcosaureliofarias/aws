window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.projectMilestones = {
  patch: function () {
    if (!ysy.settings.showProjectMilestones) return;
    ysy.view.bars.registerRenderer("project", function (task, next) {
      var bar = next().call(this, task, next);
      if (task.$open) return bar;
      var allMilestones = ysy.data.milestones.array;
      var projectId = task.real_id;
      var $cont, sx;
      for (var i = 0; i < allMilestones.length; i++) {
        var milestone = allMilestones[i];
        if (milestone.project_id === projectId && !milestone._noDate) {
          if (!$cont) {
            $cont = $("<div class='gantt-project-milestones'>");
            $cont.css("top", (gantt.config.task_height / 2 - 1) + "px");
            sx = gantt.posFromDate(task.start_date) + 1;
          }
          var date = milestone.start_date.valueOf() + 86400000;
          var x = gantt.posFromDate(date);
          var title = milestone.name + "\n" + milestone.start_date.format("YYYY-MM-DD");
          $cont.append("<div class='gantt-project-milestone' title='" + title + "' style='left:" + (x - sx) + "px'></div>");
        }
      }
      if (!$cont) return bar;
      $(bar).append($cont);
      return bar;
    });
  }
};