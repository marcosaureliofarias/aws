/**
 * Created by Ringael on 30. 10. 2015.
 */

window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {estimatedLeft: "estimated"});
ysy.pro.resource.estimated = EasyGem.extend(ysy.pro.resource.estimated, {
  patch: function () {
    var sett = ysy.settings.resource;
    var resourceClass = ysy.pro.resource;
    gantt.templates.leftside_text = function (start, end, task) {
      if (!sett.open) return null;
      var estimated = 0;
      var spent = 0;
      if (task.type === "project") {
        var project = task.widget && task.widget.model;
        if (project && project.id === ysy.settings.projectID) {
          var issues = ysy.data.issues.getArray();
          for (var i = 0; i < issues.length; i++) {
            estimated += issues[i].estimated_hours || 0;
            spent += issues[i].spent || 0;
          }
        } else {
          gantt.eachTask(function (child) {
            estimated += child.estimated;
            spent += child.spent;
          }, task.id);
        }
      } else {
        spent = task.spent;
        estimated = task.estimated;
      }
      return Mustache.render(ysy.view.templates.resourceLeftText, {
        estimated: resourceClass.roundTo1(estimated) || 0,
        spent: resourceClass.roundTo1(spent),
        withSpent: spent > 0,
        withEvents: task.type !== "project"
      });
    }
  },
  estimatedChange: function (e) {
    e.stopPropagation();
    var $target = $(e.target);
    var $input;
    var taskID = $target.closest(".gantt_task_line").attr("task_id");
    var task = gantt._pull[taskID];
    if (!task) return;
    if (!task.widget || !task.widget.model) return;
    var issue = task.widget.model;
    var saveEstimated = function (event) {
      e.stopPropagation();
      $input.off();
      gantt.refreshTask(task.id);
      // validation part
      var value = parseFloat($input.val());
      if (isNaN(value) || value < 0 || value < issue.spent) return false;
      // execute part
      issue.set({estimated_hours: value, start_date: issue._start_date, end_date: issue._end_date});
    };
    var validEstimated = function (value) {
      var parsedValue = parseFloat(value);
      return !(isNaN(parsedValue) || parsedValue < 0 || parsedValue < issue.spent);
    };
    $input = ysy.pro.resource.responsiveInput(
        'class="gantt-rm-estimated-input" type="text" size="4"',
        saveEstimated,
        validEstimated
    );
    $input.val(ysy.pro.resource.roundTo1(task.estimated));
    $target.empty().append($input);
    $input.focus();
    return false;
  }
});