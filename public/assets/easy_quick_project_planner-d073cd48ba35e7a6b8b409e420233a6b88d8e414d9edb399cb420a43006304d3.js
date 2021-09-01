!function(t){"use strict";t.fn.quickplanner=function(e){function n(t){return 6===t.day()||0===t.day()}function i(e){var i=!1;return!n(e)&&(t.each(m.holidays,function(){if(this.isRepeating&&this.date.date()===e.date()&&this.date.month()===e.month()||this.date.isSame(e))return i=!0,!1}),!i)}function s(e){var n;n=t("<ul/>").appendTo(t("<div/>").attr("id","errorExplanation").insertBefore(t("#issues-container"))),t.each(e,function(){t("<li/>").html(this).appendTo(n)})}function a(){t.ajax({type:"POST",url:m.newIssueRowPath,data:t("input, select, textarea","tr.new-issue").serialize(),success:function(e){t("tr.new-issue").html(e),initInlineEditForContainer()}})}function o(){return t("input, select, textarea","tr.new-issue").serializeArray()}function u(){t("#issues-container").load(m.loadIssuesPath,function(){initInlineEditForContainer()})}function r(e,n,i){var s,a={text:m.lang.cancel,click:function(){p.dialog("close").remove()},"class":"button button-2"};p&&p.remove(),p=t("<div/>").addClass("quick-planner-issue-dialog").hide().appendTo("body"),n&&(s=t("<ul/>").appendTo(t("<div/>").attr("id","errorExplanation").appendTo(p)),t.each(n,function(){t("<li/>").html(this).appendTo(s)})),t.ajax({type:"GET",url:m.newIssuePath,data:e,error:function(t){p.append(t),p.dialog({title:"New issue",width:850,buttons:[a]})},success:function(e){p.append(e);var n=[{text:m.lang.createIssue,click:function(){if("function"==typeof i){var e;if("undefined"!=typeof CKEDITOR)for(e in CKEDITOR.instances)CKEDITOR.instances[e].updateElement();i(t("form",p).serializeArray())}p.dialog("close").remove()},"class":"button button-1"},a];p.dialog({title:"New issue",width:850,buttons:n})}})}function c(e){t.ajax({type:"post",url:m.createIssuePath,data:e,error:function(n){422===n.status&&r(e,t.parseJSON(n.responseText).errors,c)},success:function(e){t("tr.new-issue input[type='text']").val("").first().focus(),t.ajax({url:m.loadCreatedIssuePath,dataType:"html",data:{issue_id:e.issue.id},success:function(e){t("tr.new-issue").after(e),initInlineEditForContainer()}})}})}function d(e){t.ajax({type:"delete",url:m.issuesPath,data:{id:e,format:"json"},complete:function(){u()}})}function l(e){t("div.display, div.edit",e).toggle()}function f(e,n){t("#errorExplanation").remove(),n.push({name:"id",value:e}),t.ajax({type:"post",url:m.createIssuePath,data:n,complete:function(e){422===e.status?s(t.parseJSON(e.responseText).errors):u()}})}var p,h={loadIssuesPath:"quick_planner/issues",issuesPath:"/issues",newIssuePath:"issues/from_gantt",createIssuePath:"issues.json",lang:{},holidays:[],hoursPerDay:8},m=t.extend(!0,{},h,e);t.each(m.holidays,function(){this.date=moment(this.date)}),t(this).on("change","#easy_quick_project_planner_issue_tracker_id",function(){a()}),t("#project_is_planned").change(function(){t(this).is(":checked")&&(t("#project-settings-form").submit(),t("#project-settings-container").remove())}),t("tr.new-issue #issue_estimated_hours").on("keyup",function(){var e=parseFloat(t(this).val()),n=moment();if(e){if(e<1e3)for(;e>0;)i(n)&&(e-=m.hoursPerDay),n.add(1,"day");else n.add(Math.round(e/m.hoursPerDay),"days");t("tr.new-issue #issue_due_date").val(n.subtract(1,"day").format("YYYY-MM-DD"))}}),t(document).off("click","#create-issue-button").on("click","#create-issue-button",function(){return c(o()),!1}),t("tr.new-issue input").on("keyup",function(t){if(13===t.which)return c(o()),!1}),t(document).off("click","#issue-dialog-button").on("click","#issue-dialog-button",function(){return r(o(),null,c),!1}),t(document).off("click",".delete-issue-button").on("click",".delete-issue-button",function(){var e=t(this).closest("tr").attr("data-id");return confirm(m.lang.confirmDeletion)&&d(e),!1}),t(document).on("click",".edit-estimated-hours, .edit-due-date",function(){return l(t(this).closest("tr")),!1}),t("tr div.edit input").on("keyup",function(e){if(13===e.which){var n=t(this).closest("tr");return f(n.attr("data-id"),t("input",n).serializeArray()),!1}}),t(".save-issue-button").on("click",function(){var e=t(this).closest("tr");return f(e.attr("data-id"),t("input",e).serializeArray()),!1})}}(jQuery);