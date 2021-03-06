/**
 * Created by Ringael on 5. 8. 2015.
 */
window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.addTask = {
  _name: "AddTask",
  initToolbar: function (ctx) {
    var addTaskPanel = new ysy.view.AddTaskPanel();
    addTaskPanel.init(ysy.settings.addTask);
    ctx.children.push(addTaskPanel);
  },
  patch: function () {
    ysy.proManager.register("initToolbar", this.initToolbar);
    ysy.proManager.register("close", this.close);
    var proManager = ysy.proManager;
    var addTaskClass = ysy.pro.addTask;
    ysy.view.AllButtons.prototype.extendees.add_task = {
      bind: function () {
        this.model = ysy.settings.addTask;
        this._register(ysy.settings.resource);
        if (this.isOn()) {
          proManager.closeAll(addTaskClass);
          var addTask = ysy.settings.addTask;
          addTask.setSilent("open", !addTask.open);
          addTask._fireChanges(this, "toggle");
        }
      },
      func: function () {
        proManager.closeAll(addTaskClass);
        var addTask = ysy.settings.addTask;
        addTask.setSilent("open", !addTask.open);
        ysy.settings.critical.open = false;
        if (ysy.settings.cashflow) {
          ysy.settings.cashflow.active = false;
          ysy.data.storage.savePersistentData('cashflow', ysy.settings.cashflow.active);
        }
        ysy.data.storage.savePersistentData('criticalType', ysy.settings.critical.open);
        ysy.data.storage.savePersistentData('addTask', addTask.open);
        addTask._fireChanges(this, "toggle");
      },
      isOn: function () {
         return ysy.main.checkForStorageValue('addTask', ysy.settings.addTask.open);
      },
      isHidden: function () {
        return ysy.settings.resource.open;
        // return !ysy.settings.permissions.allowed("add_issues")
      }
    };
    ysy.proManager.register("onDragStart", function (temp, dnd) {
      temp.addTask = ysy.settings.addTask.open;
      if (!temp.addTask) return false;
      temp.addType = ysy.settings.addTask.type;
      temp.startDate = gantt.dateFromPos(dnd.getRelativePos().x);
      temp.lastScroll = gantt.getCachedScroll();
      return true;
    });
    ysy.proManager.register("onDragMove", function (temp, dnd) {
      if (!temp.addTask) return false;
      temp.endDate = gantt.dateFromPos(dnd.getRelativePos().x);
      if (temp.addType === "milestone") {
        temp.line = addTaskClass.modifyMileMarker(
            dnd.config.marker,
            {start_date: moment(temp.endDate)},
            dnd.config.offset,
            temp.lastScroll
        );
      } else {
        temp.line = addTaskClass.modifyIssueMarker(
            dnd.config.marker,
            {start_date: moment(temp.startDate), end_date: moment(temp.endDate), type: temp.addType},
            dnd.config.offset,
            temp.lastScroll
        );
      }
      return true;
    });
    ysy.proManager.register("onDragEnd", function (temp, dnd) {
      if (!temp.addTask) return false;
      if (dnd.config.started) {
        ysy.log.debug("start: " + temp.startDate.toString() + " end: " + temp.endDate.toString(), "taskModal");
        var task = {start_date: moment(temp.startDate), end_date: moment(temp.endDate)};
        addTaskClass.roundDates(task, temp.addType !== "milestone");
        var preFill = {
          start_date: task.start_date.format("YYYY-MM-DD"),
          due_date: task.end_date.format("YYYY-MM-DD"),
          project_id: ysy.settings.projectID
        };
        ysy.log.debug("line=" + temp.line, "taskModal");
        //preFill.parent=ysy.pro.addTask.getMilestoneByLine(temp.line);
        var parent = addTaskClass.getParentByLine(temp.line, temp.addType);
        preFill.parent= {
          id: parent.real_id,
          type: parent.type,
          project_id: parent.widget.model.project_id,
          fixed_version_id: parent.widget.model.fixed_version_id
        };
        addTaskClass.openModal(temp.addType, preFill);
      }
      return true;
    });
  },
  close: function () {
    var addTask = ysy.settings.addTask;
    if (addTask.setSilent("open", false)) {
      addTask._fireChanges(this, "close");
    }
  }
};
//#############################################################################################
ysy.view.AddTaskPanel = function () {
  ysy.view.Widget.call(this);
};
ysy.main.extender(ysy.view.Widget, ysy.view.AddTaskPanel, {
  name: "AddTaskPanelWidget",
  templateName: "AddTaskPanel",
  buttons: ["issue", "milestone"],
  _repaintCore: function () {
    var sett = ysy.settings.addTask;
    var target = this.$target;
    if (sett.open) {
      target.show();
    } else {
      target.hide();
      return;
    }
    target.find(".add_task_type").removeClass("active");
    target.find("#add_task_" + sett.type).addClass("active");
    this.tideFunctionality();
  },
  tideFunctionality: function () {
    var types = this.buttons;
    var $target = this.$target;
    var model = this.model;
    var self = this;
    var bind = function (type) {
      $target.find("#add_task_" + type).off("click").on("click", function () {
        //ysy.log.debug("AddTask issue button pressed","taskModal");
        if (model.type === type) {
          ysy.pro.addTask.openModal(type);
        } else {
          model.setSilent("type", type);
          model._fireChanges(self, "toggle");
        }
      });

    };
    for (var i = 0; i < types.length; i++) {
      bind(types[i]);
    }
  }
});
//#############################################################
EasyGem.extend(ysy.pro.addTask, {
  openModal: function (addType, preFill) {
    if (preFill === undefined) {
      preFill = {project_id: ysy.settings.projectID};
    }
    if (addType === "milestone") {
      preFill.due_date = moment(preFill.due_date).add(1, "days").format("YYYY-MM-DD");
    }
    if (preFill.parent) {
      var parent = preFill.parent;
      if (parent.id > 1000000000000) {
        dhtmlx.message(ysy.settings.labels.errors2.unsaved_parent, "error");
        return;
      }
      preFill.project_id = parent.project_id;
      preFill.fixed_version_id = parent.type === 'milestone' ? parent.id : parent.fixed_version_id;
      if (parent.type === 'task') {
        preFill.parent_issue_id = parent.id;
      }
      delete preFill["parent"];
    }
    var $target = ysy.main.getModal("form-modal", "90%");
    var submitFunc = function (e) {
      var addTaskClass = ysy.pro.addTask;
      if (window.fillFormTextAreaFromCKEditor) {
        window.fillFormTextAreaFromCKEditor("issue_description");
        window.fillFormTextAreaFromCKEditor("version_description");
      }
      if ($(this).is("form")) {
        var data = $(this).serializeArray();
      } else {
        data = $target.find("form").serializeArray();
      }
      var errors = addTaskClass.collectErrors($target, data);
      if (errors.length) {
        dhtmlx.message(errors.join("<br>"), "error");
        $("#content").find(".flash").appendTo('body');
        return false;
      }
      var transformed = addTaskClass.transformData(data, addType);
      if (addType === "milestone") {
        addTaskClass.createMilestone(transformed);
      } else {
        addTaskClass.createIssue(transformed);
      }
      $target.dialog("close");
      return false;
    };
    if (addType === "milestone") {
      ysy.gateway.polymorficGet(ysy.settings.paths.newMilestonePath.replace(":projectID", preFill.project_id), {
        version: preFill
      }, function (data) {
        var $content = $(data).find("#content");
        if ($content.length) {
          $target.html($content.html());
        } else {
          $target.html(data);
        }
        var project_id = $target.find("#version_project_id").val();
        var title = $target.find("h2");
        title.replaceWith($("<h3 class='title'></h3>").html(title.html()));
        showModal("form-modal");
        $target.find("input[type=submit], .form-actions").hide();
        $target.find("#new_version").submit(submitFunc);
        $target.dialog({
          buttons: [
            {
              id: "add_milestone_modal_submit",
              class: "button-1 button-positive",
              text: ysy.settings.labels.buttons.create,
              click: submitFunc
            }
          ]
        });
        $target.find("#version_name").focus();
        if (ysy.settings.easyRedmine) {
          window.initEasyAutocomplete();
          var project_input = $target.find("#version_project_id_autocomplete");
          project_input.val(project_input.attr("value"));
          $target.find("#version_project_id").val(project_id);
        }
      });
    } else {
      ysy.gateway.polymorficGet(ysy.settings.paths.newIssuePath, {
        issue: preFill
      }, function (data) {
        $target.html(data);
        var title = $target.find("h2");
        title.replaceWith($("<h3 class='title'></h3>").html(title.html()));
        showModal("form-modal");
        $target.find("input[type=submit], .form-actions").hide();
        $target.dialog({
          buttons: [
            {
              id: "add_issue_modal_submit",
              class: "button-1 button-positive",
              text: ysy.settings.labels.buttons.create,
              click: submitFunc
            }
          ]
        });
        const modalNewIssueForm = $("#form-modal #issue-form");
        if (modalNewIssueForm.length) {
          modalNewIssueForm.on("new-issue-attribute-reloaded", ysy.pro.addTask.setRequiredFields.bind(null, $target));
        }
        ysy.pro.addTask.setRequiredFields($target);
        // Add required to start_date
        $target.find("#issue-form").submit(submitFunc);
        if ($target.find("#project_id").length === 0) {
          // because there may be no project field in EasyRedmine New issue form
          $target.find("#issue-form").append($('<input id="project_id" type="hidden" name="issue[project_id]" value="' + preFill.project_id + '" />'));
        }
        window.initEasyAutocomplete();
        $target.find("#issue_subject").focus();
      });
    }

  },
  setRequiredFields: function ($target) {
    const target = $target[0];
    const span = document.createElement("span");
    span.classList.add("required");
    // Add space for innerHTML bc of required field substring.
    // It cuts down last 2 chars for correct form serializing so it will cut down space and a star.
    span.innerHTML = " *";

    const start_date = target.querySelector("#start_date_area > label");
    if (start_date) {
      start_date.classList.add("required");
      start_date.appendChild(span);
      start_date.required = true;
    }
    const due_date = target.querySelector("#due_date_area > label");
    if (due_date) {
      due_date.classList.add("required");
      due_date.appendChild(span);
      due_date.required = true;
    }
  },
  collectErrors: function ($target, data) {
    var errors = [];
    var required = {};
    if (ysy.settings.easyRedmine) {
      $target.find("label.required").each(function () {
        var $label = $(this);
        var $inputCont = $label.next();
        var $inputs = $inputCont.filter("[name]");
        if ($inputs.length === 0) {
          $inputs = $inputCont.find("[name]");
        }
        var label = $label.text();
        if (label.charAt(label.length - 1) === "*") {
          label = label.substring(0, label.length - 2);
        }
        required[$inputs.attr("name")] = label;
      });
      $target.find('input[required],textarea[required],select[required]').each(function () {
        // finder for inputs with required attribute
        var $this = $(this);
        required[$this.attr("name")] = $this.attr("placeholder");
      });
    }
    $target.find("label > span.required").each(function () {
      // finder for classic Redmine and Redmine-like inputs
      var $label = $(this).parent("label");
      var $input = $label.parent().find("#" + $label.attr("for"));
      var label = $label.text();
      var name = $input.attr("name");
      if (name) {
        required[name] = label.substring(0, label.length - 2);
      }
    });
    for (var key in required) {
      if (!required.hasOwnProperty(key)) continue;
      var valid = false;
      for (var i = 0; i < data.length; i++) {
        if (data[i].name === key) {
          if (data[i].value !== "") {
            valid = true;
          }
          break;
        }
      }
      if (!valid) {
        errors.push(required[key] + " " + ysy.view.getLabel("addTask", "error_blank"));
      }
    }
    return errors;
  },
  transformData: function (data, addType) {
    var structured = ysy.main.formToJson(data);
    if (addType == "issue") {
      var entityStructured = structured.issue;
    } else if (addType == "milestone") {
      entityStructured = structured.version;
    } else {
      entityStructured = {};
    }
    var transformed = {
      project_id: ysy.settings.project ? ysy.settings.project.id : null
    };
    var parseInteger = function (number) {
      if (number === "") return null;
      return parseInt(number);
    };
    var parseDecimal = function (number) {
      if (number === "") return null;
      return parseFloat(number);
    };
    var functionMap = {
      // name: nothing,
      is_private: parseInteger,
      tracker_id: parseInteger,
      status_id: parseInteger,
      // status: nothing,
      // sharing: nothing,
      // subject: nothing,
      // description: nothing,
      priority_id: parseInteger,
      project_id: parseInteger,
      assigned_to_id: parseInteger,
      fixed_version_id: parseInteger,
      easy_version_category_id: parseInteger,
      old_fixed_version_id: parseInteger,
      parent_issue_id: parseInteger,
      // start_date: nothing,
      // due_date: nothing,
      effective_date: function (value) {
        transformed.start_date = value;
        return null;
      },
      estimated_hours: parseDecimal,
      done_ratio: parseInteger,
      // custom_field_values: nothing,
      // easy_distributed_tasks: nothing,
      // easy_repeat_settings: nothing,
      // easy_repeat_simple_repeat_end_at: nothing,
      // watcher_user_ids: nothing,
      // easy_ldap_entity_mapping: nothing,
      // skip_estimated_hours_validation: nothing,
      activity_id: parseInteger
    };
    var entityKeys = Object.getOwnPropertyNames(entityStructured);
    for (var i = 0; i < entityKeys.length; i++) {
      var key = entityKeys[i];
      if (functionMap.hasOwnProperty(key)) {
        var parsed = functionMap[key](entityStructured[key], key);
      } else {
        parsed = entityStructured[key];
      }
      transformed[key] = parsed;
    }
    return transformed;
  },
  roundDates: function (task, sort) {
    if (task.end_date) {
      if (sort && task.end_date < task.start_date) {
        task.end_date.add(12, "hours");
        var end = task.end_date;
        task.end_date = task.start_date;
        task.start_date = end;
      } else {
        task.end_date.add(-12, "hours");
      }
      task.end_date._isEndDate = true;
      gantt.date.date_part(task.end_date);
    }
    gantt.date.date_part(task.start_date);
  },
  createIssue: function (jissue) {
    ysy.log.debug("creating issue " + JSON.stringify(jissue), "taskModal");
    $.extend(jissue, {
      id: dhtmlx.uid(),
      name: jissue.subject,
      //progress:0,
      columns: {
        subject: jissue.subject
      },
      permissions: {
        editable: true
      },
      css: "fresh"
    });
    var issue = new ysy.data.Issue();
    issue.init(jissue);
    ysy.data.issues.push(issue);
    gantt._selected_task = issue.getID();
  },
  createMilestone: function (jmile) {
    ysy.log.debug("creating milestone " + JSON.stringify(jmile), "taskModal");
    $.extend(jmile, {
      id: dhtmlx.uid(),
      permissions: {
        editable: true
      },
      css: "fresh"
    });
    var mile = new ysy.data.Milestone();
    mile.init(jmile);
    ysy.data.milestones.push(mile);
    gantt._selected_task = mile.getID();
  },
  modifyIssueMarker: function ($marker, task, offset, lastScroll) {
    this.roundDates(task, true);
    //var pos = gantt._get_task_pos(task);
    var posx = gantt.posFromDate(task.start_date);
    var cfg = gantt.config;
    var height = gantt._get_task_height();
    var row_height = cfg.row_height;
    var padd = Math.floor((row_height - height) / 2);

    var top = parseFloat($marker.style.top) - offset.top;
    top = Math.max(top, lastScroll.y);
    var line = Math.floor(top / row_height);
    var clampedLine = Math.min(Math.max(line, 0), gantt._order.length - 1);

    //ysy.log.debug("offset: "+offset.top+" scroll: "+lastScroll.y+" line: "+line,"add_task_marker");

    var roundedTop = clampedLine * row_height + padd;
    var width = gantt.posFromDate(task.end_date) - posx;
    //var div = document.createElement("div");
    //var width = gantt._get_task_width(task);
    $marker.className = "gantt_task_line planned gantt_" + task.type + "-type";
    $marker.innerHTML = '<div class="gantt_task_content"></div>';
    var styles = [
      "left:" + (posx + offset.left) + "px",
      "top:" + (roundedTop + offset.top) + "px",
      "height:" + height + 'px',
      //"line-height:" + height + 'px',
      "width:" + width + 'px'
    ];

    $marker.style.cssText = styles.join(";");
    return line;
  },
  modifyMileMarker: function ($marker, task, offset, lastScroll) {
    gantt._working_time_helper.round_date(task.start_date);
    //var pos = gantt._get_task_pos(task);
    var posx = gantt.posFromDate(task.start_date);
    var cfg = gantt.config;
    var row_height = cfg.row_height;
    var height = gantt._get_task_height();

    var padd = Math.floor((row_height - height) / 2);
    var top = parseFloat($marker.style.top) - offset.top;
    top = Math.max(top, lastScroll.y);
    var line = Math.floor(top / row_height);
    var clampedLine = Math.min(Math.max(line, 0), gantt._order.length - 1);
    var roundedTop = clampedLine * row_height + padd;
    //ysy.log.debug("top="+top+", rTop="+roundedTop);
    $marker.className = "gantt_task_line planned gantt_milestone-type";
    $marker.innerHTML = '<div class="gantt_task_content"></div>';
    var styles = [
      "left:" + (posx + offset.left - Math.floor(height / 2) - 1) + "px",
      "top:" + (roundedTop + offset.top) + "px",
      "height:" + height + 'px',
      "line-height:" + height + 'px',
      "width:" + height + 'px'
    ];

    $marker.style.cssText = styles.join(";");
    return line;
  },
  allowedParent: {
    issue: ["task", "milestone", "project"],
    milestone: ["project"],
    reservation: ["assignee", "project"]
  },
  getParentByLine: function (line, type) {
    var allowed = this.allowedParent[type];
    var order = gantt._order;
    if (line < 0 || line >= order.length) {
      ysy.log.debug("wrong line number", "taskModal");
      return null;
    }
    var targetID = order[line];
    var task = gantt.getTask(targetID);
    if (!task) {
      ysy.log.debug("task not found", "taskModal");
      return null;
    }
    for (var i = 0; i < allowed.length; i++) {
      if (gantt._get_safe_type(task.type) === allowed[i]) {
        return task;
      }
    }
    return this.getParentByLine(line - 1, type);
  }
});



