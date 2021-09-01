/*globals jQuery */
/*jslint browser: true, devel: true*/
;
(function($, window, document, undefined) {
    "use strict";

    var pluginName = "agileboard",
            defaults = {
        newSprintUrl: null,
        loadHistory: false,
        historyToggle: null,
        assignedToCombo: null
    };

    function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
    }

    Plugin.prototype = {
        init: function() {
            var self = this;
            this.sidebar = $(".agile-board-sidebar", this.element).accordion({
                heightStyle: "content",
                collapsible: true
            });
            this.body = $(".agile-board-body", this.element);
            this.loadSprints(this.options.loadHistory);
            if (this.options.editable) {
                this.initProjectBacklog();
                this.initProjectTeam();
            }
            if (this.options.historyToggle) {
                $(this.options.historyToggle).change(function(evt) {
                    if ($(this).is(':checked')) {
                        self.options.loadHistory = true;
                        if (!self.historyLoaded)
                            self.loadSprints(self.options.loadHistory);
                    } else {
                        self.options.loadHistory = false;
                    }
                });
            }
            if (this.options.assignedToCombo) {
                $(this.options.assignedToCombo).change(function(evt) {
                    self.loadSprints(self.options.loadHistory);
                });
            }

            this.initRating();
        },
        initRating: function() {
            var self = this;
            this.element.on('click', '.issue-rating', function() {
                var $this = $(this);
                var newValue;
                if (newValue = prompt(self.options.lang.est, $this.data('value'))) {
                    var data = {};
                    data[$this.data('key')] = newValue;
                    $.ajax({
                        url: window.urlPrefix + '/issues/' + $this.data('id') + '.json',
                        type: 'PUT',
                        data: {
                            issue: data
                        },
                        success: function(data) {
                            $('.value', $this).text(newValue);
                            // self.ra.flash(self.ra.settings.lang.successfulUpdate, 'notice');
                        },
                        error: function(xhr) {
                            data = $.parseJSON(xhr.responseText);
                            // self.ra.flash(data.errors.join('\n'), 'error');
                        }

                    });
                }
                return $this;
            });
        },
        initProjectBacklog: function() {
            this.projectBacklog = $(".project-backlog", this.element);
            this.initAgileListItems($("li", this.projectBacklog));
            $(".agile-list", this.projectBacklog).droppable({
                activeClass: 'droppable-active',
                hoverClass: 'droppable-hover',
                accept: '.agile-issue-item',
                tolerance: 'pointer',
                drop: function(event, ui) {
                    ui.draggable.appendTo(this);
                    $.post('easy_sprints/unassign_issue', {
                        issue_id: ui.draggable.data('id')
                    });
                }
            });
        },
        initAgileListItems: function(el) {
            el.draggable({
                helper: "clone",
                cursorAt: {left: 10, top: 10}
            }).droppable({
                activeClass: 'droppable-active',
                hoverClass: 'droppable-hover',
                accept: '.member',
                tolerance: 'pointer',
                drop: function(event, ui) {
                    $(".avatar-container", this).remove();
                    var ac = $(".avatar-container", ui.draggable).clone().prependTo($(this));
                    $("img", ac).attr("width", 30).attr("height", 30);
                    $.ajax({
                        url: "/issues/" + $(this).data("id") + ".json",
                        type: "PUT",
                        data: {issue: {assigned_to_id: ui.draggable.data("id")}}
                    });
                }
            });
        },
        initProjectTeam: function() {
            this.projectTeam = $(".project-team", this.element);
            $("div.member", this.projectTeam).draggable({
                helper: function() {
                    return $(".avatar-container", this).clone();
                },
                cursorAt: {left: 10, top: 10}
            });
        },
        newSprint: function() {
            var self = this;
            if (this.newSprintForm) {
                this.newSprintForm.remove();
            }
            $.get(this.options.newSprintUrl, function(resp) {
                self.newSprintForm = $(resp).prependTo(self.body).find('form.easy-sprint');
                self.newSprintForm.submit(function() {
                    self.createSprint();
                    return false;
                });
            });
        },
        createSprint: function() {
            var self = this;
            $.ajax({
                url: this.options.sprintsUrl + ".json",
                type: "POST",
                data: this.newSprintForm.serialize(),
                complete: function(resp) {
                    if (resp.status === 422) {
                        self.validationErrors($.parseJSON(resp.responseText).errors);
                    } else {
                        self.loadSprints(self.options.loadHistory);
                    }
                }
            });
        },
        validationErrors: function(errors) {
            var err, ul;
            $("#errorExplanation").remove();
            err = $("<div/>")
                    .prependTo(this.body)
                    .attr("id", "errorExplanation");
            ul = $("<ul/>").appendTo(err);
            if (errors) {
                $("<li/>").appendTo(ul).html(errors.join('<br/>'));
            }
        },
        loadSprints: function(history) {
            var self = this;
            this.sprints = [];
            var url = this.options.sprintsUrl;
            var urlOptions = [];
            if (history) {
                urlOptions.push('history=true');
            }
            if (this.options.assignedToCombo) {
                var assigned_to_id = $(this.options.assignedToCombo).val();
                urlOptions.push('assigned_to_id=' + assigned_to_id);
            }
            url += '?' + urlOptions.join('&');
            this.body.load(url, function() {
                $(".easy-sprint", this.element).each(function() {
                    self.sprints.push(new Sprint(self, $(this)));
                });
                if (self.options.editable) {
                    self.newSprint();
                }
            });
            self.historyLoaded = history;
        },
        initExternalSprint: function(options) {
            if (!this.external_sprints)
                this.external_sprints = [];
            this.external_sprints.push(new Sprint(this, $(options.element)));
        }

    };

    function Sprint(plugin, element) {
        this.plugin = plugin;
        this.element = element;
        this.init();
    }

    Sprint.prototype = {
        init: function() {
            var self = this;
            if (this.plugin.options.editable) {
                $(".sprint-col", this.element).droppable({
                    activeClass: 'droppable-active',
                    hoverClass: 'droppable-hover',
                    accept: '.agile-issue-item',
                    tolerance: 'pointer',
                    drop: function(event, ui) {
                        var $ul = $('.agile-list', $(this));
                        ui.draggable.appendTo($ul);
                        $.post(window.urlPrefix + '/easy_sprints/' + self.element.data('id') + '/assign_issue', {
                            issue_id: ui.draggable.data('id'),
                            relation_type: $ul.data('relation-type'),
                            relation_position: $ul.data('relation-position')
                        });

                    }
                });
                this.plugin.initAgileListItems($("li", this.element));
            }
        }
    };

    $.fn[pluginName] = function(options, methodAttrs) {
        return this.each(function() {
            var instance = $.data(this, "plugin_" + pluginName);
            if (!instance) {
                $.data(this, "plugin_" + pluginName, new Plugin($(this), options));
            } else if (typeof options === "string") {
                instance[options].call(instance, methodAttrs);
            }
        });
    };

})(jQuery, window, document);
