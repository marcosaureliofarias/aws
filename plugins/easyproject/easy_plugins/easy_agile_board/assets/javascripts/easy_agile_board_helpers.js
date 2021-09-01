// pokus o jquery plugin, easy first
;
(function($, window, document, undefined) {
    "use strict";

    var pluginName = "agileboardstatuses",
            defaults = {
        doneContainer: null,
        triggerAdd: '#add_button',
        triggerDel: '.remove_status',
        states: 'tr',
        newStateClass: 'new-state',
        positionPlaceholder: 'NEW_POSITION'
    };

    function Plugin(element, options) {
        this.element = element;
        this.statesTable = element.find('table');
        this.confirmation = element.data('confirm');
        if (this.statesTable.length !== 1) {
            if ('console' in window) {
                console.warn('Warning: Could not initialize ' + pluginName + ', exactly one table of states expected.');
            }
            return;
        }
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.nextPosition = parseInt(element.data('nextpos'));
        this.init();
    }

    Plugin.prototype = {
        init: function() {
            var self = this;
            this.trigger = $(this.options.triggerAdd, this.element);
            this.initStates();
            this.trigger.click(function(evt) {
                evt.preventDefault();
                self.addState();
            });
        },
        initStates: function() {
            var self = this;
            this.states = [];
            $(this.options.states, this.element).each(function() {
                if ($(this).hasClass(self.options['newStateClass'])) {
                    $(this).hide();
                    self.newStateElement = $(this);
                    self.newState = new State(self, self.newStateElement);
                } else {
                    self.states.push(new State(self, $(this)));
                }
            });
            if (typeof self.newStateElement == typeof undefined) {
                if ('console' in window) {
                    console.warn('Warning: Could not find newElement form.');
                }
                return;
            }
            this.element.closest('form').on('submit', function(evt) {
                self.newStateElement.remove();
            });
            this.doneState = new State(self, $( this.options.doneContainer ) );
            for (var i = 0; i < this.states.length; i++) {
                this.states[i].initState();
            }
            this.doneState.initState();
        },
        addState: function() {
            var self = this;
            var state = this.newStateElement.clone();
            var reg_pos = new RegExp(self.options.positionPlaceholder, 'g');
            $('.easy_agile_change_new_position', state).each(function() {
                var attr_name = $(this).attr('name');
                if (attr_name) {
                    attr_name = attr_name.replace(reg_pos, String(self.nextPosition));
                    $(this).attr('name', attr_name);
                }
                var attr_for = $(this).attr('for');
                if (attr_for) {
                    attr_for = attr_for.replace(reg_pos, String(self.nextPosition));
                    $(this).attr('for', attr_for);
                }
                var attr_id = $(this).attr('id');
                if (attr_id) {
                    attr_id = attr_id.replace(reg_pos, String(self.nextPosition));
                    $(this).attr('id', attr_id);
                }
                $(this).removeClass('easy_agile_change_new_position');
            });
            state.appendTo(this.statesTable);
            state.show();
            self.nextPosition += 1;
            this.states.push(new State(this, state));
        }

    }

    function State(plugin, element) {
        this.plugin = plugin;
        this.element = element;
        this.position = element.data('position');
        this.initEvents();
    }

    State.prototype = {
        initEvents: function() {
            var self = this;

            this.element.on('click', this.plugin.options.triggerDel, function(evt) {
                evt.preventDefault();
                if (confirm(self.plugin.confirmation)) {
                    self.deinitState();
                    self.element.remove();
                    for (var i = self.plugin.states.length - 1; i >= 0; i--) {
                        if ( self.plugin.states[i] === self ) {
                            self.plugin.states.splice(i, 1);
                            return;
                        }
                    }
                }
            });

            this.status_select = $('.status_select', this.element);
            $('.status_checkbox', this.element).on('change', function(evt){
                var $chckbox = $(this);
                self.toggle_checked_state( $chckbox.data('statusid'), $chckbox.is(':checked') );
                if( $(this).is(':checked') && self.status_select.val() == '' ) {
                    self.status_select.val($(this).data('statusid'));
                }
            });
        },

        initState: function() {
            var self = this;

            $('.status_checkbox:checked', this.element).each(function(idx) {
                var $chckbox = $(this);
                self.toggle_checked_state( $chckbox.data('statusid'), $chckbox.is(':checked') );
            });
        },

        deinitState: function() {
            var self = this;
            $('.status_checkbox:checked', this.element).each(function(idx) {
                var status_id = $(this).data('statusid');
                self.toggle_checked_state( status_id, false );
            });
        },

        toggle_checked_state: function(status_id, disable) {
            for (var i = this.plugin.states.length - 1; i >= 0; i--) {
                if( this.plugin.states[i] == this )
                    continue;
                this.plugin.states[i].toggle_status(status_id, disable);
            }
            if( this.plugin.doneState !== this )
                this.plugin.doneState.toggle_status(status_id, disable);
            this.plugin.newState.toggle_status(status_id, disable);
        },

        toggle_status: function(status_id, disable) {
            $('.status_checkbox[data-statusid="'+status_id.toString()+'"]', this.element).prop('disabled', disable);
            if( disable ) {
                $('.status_checkbox[data-statusid="'+status_id.toString()+'"]', this.element).prop('checked', false);
            }
        }
    }

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
