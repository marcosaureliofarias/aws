(function () {
    window.easyUtils = window.easyUtils || {};

    var $input;
    window.easyUtils.autocomplete = function (targetSelector, callback) {
        $input = $(targetSelector);
        var timeout = null;
        var submit = function () {
            callback();
        };
        $input.on('input', function () {
            if (timeout !== null) {
                window.clearTimeout(timeout);
            }
            timeout = window.setTimeout(submit, 300);
        });
    };
})();


window.easyAutocomplete = function(name, sourceOrLoadPath, onchange, rootElement, options) {
    if (typeof options === "undefined") {
        options = {};
    }
    options.widget = options.widget || 'autocomplete';
    options.delay = options.delay || 500;
    var hiddenInput = $('#' + name);
    var source;
    if (typeof(sourceOrLoadPath) === 'string') {
        source = function (request, response) {
            $.getJSON(sourceOrLoadPath, {
                term: request.term
            }, function (json) {
                response(rootElement ? json[rootElement] : json);
            });
        };
    } else {
        source = sourceOrLoadPath;
    }

  var ac = $('#' + name + '_autocomplete')[options.widget]({
    source: source,
    minLength: 0,
    delay: options.delay,
    select: function (event, ui) {
      $(this).val(ui.item.value);
      hiddenInput.val(ui.item.id);
      if (typeof(onchange) === 'function') {
        onchange(event, ui);
      }
      if (options.widget === 'suggester'){
        if (event.which === 13){
          EASY.search.suggesterChange(ui.item.id);
        }
        EASY.search.suggesterItemSelect(ui.item);
      }
      hiddenInput.change();
      return false;
    },
    change: function (event, ui) {
      if (!ui.item) {
        $(this).val('');
        hiddenInput.val('');
        if (typeof(onchange) === 'function') {
          onchange(event, ui);
        }
        hiddenInput.change();
      }
    },
    search(){
        const isUserAutocomplete = this.id === "user_select_autocomplete";
        if (isUserAutocomplete) {
            const selectedUsers = document.querySelector("#selected-users-entity-array");
            if (selectedUsers) {
                const used_user_ids = [...selectedUsers.children].map(el => {
                    const input = el.querySelector("input");
                    if (input) return `used_user_ids[]=${input.value}`;
                }).join('&');
                const oldPath = sourceOrLoadPath.split("&used_user_ids")[0];
                sourceOrLoadPath = `${oldPath}&${used_user_ids}`;
            }
        }
    },
    position: (options['position'] || {
      collision: "flip"
    }),
    appendTo: options['append_to'],
    autoFocus: options['auto_focus'] !== false
  }).css('margin-right', 0).click(function () {
    $(this).select();
  });

  if (typeof(onchange) === 'function') {
    $.data(ac[0], 'ac_onchange_callback', onchange);
  }

  if (options['activate_on_input_click']) {
    ac.on('click', function () {
      ac.focus().val('');
      ac.trigger('keydown');
    });
  }

  if (!options['no_button']) {
    $("<button type='button'></button>")
        .attr("tabIndex", -1)
        .attr("title", $('#' + name + '_autocomplete').attr("title"))
        .insertAfter(ac)
        .button({
          icons: {
            primary: "ui-icon-triangle-1-s"
          },
          text: false
        })
        .removeClass("ui-corner-all")
        .addClass("ui-corner-right ui-button-icon")
        .css('font-size', '10px')
        .css('margin-left', -1)
        .click(function () {
          if (ac[options.widget]("widget").is(":visible")) {
            ac[options.widget]("close");
            ac.blur();
            return;
          }
          $(this).blur();
          ac.focus().val('');
          ac[options.widget]("search", "");
        });
  }
  // set autocomplete to search to prevent google chrome filling data to inputs with his own autocomplete
  ac[0].setAttribute("type", "search");
  return ac;
}

window.initEasyAutocomplete = function() {
    if (isIE()) {
        $(".easy-autocomplete-tag").addClass("IE-ui-autocomplete-input").find('input').addClass("ui-autocomplete-input");
        $(document).on("click, blur, focus, mouseover", ".easy-autocomplete-tag[data-easy-autocomplete]", function (event) {
            var t = $(this);
            t.closest('.IE-ui-autocomplete-input').removeClass('IE-ui-autocomplete-input').find('input').removeClass("ui-autocomplete-input");
            initEasyAutocompleteFor(t);
        });
    } else {
        $(".easy-autocomplete-tag[data-easy-autocomplete]").each(function (index, item) {
            initEasyAutocompleteFor($(item));
        });
    }
}

