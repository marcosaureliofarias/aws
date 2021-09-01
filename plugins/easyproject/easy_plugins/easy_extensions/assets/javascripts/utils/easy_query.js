/**
 *
 * @param {String} modul_uniq_id
 */
EASY.query.addFilter = function (modul_uniq_id) {
    var select = $('#' + modul_uniq_id + 'add_filter_select');
    var field = select.val();
    $('[id="' + modul_uniq_id + 'tr_' + field + '"]').show();
    $('[id="' + modul_uniq_id + 'cb_' + field + '"]').prop('checked', true);
    EASY.query.toggleFilter(field, modul_uniq_id);
    EASY.responsivizer.tabularFakeResponsive();
    select.selectedIndex = 0;
    $("option[value='" + field + "']", select).prop('disabled', true);
};

EASY.query.toggleFilter = function (field, modul_uniq_id) {
    var check_box = $('#' + modul_uniq_id + 'cb_' + field);

    if (check_box.is(':checked')) {
        $('#' + modul_uniq_id + "operators_" + field).show();
        EASY.utils.toggleOperator(field, modul_uniq_id);
    } else {
        $('#' + modul_uniq_id + "operators_" + field).hide();
        $('#' + modul_uniq_id + "div_values_" + field).hide();
    }
    $( document ).trigger( "erui_interface_change_vertical" );
};

EASY.query.initEasyFilters = function(fields, modul_uniq_id) {
    for(var i = 0; i < fields.length; i++) {
        var check_box = $('#' + modul_uniq_id + 'cb_' + fields[i]);
        if (check_box.is(':checked')) {
            $('#' + modul_uniq_id + "operators_" + fields[i]).show();
            EASY.utils.toggleOperator(fields[i], modul_uniq_id);
        }
    }
};

EASY.query.toggleFilterButtons = function(elButtonsID, elFilterToggleSelector) {
    var $elButtons = $('#' + elButtonsID);
    var $elFilterToggle = $(elFilterToggleSelector);
    var filtersCollapsed = true;
    $elFilterToggle.each(function(){
        if (!$(this).hasClass('collapsed')){
            filtersCollapsed = false;
        }
    });
    if (filtersCollapsed) {
        $elButtons.slideUp(0).addClass('collapsed');
    } else {
        $elButtons.slideDown(0).removeClass('collapsed');
    }
};


/**
 * Copy every selected item from list to another list
 * @param {HTMLElement} fromList
 * @param {HTMLElement} toList
 */
EASY.query.addOption = function addOption(fromList, toList) {
    var added = [];
    var $self, value;
    var $toList = $(toList);
    var $fromList = $(fromList);
    $fromList.find('option:selected').each(function(){
        $self = $(this);
        value = $self.val();
        if(added.indexOf(value) === -1) {
            $toList.append($self.clone());
            added.push(value);
        }
        $fromList.find('option[value="' + value + '"]').prop('disabled', true).prop('selected', false);
    });
};

/**
 * @param {HTMLElement} fromList
 * @param {HTMLElement} toList
 */
EASY.query.removeOption = function (fromList, toList) {
    var $fromList = $(fromList);
    var $self;
    $(toList).find('option:selected').each(function(){
        $self = $(this);
        $fromList.find('option[value="' + $self.val() + '"]').prop('disabled', false);
        $self.remove();
    });
};


EASY.query.toggleTableRowGroupVisibility = function(el, filter_uniq_id, user_id, update_user_pref) {
    if (update_user_pref) {
        EASY.utils.updateUserPref(filter_uniq_id, user_id);
    }
    var tr = el.up('tr');
    var n = tr.next();
    tr.toggleClass('open');
    var group_opening = tr.hasClass('open');
    var css_was_visible = "was-visible";
    var css_was_hidden = "was-hidden";
    while (n !== undefined && !n.hasClass('group')) {
        if (group_opening) {
            if (n.hasClass(css_was_visible)) {
                Element.show(n);
                n.removeClass(css_was_visible);
            }
            if (n.hasClass(css_was_hidden)) {
                Element.hide(n);
                n.removeClass(css_was_hidden);
            }
        } else {
            if (n.visible())
                n.addClass(css_was_visible);
            else
                n.addClass(css_was_hidden);
            n.hide();
        }
        n = n.next();
    }
    $( document ).trigger( "erui_interface_change_vertical" );
};

