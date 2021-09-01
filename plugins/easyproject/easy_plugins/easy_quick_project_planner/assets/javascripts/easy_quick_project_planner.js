//= require_self
/*globals jQuery, moment*/
/*jslint browser: true, devel: true*/
(function ($) {
    "use strict";
    $.fn.quickplanner = function (options) {

        var defaults = {
                loadIssuesPath   : "quick_planner/issues",
                issuesPath       : "/issues",
                newIssuePath     : "issues/from_gantt",
                createIssuePath  : "issues.json",
                lang             : {},
                holidays         : [],
                hoursPerDay      : 8
            },
            opts = $.extend(true, {}, defaults, options),
            issueDialog;

        //parse holidays
        $.each(opts.holidays, function () {
            this.date = moment(this.date);
        });

        function isWeekend(d) {
            return d.day() === 6 || d.day() === 0;
        }

        function isWorkingDay(d) {
            var isHoliday = false;
            if (isWeekend(d)) {
                return false;
            }
            $.each(opts.holidays, function () {
                if ((this.isRepeating && (this.date.date() === d.date() && this.date.month() === d.month())) || this.date.isSame(d)) {
                    isHoliday = true;
                    return false;
                }
            });
            return !isHoliday;
        }

        function errorExplanation(messages) {
            var flashUl;

            flashUl = $("<ul/>")
                .appendTo($("<div/>").attr("id", "errorExplanation").insertBefore($("#issues-container")));

            $.each(messages, function () {
                $("<li/>").html(this).appendTo(flashUl);
            });
        }

        function reloadNewIssueRow() {
            $.ajax({
                type: 'POST',
                url: opts.newIssueRowPath,
                data: $('input, select, textarea', 'tr.new-issue').serialize(),
                success: function(response) { $('tr.new-issue').html(response); initInlineEditForContainer(); }
            });
        }

        $(this).on('change', '#easy_quick_project_planner_issue_tracker_id', function() {
            reloadNewIssueRow();
        });

        // submit and hide project settings when project is set to be planned
        $("#project_is_planned").change(function () {
            if ($(this).is(":checked")) {
                $("#project-settings-form").submit();
                $("#project-settings-container").remove();
            }
        });

        // autoset due date based on estimated hours with respect to holidays
        $("tr.new-issue #issue_estimated_hours").on('keyup', function () {
            var hours = parseFloat($(this).val()),
                date = moment();

            if (hours) {
                if (hours < 1000) {
                    while (hours > 0) {
                        if (isWorkingDay(date)) {
                            hours -= opts.hoursPerDay;
                        }
                        date.add(1, "day");
                    }
                } else {
                    date.add(Math.round(hours / opts.hoursPerDay), "days");
                }
                $("tr.new-issue #issue_due_date").val(date.subtract(1, "day").format("YYYY-MM-DD"));
            }
        });

        // Pointless?
        //
        // dialog with all issue fields
        // $("#issue-dialog-button").on("click", function () {
        //     return false;
        // });

        // gets issue params from table row
        function basicIssueParams() {
            return $('input, select, textarea', 'tr.new-issue').serializeArray();
        }

        // reloads issue list
        function reloadIssues() {
            $("#issues-container").load(opts.loadIssuesPath, function() { initInlineEditForContainer(); });
        }

        // shows dialog with issue form
        function showIssueDialog(params, flashError, createCallback) {
            var flashUl;
            var cancelButton = {
                text: opts.lang.cancel,
                click: function() {
                    issueDialog.dialog("close").remove();
                },
                class: 'button button-2'
            };


            if (issueDialog) {
                issueDialog.remove();
            }
            issueDialog = $("<div/>")
                .addClass("quick-planner-issue-dialog")
                .hide()
                .appendTo("body");

            if (flashError) {
                flashUl = $("<ul/>")
                    .appendTo($("<div/>").attr("id", "errorExplanation").appendTo(issueDialog));

                $.each(flashError, function () {
                    $("<li/>").html(this).appendTo(flashUl);
                });
            }

            $.ajax({
                type: 'GET',
                url: opts.newIssuePath,
                data: params,
                error: function(response) {
                    issueDialog.append(response);
                    issueDialog.dialog({title: 'New issue', width: 850, buttons: [cancelButton]});
                },
                success: function (response) {
                    issueDialog.append(response);

                    var dialogButtons = [
                        {
                            text: opts.lang.createIssue,
                            click: function() {
                                if (typeof createCallback === "function") {
                                // serializeArray not include values from CKEDITOR
                                if(!(typeof CKEDITOR === "undefined")){
                                    var instance;
                                    for(instance in CKEDITOR.instances){
                                        CKEDITOR.instances[instance].updateElement();
                                    }
                                }

                                createCallback($("form", issueDialog).serializeArray());
                            }
                            issueDialog.dialog("close").remove();},
                            class: 'button button-1'
                        },
                        cancelButton
                    ];

                    issueDialog.dialog({title: 'New issue', width: 850, buttons: dialogButtons});
                }
            });
        }

        // issue creation
        function createIssue(params) {
            $.ajax({
                type: "post",
                url: opts.createIssuePath,
                data: params,
                error: function (jqXHR) {
                    if (jqXHR.status === 422) {
                        showIssueDialog(params, $.parseJSON(jqXHR.responseText).errors, createIssue);
                    }
                },
                success: function(response) {
                    $('tr.new-issue input[type=\'text\']').
                      val('').first().focus();
                    $.ajax({
                      url: opts.loadCreatedIssuePath,
                      dataType: "html",
                      data: { 'issue_id': response.issue.id },
                      success: function(response) {
                        $('tr.new-issue').after(response);
                        initInlineEditForContainer();
                      }
                    });
                }
            });
        }

        function loadNewIssueRow() {
            $.ajax({
                url: opts.issueRowPath
            });
        }

        // issue deletion
        function destroyIssue(id) {
            $.ajax({
                type: "delete",
                url: opts.issuesPath,
                data: {id: id, format: "json"},
                complete: function () {
                    reloadIssues();
                }
            });
        }

        // inline edit for existing rows
        function inlineEdit(row, issueId) {
            $("div.display, div.edit", row).toggle();
        }

        // save changes
        function updateIssue(id, attributes) {
            $("#errorExplanation").remove();
            attributes.push({name: 'id', value: id});
            $.ajax({
                type: "post",
                url: opts.createIssuePath,
                data: attributes,
                complete: function (jqXHR) {
                    if (jqXHR.status === 422) {
                        errorExplanation($.parseJSON(jqXHR.responseText).errors);
                    } else {
                        reloadIssues();
                    }
                }
            });
        }

        $(document).off('click', '#create-issue-button').on('click', '#create-issue-button' , function(){
            createIssue(basicIssueParams());
            return false;
        });

        $("tr.new-issue input").on("keyup", function (event) {
            if (event.which === 13) {
                createIssue(basicIssueParams());
                return false;
            };
        });

        $(document).off('click', '#issue-dialog-button').on('click', '#issue-dialog-button' , function(){
            var params = basicIssueParams();
            showIssueDialog(params, null, createIssue);
            return false;
        });

        $(document).off('click', '.delete-issue-button').on('click', '.delete-issue-button' , function(){
            var id = $(this).closest("tr").attr("data-id");
            if (confirm(opts.lang.confirmDeletion)) {
                destroyIssue(id);
            }
            return false;
        });

        $(document).on('click', '.edit-estimated-hours, .edit-due-date' , function(){
            inlineEdit($(this).closest("tr"));
            return false;
        });

        $("tr div.edit input").on("keyup", function (event) {
            if (event.which === 13) {
            var row = $(this).closest("tr");
                updateIssue(row.attr("data-id"), $("input", row).serializeArray());
                return false;
            };
        });

        $(".save-issue-button").on("click", function () {
            var row = $(this).closest("tr");
            updateIssue(row.attr("data-id"), $("input", row).serializeArray());
            return false;
        });

    };
}(jQuery));
