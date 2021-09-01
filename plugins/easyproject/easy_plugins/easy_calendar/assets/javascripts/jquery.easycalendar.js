/*globals jQuery, moment, I18n, CKEDITOR */
/*jslint browser: true, devel: true*/
(function ($) {
    "use strict";
    $.fn.easyCalendar = function (easyOpts) {
        var calendar = $(this),
            header = calendar.prev(".easy-calendar-header"),
            //userSelector = $(".easy-cal-user-selection", header),
            userArray = $(".easy-cal-selected-users", header),
            //calendarArray = $("#module_inside_" + easyOpts.moduleId + " .easy-cal-calendar-selection .entity-array"),
            //selectedCalendars = [],
            dialogWidths = "80%",
            opts = {
                events: {
                    url: window.easyCalendarOptions.easy_calendar_feed + "?" + $.param({
                        module_id: easyOpts.moduleId,
                        user_calendars: null
                    })
                },
                calendarTypes: [],
                minTime: easyOpts.minTime || 0,
                maxTime: easyOpts.maxTime || 24,
                defaultView: easyOpts.defaultView || "agendaWeek",
                calendarNewEvent: easyOpts.calendarNewEvent || "easy_meeting_calendar",
                urlPrefix: window.urlPrefix,
                origin: window.easyCalendarOptions.easy_calendar_base_url,
                firstDay: easyOpts.firstDay || 1,
                firstHour: easyOpts.firstHour || 8
            },

            entityDialog = function (element, html, buttons) {
                var title;
                element.html($(html));
                title = $("h2", element).text();
                $("h2", element).remove();
                var mh = ERUI.topMenu.outerHeight();
                var wh = window.innerHeight;

                element.dialog({
                    title: title,
                    width: dialogWidths,
                    buttons: buttons,
                    modal: true,
                    resizable: false,
                    maxHeight: wh - mh,
                    close: function() {
                        element.dialog("close").remove();
                        ERUI.body.removeClass('modal-opened');
                    },
                    open: function() {
                        initEasyAutocomplete();
                        ERUI.body.addClass('modal-opened');
                    }
                });
            },
            eventTypes = {
                meeting_detail: {
                    click: function (event) {
                        var dialog = $("<div/>").appendTo($("body"));
                        $.get(opts.origin + event.url, function (resp) {
                            entityDialog(dialog, resp, {});
                        });
                        return false;
                    },
                    afterRender: function (event, element) {
                        if(event.editable) { addDeleteButton(element, event); };
                        addTitle(element, event.title);
                    }
                },
                meeting_invitation: {
                    click: function (event) {
                        var dialog = $("<div/>").appendTo($("body")),
                            availableButtons = {};
                        if (event.accepted === false || event.accepted === undefined) {
                            availableButtons['accept'] =
                            {
                                text: I18n.meetingAccept,
                                class: 'button-positive',
                                tabIndex: -1,
                                click: function() {
                                    $.post(opts.origin + event.url + "/accept", function() {
                                        calendar.fullCalendar("refetchEvents");
                                        dialog.dialog("close");
                                    });
                                }
                            };
                        }
                        if (event.declined === false || event.declined === undefined) {
                            availableButtons['decline'] =
                                {
                                    text: I18n.meetingDecline,
                                    class: 'button',
                                    tabIndex: -1,
                                    click: function() {
                                        $.post(opts.origin + event.url + "/decline", function() {
                                            calendar.fullCalendar("refetchEvents");
                                            dialog.dialog("close");
                                        });
                                    }
                               };
                        }
                        if (event.editable) {
                            availableButtons['edit'] =
                            {
                                text: I18n.meetingEdit,
                                class: 'button',
                                tabIndex: -1,
                                click: function() {
                                    var dialog_edit = $("<div/>").appendTo($("body"));
                                    $.get( opts.origin + event.url + "/edit", function (resp) {
                                        dialog.dialog("close");
                                        entityDialog(dialog_edit, resp, [
                                            {
                                                text: I18n.buttonSave,
                                                class: 'button-positive',
                                                click: function () {
                                                    if (typeof CKEDITOR !== "undefined" && CKEDITOR && CKEDITOR.instances.easy_meeting_description) {
                                                        CKEDITOR.instances.easy_meeting_description.updateElement();
                                                    }
                                                    $.ajax({
                                                        url: opts.origin + event.url + ".json",
                                                        type: "PUT",
                                                        data: $("form", dialog_edit).serialize(),
                                                        complete: function (jqXHR) {
                                                            var json;
                                                            if (jqXHR.status === 422) {
                                                                json = $.parseJSON(jqXHR.responseText);
                                                                $(".flash", dialog_edit).remove();
                                                                $("<div/>")
                                                                    .addClass("flash error")
                                                                    .prependTo(dialog_edit)
                                                                    .html(json.errors.join("</br>"));
                                                            } else {
                                                                dialog_edit.dialog("close");
                                                                calendar.fullCalendar("refetchEvents");
                                                            }
                                                        }
                                                    });
                                                }
                                            },
                                            {
                                                text: I18n.buttonCancel,
                                                class: 'button',
                                                click: function () {
                                                    dialog_edit.dialog("close");
                                                }
                                            }
                                        ]);
                                        bindDeleteRepeatingButtons(dialog_edit);
                                        if (typeof event.parentUrl !== "undefined" && event.parentUrl.length > 0) {
                                            bindParentButton(event, dialog_edit);
                                        }
                                    });
                                    return false;
                                }
                            };
                        }

                        $.get(opts.origin + event.url, function (resp) {
                            entityDialog(dialog, resp, availableButtons);
                        });
                        return false;
                    },
                    render: function (event, element) {
                        if (event.accepted === true) {
                            element.addClass("invitation-accepted");
                        } else if (event.declined === true) {
                            element.addClass("invitation-declined");
                        } else {
                            element.addClass("invitation-new");
                        }
                    },
                    afterRender: function (event, element) {
                        if(event.editable) { addDeleteButton(element, event); };
                        addTitle(element, event.title);
                    }
                },
                easy_crm_case_contract: {
                    afterRender: function (event, element) {
                        $(element).find(".fc-event-inner").addClass("icon-money");
                    }
                },
                easy_crm_case_next_action: {
                    afterRender: function (event, element) {
                        $(element).find(".fc-event-inner").addClass("icon-move");
                    }
                },
                issue: {
                    afterRender: function (event, element) {
                        console.warn("attempt to bind tooltip on issue", event);
                        // probably not used
                    }
                },
                meeting: {
                    change: function (event) {
                        $.ajax({
                            url: opts.origin + event.url,
                            type: "PUT",
                            data: {
                                format: "json",
                                easy_meeting: {
                                    start_time: event.start,
                                    end_time: event.end,
                                    all_day: event.allDay
                                }
                            },
                            error: function () {
                                calendar.fullCalendar("refetchEvents");
                            }
                        });
                    },
                    click: clickOnMeeting,
                    afterRender: function (event, element) {
                        var title;

                        if (event.editable) {
                            addDeleteButton(element, event);
                        }

                        if (event.bigRecurringChildren) {
                            $("<span style=\"position:absolute;top: 0px;right: 0px;z-index:9\"/>").addClass("icon icon-reload").prependTo(element);
                        }

                        if (event.location) {
                            title = $(".fc-event-title", element);
                            if (title.length > 0) {
                                $("<div/>")
                                    .html(event.location)
                                    .addClass("fc-event-location")
                                    .insertAfter(title);
                            } else {
                                $(".fc-event-time", element).append(" - " + event.location);
                            }
                        }
                        addTitle(element, event.title)

                    }
                },
                availability_meeting: {
                    afterRender: function (event, element) {
                        if(event.editable) { addDeleteButton(element, event); };
                        addTitle(element, event.title);
                    }
                },
                easy_attendance: {
                    render: function (event, element) {
                      let html = element[0].children[0];
                      let iconPending = "<span class='easy-calendar__event_body-action'><i class='icon easy-calendar__event-icon-meeting--approvable'></i></span>";
                      let iconApproved = "<span class='easy-calendar__event_body-action'><i class='icon easy-calendar__event-icon-meeting--confirmed'></i></span>";
                      let iconRejected = "<span class='easy-calendar__event_body-action'><i class='icon easy-calendar__event-icon-meeting--rejected'></i></span>";
                      if (event.confirmed) {
                        html.innerHTML += `<span class="fc-event-icon">${iconApproved}</span>`;
                      } else {
                        event.needApprove ? html.innerHTML += `<span class="fc-event-icon">${iconPending}</span>` :
                                            html.innerHTML +=`<span class="fc-event-icon">${iconRejected}</span>`;
                      }
                    }
                }
            };

        $.extend(opts, easyOpts);

        function clickOnMeeting(event) {
            var dialog = $("<div/>").appendTo($("body"));
            $.get( opts.origin + event.url + "/edit.html", function (resp) {
                entityDialog(dialog, resp, [
                    {
                        text: I18n.buttonSave,
                        class: 'button-positive',
                        click: function () {
                            if (typeof CKEDITOR !== "undefined" && CKEDITOR && CKEDITOR.instances.easy_meeting_description) {
                                CKEDITOR.instances.easy_meeting_description.updateElement();
                            }
                            $.ajax({
                                url: opts.origin + event.url + ".json",
                                type: "PUT",
                                data: $("form", dialog).serialize(),
                                complete: function (jqXHR) {
                                    var json;
                                    if (jqXHR.status === 422) {
                                        json = $.parseJSON(jqXHR.responseText);
                                        $(".flash", dialog).remove();
                                        $("<div/>")
                                            .addClass("flash error")
                                            .prependTo(dialog)
                                            .html(json.errors.join("</br>"));
                                    } else {
                                        dialog.dialog("close");
                                        calendar.fullCalendar("refetchEvents");
                                    }
                                }
                            });
                        }
                    },
                    {
                        text: I18n.buttonCancel,
                        class: 'button',
                        click: function () {
                            dialog.dialog("close");
                        }
                    }
                ]);
                bindDeleteRepeatingButtons(dialog);
                if (typeof event.parentUrl !== "undefined" && event.parentUrl.length > 0) {
                    bindParentButton(event, dialog);
                }
            });
            return false;
        }

        function getNewEventType() {
            return opts.calendarNewEvent;
        }

        function createEvent(typeOpts, dialog) {
            var form = $("form", dialog);

            if (typeof CKEDITOR !== "undefined" && CKEDITOR && CKEDITOR.instances.easy_meeting_description) {
                CKEDITOR.instances.easy_meeting_description.updateElement();
            }

            $.ajax({
                url: typeOpts.create_record_path,
                type: "POST",
                data: form.serialize(),
                complete: function (jqXHR) {
                    var json;
                    if (jqXHR.status === 422) {
                        json = $.parseJSON(jqXHR.responseText);
                        $(".flash", dialog).remove();
                        $("<div/>")
                            .addClass("flash error")
                            .prependTo(dialog)
                            .html(json.errors.join("</br>"));
                    } else {
                        dialog.dialog("close");
                        calendar.fullCalendar("refetchEvents");
                    }
                }
            });
        }

        function newEvent(start, end, allDay) {
            var typeOpts = opts.calendarTypes[getNewEventType()],
                newEventDialog = $("<div/>").addClass("new-event-dialog").addClass("active-dialog").appendTo("body");
                if (easyOpts.roomId){
                    newEventDialog.attr("data-room-id", easyOpts.roomId);
                }
                if (easyOpts.roomName){
                    newEventDialog.attr("data-room-name", easyOpts.roomName);
                }

            if (!typeOpts) {
                return false;
            }
            $.get(typeOpts.new_record_path, {
                    easy_meeting: {
                        start_time: allDay ? moment(start).startOf("day").toDate() : start,
                        end_time: allDay ? moment(end).endOf("day").toDate() : end,
                        all_day: allDay ? "1" : "0"
                    }
                },
                function (data) {
                    entityDialog(newEventDialog, data, [
                        {
                            text: I18n.buttonSave,
                            class: 'button-positive',
                            click: function () {
                                createEvent(typeOpts, newEventDialog);
                            }
                        },
                        {
                            text: I18n.buttonCancel,
                            class: 'button',
                            click: function () {
                                $(this).dialog("close");
                            }
                        }
                    ]);
                }
            );
        }

        function eventTypeCallback(functionName, event) {
            var eventType;
            if (event.eventType && (eventType = eventTypes[event.eventType])) {
                if (typeof eventType[functionName] === "function") {
                    return eventType[functionName].apply(null, [].splice.call(arguments, 1));
                }
            }
        }

        function addUserCalendar(id, name, className) {
            var entity = userArray.entityArray("add", {
                id: id,
                name: name,
                className: className
            });
            if (entity) {
                calendar.fullCalendar("addEventSource", {
                    url: window.easyCalendarOptions.easy_calendar_user_availability + "?user_id=" + id,
                    className: className
                });
            }
        }

        function saveUserAvailability() {
            var ids = [];
            $('input', userArray).each(function (i) {
                ids.push($(this).val());
            });
            $.post(window.easyCalendarOptions.easy_calendar_save_availability, {user_ids: ids, module_id: opts.moduleId});
        }

        function saveAndRefreshCalendars() {
            var ids = [];
            $("#module_inside_" + opts.moduleId + " .easy-cal-calendar-selection .entity-array input").each(function (i) {
                ids.push($(this).val());
            });
            $.post(window.easyCalendarOptions.easy_calendar_save_calendars, {calendar_ids: ids, module_id: opts.moduleId}, function() {
                calendar.fullCalendar("refetchEvents");
            });
        }

        function updateTitle(html) {
            $('.easy-cal-title', header).html(html);
        }

        function addTitle(element, title) {
            element.prop('title', title);
        }

        function addDeleteButton(element, event) {
            $("<span style=\"position:absolute;top: 0px;right: 0px;z-index:9\"/>").addClass("icon icon-del delete-meeting").prependTo(element).click(function () {
                if (confirm(I18n.meetingDestroyConfirmation)) {
                    $.ajax({
                        url: opts.origin + event.url,
                        type: "DELETE",
                        success: function () {
                            calendar.fullCalendar("refetchEvents");
                        }
                    });
                }
                return false;
            });
        }

        function bindParentButton(event, dialog) {
          $('.easy-show-repeating-parent').click(function(e) {
            e.preventDefault();
            dialog.dialog("close");
            var parentEvent = {
                url: event.parentUrl,
                parentUrl: ''
            };
            clickOnMeeting(parentEvent);
          });
        }

        // refetch events, when event/events is/are deleted
        function bindDeleteRepeatingButtons(dialog) {
          $('.easy-delete-meeting').bind('ajax:complete', function() {
            dialog.dialog("close");
            calendar.fullCalendar("refetchEvents");
          });
        }

        calendar.fullCalendar($.extend(opts, {
            header: "",
            // view options
            editable: false,
            selectable: true,
            // lang
            monthNamesShort: moment.monthsShort(),
            monthNames: moment.months(),
            dayNames: moment.weekdays(),
            dayNamesShort: moment.weekdaysShort(),
            // date / time formats
            axisFormat: "H:mm",
            timeFormat: "H:mm",
            columnFormat: easyOpts.columnFormat || {
                month: "dddd",
                week: "dddd d. M.",
                day: "dddd d. M."
            },
            // events
            select: function (start, end, allDay) {
                newEvent(start, end, allDay);
                calendar.fullCalendar("unselect");
            },
            eventClick: function (event) {
                return eventTypeCallback("click", event);
            },
            eventDrop: function (event) {
                return eventTypeCallback("change", event);
            },
            eventResize: function (event) {
                return eventTypeCallback("change", event);
            },
            eventRender: function (event, element, view) {
                return eventTypeCallback("render", event, element, view);
            },
            eventAfterRender: function (event, element, view) {
                return eventTypeCallback("afterRender", event, element, view);
            },
            viewRender: function() {
                var view = calendar.fullCalendar('getView');
                var title = view.title;
                updateTitle(title);
                var h;
                if (view.name === "month") {
                    h = NaN;
                }
                else {
                    h = 5500;  // high enough to avoid scrollbars
                }
                calendar.fullCalendar('option', 'contentHeight', h);
            }
        }));

        // rerender on toggle
        calendar.closest(".module-content").prev(".module-toggle-button").click(function () {
            calendar.fullCalendar("render");
        });

        // user selection
        (function () {
            var userField = $('#' + calendar[0].id + "-user-select"),
                userAutocompleteField = $('#' + calendar[0].id + "-user-select_autocomplete"),
                n = 0;

            userArray.entityArray({
                afterRemove: function (entity) {
                    calendar.fullCalendar("removeEventSource", window.easyCalendarOptions.easy_calendar_user_availability + "?user_id=" +entity.id);
                    saveUserAvailability();
                }
            });

            userField.change(function () {
                addUserCalendar(userField.val(), userAutocompleteField.val(), "palette-"+(n+1));
                userField.val("");
                userAutocompleteField.val("");
                n += 1;
                saveUserAvailability();
            });

            if (opts.users) {
                $.each(opts.users, function () {
                    addUserCalendar(this.id, this.name, "palette-"+(n+1));
                    userField.val("");
                    userAutocompleteField.val("");
                    n += 1;
                });
            }
        }());

        // calendar selection
        (function () {
            var calendarField = $('#' + calendar[0].id + "-calendar-select");

            calendarField.change(function () {
                saveAndRefreshCalendars();
            });

        }());

        // calendar header actions

        // <
        $(".easy-cal-prev", header).click(function () {
            calendar.fullCalendar("prev");
            return false;
        });
        // >
        $(".easy-cal-next", header).click(function () {
            calendar.fullCalendar("next");
            return false;
        });
        // month
        $(".easy-cal-month", header).click(function () {
            $(this).addClass("pressed").siblings().removeClass("pressed");
            calendar.fullCalendar("changeView", "month");
            return false;
        });
        // week
        $(".easy-cal-week", header).click(function () {
            $(this).addClass("pressed").siblings().removeClass("pressed");
            calendar.fullCalendar("changeView", "agendaWeek");
            return false;
        });
        // day
        $(".easy-cal-day", header).click(function () {
            $(this).addClass("pressed").siblings().removeClass("pressed");
            calendar.fullCalendar("changeView", "agendaDay");
            return false;
        });
    };

}(jQuery));
