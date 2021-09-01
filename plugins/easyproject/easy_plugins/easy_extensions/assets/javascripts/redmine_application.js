/* Redmine - project management software
   Copyright (C) 2006-2017  Jean-Philippe Lang */

/* Fix for CVE-2015-9251, to be removed with JQuery >= 3.0 */
$.ajaxPrefilter(function (s) {
  if (s.crossDomain) {
    s.contents.script = false;
  }
});

window.checkAll = function(id, checked) {
  $('#'+id).find('input[type=checkbox]:enabled').prop('checked', checked);
}

window.toggleCheckboxesBySelector = function(selector) {
  event.stopPropagation();
  var all_checked = true;
  $(selector).each(function(index) {
    if (!$(this).is(':checked')) { all_checked = false; }
  });
  $(selector).prop('checked', !all_checked).trigger('change');
}

window.showAndScrollTo = function(id, focus) {
  var $element = $('#'+id);
  $element.show();
  if (focus !== null) {
    $('#'+focus).focus();
  }
  $('html, body').animate({scrollTop: $element.offset().top}, 100);
  ERUI.document.trigger( "erui_interface_change_vertical" );
}

window.toggleRowGroup = function(el) {
  var tr = $(el).parents('tr').first();
  var n = tr.next();
  tr.toggleClass('open');
  while (n.length && !n.hasClass('group')) {
    n.toggle();
    n = n.next('tr');
  }
  $( document ).trigger( "erui_interface_change_vertical" );
}

window.collapseAllRowGroups = function(el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function(index) {
    if ($(this).hasClass('group')) {
      $(this).removeClass('open');
    } else {
      $(this).hide();
    }
  });
  $( document ).trigger( "erui_interface_change_vertical" );
}

window.expandAllRowGroups = function(el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function(index) {
    if ($(this).hasClass('group')) {
      $(this).addClass('open');
    } else {
      $(this).show();
    }
  });
  $( document ).trigger( "erui_interface_change_vertical" );
}

window.toggleAllRowGroups = function(el) {
  var tr = $(el).parents('tr').first();
  if (tr.hasClass('open')) {
    collapseAllRowGroups(el);
  } else {
    expandAllRowGroups(el);
  }
  $( document ).trigger( "erui_interface_change_vertical" );
}

window.toggleFieldset = function(el) {
  var fieldset = $(el).parents('fieldset').first();
  fieldset.toggleClass('collapsed');
  fieldset.children('div').toggle();
  $( document ).trigger( "erui_interface_change_vertical" );
}

window.hideFieldset = function(el) {
  var fieldset = $(el).parents('fieldset').first();
  fieldset.toggleClass('collapsed');
  fieldset.children('div').hide();
  $( document ).trigger( "erui_interface_change_vertical" );
}

// columns selection
window.moveOptions = function(theSelFrom, theSelTo) {
  $(theSelFrom).find('option:selected').detach().prop("selected", false).appendTo($(theSelTo));
}

window.moveOptionUp = function(theSel) {
  $(theSel).find('option:selected').each(function(){
    $(this).prev(':not(:selected)').detach().insertAfter($(this));
  });
}

window.moveOptionTop = function(theSel) {
  $(theSel).find('option:selected').detach().prependTo($(theSel));
}

window.moveOptionDown = function(theSel) {
  $($(theSel).find('option:selected').get().reverse()).each(function(){
    $(this).next(':not(:selected)').detach().insertBefore($(this));
  });
}

window.moveOptionBottom = function(theSel) {
  $(theSel).find('option:selected').detach().appendTo($(theSel));
}

window.initFilters = function() {
  $('#add_filter_select').change(function() {
    addFilter($(this).val(), '', []);
  });
  $('#filters-table td.field input[type=checkbox]').each(function() {
    toggleFilter($(this).val());
  });
  $('#filters-table').on('click', 'td.field input[type=checkbox]', function() {
    toggleFilter($(this).val());
  });
  $('#filters-table').on('click', '.toggle-multiselect', function() {
    toggleMultiSelect($(this).siblings('select'));
    $(this).toggleClass('icon-toggle-plus icon-toggle-minus')
  });
  $('#filters-table').on('keypress', 'input[type=text]', function(e) {
    if (e.keyCode == 13) $(this).closest('form').submit();
  });
}

