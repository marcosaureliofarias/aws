(function ($) {
    // defaults
    $.extend($.fn.editable.defaults, {
        send: 'always',
        toggle: 'manual',
        ajaxOptions: {
          type: 'PUT',
          dataType: 'text',
          complete: function(jqXHR) {
            if(jqXHR.status !== 422) {
              window.easy_lock_version = jqXHR.getResponseHeader('X-Easy-Lock-Version');
              window.easy_last_journal_id = jqXHR.getResponseHeader('X-Easy-Last-Journal-Id');
            }
          },
          beforeSend: function(jqXHR, settings) {
            if (window.easy_lock_version) {
              var new_params = $.param({
                lock_verrsion: window.easy_lock_version,
                last_journal_id: window.easy_last_journal_id
              });
              settings.url = settings.url.replace(/\?.*$/, '?'+new_params);
            }
          }
        },
        emptytext: '-',
        title: '',
        params: function (data) {
            var params = {};
            params[data.name] = data.value;
            return params;
        },
        error: function (xhr) {
            var json = $.parseJSON(xhr.responseText.replace(/<br\s*[\/]?>/gi, "\\n"));
            if (json && json.errors) {
                return json.errors.join("\n");
            }
        }
    });

    //buttons
    $.fn.editableform.buttons = '<button type="button" class="editable-cancel button-negative icon-fake"><span>cancel</span></button>'
            +'<button type="submit" class="editable-submit button-positive icon-fake"><span>ok</span></button>';

    // checklist
    $.fn.editabletypes.checklist.prototype.input2value = function() {
        var checked = [];
        this.$input.filter(':checked').each(function(i, el) {
            checked.push($(el).val());
        });
        if(checked.length === 0) { checked.unshift(''); }
        return checked;
    };

    // DateUI
    EASY.schedule.require(function () {
        var options = { datepicker: EASY.datepickerOptions };
        if(typeof(I18n) !== 'undefined')
            options['clear'] = '&times; ' + I18n.buttonClear;
        $.extend($.fn.editable.defaults, options);
    }, function () {
      return window.$ && $.fn.editable;
    });

    $.fn.editabletypes.dateui.prototype.value2html = function(value, element) {
        var text;
        if (value) {
            text = moment(value).format(momentjsFormat);
        } else {
            text = '';
        }
        $.fn.editabletypes.dateui.superclass.value2html(text, element);
    };
    $.fn.editableform.Constructor.prototype.showLoading = function () {};

    // Hours
    var Hours = function (options) {
        this.init('hours', options, Hours.defaults);
    };
    $.fn.editableutils.inherit(Hours, $.fn.editabletypes.text);
    $.extend(Hours.prototype, {
        input2value: function () {
            var val = this.$input.val().replace(',', '.');
            return val;
        },
        value2html: function (value, element) {
            if (isNaN(value)) {
                $('<span/>').addClass('hours hours-int').text(value).appendTo($(element).empty());
            } else {
                if (!value) {
                    $(element).text('');
                } else {
                    var fixed = parseFloat(value).toFixed(2).split('.');
                    $('<span/>').addClass('hours hours-int').text(fixed[0]).appendTo($(element).empty());
                    $('<span/>').addClass('hours hours-dec').text('.' + fixed[1]).appendTo($(element));
                }
            }
        }
    });
    Hours.defaults = $.extend({}, $.fn.editabletypes.text.defaults, {});
    $.fn.editabletypes.hours = Hours;

    // EasyAutocomplete
    // data-tpl is required, exmpl render_issue_attribute_for_inline_edit_assigned_to_id
    // easy.catcomplete widget
    var EasyAutocomplete = function (options) {
        this.init('easy_autocomplete', options, EasyAutocomplete.defaults);
    };
    $.fn.editableutils.inherit(EasyAutocomplete, $.fn.editabletypes.text);
    $.extend(EasyAutocomplete.prototype, {
        render: function() {
           this.setClass();
           this.setAttr('placeholder');
        },
        postrender: function () {
            initEasyAutocompleteFor($(this.$input));
            $('.editable-open').data('editableContainer').tip().css('overflow', 'unset');
        },
        value2html: function(value, element) {
          if (this.$input) {
            var uiItem = this.$input.find('.ui-autocomplete-input').data('easyCatcomplete').selectedItem;
            if (uiItem) {
                // to refresh tpl with autocomplete.
                var $tpl = $(this.options.tpl).wrap('<p/>');
                $tpl.find('input:hidden').attr('value', uiItem.id);
                $tpl.find('input[type="text"]').attr('value', uiItem.value);
                this.options.tpl = $tpl.parent().html();
                $(element).text(uiItem.value);
            }
          }
        },
        input2value: function () {
            var val = this.$input.closest('form').serializeArray()[0].value;
            return val;
        }
    });
    EasyAutocomplete.defaults = $.extend({}, $.fn.editabletypes.text.defaults, {

    });
    $.fn.editabletypes.easy_autocomplete = EasyAutocomplete;


    // multivalueselect
    var MultiValueSelect = function (options) {
        this.init('multivalueselect', options, MultiValueSelect.defaults);
    };
    $.fn.editableutils.inherit(MultiValueSelect, $.fn.editabletypes.select);
    $.extend(MultiValueSelect.prototype, {
        value2html: function (value, element) {
            var onSelectFunction = $(element).data('onValueSelect');
            if (onSelectFunction !== undefined) {
                window.eval.call(window,'(function (element) {'+onSelectFunction+'})')(element);
            } else {
                var valuesSelector = $(element).data('valuesSelector');
                if (valuesSelector !== undefined) {
                    $(valuesSelector).val(value);
                }
            }
        }
    });
    MultiValueSelect.defaults = $.extend({}, $.fn.editabletypes.select.defaults, {});
    $.fn.editabletypes.multivalueselect = MultiValueSelect;

    var ValueTree = function (options) {
        this.init('valuetree', options, ValueTree.defaults);
    };
    $.fn.editableutils.inherit(ValueTree, $.fn.editabletypes.select);
    $.extend(ValueTree.prototype, {
        renderList: function() {
            this.$input.empty();

            var fillItems = function($el, data) {
                var attr;
                var text;
                if($.isArray(data)) {
                    for(var i=0; i<data.length; i++) {
                        attr = {};
                        attr.value = data[i].value;
                        $el.append($('<option>', attr).html(data[i].text));
                    }
                }
                return $el;
            };
            fillItems(this.$input, this.sourceData);
            this.setClass();
            //enter submit
            this.$input.on('keydown.editable', function (e) {
                if (e.which === 13) {
                    $(this).closest('form').submit();
                }
            });
        }
    });
    ValueTree.defaults = $.extend({}, $.fn.editabletypes.select.defaults, {});
    $.fn.editabletypes.valuetree = ValueTree;

    // select
    $.fn.editabletypes.select.prototype.value2htmlFinal = function(value, element) {
      var text = '',
          items = $.fn.editableutils.itemsByValue(value, this.sourceData);

      if(items.length) {
          text = items[items.length-1].text;
      }

      $(element).html(text);
    };

  window.initInlineEditForContainer = function (container) {
    $('.multieditable', container).each(function(){
      var $container = $(this).closest('.multieditable-container');
      var me = $(this);
      if (me.hasClass('multieditable-initialized')) {
        return true;
      }
      me.wrap("<span class='multieditable-parent'></span>");
      me.editable($.extend($($container).data(), {title: ' '}));
      if(me.attr('title') === undefined) {
        me.attr('title', I18n.titleInlineEditable);
      }
      $('<span/>')
        .addClass('icon-edit')
        //.attr('title', I18n.titleInlineEditable)
        .insertAfter(me)
        .click(function () {
          $(this).prev().editable('toggle');
          return false;
        });
      $container.addClass('multieditable-initialized');
      me.addClass('multieditable-initialized');
    });
  };

    // initialization
    $(function () {
        $('.multieditable-container').each(function () {
            initInlineEditForContainer(this);
        });
    });
}(jQuery));
