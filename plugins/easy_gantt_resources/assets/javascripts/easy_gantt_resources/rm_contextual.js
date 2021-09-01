window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {contextualMenu: "contextual"});
ysy.pro.resource.contextual = {
  patch: function () {
    var contextClass = ysy.pro.resource.contextual;
    $("#gantt_cont").on("contextmenu", ".gantt-task-bar-line", function (e) {
      var entityId = $(this).parent().attr("task_id");
      var ganttEntity = gantt._pull[entityId];
      if(!entityId) return;
      var entity =ganttEntity.widget.model;
      if (!entity) return;
      contextClass.show(entity,ganttEntity.type || "task");
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
    this.$target = $("#ajax-modal");
  },
  show: function (issue,type) {
    if (type === "project") return;
    var $target = this.$target;
    var issueAllocations = issue.getAllocationInstance();
    /** SET MAX ALLOCATIONS - not used now */
    // var maxAllocation = issueAllocations.max_allocation;
    // if (!maxAllocation) {
    //   var assignee = ysy.data.assignees.getByID(issue.assigned_to_id);
    //   if (assignee) {
    //     maxAllocation = assignee.hours;
    //   } else {
    //     maxAllocation = 8;
    //   }
    // }
    var disabled = !issue.permissions.editable || !ysy.settings.enableAllocatorChange;
    var obj = {
      disabled: disabled,
      name: issue.name,
      isReservation: type === "reservation"
      // maxAllocation: maxAllocation
    };
    if (type === 'reservation') {
      var preFill = {
        name: issue.name,
        assigned_to_id: issue.assigned_to_id,
        due_date: moment(issue.end_date).format("YYYY-MM-DD"),
        estimated_hours: issue.estimated_hours,
        start_date: moment(issue.start_date).format("YYYY-MM-DD"),
        description: issue.description,
        allocator: issue.allocator,
        project_id: issue.project_id
      };
      ysy.pro.resource.reservations.openModal(preFill,issueAllocations, issue);
    }
    else {
      obj["selected_" + issueAllocations.allocator] = "selected";
      $target.html(Mustache.render(ysy.view.templates.resourceContextual, obj));
      showModal("ajax-modal", 500);
      if (!disabled) {
        this.bindEvents($target, issue, issueAllocations);
      }
      // $target.find("#input_max_allocation").focus();
    }
  },
  hide: function () {
    this.$target.dialog("close");
  },
  bindEvents: function ($target, issue, issueAllocations) {
    var contextClass = ysy.pro.resource.contextual;
    $target.find("#submit_allocator").click(function () {
      // var maxAllocation = parseInt($target.find("#input_max_allocation").val());
      contextClass.hide();
      // if (isNaN(maxAllocation)) {
      //   maxAllocation = null;
      // }
      var allocator = $target.find("#select_allocator").val();
      if (allocator === "") allocator = null;
      // issueAllocations.set({allocator: allocator, max_allocation: maxAllocation});
      issueAllocations.set({allocator: allocator, _oldAllocator: issueAllocations.allocator});
    });
    $target.find("#reset_allocator").click(function () {
      contextClass.hide();
      issueAllocations.set({allocator: null, _oldAllocator: issueAllocations.allocator});
    });
    $target.find("#delete_button").click(function () {
      contextClass.hide();
      issue.remove();
    });
    // $target.find("#pseudo_even_allocation").on('click', function () {
    //   var hours = ysy.pro.resource.pseudoEvenHours(issueAllocations, {});
    //   $target.find("#input_max_allocation").val(Math.ceil(hours));
    // });
  }
};