window.addFilter = function(field, operator, values) {
  var fieldId = field.replace('.', '_');
  var tr = $('#tr_'+fieldId);
  
  var filterOptions = availableFilters[field];
  if (!filterOptions) return;

  if (filterOptions['remote'] && filterOptions['values'] == null) {
    $.getJSON(filtersUrl, {'name': field}).done(function(data) {
      filterOptions['values'] = data;
      addFilter(field, operator, values) ;
    });
    return;
  }

  if (tr.length > 0) {
    tr.show();
  } else {
    buildFilterRow(field, operator, values);
  }
  $('#cb_'+fieldId).prop('checked', true);
  toggleFilter(field);
  $('#add_filter_select').val('').find('option').each(function() {
    if ($(this).attr('value') == field) {
      $(this).attr('disabled', true);
    }
  });
}

window.buildFilterRow = function(field, operator, values) {
  var fieldId = field.replace('.', '_');
  var filterTable = $("#filters-table");
  var filterOptions = availableFilters[field];
  if (!filterOptions) return;
  var operators = operatorByType[filterOptions['type']];
  var filterValues = filterOptions['values'];
  var i, select;

  var tr = $('<tr class="filter">').attr('id', 'tr_'+fieldId).html(
    '<td class="field"><input checked="checked" id="cb_'+fieldId+'" name="f[]" value="'+field+'" type="checkbox"><label for="cb_'+fieldId+'"> '+filterOptions['name']+'</label></td>' +
    '<td class="operator"><select id="operators_'+fieldId+'" name="op['+field+']"></td>' +
    '<td class="values"></td>'
  );
  filterTable.append(tr);

  select = tr.find('td.operator select');
  for (i = 0; i < operators.length; i++) {
    var option = $('<option>').val(operators[i]).text(operatorLabels[operators[i]]);
    if (operators[i] == operator) { option.prop('selected', true); }
    select.append(option);
  }
  select.change(function(){ toggleOperator(field); });

  switch (filterOptions['type']) {
  case "list":
  case "list_optional":
  case "list_status":
  case "list_subprojects":
    tr.find('td.values').append(
      '<span style="display:none;"><select class="value" id="values_'+fieldId+'_1" name="v['+field+'][]"></select>' +
      ' <span class="toggle-multiselect icon-only icon-toggle-plus">&nbsp;</span></span>'
    );
    select = tr.find('td.values select');
    if (values.length > 1) { select.attr('multiple', true); }
    for (i = 0; i < filterValues.length; i++) {
      var filterValue = filterValues[i];
      var option = $('<option>');
      if ($.isArray(filterValue)) {
        option.val(filterValue[1]).text(filterValue[0]);
        if ($.inArray(filterValue[1], values) > -1) {option.prop('selected', true);}
        if (filterValue.length === 3) {
          var optgroup = select.find('optgroup').filter(function(){return $(this).attr('label') === filterValue[2]});
          if (!optgroup.length) {optgroup = $('<optgroup>').attr('label', filterValue[2]);}
          option = optgroup.append(option);
        }
      } else {
        option.val(filterValue).text(filterValue);
        if ($.inArray(filterValue, values) > -1) {option.prop('selected', true);}
      }
      select.append(option);
    }
    break;
  case "date":
  case "date_past":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="date" name="v['+field+'][]" id="values_'+fieldId+'_1" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="date" name="v['+field+'][]" id="values_'+fieldId+'_2" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="3" class="value" /> '+labelDayPlural+'</span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]).datepickerFallback(EASY.datepickerOptions);
    $('#values_'+fieldId+'_2').val(values[1]).datepickerFallback(EASY.datepickerOptions);
    $('#values_'+fieldId).val(values[0]);
    break;
  case "string":
  case "text":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="30" class="value" /></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    break;
  case "relation":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="6" class="value" /></span>' +
      '<span style="display:none;"><select class="value" name="v['+field+'][]" id="values_'+fieldId+'_1"></select></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    select = tr.find('td.values select');
    for (i = 0; i < filterValues.length; i++) {
      var filterValue = filterValues[i];
      var option = $('<option>');
      option.val(filterValue[1]).text(filterValue[0]);
      if (values[0] === filterValue[1]) { option.prop('selected', true); }
      select.append(option);
    }
    break;
  case "integer":
  case "float":
  case "tree":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_1" size="14" class="value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_2" size="14" class="value" /></span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]);
    $('#values_'+fieldId+'_2').val(values[1]);
    break;
  }
}