(function(){
    /**
     *
     * @return {string}
     */
    function getEasyQueryCustomFormattingForURL() {
        var filter_values = [];
        $('#schemes-table').find('[class^="row-scheme-"] .easyquery-filters').each(function(){
            var scheme = {};
            scheme[ $(this).closest('[class^="row-scheme-"]').data('scheme')] = $(this).filters('getValues');
            filter_values.push( $.param(scheme) );
        });
        return filter_values.join('&');
    }

    /**
     *
     * @param {jQuery} filter_value_element
     * @return {string}
     */
    function getEasyQueryFilterValue(filter_value_element) {
        var filter_value = '',
            val_el_val = [];

        if (filter_value_element.length > 0) {
            if (filter_value_element[0].tagName === 'SPAN') {
                filter_value_element.find('input[type="hidden"]').each(function(i, el) {
                    val_el_val.push($(el).val());
                });
            } else if (filter_value_element[0].tagName === 'SELECT') {
                var value = filter_value_element.val();
                if ($.isArray(value)) {
                    $.merge(val_el_val, value);
                } else {
                    val_el_val.push(value);
                }
            } else if (filter_value_element.is("input:radio")) {
                val_el_val.push(filter_value_element.filter(":checked").val());
            } else {
                filter_value_element.each(function() {
                    val_el_val.push($(this).val());
                });
            }
            filter_value = val_el_val && val_el_val.join('|');
        }
        return filter_value;
    }

    /**
     *
     * @param {jQuery} $target
     * @param {String} modul_uniq_id
     * @return {Array}
     */
    function getEasyQueryFilterValuesOld($target, modul_uniq_id){
        var filter_values = [];
        $target.find('input:checkbox[name*="fields"]').filter(":checked").each(function(idx, el) {
            var filter_value = '';
            var el_val = el.value.replace('.', '_');
            var operator = $('#' + modul_uniq_id + 'operators_' + el_val).val();
            var val_el_single_value = $("#" + modul_uniq_id + "tr_" + el_val + " span.span_values_" + el_val).find("input[name*=values], select");
            var val_el_two_values_1 = $('#' + modul_uniq_id + 'values_' + el_val + '_1');
            var val_el_two_values_2 = $('#' + modul_uniq_id + 'values_' + el_val + '_2');
            if (operator === undefined) { operator = '='; }

            if (['=', '!', 'o', 'c', '*', '!*', '~', '!~', '^~', '$~', '=p', '=!p', '!p'].indexOf(operator) >= 0 && val_el_single_value.length > 0) {
                filter_value = getEasyQueryFilterValue(val_el_single_value);
            } else if (['=', '>=', '<=', '><', '!*', '*'].indexOf(operator) >= 0 && val_el_two_values_1.length > 0 && val_el_two_values_2.length > 0) {
                filter_value = getEasyQueryFilterValue(val_el_two_values_1);
                filter_value += '|' + getEasyQueryFilterValue(val_el_two_values_2);
            } else if (operator === '') {
                var p1 = $('#' + modul_uniq_id + '' + el_val + '_date_period_1');
                if (p1 && p1.is(':checked')) {
                    filter_value = $('#' + modul_uniq_id + 'values_' + el_val + '_period').val();
                    if (filter_value === 'from_m_to_n_days') {
                        filter_value += '|' + $('#' + modul_uniq_id + 'values_' + el_val + '_period_days2').val() + '|' + $('#' + modul_uniq_id + 'values_' + el_val + '_period_days').val();
                    }
                    else if (filter_value.indexOf('n_days') !== -1) {
                        filter_value += '|' + $('#' + modul_uniq_id + 'values_' + el_val + '_period_days').val();
                    }
                }
                var p2 = $('#' + modul_uniq_id + '' + el_val + '_date_period_2');
                if (p2 && p2.is(':checked')) {
                    filter_value = $('#' + modul_uniq_id + '' + el_val + '_from').val();
                    filter_value += '|' + $('#' + modul_uniq_id + '' + el_val + '_to').val();
                }
            }

            if (!filter_value) { filter_value = '0'; }
            filter_values.push(el.value + '=' + encodeURIComponent(operator + filter_value));
        });
        return filter_values;
    }

    /**
     *
     * @param {jQuery} $target
     */
    function getEasyQueryFilterValues($target) {
        return $.param({f: $target.filters('getValues')});
    }

    /**
     *
     * @param {String} modul_uniq_id
     */
    function getFiltersForURL(modul_uniq_id) {
        var filter_values;
        var $target = $('#' + modul_uniq_id + 'easyquery-filters');
        if( $target.length > 0 ) {
            filter_values = [];
            filter_values.push(getEasyQueryFilterValues($target));
        } else {
            $target = $('#' + modul_uniq_id + 'filters');
            filter_values = getEasyQueryFilterValuesOld($target, modul_uniq_id);
        }
        EASY.modalSelector.selectAllOptions(modul_uniq_id + 'selected_columns');
        if ($('#selected_project_columns').length > 0)
          EASY.modalSelector.selectAllOptions(modul_uniq_id + 'selected_project_columns');
        filter_values.push($('#' + modul_uniq_id + 'selected_columns').serialize());
        var show_sum_val = $('#' + modul_uniq_id + 'show_sum_row_1').serialize();
        if (show_sum_val.length === 0) {
            show_sum_val = $('#' + modul_uniq_id + 'show_sum_row_0').serialize();
        }
        filter_values.push($('#' + modul_uniq_id + 'group_by :input').serialize());
        var options = $(':input', $((modul_uniq_id === '' ? '' : '#' + modul_uniq_id) + ' .easy_query_additional_options')).serialize();
        filter_values.push(show_sum_val);
        filter_values.push(options);
        filter_values.push($('select.serialize, input.serialize', $target.closest('form')).serialize());
        if ($('#' + modul_uniq_id + 'sort_criteria').length > 0) {
            filter_values.push($('select', '#' + modul_uniq_id + 'sort_criteria').serialize());
        }
        var $other_outputs = $(':input', $('#' + modul_uniq_id + 'outputs_settings > div:not(.list_settings):not(.kanban_settings), #'+modul_uniq_id+'outputs_select') );
        if( $other_outputs.length > 0 ) {
            filter_values.push($other_outputs.serialize());
        }
        var $kanban_output = $(':input', $('#' + modul_uniq_id + 'outputs_settings > div.kanban_settings') );
        filter_values.push(serializeKanbanSettings($kanban_output));

        return filter_values.join('&');
    }

    function serializeKanbanSettings($kanban_output) {
      if($kanban_output.length > 0) {
        var res = '';
        var keys = [];
        for (var key in $kanban_output) {
          if ($kanban_output.hasOwnProperty(key)) {
            var input_name = $kanban_output[key].name;
            if (input_name === '' || input_name === undefined) continue;
            if (keys.indexOf(input_name) !== -1) {
              res = res.concat(this.escape("|" + $kanban_output[key].value));
            } else {
              res = res.concat('&' + this.escape(input_name) + "=" + this.escape($kanban_output[key].value));
              keys.push(input_name);
            }
          }
        }
        return res;
      }
    }

    /**
     *
     * @param {String} url
     * @param {String} modul_uniq_id
     * @param {jQuery} additional_elements_to_serialize
     */
    function applyFilters(url, modul_uniq_id, additional_elements_to_serialize) {
        if (url.indexOf('?') >= 0) {
            url += '&';
        } else {
            url += '?';
        }

        var target_url = url + getFiltersForURL(modul_uniq_id) + '&' + getEasyQueryCustomFormattingForURL();
        if (additional_elements_to_serialize && (additional_elements_to_serialize instanceof jQuery)) {
            target_url += '&' + additional_elements_to_serialize.serialize();
        }

        window.location = target_url;
    }

    /**
     *
     * @param {HTMLAnchorElement} link
     */
    function applyPreviewEasyQueryInModules(link) {
        var url = link.dataset.url;
        var moduleUniqId = link.dataset.moduleUniqId;
        var targetElement = link.dataset.target;
        var queryClass = link.dataset.queryClass;
        var params = getFiltersForURL(moduleUniqId);

        if (url.indexOf('?') >= 0) {
            url += '&';
        } else {
            url += '?';
        }
        var targetUrl = url + params;
        $.post(targetUrl, $(link).closest(".preview-options").find("input").serialize(), function(data) {
            var $target = $('#' + targetElement);
            $target.html(data);
            if (queryClass) {
                $('#'+targetElement+' table.entities').easygrouploader({
                    loadUrl: targetUrl + $(".preview-options input", $('#'+moduleUniqId)).serialize(),
                    easy_query: queryClass,
                    load_opened: false,
                    next_button_cols: 3
                });
            }
            $target.trigger('easy_pagemodule_querypreviev_new_dom');
        });
    }

    EASY.query.getFiltersForURL = getFiltersForURL;
    EASY.query.applyFilters = applyFilters;
    EASY.query.applyPreviewEasyQueryInModules = applyPreviewEasyQueryInModules;
    EASY.query.getEasyQueryCustomFormattingForURL = getEasyQueryCustomFormattingForURL;

})();
