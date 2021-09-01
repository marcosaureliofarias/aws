$(function() {
    $("#easy_to_do_list_toolbar_trigger").droppable({
        hoverClass: 'drag-over',
        tolerance: 'touch',
        accept: function(item) {
            return $().easy_to_do_list_accepted_entity(item.data().entityType);
        },
        over: function (event, ui) {
            $(event.target).removeClass('drag-ready');
        },
        out: function (event, ui) {
            $(event.target).addClass('drag-ready');
        },
        drop: function (event, ui) {
            var dropEvent = event;
            $.get($(event.target).attr('href'),{}, function(res) {
                try{
                    $("#easy_servicebar_component .easy-to-do-list-items-container").sortable('option',"stop")(dropEvent, null, ui.draggable);
                } catch(e) {
                    console.log("easy_to_do_list.js#19");
                    console.log(e);
                }
            });
        }
    });
    
    if (!ERUI.isMobile) {
      registerPanelHandlerTarget({
        containerName: 'easy_servicebar_component',
        easyServicebarTrigger: '#easy_to_do_list_toolbar_trigger',
        allowedEntity: function (entity) {
            return $().easy_to_do_list_accepted_entity(entity);
        },
        handlerAllowed: function (handler) {
            return $().easy_to_do_list_accepted_entity(handler.data().entityType);
        },
        dataAttributes: function (handler) {
            return {"data-handler-entity-id": handler.data().entityId};
        },
        connectToSortable: function () {
            return ".to-do-list ul";
        },
        handlerDraggableStart: function (event, ui) {
        }
      });
  }

});
(function ($) {
    "use strict";
    
    window.reloadToDoLists = function() {
      $.ajax({type: 'GET', url: document.getElementById("easy_to_do_list_toolbar_trigger").href});
    };

    $.fn.easy_to_do_list_accepted_entity = function(entity) {
        if(entity === undefined) { return false; }
        var accepted_entities = ['issue', 'easycrmcase'];

        return $.inArray(entity.toLowerCase(), accepted_entities) !== -1;
    };

    $.fn.easy_to_do_list = function (options) {

        var defaults = {
            moreToDoLists: false,
            lang: {},
            trigger: '#easy_to_do_list_toolbar_trigger'
        },
        opts = $.extend(true, {}, defaults, options);
        var trigger = $(defaults.trigger);
        var overrides = {
            afterOpen: function() {
                getToDoListElements().each(function () {
                    var sortable = $._data(this).data.sortable;
                    if (sortable) {
                        sortable.refreshPositions();
                    }
                });
            }
        };
        overrides = $.extend(true, {}, overrides, opts);

        var _self = $(this).easySlidingPanel(overrides);

        var expander_panel = _self; //.find("#easy_servicebar_toolbar_box");
        var button_add_easy_to_do_list = expander_panel.find(".add-easy-to-do-list");
        var new_form_easy_to_do_list = expander_panel.find(".easy-to-do-list-new-form-container");

        if (opts.moreToDoLists){
            initializeListSortable();
        }
        initializeListItemsSortable();
        disableSelection();

        /* Button - add more TODO list */
        if (opts.moreToDoLists){
            button_add_easy_to_do_list.click(function () {
                enableSelection();
                var list_input = new_form_easy_to_do_list.show().find("#easy_to_do_list_name");
                list_input.val('');
                list_input.focus();
                button_add_easy_to_do_list.hide();
            });
        }

        /* Button - close new TODO list form */
        if (opts.moreToDoLists){
            expander_panel.find(".close-easy-to-do-list").click(function () {
                closeEasyToDoListNewForm();
            });
        }

        /* Button - add more TODO list entry */
        expander_panel.find(".add-easy-to-do-lists-item").on("click", function () {
            enableSelection();
            var list_item_input = $(this).next(".easy-to-do-lists-item-new-form-container").show().find("#easy_to_do_list_item_name");
            list_item_input.val('');
            list_item_input.focus();
            $(this).hide();
        });

        /* Button - close new TODO list entry form */
        expander_panel.find(".close-easy-to-do-lists-item").on("click", function () {
            closeEasyToDoListsItemNewForm($(this));
        });

        /* Button - delete TODO list */
        if (opts.moreToDoLists){
            expander_panel.find(".delete-easy-to-do-list").on("click", function () {
                var div = $(this).closest(".to-do-list");
                if (confirm($(this).data("text"))) {
                    $.ajax({
                        type: "delete",
                        dataType: 'json',
                        url: div.data("url"),
                        complete: function(jqXHR) {
                            div.remove();
                        }
                    });
                }
            });
        }

        /* Button - delete TODO list entry */
        expander_panel.find(".delete-easy-to-do-lists-item").on("click", function () {
            var li = $(this).parent().parent();
            if (confirm($(this).data("text"))) {
                $.ajax({
                    type: "delete",
                    dataType: 'json',
                    url: li.data("url"),
                    complete: function(jqXHR) {
                        li.remove();
                    }
                });
            }
        });

        /* Button - submit TODO list form */
        if (opts.moreToDoLists){
            expander_panel.find(".easy-to-do-list-new-form").on("submit", function () {
                var frm = $(this);
                $.ajax({
                    type: "post",
                    url: frm.attr("action"),
                    dataType: 'json',
                    data: "html=1&" + frm.serialize(),
                    complete: function(jqXHR) {
                        $(".to-do-lists").append(jqXHR.responseJSON.html);
                        closeEasyToDoListNewForm();
                        initializeListItemsSortable();
                        reloadToDoLists();
                    }
                });
                return false;
            });
        }

        /* Button - submit TODO list entry form */
        expander_panel.find(".easy-to-do-lists-item-new-form").on("submit", function () {
            var frm = $(this);
            $.ajax({
                type: "post",
                url: frm.attr("action"),
                dataType: 'json',
                data: "html=1&" + frm.serialize(),
                complete: function(jqXHR) {
                    frm.closest(".to-do-list").find(".easy-to-do-list-items-container").prepend(jqXHR.responseJSON.html);
                    closeEasyToDoListsItemNewForm(frm);
                    reloadToDoLists();
                }
            });
            return false;
        });

        /* Button - click TODO list entry checkbox */
        expander_panel.find("li.movable-list-item input[type=checkbox]").on("change", function () {
            var li = $(this).parent().parent();
            $.ajax({
                type: "put",
                url: li.data("url"),
                dataType: 'json',
                data: "html=1&easy_to_do_list_item[is_done]=" + ($(this).is(":checked") ? '1' : '0'),
                complete: function(jqXHR) {
                    li.replaceWith(jqXHR.responseJSON.html);
                    reloadToDoLists();
                }
            });
        });

        expander_panel.find("li.movable-list-item").on("dblclick", function () {
            disableListItemsSortable();
            var li = $(this);
            var li_dup = li.html();
            var input = $("<input/>").attr({
                "type": "text",
                "value": li.data("text")
            });
            li.html(input);
            input.focus().keydown(function(event){
                if (event.keyCode === 13) {
                    $.ajax({
                        type: "put",
                        url: li.data("url"),
                        dataType: 'json',
                        data: "html=1&easy_to_do_list_item[name]="+$(this).val(),
                        complete: function(jqXHR) {
                            li.replaceWith(jqXHR.responseJSON.html);
                            enableListItemsSortable();
                        }
                    });
                }
                if (event.keyCode === 27) {
                    li.html(li_dup);
                    enableListItemsSortable();
                }
            }).focusout(function(event){
                $.ajax({
                    type: "put",
                    url: li.data("url"),
                    dataType: 'json',
                    data: "html=1&easy_to_do_list_item[name]="+$(this).val(),
                    complete: function(jqXHR) {
                        li.replaceWith(jqXHR.responseJSON.html);
                        enableListItemsSortable();
                    }
                });
            });
        });

        if (opts.moreToDoLists){
            expander_panel.find(".to-do-list .header").on("dblclick", function () {
                enableSelection();
                var div = $(this);
                var div_dup = div.html();
                var input = $("<input/>").attr({
                    "type": "text",
                    "value": div.data("text")
                });
                div.html(input);
                input.focus().keydown(function(event){
                    if (event.keyCode === 13) {
                        $.ajax({
                            type: "put",
                            url: div.parent().data("url"),
                            dataType: 'json',
                            data: "html=1&easy_to_do_list[name]="+$(this).val(),
                            complete: function(jqXHR) {
                                div.replaceWith($(jqXHR.responseJSON.html).find(".header"));
                                disableSelection();
                            }
                        });
                    }
                    if (event.keyCode === 27) {
                        div.html(div_dup);
                        disableSelection();
                    }
                }).focusout(function(event){
                    $.ajax({
                        type: "put",
                        url: div.parent().data("url"),
                        dataType: 'json',
                        data: "html=1&easy_to_do_list[name]="+$(this).val(),
                        complete: function(jqXHR) {
                            div.replaceWith($(jqXHR.responseJSON.html).find(".header"));
                            disableSelection();
                        }
                    });
                });
            });
        }

        function getToDoListElements(){
            return expander_panel.find(".to-do-list").find("ul");
        }

        function initializeListSortable() {
            if (!opts.moreToDoLists) return;
            expander_panel.sortable({
                items: "div.to-do-list",
                cursor: "move",
                handle: ".header",
                revert: true,
                axis: "y",
                update: function( event, ui ) {
                    $.ajax({
                        type: "put",
                        url: ui.item.data("url"),
                        dataType: 'json',
                        data: "easy_to_do_list[position]="+(ui.item.index() + 1)
                    });
                }
            });
        }

        function initializeListItemsSortable() {
            getToDoListElements().sortable({
                items: "li.movable-list-item",
                connectWith: ".to-do-list ul",
                cursor: "move",
                placeholder: {
                    element: function(currentItem) {
                        return $("<li class=\"ui-state-highlight icon-import\">"+opts.lang.pushSortbale+"</li>")[0];
                    },
                    update: function(container, p) {
                        return;
                    }
                },
                revert: true,
                tolerance: "pointer",
                forcePlaceholderSize: true,
                helper: "clone",
                appendTo: document.body,
                start: function(event, ui) {
                    if (!ui.item.hasClass("easy-panel-handler") && !ui.item.data().uiDraggable){
                        $(".easy-dropper-target").each(function(index, item) {
                            var zone; var attributes;
                            if ($(item).hasClass('easy-drop-user')) {
                                zone = createEasyDropZone(item, opts.dropZoneUser);
                                attributes = {"issue[assigned_to_id]": $(item).data().userId};
                            } else if ($(item).hasClass('easy-drop-project')) {
                                zone = createEasyDropZone(item, opts.dropZoneOther);
                                attributes = {"issue[project_id]": $(item).data().projectId};
                            } else if ($(item).hasClass('easy-drop-calendar')) {
                                zone = createEasyDropZone(item, opts.dropZoneCalendar);
                                attributes = {"issue[start_date]": $(item).data().calendarDay, "issue[due_date]": $(item).data().calendarDay};
                            } else if (!$(item).hasClass('easy-drop-issue')) {
                                zone = createEasyDropZone(item, opts.dropZoneOther);
                                attributes = {};
                            }
                            if (zone) {
                                zone.droppable({
                                    hoverClass: "easy-target-dropzone-hover",
                                    accept: "#easy_servicebar_component .to-do-list li.movable-list-item",
                                    drop: function( event, ui ) {
                                        var issue_data = {
                                            "issue[subject]": ui.draggable.data("text"),
                                            "issue[description]": ui.draggable.data("text")
                                        };
                                        $.extend(true, issue_data, attributes);
                                        redirectToNewIssue(issue_data);
                                    }
                                })

                            }
                        })
                    }
                },
                stop: function(event, ui, item) {
                    var uiItem = ui ? ui.item : $("div.to-do-list").first();
                    if (!item) {
                        item = ui.item;
                    }
                    $(".easy-target-dropzone").remove();
                    $(".easy-dropper-target").css({"position":''});
                    if (!item.is(".movable-list-item")) return;
                    var handler = $("[data-entity-id='"+(item.data().handlerEntityId)+"'][data-handler='true']");
                    if (!$().easy_to_do_list_accepted_entity(item.data().entityType)) return '';

                    $.ajax({
                        type: "post",
                        url: uiItem.closest("div.to-do-list").data("url")+"/easy_to_do_list_items",
                        dataType: 'json',
                        data: {
                            html: '1',
                            easy_to_do_list_item: {
                                name: handler.contents().first().text().trim(),
                                entity_type: handler.data().entityType,
                                entity_id: handler.data().entityId,
                                position: (ui && ui.item) ? (item.index() + 1) : 1
                            }
                        },
                        complete: function(jqXHR) {
                            if (ui === null) {
                                $("#easy_servicebar_component .to-do-list ul:first").prepend(jqXHR.responseJSON.html);
                                reloadToDoLists();
                            } else {
                                item.replaceWith(jqXHR.responseJSON.html);
                                reloadToDoLists();
                            }

                        }
                    });
                },
                update: function( event, ui ) {
                  if (this === ui.item.parent()[0]) {
                    var item_url = ui.item.data("url");
                    if (!item_url) return;
                    var list_id = ui.item.closest("div.to-do-list").data("list-id");
                    $.ajax({
                        type: "put",
                        dataType: 'json',
                        url: ui.item.data("url"),
                        data: {
                                html: '1',
                                easy_to_do_list_item: {
                                  position: ui.item.index() + 1,
                                  easy_to_do_list_id: list_id
                                }
                        },
                        complete: function(jqXHR) {
                            ui.item.replaceWith(jqXHR.responseJSON.html);reloadToDoLists();}
                    });

                }
              }
            });
        }

        function disableSelection() {
            if (opts.moreToDoLists){
                expander_panel.disableSelection();
            }
            getToDoListElements().disableSelection();
        }

        function enableSelection() {
            if (opts.moreToDoLists){
                expander_panel.enableSelection();
            }
            getToDoListElements().enableSelection();
        }

        function disableListItemsSortable() {
            getToDoListElements().sortable("disable");
            enableSelection();
        }

        function enableListItemsSortable() {
            getToDoListElements().sortable("enable");
            disableSelection();
        }

        function redirectToNewIssue(params) {
            var issue_url = opts.newIssueUrl;
            var issue_url_params = [];
            if (params) {
                $.each(params, function(key, val) {
                    issue_url_params.push(key + "=" + val);
                });
            }

            $.get(issue_url, issue_url_params.join("&"), function(data) {
                var modal = $("#ajax-modal");
                modal.html(data);
                EASY.modalSelector.showModal('95%');
                modal.dialog("option", {
                    title: opts.newIssueTitle,
                    buttons: [
                        {
                            text: opts.closeButton,
                            click: function () {
                                $(this).dialog('close');
                            }, 'class': 'button'
                        },
                        {
                            text: opts.createButton,
                            click: function () {
                                if (typeof(CKEDITOR) !== 'undefined') {
                                    CKEDITOR.instances["easy_modalissue_description"].updateElement();
                                }
                                $(this).find('form').submit();
                            }, 'class': 'button-positive'
                        }
                    ]
                });
            });
        }

        function closeEasyToDoListNewForm() {
            new_form_easy_to_do_list.hide();
            button_add_easy_to_do_list.show();
        }

        function closeEasyToDoListsItemNewForm(btnClicked) {
            btnClicked.closest(".easy-to-do-lists-item-new-form-container").hide().prev(".add-easy-to-do-lists-item").show();
        }
    };
} (jQuery));