window.toggleFilter = function(field) {
  var fieldId = field.replace('.', '_');
  if ($('#cb_' + fieldId).is(':checked')) {
    $("#operators_" + fieldId).show().removeAttr('disabled');
    toggleOperator(field);
  } else {
    $("#operators_" + fieldId).hide().attr('disabled', true);
    enableValues(field, []);
  }
}

window.enableValues = function(field, indexes) {
  var fieldId = field.replace('.', '_');
  $('#tr_'+fieldId+' td.values .value').each(function(index) {
    if ($.inArray(index, indexes) >= 0) {
      $(this).removeAttr('disabled');
      $(this).parents('span').first().show();
    } else {
      $(this).val('');
      $(this).attr('disabled', true);
      $(this).parents('span').first().hide();
    }

    if ($(this).hasClass('group')) {
      $(this).addClass('open');
    } else {
      $(this).show();
    }
  });
}

window.toggleOperator = function(field) {
  var fieldId = field.replace('.', '_');
  var operator = $("#operators_" + fieldId);
  switch (operator.val()) {
    case "!*":
    case "*":
    case "nd":
    case "t":
    case "ld":
    case "nw":
    case "w":
    case "lw":
    case "l2w":
    case "nm":
    case "m":
    case "lm":
    case "y":
    case "o":
    case "c":
    case "*o":
    case "!o":
      enableValues(field, []);
      break;
    case "><":
      enableValues(field, [0,1]);
      break;
    case "<t+":
    case ">t+":
    case "><t+":
    case "t+":
    case ">t-":
    case "<t-":
    case "><t-":
    case "t-":
      enableValues(field, [2]);
      break;
    case "=p":
    case "=!p":
    case "!p":
      enableValues(field, [1]);
      break;
    default:
      enableValues(field, [0]);
      break;
  }
}

window.toggleMultiSelect = function(el) {
  if (el.attr('multiple')) {
    el.removeAttr('multiple');
    el.attr('size', 1);
  } else {
    el.attr('multiple', true);
    if (el.children().length > 10)
      el.attr('size', 10);
    else
      el.attr('size', 4);
  }
}

window.showTab = function(name, url) {
  var $tab = $('#tab-content-' + name);
  var $tab2 = $('#tab-' + name);
  $tab.parent().find('.tab-content').hide();
  $tab.show();
  $tab2.closest('.tabs').find('a').removeClass('selected');
  $tab2.addClass('selected');
  //replaces current URL with the "href" attribute of the current link
  //(only triggered if supported by browser)
  if ("replaceState" in window.history) {
    window.history.replaceState(null, document.title, url);
  }
  ERUI.document.trigger( "tab-change" );
  return false;
}

window.moveTabRight = function(el) {
    var lis = $(el).parents('div.tabs').first().find('ul').children();
    var bw = $(el).parents('div.tabs-buttons').outerWidth(true);
    var tabsWidth = 0;
    var i = 0;
    lis.each(function() {
        if ($(this).is(':visible')) {
            tabsWidth += $(this).outerWidth(true);
        }
    });
    if (tabsWidth < $(el).parents('div.tabs').first().width() - bw) { return; }
    $(el).siblings('.tab-left').removeClass('disabled');
    while (i<lis.length && !lis.eq(i).is(':visible')) { i++; }
    var w = lis.eq(i).width();
    lis.eq(i).hide();
    if (tabsWidth - w < $(el).parents('div.tabs').first().width() - bw) {
        $(el).addClass('disabled');
    }
}

