(function($) {
    var Flag = function (options) {
        this.init('flag', options, Flag.defaults);
    };
    $.fn.editableutils.inherit(Flag, $.fn.editabletypes.list);

    $.extend(Flag.prototype, {
        renderList: function() {
            var $label;
            this.$tpl.empty();
            if(!$.isArray(this.sourceData)) {
                return;
            }

            for(var i=0; i<this.sourceData.length; i++) {
                // There should be a better way to get name. May need to be changed for other layouts
                var name = this.$input.closest('.line').find("[data-type='flag']").attr('id');
                $label = $('<label class="radio-inline">')
                    .append($('<input>', {
                        type: 'radio',
                        name: 'flag',
                        value: this.sourceData[i].value
                    }));
                $label.append($('<i class="icon icon-project-flag icon-project-flag-' + this.sourceData[i].value + '"></i></label>'));

                // Add radio buttons to template
                this.$tpl.append($label);
            }

            this.$input = this.$tpl.find('input[type="radio"]');
            this.setClass();
        },

        value2str: function(value) {
            return $.isArray(value) ? value.sort().join($.trim(this.options.separator)) : '';
        },

        //parse separated string
        str2value: function(str) {
            var reg, value = null;
            if(typeof str === 'string' && str.length) {
                reg = new RegExp('\\s*'+$.trim(this.options.separator)+'\\s*');
                value = str.split(reg);
            } else if($.isArray(str)) {
                value = str;
            } else {
                value =  '---';
            }
            return value;
        },

        //set checked on required radio buttons
        //!!Could probably be cleaned up since this was for select multiple originally
        value2input: function(value) {
            this.$input.prop('checked', false);

            if($.isArray(value) && value.length) {
                this.$input.each(function(i, el) {
                    var $el = $(el);
                    // cannot use $.inArray as it performs strict comparison
                    $.each(value, function(j, val) {
                        if($el.val() === val) {
                            $el.prop('checked', true);
                        }
                    });
                });
            }
        },

        input2value: function() {
            return this.$input.filter(':checked').val();
        },

        //collect text of checked boxes
        value2htmlFinal: function(value, element) {
            var checked = $.fn.editableutils.itemsByValue(value, this.sourceData);
            if(checked.length) {
                $(element).html($.fn.editableutils.escape(value));
            } else {
                $(element).empty();
            }
        },

        value2submit: function(value) {
            return value;
        },

        activate: function() {
            this.$input.first().focus();
        },
        value2html: function (value, element) {
            if (value === '---') {
                $(element).html('<span>---</span>');
            } else {
                var html = '';
                if($.isArray(value)) {
                    value.forEach(function(el) {
                        html += '<i class="icon icon-project-flag icon-project-flag-' + el + '"></i>';
                    });
                } else {
                    html = '<i class="icon icon-project-flag icon-project-flag-' + value + '"></i>';
                }
                $(element).html(html);
            }
        }
    });

    Flag.defaults = $.extend({}, $.fn.editabletypes.list.defaults, {
        /**
         @property tpl
         @default <div></div>
         **/
        tpl:'<label class="editable-flag"></label>',

        /**
         @property inputclass
         @type string
         @default null
         **/
        inputclass: '',

        /**
         Separator of values when reading from `data-value` attribute
         @property separator
         @type string
         @default ','
         **/
        separator: ','
    });

    $.fn.editabletypes.flag = Flag;

}(window.jQuery));

