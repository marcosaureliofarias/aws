$(function(){$("#easy_to_do_list_toolbar_trigger").droppable({hoverClass:"drag-over",tolerance:"touch",accept:function(t){return $().easy_to_do_list_accepted_entity(t.data().entityType)},over:function(t){$(t.target).removeClass("drag-ready")},out:function(t){$(t.target).addClass("drag-ready")},drop:function(t,e){var o=t;$.get($(t.target).attr("href"),{},function(){try{$("#easy_servicebar_component .easy-to-do-list-items-container").sortable("option","stop")(o,null,e.draggable)}catch(t){console.log("easy_to_do_list.js#19"),console.log(t)}})}}),ERUI.isMobile||registerPanelHandlerTarget({containerName:"easy_servicebar_component",easyServicebarTrigger:"#easy_to_do_list_toolbar_trigger",allowedEntity:function(t){return $().easy_to_do_list_accepted_entity(t)},handlerAllowed:function(t){return $().easy_to_do_list_accepted_entity(t.data().entityType)},dataAttributes:function(t){return{"data-handler-entity-id":t.data().entityId}},connectToSortable:function(){return".to-do-list ul"},handlerDraggableStart:function(){}})}),function(t){"use strict";window.reloadToDoLists=function(){t.ajax({type:"GET",url:document.getElementById("easy_to_do_list_toolbar_trigger").href})},t.fn.easy_to_do_list_accepted_entity=function(e){if(e===undefined)return!1;var o=["issue","easycrmcase"];return-1!==t.inArray(e.toLowerCase(),o)},t.fn.easy_to_do_list=function(e){function o(){return f.find(".to-do-list").find("ul")}function a(){m.moreToDoLists&&f.sortable({items:"div.to-do-list",cursor:"move",handle:".header",revert:!0,axis:"y",update:function(e,o){t.ajax({type:"put",url:o.item.data("url"),dataType:"json",data:"easy_to_do_list[position]="+(o.item.index()+1)})}})}function i(){o().sortable({items:"li.movable-list-item",connectWith:".to-do-list ul",cursor:"move",placeholder:{element:function(){return t('<li class="ui-state-highlight icon-import">'+m.lang.pushSortbale+"</li>")[0]},update:function(){}},revert:!0,tolerance:"pointer",forcePlaceholderSize:!0,helper:"clone",appendTo:document.body,start:function(e,o){o.item.hasClass("easy-panel-handler")||o.item.data().uiDraggable||t(".easy-dropper-target").each(function(e,o){var a,i;t(o).hasClass("easy-drop-user")?(a=createEasyDropZone(o,m.dropZoneUser),i={"issue[assigned_to_id]":t(o).data().userId}):t(o).hasClass("easy-drop-project")?(a=createEasyDropZone(o,m.dropZoneOther),i={"issue[project_id]":t(o).data().projectId}):t(o).hasClass("easy-drop-calendar")?(a=createEasyDropZone(o,m.dropZoneCalendar),i={"issue[start_date]":t(o).data().calendarDay,"issue[due_date]":t(o).data().calendarDay}):t(o).hasClass("easy-drop-issue")||(a=createEasyDropZone(o,m.dropZoneOther),i={}),a&&a.droppable({hoverClass:"easy-target-dropzone-hover",accept:"#easy_servicebar_component .to-do-list li.movable-list-item",drop:function(e,o){var a={"issue[subject]":o.draggable.data("text"),"issue[description]":o.draggable.data("text")};t.extend(!0,a,i),d(a)}})})},stop:function(e,o,a){var i=o?o.item:t("div.to-do-list").first();if(a||(a=o.item),t(".easy-target-dropzone").remove(),t(".easy-dropper-target").css({position:""}),a.is(".movable-list-item")){var s=t("[data-entity-id='"+a.data().handlerEntityId+"'][data-handler='true']");if(!t().easy_to_do_list_accepted_entity(a.data().entityType))return"";t.ajax({type:"post",url:i.closest("div.to-do-list").data("url")+"/easy_to_do_list_items",dataType:"json",data:{html:"1",easy_to_do_list_item:{name:s.contents().first().text().trim(),entity_type:s.data().entityType,entity_id:s.data().entityId,position:o&&o.item?a.index()+1:1}},complete:function(e){null===o?(t("#easy_servicebar_component .to-do-list ul:first").prepend(e.responseJSON.html),reloadToDoLists()):(a.replaceWith(e.responseJSON.html),reloadToDoLists())}})}},update:function(e,o){if(this===o.item.parent()[0]){if(!o.item.data("url"))return;var a=o.item.closest("div.to-do-list").data("list-id");t.ajax({type:"put",dataType:"json",url:o.item.data("url"),data:{html:"1",easy_to_do_list_item:{position:o.item.index()+1,easy_to_do_list_id:a}},complete:function(t){o.item.replaceWith(t.responseJSON.html),reloadToDoLists()}})}}})}function s(){m.moreToDoLists&&f.disableSelection(),o().disableSelection()}function n(){m.moreToDoLists&&f.enableSelection(),o().enableSelection()}function r(){o().sortable("disable"),n()}function l(){o().sortable("enable"),s()}function d(e){var o=m.newIssueUrl,a=[];e&&t.each(e,function(t,e){a.push(t+"="+e)}),t.get(o,a.join("&"),function(e){var o=t("#ajax-modal");o.html(e),EASY.modalSelector.showModal("95%"),o.dialog("option",{title:m.newIssueTitle,buttons:[{text:m.closeButton,click:function(){t(this).dialog("close")},"class":"button"},{text:m.createButton,click:function(){"undefined"!=typeof CKEDITOR&&CKEDITOR.instances.easy_modalissue_description.updateElement(),t(this).find("form").submit()},"class":"button-positive"}]})})}function c(){h.hide(),_.show()}function u(t){t.closest(".easy-to-do-lists-item-new-form-container").hide().prev(".add-easy-to-do-lists-item").show()}var p={moreToDoLists:!1,lang:{},trigger:"#easy_to_do_list_toolbar_trigger"},m=t.extend(!0,{},p,e),y=(t(p.trigger),{afterOpen:function(){o().each(function(){var e=t._data(this).data.sortable;e&&e.refreshPositions()})}});y=t.extend(!0,{},y,m);var f=t(this).easySlidingPanel(y),_=f.find(".add-easy-to-do-list"),h=f.find(".easy-to-do-list-new-form-container");m.moreToDoLists&&a(),i(),s(),m.moreToDoLists&&_.click(function(){n();var t=h.show().find("#easy_to_do_list_name");t.val(""),t.focus(),_.hide()}),m.moreToDoLists&&f.find(".close-easy-to-do-list").click(function(){c()}),f.find(".add-easy-to-do-lists-item").on("click",function(){n();var e=t(this).next(".easy-to-do-lists-item-new-form-container").show().find("#easy_to_do_list_item_name");e.val(""),e.focus(),t(this).hide()}),f.find(".close-easy-to-do-lists-item").on("click",function(){u(t(this))}),m.moreToDoLists&&f.find(".delete-easy-to-do-list").on("click",function(){var e=t(this).closest(".to-do-list");confirm(t(this).data("text"))&&t.ajax({type:"delete",dataType:"json",url:e.data("url"),complete:function(){e.remove()}})}),f.find(".delete-easy-to-do-lists-item").on("click",function(){var e=t(this).parent().parent();confirm(t(this).data("text"))&&t.ajax({type:"delete",dataType:"json",url:e.data("url"),complete:function(){e.remove()}})}),m.moreToDoLists&&f.find(".easy-to-do-list-new-form").on("submit",function(){var e=t(this);return t.ajax({type:"post",url:e.attr("action"),dataType:"json",data:"html=1&"+e.serialize(),complete:function(e){t(".to-do-lists").append(e.responseJSON.html),c(),i(),reloadToDoLists()}}),!1}),f.find(".easy-to-do-lists-item-new-form").on("submit",function(){var e=t(this);return t.ajax({type:"post",url:e.attr("action"),dataType:"json",data:"html=1&"+e.serialize(),complete:function(t){e.closest(".to-do-list").find(".easy-to-do-list-items-container").prepend(t.responseJSON.html),u(e),reloadToDoLists()}}),!1}),f.find("li.movable-list-item input[type=checkbox]").on("change",function(){var e=t(this).parent().parent();t.ajax({type:"put",url:e.data("url"),dataType:"json",data:"html=1&easy_to_do_list_item[is_done]="+(t(this).is(":checked")?"1":"0"),complete:function(t){e.replaceWith(t.responseJSON.html),reloadToDoLists()}})}),f.find("li.movable-list-item").on("dblclick",function(){r();var e=t(this),o=e.html(),a=t("<input/>").attr({type:"text",value:e.data("text")});e.html(a),a.focus().keydown(function(a){13===a.keyCode&&t.ajax({type:"put",url:e.data("url"),dataType:"json",data:"html=1&easy_to_do_list_item[name]="+t(this).val(),complete:function(t){e.replaceWith(t.responseJSON.html),l()}}),27===a.keyCode&&(e.html(o),l())}).focusout(function(){t.ajax({type:"put",url:e.data("url"),dataType:"json",data:"html=1&easy_to_do_list_item[name]="+t(this).val(),complete:function(t){e.replaceWith(t.responseJSON.html),l()}})})}),m.moreToDoLists&&f.find(".to-do-list .header").on("dblclick",function(){n();var e=t(this),o=e.html(),a=t("<input/>").attr({type:"text",value:e.data("text")});e.html(a),a.focus().keydown(function(a){13===a.keyCode&&t.ajax({type:"put",url:e.parent().data("url"),dataType:"json",data:"html=1&easy_to_do_list[name]="+t(this).val(),complete:function(o){e.replaceWith(t(o.responseJSON.html).find(".header")),s()}}),27===a.keyCode&&(e.html(o),s())}).focusout(function(){t.ajax({type:"put",url:e.parent().data("url"),dataType:"json",data:"html=1&easy_to_do_list[name]="+t(this).val(),complete:function(o){e.replaceWith(t(o.responseJSON.html).find(".header")),s()}})})})}}(jQuery);