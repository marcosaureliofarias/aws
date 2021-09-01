(function () {
  /***
   *
   * @param {CalendarMain} main
   * @class
   * @constructor
   */

  function TaskModal (main) {
    this.main = main;
  }

  TaskModal.prototype.openTaskModal = function (taskID, event) {
    if (window.EasyVue && EasyVue.showModal) {
      let actions;
      let task = {};
      if (event) {
        actions = this.main.scheduler.modalActions(event);
      } else {
        task.type = "issue";
        task.id = taskID;
        actions = this.main.scheduler.modalActions(task);
      }
      EasyVue.showModal(`scroll`, taskID, { actions });
    } else {
      const self = this;
      const issueUrl = this.main.settings.paths.issue_path.replace('__issueId', taskID);
      $.ajax({
        url: issueUrl,
        dataType: 'json',
        data: {
          include: ['journals', 'attachments'],
          textilizable: true,
          include_permissions: ['add_comment', 'view_estimated_hours', 'edit_estimated_hours']
        }
      }).done(
        function (data) {
          const dataIssue = data.issue;
          let permissions = {};
          dataIssue.permissions.forEach((val) => {
            permissions[val.name] = val.result
          });

          const obj = {
            taskID: dataIssue.id,
            assigned_to_id: dataIssue.assigned_to ? dataIssue.assigned_to.id : "",
            status: dataIssue.status,
            subject: dataIssue.subject,
            priority: dataIssue.priority,
            author_id: dataIssue.author.id,
            estimated_hours: dataIssue.estimated_hours,
            spent_hours: dataIssue.spent_hours,
            tracker: dataIssue.tracker,
            project: dataIssue.project,
            due_date: isNaN(dataIssue.due_date) ? new Date(dataIssue.due_date) : "",
            start_date: isNaN(dataIssue.start_date) ? new Date(dataIssue.start_date) : "",
            fixed_version: dataIssue.fixed_version,
            journals: dataIssue.journals,
            description: dataIssue.description,
            attachments: dataIssue.attachments,
            permissions: permissions
          };
          self.showTaskModal(obj, event);
        });
    }
  };
  TaskModal.prototype.showTaskModal = function (task, event) {
    var main = this.main;
    var content = this.selected_task_content(task);
    var header = task.subject;
    var self = this;
    if (event) {
      header += main.scheduler.toolModalIcons(event);
    } else {
      task.type = "issue";
      header += main.scheduler.toolModalIcons(task);
    }
    var modalClass = main.scheduler.modal;
    var id = task.taskID;
    var url = main.settings.paths.issuesDataPath;
    modalClass.showModal(content, 800, header);
    modalClass.$modal.dialog({
      position: {
        my: "top",
        at: "bottom",
        of: '#top-menu'
      },
      buttons: [
        {
          id: "save_comment",
          class: "button-positive",
          text: main.settings.labels.saveAndClose,
          click: function () {
            if (ajaxSend) return;
            var comment = modalClass.$modal.find('#comment').val().replace(/(?:\r\n|\r|\n)/g, '<br>\n');
            if (comment.length === 0) {
              modalClass.$modal.dialog('close');
              return;
            }
            var issue = {
              notes: comment,
              private_notes: 0,
              update_repeat_entity_attributes: 1
            };
            var ajaxSend = true;
            var issueUrl = '/issues/' + id + '.json';
            $.ajax({
              url: issueUrl,
              data: { issue: issue },
              method: "PUT"
            })
              .always(
                function (data) {
                  ajaxSend = false;
                  var $target = modalClass.$modal;
                  var message;
                  if (data.status >= 200 && data.status < 300) {
                    message = easyScheduler.settings.labels.notice_successful_update;
                    $target.dialog('close');
                    showFlashMessage('notice', message, 3000);
                  } else {
                    message = data.responseJSON.errors[0] || data.statusText;
                    modalClass.showFlash(message, 'error');
                  }
                });
          }
        }
      ]
    });
    modalClass.$modal.on("dialogclose", function () {
      const queryID = main.settings.paths.queryID;
      let data = {};
      if (!queryID || queryID === "default") {
        data = { issue_ids: id, included_in_query: main.settings.defaultQueryParams };
      } else {
        data = { issue_ids: id, included_in_query_id: queryID };
      }
      $.ajax({
        url: url,
        dataType: "JSON",
        data: data
      })
        .done(function (data) {
          self.compareWithChanged(task, data.issues[0]);
        });
    });
    if (event) {
      main.scheduler.initToolModalIcons(event.id);
    } else {
      main.scheduler.initToolModalIcons(id);
    }
    this.initTabsAction(main);
    this.initDetailAction(main, id);
  };

  TaskModal.prototype.afterModalClose = function (event) {
    this.loader.reload();
  };

  TaskModal.prototype.compareWithChanged = function (task, toCompare) {
    var newTask = this.main.taskData.getTaskById(task.taskID, 'issues');
    if (!newTask) {
      newTask = toCompare;
    } else {
      newTask.update(toCompare);
    }
    var self = this;
    this.main.eventBus.fireEvent("taskChanged", toCompare);
    this.main.tasksView.refreshAll();
    var filteredEvents = this.main.scheduler.getEvents().filter(ev => ev.issue_id === task.taskID);
    filteredEvents.forEach(function (ev) {
      ev.user_id = newTask.assigned_to_id;
      ev.subject = newTask.subject;
      ev.text = newTask.subject;
      self.main.scheduler.updateEvent(ev.id);
    });
  };

  TaskModal.prototype.selected_task_content = function (task) {
    var main = this.main;
    var tabsTemplate = main.settings.templates.modalTab;
    this.tabData = { tabs: [] };
    var detailContainer = this.getDetail(task);
    var descriptionContainer = this.getDescription(task);
    var commentsContainer = this.getComments(task);
    var attachmentsContainer = this.getAttachments(task);

    var maincontent = detailContainer + descriptionContainer + commentsContainer + attachmentsContainer;

    var content = '<div id="easy_scheduler_modal_tabs">' + Mustache.render(tabsTemplate, this.tabData) + maincontent + '</div></div>';
    return content;
  };

  TaskModal.prototype.getDetail = function (task) {
    var main = this.main;
    var labels = main.settings.labels;
    var dMYFormater = main.scheduler.templates.dMY_format;
    var startDate = task.start_date instanceof Date ? dMYFormater(task.start_date) : "";
    var dueDate = task.due_date instanceof Date ? dMYFormater(task.due_date) : "";
    var assignee = main.assigneeData.getAssigneeById(task.assigned_to_id);
    var author = main.assigneeData.getAssigneeById(task.author_id);
    var issueDetailContent = main.settings.templates.issueDetailsContent;
    var project = task.project;

    var paths = main.settings.paths.issues.inline_edit_data_sources;
    var statusPath = paths.status.replace('__issueID__', task.taskID);
    var assigneePath = paths.assignee.replace('__issueID__', task.taskID);
    var milestonePath = paths.milestone.replace('__issueID__', task.taskID);
    var priorityPath = paths.priority;
    const estimatedHours = task.permissions.view_estimated_hours ? task.estimated_hours : "";

    var contentData = {
      issueID: task.taskID,
      status: task.status ? task.status.name : "",
      statusID: task.status ? task.status.id : "",
      priority: task.priority ? task.priority.name : "",
      priorityID: task.priority ? task.priority.id : "",
      assigneeName: assignee ? assignee.name : "---",
      assigneeAvatarUrl: assignee ? assignee.avatar_url : "",
      assigneeID: assignee ? assignee.id : "",
      authorName: author ? author.name : "",
      authorAvatarUrl: author ? author.avatar_url : "",
      estimatedHours: estimatedHours,
      spentHours: task.spent_hours.toFixed(2),
      tracker: task.tracker ? task.tracker.name : "",
      project: project.name,
      dueDate: dueDate,
      startDate: startDate,
      fixedVersion: task.fixed_version ? task.fixed_version.name : "",
      issueInlineEditPath_Status: statusPath,
      issueInlineEditPath_Assignee: assigneePath,
      issueInlineEditPath_Milestone: milestonePath,
      issueInlineEditPath_Priority: priorityPath,
      commentsPermission: !!task.permissions.add_comment,
      estimatePermissionEditable: !!task.permissions.edit_estimated_hours,
      estimatePermissionEditableNegation: !task.permissions.edit_estimated_hours,
    };
    var url = main.settings.paths.issue_path.replace('__issueId', task.taskID);
    var detail = '<div class="easy-calendar__event-modal">' +
        '<div id="issue-detail" class="easy-calendar__event-issue-detail multieditable-container"' +
        ' data-entity-type="Issue" ' +
        'data-entity-id="' + task.taskID + '"' +
        'data-url="' + url + '">' +
        Mustache.render(issueDetailContent, contentData);
    this.tabData.tabs.push({ tabSelector: 'detail', selected: true, tabName: labels.tabs.details });
    return detail;
  };

  TaskModal.prototype.getComments = function (task) {
    var main = this.main;
    var labels = main.settings.labels;
    var dMYTimeFormater = main.scheduler.templates.dMY_time_format;
    var issueCommentsContent = main.settings.templates.issueCommentsContent;
    var comments = [];
    if (task.journals.length > 0) {
      var journals = task.journals;
      for (var i = 0; i < journals.length; i++) {
        var journal = journals[i];
        if (journal.notes) {
          var commentDate = dMYTimeFormater(new Date(journal.created_on));
          var comment = {
            userID: journal.user.id,
            userName: journal.user.name,
            date: commentDate,
            notesID: journal.id,
            notes: journal.notes
          };
          comments.push(comment);
        }
      }
    }

    if (comments.length > 0) {
      this.tabData.tabs.push({ tabSelector: 'comments', selected: false, tabName: labels.tabs.comments });
      var commentsData = {
        comments: comments
      };
      return Mustache.render(issueCommentsContent, commentsData);
    }
    return "";
  };

  TaskModal.prototype.getDescription = function (task) {
    var main = this.main;
    var labels = main.settings.labels;
    var description = "";
    if (task.description.length > 0) {
      this.tabData.tabs.push({ tabSelector: 'description', selected: false, tabName: labels.tabs.description });
      description = '<div id="tab-description" class="easy-calendar__event-description tab-content-container' +
          ' hidden">' + task.description + '</div>';
    }
    return description;
  };

  TaskModal.prototype.getAttachments = function (task) {
    var main = this.main;
    var labels = main.settings.labels;
    var dMYTimeFormater = main.scheduler.templates.dMY_time_format;
    var attachmentsContent = main.settings.templates.attachmentsContent;
    var attachments = [];
    if (task.attachments.length > 0) {
      var attachmentArray = task.attachments;
      for (var i = 0; i < attachmentArray.length; i++) {
        var attachment = attachmentArray[i];
        var attachmentDate = dMYTimeFormater(new Date(attachment.created_on));
        var attachmentFileSize = this.formatFileSize(attachment.filesize);
        var attachmentData = {
          userID: attachment.author.id,
          userName: attachment.author.name,
          date: attachmentDate,
          attachmentId: attachment.id,
          description: "",
          attachmentName: attachment.filename,
          attachmentSize: attachmentFileSize,
          attachmentType: attachment.content_type,
          attachmentUrl: attachment.href_url,
          attachmentThumbnail: attachment.thumbnail_url
        };
        attachments.push(attachmentData);
      }
    }
    if (attachments.length > 0) {
      this.tabData.tabs.push({ tabSelector: 'attachments', selected: false, tabName: labels.tabs.attachments });
      var attachmentsInfo = {
        attachments: attachments
      };
      return Mustache.render(attachmentsContent, attachmentsInfo);
    }
    return "";
  };

  TaskModal.prototype.initTabsAction = function (main) {
    var modalClass = main.scheduler.modal;
    modalClass.$modal.find(".tab-selector").on("click", function () {
      var selector = this.dataset.tabId;
      var allBlocks = modalClass.$modal.find('[id^="tab-"]');
      for (var i = 0; i < allBlocks.length; i++) {
        var block = allBlocks[i];
        $(block).toggleClass("hidden", block.id !== selector);
      }
      var selectedTab = modalClass.$modal.find('.tab-selector.selected');
      if (selectedTab[0].dataset.tabId !== selector) {
        selectedTab.toggleClass("selected", false);
        $(this).toggleClass("selected", true);
      }
    });
  };

  TaskModal.prototype.initDetailAction = function (main, id) {
    var modalClass = main.scheduler.modal;
    window.initInlineEditForContainer(modalClass.$modal);
  };
  TaskModal.prototype.formatFileSize = function (size) {
    var units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var l = 0;
    var n = parseInt(size, 10) || 0;
    while (n >= 1024 && ++l) { n = n / 1024; }
    return (n.toFixed(n < 10 && l > 0 ? 1 : 0) + ' ' + units[l]);
  };
  EasyCalendar.TaskModal = TaskModal;
})();