window.moveTabLeft = function(el) {
    var lis = $(el).parents('div.tabs').first().find('ul').children();
    var i = 0;
    while (i < lis.length && !lis.eq(i).is(':visible')) { i++; }
    if (i > 0) {
        lis.eq(i-1).show();
        $(el).siblings('.tab-right').removeClass('disabled');
    }
    if (i <= 1) {
        $(el).addClass('disabled');
    }
}

window.displayTabsButtons = function() {
    var lis;
    var tabsWidth;
    var el;
    var numHidden;
    $('div.tabs').each(function() {
        el = $(this);
        lis = el.find('ul').children();
        tabsWidth = 0;
        numHidden = 0;
        lis.each(function(){
            if ($(this).is(':visible')) {
                tabsWidth += $(this).outerWidth(true);
            } else {
                numHidden++;
            }
        });
        var bw = $(el).find('div.tabs-buttons').outerWidth(true);
        if ((tabsWidth < el.width() - bw) && (lis.length === 0 || lis.first().is(':visible'))) {
            el.find('div.tabs-buttons').hide();
        } else {
            el.find('div.tabs-buttons').show().children('button.tab-left').toggleClass('disabled', numHidden == 0);
        }
    });
}

window.setPredecessorFieldsVisibility = function() {
  var relationType = $('#relation_relation_type');
  if (relationType.val() == "precedes" || relationType.val() == "follows") {
    $('#predecessor_fields').show();
  } else {
    $('#predecessor_fields').hide();
  }
}

window.showModal = function(id, width, title, minHeight, maxHeight) {
  var el = $('#'+id).first();
  if (el.length === 0 || el.is(':visible')) {return;}
  if (!title) title = el.find('h3.title').text();
  var mh = ERUI.topMenu.outerHeight();
  var wh = window.innerHeight;
  var defaultMaxHeight = wh - mh - 20;
  if(width == null){
    width = '90%';
  }
  if(typeof minHeight === 'string'){
    minHeight = defaultMaxHeight * parseInt(minHeight) / 100;
  }
  if(typeof maxHeight === 'string'){
    maxHeight = defaultMaxHeight * parseInt(maxHeight) / 100;
  }
  el.dialog({
    width: width,
    modal: true,
    resizable: false,
    dialogClass: 'modal',
    maxHeight: maxHeight || defaultMaxHeight,
    maxWidth: '100%',
    minHeight: minHeight,
    title: title,
    position: {my:"top", at: 'top'},
    open: function() {
      ERUI.body.addClass('modal-opened');
      initEasyAutocomplete();
      EasyToggler.ensureToggle();
      displayTabsButtons();
      EASY.utils.modalOpened = true;
    },
    close: function() {
      ERUI.body.removeClass('modal-opened');
      $(this).dialog("destroy");
      EASY.utils.modalOpened = false;
    }
  });
  $('#ajax-modal').trigger( "erui_interface_change_modal" );
}

window.resizeModal = function(id, width, minHeight, maxHeight) {
    var el = $('#'+id).first();
    var mh = ERUI.topMenu.outerHeight();
    var wh = window.innerHeight;
    var defaultMaxHeight = wh - mh - 20;
    if(width == null){
        width = '90%';
    }
    if(typeof minHeight === 'string'){
        minHeight = defaultMaxHeight * parseInt(minHeight) / 100;
    }
    if(typeof maxHeight === 'string'){
        maxHeight = defaultMaxHeight * parseInt(maxHeight) / 100;
    }
    el.dialog({
        width: width,
        maxHeight: maxHeight || defaultMaxHeight,
        minHeight: minHeight
    });
    $('#ajax-modal').trigger( "erui_interface_change_modal" );
}

