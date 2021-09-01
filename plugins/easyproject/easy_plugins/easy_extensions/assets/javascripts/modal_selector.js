(function () {
  function copyInnerHTML(source_id, target_id) {
    var $target = $("#" + target_id);
    $target.html($("#" + source_id).html());
    var height = $target.height();
    $target.parent().height(height)
  }

  function closeFullscreen(element_id, close_button_container) {
    $("#footer, #header, #indent-box, #top-menu, #easy_servicebar").show();
    ERUI.main.removeAttr('style');
    $("#" + close_button_container).remove();
    $("#fullscreen-background-cover").remove();
    source = $('#' + element_id);
    $('#content').scrollTop(source.data('scrollTopWas'));
    source.removeData('isFullScreen');
    source.removeData('scrollTopWas');
    source.removeAttr("style");
    source.removeClass("fullscreen");
  }

  function addFullscreenCloseButton(label, title, container_id, element_id) {
    var a = $("<a href=\"javascript:;\">").click(function (event) {
      event.stopPropagation();
      event.preventDefault();
      closeFullscreen(element_id, container_id);
    });

    a.attr({
      'title': title,
      'id': 'modal-selector-close-button',
      'class': 'button'
    });
    a.html(label);

    var $div = $("<div id='" + container_id + "' class='modal-close-button'></div>").css({
      'position': 'fixed',
      'top': 0,
      'height': '30px',
      'padding': '10px 0',
      'line-height': '30px',
      'right': 0,
      'left': 0,
      'z-index': '10001',
      'background': '#fff',
      'text-align': 'center'
    }).html(a);
    return $div;
  }

  function addSelectedValueInModalSelector(container_id, internal_id, display_value, display_value_escaped, field_name, field_id) {
    var new_easy_lookup_selected_value_wrapper = $("<span>").attr({
      'class': 'easy-lookup-selected-value-wrapper easy-lookup-' + field_id + '-' + internal_id + '-wrapper'
    });
    var new_hidden_id = $('<input />').attr({
      'type': 'hidden',
      'value': internal_id,
      'name': field_name,
      'class': 'serializable-' + field_id
    });
    var new_display_name = $("<span>").attr({
      'class': 'display-name'
    }).html(display_value);
    var new_dont_copy = $("<span>").attr({
      'class': 'dont-copy'
    });
    var new_other_delete = $("<a>").attr({
      'href': 'javascript:void(0)',
      'class': 'icon icon-del',
      'onclick':
        "event.stopPropagation();" +
        "EASY.modalSelector.removeSelectedModalEntity('.easy-lookup-" + field_id + "-" + internal_id + "-wrapper', 'entity-" + internal_id + "');" +
        "EASY.modalSelector.updateHiddenField('" + field_id + "');"
    });

    var selected_values_container = $('#' + container_id + '-modal-selected-values-container');

    new_easy_lookup_selected_value_wrapper.append(new_hidden_id);
    new_easy_lookup_selected_value_wrapper.append(new_display_name);
    new_dont_copy.append(new_other_delete);
    new_easy_lookup_selected_value_wrapper.append(new_dont_copy);
    selected_values_container.append(new_easy_lookup_selected_value_wrapper);
  }

  EASY.modalSelector.removeSelectedModalEntity = function (selector, tr_id) {
    $(selector).remove();
    var tr = $('#' + tr_id);
    if (tr.length > 0) {
      EASY.contextMenu.contextMenuRemoveSelection(tr);
    }
  };

  EASY.modalSelector.changeValue = function (container_id, input_id, display_value_id, display_escaped_value_id, field_name, field_id, multiple) {
    var cbx = $("#" + input_id);
    if (cbx.prop('type') == 'radio') {
      if (cbx.is(':checked')) {
        $('.modal-selected-values [class*="-wrapper"]').remove();
        addSelectedValueInModalSelector(container_id, cbx.val(), $("#" + display_value_id).val(), $("#" + display_escaped_value_id).val(), field_name, field_id);
      }
    } else {
      var old_selected_values = $('.modal-selected-values .easy-lookup-' + field_id + '-' + cbx.val() + '-wrapper');
      if (old_selected_values.length == 0 && cbx.is(":checked")) {
        addSelectedValueInModalSelector(container_id, cbx.val(), $("#" + display_value_id).val(), $("#" + display_escaped_value_id).val(), field_name, field_id);
      } else if (old_selected_values.length > 0 && !cbx.is(":checked")) {
        old_selected_values.remove();
      }
    }
  };


  EASY.modalSelector.copySelectedModalEntities = function (source_id, target_id) {
    var delete_container = $("#" + target_id + "_lookup_delete_button");
    delete_container.show();
    var $target = $("#" + target_id);
    copyInnerHTML(source_id, target_id);
    $target.children('.dont-copy').remove();
    if ($target.html().match(/^\s*$/)) {
      $target.html($("#" + target_id + "-no_value").clone().show());
    }
    EASY.modalSelector.updateHiddenField(target_id);
  };

  EASY.modalSelector.closeModal = function (ele) {
    var modal = $("#easy_modal");
    if (modal.length === 0 || !modal.is(':visible'))
      modal = $("#ajax-modal");
    if (modal.is(':visible'))
      modal.dialog("close");
    EASY.modalSelector.unbindInfiniteScroll();
    if (ele) {
      window.location.reload();
    }
  };
  EASY.modalSelector.showEasyModal = function (pathParse) {
    showModal("easy_modal", "70%");
    $('#easy_modal').dialog({
      beforeClose: function (event, ui) {
        EASY.modalSelector.unbindInfiniteScroll();
      }
    });
  };
  EASY.modalSelector.showFullscreen = function (element_id, label_close, title_close, options) {
    source = $('#' + element_id);
    if (source.data('isFullScreen'))
      return;
    options = options || {};
    // $.data(source[0], 'oldCss', source.attr("style"));
    $("body").append($("<div style='position:fixed;top:0;left:0;width:100%;height:100%;background:#fff' id='fullscreen-background-cover'></div>"));
    source.css({
      'position': 'fixed',
      'top': '50px',
      'left': '0',
      'right': '0',
      'bottom': '0',
      'z-index': 10000,
      'background-color': '#fff',
      'overflow-y': 'scroll',
      'overflow-x': 'hidden'
    }).addClass('fullscreen');
    $("#footer, #header, #indent-box, #top-menu, #easy_servicebar").hide();
    $('#main').css('top', 30);

    source.append(addFullscreenCloseButton(label_close, title_close, 'fullscreen-close', element_id, options));
    source.data('isFullScreen', true);
    var $content = $('#content')
    source.data('scrollTopWas', $content.scrollTop());
    $content.scrollTop(0);
    if (typeof options['afterFull'] === 'function')
      options.afterFull.call(source);
  };

  EASY.modalSelector.saveAndCloseModal = function (field_id) {
    if (eval("typeof beforeCloseModalSelectorWindow_" + field_id) == 'function') {
      eval('beforeCloseModalSelectorWindow_' + field_id + '();');
    }
    else {
      EASY.modalSelector.copySelectedModalEntities(field_id + '-modal-selected-values-container', field_id);
    }

    EASY.modalSelector.closeModal();

    if (eval("typeof afterCloseModalSelectorWindow_" + field_id) == 'function') {
      eval('afterCloseModalSelectorWindow_' + field_id + '();');
    }
  };

  EASY.modalSelector.bindInfiniteScroll = function (pathParse) {
    $.extend($.infinitescroll.defaults.loading, {
      selector: '#modal-selector-entities',
      binder: $('#modal-selector-entities').closest('#easy_modal'),
      msgText: '',
      finishedMsg: ''
    });

    $('#easy_modal #modal-selector-entities table.entities tbody:first').infinitescroll({
        navSelector: '#easy_modal .pagination',
        nextSelector: '#easy_modal .pagination .next > a',
        itemSelector: '#modal-selector-entities table.entities tbody:first tr.selectable',
        binder: $('#modal-selector-entities').closest('#easy_modal'),
        behavior: 'modal_selector',
        pathParse: pathParse,
        localMode: true
      }, function (data, opts) {
        if (parseInt($(opts.navSelector + " li[class='page']:last").text()) == opts.state.currPage) {
          opts.state.isPaused = true;
          $("#easy_modal .infinite-scroll-load-next-page-trigger").parent().hide();
        }
      }
    );
  };

  EASY.modalSelector.unbindInfiniteScroll = function () {
    $('#easy_modal #modal-selector-entities table.entities tbody:first').infinitescroll('unbind');
  };

  EASY.modalSelector.initContextMenu = function () {
    EASY.contextMenu.init('', $('#easy_modal .easy-query-list'));
    $('div.modal-selected-values .easy-lookup-selected-value-wrapper input[type="hidden"]').each(function(i, e){
      $('tr#entity-'+e.value).addClass('context-menu-selection');
      $('tr#entity-'+e.value+' input[type="checkbox"], tr#entity-'+e.value+' input[type="radio"]').prop('checked', true);
    });
  };

  EASY.modalSelector.updateHiddenField = function (field_id) {
    var values_span = $('span#' + field_id);
    var hiddenField = values_span.siblings('.' + field_id + '-hidden');
    var valuesEmpty = !values_span.children().length;

    hiddenField.attr('disabled', !valuesEmpty);
  };

  EASY.modalSelector.selectAllOptions = function (id) {
    var select = $('#' + id);
    select.children('option').prop('selected', true);
  };

  EASY.modalSelector.parseEasyQueryData = function(modul_uniq_id, additional_elements_to_serialize) {
    var dataString = EASY.query.getFiltersForURL(modul_uniq_id) + EASY.query.getEasyQueryCustomFormattingForURL();
    if (additional_elements_to_serialize && (additional_elements_to_serialize instanceof jQuery)) {
      dataString += '&' + additional_elements_to_serialize.serialize();
    }
    return dataString
  }
})();
