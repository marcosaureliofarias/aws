/* tooltip.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.tooltip = EasyGem.extend(ysy.view.tooltip, {
  instance: null,
  show: function (className, event, template, out) {
    if (!this.instance) {
      this.instance = new ysy.view.ToolTip().init();
    }
    return this.instance.set(className, event, template, out);
  },
  hide: function () {
    if (this.instance)
      return this.instance.hide();
    return false;
  },
  changePos: function (event) {
    if (this.instance)
      return this.instance.changePos(event);
  }
});
ysy.view.taskTooltip = EasyGem.extend(ysy.view.taskTooltip, {
  timeout: 0,
  timeoutTime: 250,
  phase: 1,
  /**
   * phase 1 mouse is out
   * phase 2 mouse on, start timer
   * phase 3 tooltip display
   */
  taskTooltipInit: function () {
    var self = this;
    /**
     * phase 2 mouse on, start timer 1s
     */
    $("#content")
        .on("mouseenter", ".gantt_task_content, .gantt_task_progress, .gantt-task-tooltip-area", function (e) {
          if (self.phase !== 1) return;
          ysy.log.debug("mouseenter", "tooltip");
          if (e.buttons !== 0) return;
          self.phase = 2;
          // ysy.log.debug("e.which = "+e.which+" e.button = "+ e.button+" e.buttons = "+ e.buttons);
          self.bindHiders(e.target);
          self.updatePos(e);
        });

  },
  bindHiders: function (target) {
    target.addEventListener("mouseleave", this.hideTooltip);
    target.addEventListener("mousedown", this.hideTooltip);
    target.addEventListener("mousemove", this.updatePos);
  },
  hideTooltip: function (event) {
    var self = ysy.view.taskTooltip;
    /**
     * set phase 1 mouse out
     */
    self.phase = 1;
    self.lastPos = null;
    if (self.timeout) {
      clearTimeout(self.timeout);
    }
    if (ysy.view.tooltip.hide()) {
      event.target.removeEventListener("mouseleave", this.hideTooltip);
      event.target.removeEventListener("mousedown", this.hideTooltip);
      event.target.removeEventListener("mousemove", this.updatePos);
    }
  },
  /**
   * @param {MouseEvent} event
   */
  updatePos: function (event) {
    var self = ysy.view.taskTooltip;
    if (self.phase === 1) return;

    var changed = false;
    if (self.lastPos) {
      if (Math.abs(self.lastPos.clientX - event.clientX) > 5) {
        self.lastPos.clientX = event.clientX;
        changed = true;
      }
      if (Math.abs(self.lastPos.clientY - event.clientY) > 5) {
        self.lastPos.clientY = event.clientY;
        changed = true;
      }
    } else {
      self.lastPos = {clientX: event.clientX, clientY: event.clientY};
      changed = true;
    }
    if (self.phase === 3 && changed) {
      self.hideTooltip(event);
      return;
    }
    self.lastPos.target = event.target;
    if (changed) {
      if (self.timeout) {
        window.clearTimeout(self.timeout);
      }
      self.timeout = window.setTimeout(function () {
        self.showTaskTooltip(self.lastPos)
      }, self.timeoutTime);
    }
  },
  showTaskTooltip: function (event) {
    var self = this;
    /**
     * phase 3 tooltip display
     */
    if (self.phase !== 2) return;
    var task = gantt._pull[gantt.locate(event)];
    if (!task) return;
    self.phase = 3;
    if (event.target.parentElement.parentElement === null) {
      self.phase = 1;
      return;
    }
    var taskPos = $(event.target).offset();
    return ysy.view.tooltip.show("gantt-task-tooltip",
        {clientX: event.clientX, clientY: event.clientY, top: taskPos.top + gantt.config.row_height},
        ysy.view.templates.TaskTooltip,
        self.taskTooltipOut(task));
  },

  taskTooltipOut: function (task) {
    var issue = task.widget.model;
    var problemList = issue.getProblems();
    var columns = [];
    var maxDescriptionLength = 500;
    var formatedDescription;
    const duration = task.duration;
    if (issue.milestone) {
      if (issue.isShared) {
        columns = [{
          name: "shared-from",
          label: "Shared from project",
          value: ysy.main.escapeText(issue.real_project_name)
        }]
      }
      return {
        name: issue.name,
        end_date: !issue._noDate ? issue.start_date.format(gantt.config.date_format) : ysy.settings.labels.label_not_available,
        columns: columns,
        duration
      };
    }
    var columnHeads = gantt.config.columns;
    var banned = ["subject", "start_date", "end_date", "due_date"];
    for (var i = 0; i < columnHeads.length; i++) {
      var columnHead = columnHeads[i];
      if (banned.indexOf(columnHead.name) < 0) {
        var html = columnHead.template(task);
        if (!html) continue;
        if (html.indexOf("<") === 0) {
          html = $(html).html();
        }
        columns.push({name: columnHead.name, label: columnHead.label, value: html});
      }
    }
    if (issue.fixed_version_id) {
      var milestone = ysy.data.milestones.getByID(issue.fixed_version_id);
    }
    if (issue.description) {
      formatedDescription = this.strip(issue.description);
      if (issue.description.length >= maxDescriptionLength) {
        formatedDescription = `${formatedDescription.substr(0, maxDescriptionLength)} ...`;
      }
    }

    return {
      name: issue.name,
      start_date: issue.start_date ? issue.start_date.format(gantt.config.date_format) : ysy.settings.labels.label_not_available,
      end_date: issue.end_date ? issue.end_date.format(gantt.config.date_format) : ysy.settings.labels.label_not_available,
      milestone: milestone,
      columns: columns,
      problems: problemList,
      description: formatedDescription || "",
      duration
    };
  },
  strip: function (html){
    var doc = new DOMParser().parseFromString(html, 'text/html');
    return doc.body.textContent || "";
  }
});
ysy.view.ToolTip = function () {
  ysy.view.Widget.call(this);
};
ysy.main.extender(ysy.view.Widget, ysy.view.ToolTip, {
  name: "ToolTip",
  init: function () {
    var $target = this.$target = $("<div id='gantt_tooltip' style='display: none'></div>").appendTo("#content");
    $target.on("mouseleave", function () {
      $target[0].style.display = "none";
    });
    document.addEventListener("click", this.checkOutterClick.bind(null, $target));
    ysy.view.onRepaint.push($.proxy(this.repaint, this));
    return this;
  },
  set: function (className, event, template, out) {
    this.className = className || this.className;
    this.event = event || this.event;
    this.template = template || this.template;
    this.outed = out;
    this.repaintRequested = true;
    return this.$target;
  },
  hide: function () {
    this.$target[0].style.display = "none";//.hide();
    return true;
  },
  changePos: function (event) {
    var left = event.clientX;
    var top = event.top;
    if (event.clientY + this.elementHeight > window.innerHeight) {
      top -= this.elementHeight + gantt.config.row_height + 4;
    }
    if (event.clientX + this.elementWidth > window.innerWidth) {
      left -= this.elementWidth;
    }
    this.$target[0].style.cssText = "display: flex; left: " + left + "px; top: " + top + "px";
  },
  _repaintCore: function () {
    this.$target.html(Mustache.render(this.template, this.outed)); // REPAINT
    this.$target[0].style.display = "flex";
    this.$target[0].className = 'gantt-tooltip ' + this.className;
    this.elementWidth = this.$target.outerWidth();
    this.elementHeight = this.$target.outerHeight();
    var event = this.event;
    if (event) {
      this.changePos(event);
    }
    return false;
  },
  checkOutterClick($tooltip, event) {
    const tooltip = $tooltip[0];
    if (tooltip.style.display === "none") return;
    // if selector find #gantt_tooltip it means that you clicked inside tooltip, otherwise close tooltip
    const insideClick = event.target.closest(`#${tooltip.id}`);
    if (insideClick) return;
    tooltip.style.display = "none";
  }
});