window.recalculateModalHeight = function($el, $btns) {
  var mh = ERUI.topMenu.outerHeight();
  var wh = window.innerHeight;
  var btnsHeight = $btns ? $btns.outerHeight() : 0;
  var posBottom = 158;
  var maxHeight = wh - mh - btnsHeight - posBottom;
  //hack instead of not functional $el.dialog({maxHeight: 'value'})
  $el.css('max-height', maxHeight);
}

window.hideModal = function(el) {
  var modal;
  if (el) {
    modal = $(el).parents('.ui-dialog-content');
  } else {
    modal = $('#ajax-modal');
  }
  modal.dialog("close");
}

// deprecated, remove me
window.submitPreview = function(url, form, target) {
    $.ajax({
        url: url,
        type: 'post',
        data: $('#'+form).serialize(),
        success: function(data){
            $('#'+target).html(data);
        }
    });
}

window.collapseScmEntry = function(id) {
  $('.'+id).each(function() {
    if ($(this).hasClass('open')) {
      collapseScmEntry($(this).attr('id'));
    }
    $(this).hide();
  });
  $('#'+id).removeClass('open');
}

window.expandScmEntry = function(id) {
  $('.'+id).each(function() {
    $(this).show();
    if ($(this).hasClass('loaded') && !$(this).hasClass('collapsed')) {
      expandScmEntry($(this).attr('id'));
    }
  });
  $('#'+id).addClass('open');
}

window.scmEntryClick = function(id, url) {
    var el = $('#'+id);
    if (el.hasClass('open')) {
        collapseScmEntry(id);
        el.find('.expander').switchClass('icon-expended', 'icon-collapsed');
        el.addClass('collapsed');
        return false;
    } else if (el.hasClass('loaded')) {
        expandScmEntry(id);
        el.find('.expander').switchClass('icon-collapsed', 'icon-expended');
        el.removeClass('collapsed');
        return false;
    }
    if (el.hasClass('loading')) {
        return false;
    }
    el.addClass('loading');
    $.ajax({
      url: url,
      success: function(data) {
        el.after(data);
        el.addClass('open').addClass('loaded').removeClass('loading');
        el.find('.expander').switchClass('icon-collapsed', 'icon-expended');
      }
    });
    return true;
}

window.randomKey = function(size) {
  var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  var key = '';
  for (var i = 0; i < size; i++) {
    key += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return key;
}

window.updateIssueFrom = function(url, el) {
  $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
    $(this).data('valuebeforeupdate', $(this).val());
  });
  if (el) {
    $("#form_update_triggered_by").val($(el).attr('id'));
  }
  return $.ajax({
    url: url,
    type: 'post',
    data: $('#issue-form').serialize()
  });
}

window.replaceIssueFormWith = function(html){
  var replacement = $(html);
  $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
    var object_id = $(this).attr('id');
    if (object_id && $(this).data('valuebeforeupdate')!=$(this).val()) {
      replacement.find('#'+object_id).val($(this).val());
    }
  });
  $('#all_attributes').empty();
  $('#all_attributes').prepend(replacement);
}

window.updateBulkEditFrom = function(url) {
  if (typeof CKEDITOR !== 'undefined') {
    for (var i in CKEDITOR.instances) {
      fillFormTextAreaFromCKEditor(CKEDITOR.instances[i].name);
    }
  }
  $.ajax({
    url: url,
    type: 'post',
    data: $('#bulk_edit_form').serialize()
  });
}

window.observeAutocompleteField = function(fieldId, url, options) {
  $(document).ready(function() {
    $('#'+fieldId).autocomplete($.extend({
      source: url,
      minLength: 2,
      position: {collision: "flipfit"},
      search: function(){$('#'+fieldId).addClass('ajax-loading');},
      response: function(){$('#'+fieldId).removeClass('ajax-loading');}
    }, options));
    $('#'+fieldId).addClass('autocomplete');
  });
}