window.initEasyAutocompleteFor = function(item) {
    if ($(item).data().autocompleteLoaded) {
        // skip
    } else {
        eval($.base64.decode($(item).data().easyAutocomplete, true));
        $(item).data().autocompleteLoaded = true;
    }
}

window.initEasyInlineEdit = function() {
    $('.multieditable-container:not(.multieditable-initialized)').each(function () {
        initInlineEditForContainer(this);
    });
}

EASY.schedule.late(initEasyAutocomplete);

window.removeAutocompleteFromMultiselectTag = function(id, default_value, input_name) {
    $('input[name="' + input_name + '"]').remove();
    var element = $('#' + id + '_autocomplete');
    element.autocomplete({
        select: function () {
        }, change: function () {
        }
    });
    element.attr('id', id);
    element.attr('name', input_name);
    element.change(function () {
        element.attr('value', $("#" + id + ".ui-autocomplete-input").val());
    });
    element.parent().next().hide();
    element.val(default_value);
}

window.easyComboboxTag = function(id, name, possibleValues, selectedValues, default_value) {
    easyMultiselectTag(id, name, possibleValues, selectedValues);
    removeAutocompleteFromMultiselectTag(id, default_value, name);
}

window.easyMultiselectTag = function(id, name, possibleValues, selectedValues, options) {
    if (typeof options === "undefined") {
        options = {};
    }
    var entities,
        entityArray = $('#' + id + '_entity_array'),
        ac = $('#' + id + '_autocomplete');

    entities = $.map(possibleValues, function (val) {
        if (selectedValues && (selectedValues.indexOf(val.id) > -1) || (selectedValues.indexOf(val.id.toString()) > -1)) {
            return {
                id: val.id,
                name: val.value
            };
        }
    });

    entityArray.entityArray({
        inputNames: name,
        entities: entities,
        afterRemove: function (entity) {
            ac.trigger('change');
        }
    });

    ac.autocomplete($.extend({}, {
        source: function (request, response) {
            var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
            response($.map(possibleValues, function (val) {
                if (!request.term || matcher.test(val.value)) {
                    return val;
                }
            }));
        },
        minLength: 0,
        select: function (event, ui) {
            entityArray.entityArray('add', {
                id: ui.item.id,
                name: ui.item.value
            });
            ac.trigger('change');
            return false;
        },
        change: function (event, ui) {
            if (!ui.item) {
                $(this).val('');
            }
        },
        position: {
            collision: "flip"
        },
        autoFocus: false
    }, (options || {}))).data("ui-autocomplete")._renderItem = function (ul, item) {
        return $("<li>")
            .data("item.autocomplete", item)
            .append(item.label)
            .appendTo(ul);
    };
    $("<button type='button'>&nbsp;</button>")
        .attr("tabIndex", -1)
        .insertAfter(ac)
        .button({
            icons: {
                primary: "ui-icon-triangle-1-s"
            },
            text: false
        })
        .removeClass("ui-corner-all")
        .addClass("ui-corner-right ui-button-icon")
        .css('font-size', '10px')
        .css('margin-left', -1)
        .click(function () {
            if (ac.autocomplete("widget").is(":visible")) {
                ac.autocomplete("close");
                ac.blur();
                return;
            }
            $(this).blur();
            ac.focus().val('');
            ac.trigger('keydown');
            ac.autocomplete("search", "");
        });
}


window.setEasyAutoCompleteValue = function(select_element_id, value_id, value_name) {
    var ac = $('#' + select_element_id + '_autocomplete');
    var sel = $('#' + select_element_id);
    if (ac) {
        ac.val(value_name);
        sel.attr('value', value_id);
        var onchange = $.data(ac[0], 'ac_onchange_callback');
        if (typeof(onchange) === 'function')
            onchange();
    } else {
        sel.attr('value', value_id);
    }
    sel.change();
}