window.observeSearchfield = function(fieldId, targetId, url) {
  $('#'+fieldId).each(function() {
    var $this = $(this);
    $this.addClass('autocomplete');
    $this.attr('data-value-was', $this.val());
    var check = function() {
      var val = $this.val();
      if ($this.attr('data-value-was') != val){
        $this.attr('data-value-was', val);
        $.ajax({
          url: url,
          type: 'get',
          data: {q: $this.val()},
          success: function(data){ if(targetId) $('#'+targetId).html(data); },
          beforeSend: function(){ $this.addClass('ajax-loading'); },
          complete: function(){ $this.removeClass('ajax-loading'); }
        });
      }
    };
    var reset = function() {
      if (timer) {
        clearInterval(timer);
        timer = setInterval(check, 300);
      }
    };
    var timer = setInterval(check, 300);
    $this.bind('keyup click mousemove', reset);
  });
}

window.beforeShowDatePicker = function(input, inst) {
  var default_date = null;
  switch ($(input).attr("id")) {
    case "issue_start_date" :
      if ($("#issue_due_date").length > 0) {
        default_date = $("#issue_due_date").val();
      }
      break;
    case "issue_due_date" :
      dueDateSetter('issue', input);
      break;
    case "project_easy_due_date" :
      dueDateSetter('project_easy', input);
      break;
  }
  $(input).datepickerFallback("option", "defaultDate", default_date);
}

window.dueDateSetter = function(id_prefix, input){
  var start_date = $('#' + id_prefix + '_start_date');
  if (start_date.length > 0) {
    var due_date = $('#' + id_prefix + '_due_date');
    if (start_date.val() != "" && due_date.val() == "") {
      start_date = new Date(Date.parse(start_date.val()));
      if (start_date > new Date()) {
        default_date = start_date;
        $(input).datepicker("option", "defaultDate", default_date);
      }
    }
    if (due_date.length > 0) {
      if (due_date.val() != "" && start_date.val() > due_date.val()) {
        $(input).datepicker("setDate", start_date.val());
      }
    }
  }
};

(function($){
  $.fn.positionedItems = function(sortableOptions, options){
      var settings = $.extend({
          firstPosition: 1
      }, options );

      return this.sortable($.extend({
          handle: ".sort-handle",
          helper: function(event, ui){
              ui.children('td').each(function(){
                  $(this).width($(this).width());
              });
              return ui;
          },
          update: function(event, ui) {
              var sortable = $(this);
              var handle = ui.item.find(".sort-handle").addClass("ajax-loading");
              var url = handle.data("reorder-url");
              var param = handle.data("reorder-param");
              var data = {};
              data[param] = {position: ui.item.index() + settings['firstPosition']};
              $.ajax({
                  url: url,
                  type: 'put',
                  dataType: 'script',
                  data: data,
                  success: function(data){
                      sortable.children(":even").removeClass("even").addClass("odd");
                      sortable.children(":odd").removeClass("odd").addClass("even");
                  },
                  error: function(jqXHR, textStatus, errorThrown){
                      alert(jqXHR.status);
                      sortable.sortable("cancel");
                  },
                  complete: function(jqXHR, textStatus, errorThrown){
                      handle.removeClass("ajax-loading");
                  }
              });
          }
      }, sortableOptions));
  }
}( jQuery ));

window.initMyPageSortable = function(list, url) {
  $('#list-'+list).sortable({
    connectWith: '.block-receiver',
    tolerance: 'pointer',
    update: function(){
      $.ajax({
        url: url,
        type: 'post',
        data: {'blocks': $.map($('#list-'+list).children(), function(el){return $(el).attr('id');})}
      });
    }
  });
  $("#list-top, #list-left, #list-right").disableSelection();
}

var warnLeavingUnsavedMessage;
window.warnLeavingUnsaved = function(message) {
  warnLeavingUnsavedMessage = message;
  $(document).on('submit', 'form', function(){
    $('textarea').removeData('changed');
  });
  $(document).on('change', 'textarea', function(){
    $(this).data('changed', 'changed');
  });
  window.onbeforeunload = function(){
    var warn = false;
    $('textarea').blur().each(function(){
      if ($(this).data('changed')) {
        warn = true;
      }
    });
    if (warn) {return warnLeavingUnsavedMessage;}
  };
}

window.setupAjaxIndicator = function() {
  $(document).bind('ajaxSend', function(event, xhr, settings) {
    // if ($('#ajax-indicator').length === 0 && settings.contentType != 'application/octet-stream') { //binding on div ID not working
    if ($('.ajax-loading').length === 0 && settings.contentType != 'application/octet-stream') {
      $('#ajax-indicator').addClass("loading");
      $('#ajax-indicator').show();
    }
  });
  $(document).bind('ajaxStop', function() {
    $('#ajax-indicator').removeClass("loading");
    $('#ajax-indicator').addClass("done");
    setTimeout(function(){
      $('#ajax-indicator').removeClass("done");
      $('#ajax-indicator').hide();
    }, 700);
  });
}

window.setupTabs = function() {
  if($('.tabs').length > 0) {
      displayTabsButtons();
      $(window).resize(displayTabsButtons);
  }
}

window.hideOnLoad = function() {
  $('.hol').hide();
}

window.addFormObserversForDoubleSubmit = function() {
  $('form[method=post]').each(function() {
    if (!$(this).hasClass('multiple-submit')) {
      $(this).submit(function(form_submission) {
        if ($(form_submission.target).attr('data-submitted')) {
          form_submission.preventDefault();
        } else {
          $(form_submission.target).attr('data-submitted', true);
        }
      });
    }
  });
}

window.defaultFocus = function(){
  if (($('#content :focus').length == 0) && (window.location.hash == '')) {
    $('#content input[type=text], #content textarea').first().focus();
  }
}

window.blockEventPropagation = function(event) {
  event.stopPropagation();
  event.preventDefault();
}

window.toggleDisabledOnChange = function() {
  var checked = $(this).is(':checked');
  $($(this).data('disables')).attr('disabled', checked);
  $($(this).data('enables')).attr('disabled', !checked);
  $($(this).data('shows')).toggle(checked);
}
window.toggleDisabledInit = function() {
  $('input[data-disables], input[data-enables], input[data-shows]').each(toggleDisabledOnChange);
}

window.toggleNewObjectDropdown = function() {
  var dropdown = $('#new-object + ul.menu-children');
  if(dropdown.hasClass('visible')){
      dropdown.removeClass('visible');
  }else{
      dropdown.addClass('visible');
  }
}

(function ( $ ) {
  $('#content, #ajax-modal').on('click', 'div.jstTabs a.tab-preview', function (event) {
    var tab = $(event.target);
    var url = tab.data('url');
    var form = tab.parents('form');
    var jstBlock = tab.parents('.jstBlock');
    var element = encodeURIComponent(jstBlock.find('.wiki-edit').val());
    var attachments = form.find('.attachments_fields input').serialize();
    $.ajax({
      url: url,
      type: 'post',
      data: "text=" + element + '&' + attachments,
      success: function (data) {
        jstBlock.find('.wiki-preview').html(data);
      }
    });
  });

  $('#auth_source_ldap_mode').change(function () {
    $('.ldaps_warning').toggle($(this).val() !== 'ldaps_verify_peer');
  }).change();

  // detect if native date input is supported
  var nativeDateInputSupported = true;

  var input = document.createElement('input');
  input.setAttribute('type','date');
  if (input.type === 'text') {
      nativeDateInputSupported = false;
  }

  var notADateValue = 'not-a-date';
  input.setAttribute('value', notADateValue);
  if (input.value === notADateValue) {
      nativeDateInputSupported = false;
  }

  $.fn.datepickerFallback = function( options ) {
      if (nativeDateInputSupported) {
          return this;
      } else {
          return this.datepicker( options );
      }
  };
}( jQuery ));

window.keepAnchorOnSignIn = function(form){
  var hash = decodeURIComponent(self.document.location.hash);
  if (hash) {
    if (hash.indexOf("#") === -1) {
      hash = "#" + hash;
    }
    form.action = form.action + hash;
  }
  return true;
}
