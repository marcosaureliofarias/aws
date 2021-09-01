EASY.schedule.late(function () {
  EASY.utils.loadModules();
  EASY.utils.initFileUploads();

  if (EASY.contextMenu.contextMenuRightClick) {
    ERUI.document.on('click', '.btn_contextmenu_trigger', EASY.contextMenu.contextMenuRightClick);
    ERUI.document.on('click', '.js-contextmenu', EASY.contextMenu.contextMenuRightClick);
  }

  $('div.module-toggle-button.manual').click(function () {
    $(this).next('div').toggle();
    $('div.group:first', this).toggleClass('open');
  });
  EASY.dragAndDrop.initHandlers();
  EASY.dragAndDrop.initReorders();
  $(document).bind('ajaxStart', function (event, xhr, settings) {
    $('#ajax-indicator').addClass('loading');
  });
  $(document).unbind('ajaxSend').bind('ajaxSend', function (event, xhr, settings) {
    if (!settings.noLoader && $('.ajax-loading').length === 0 && settings.contentType !== 'application/octet-stream') {
      $('#ajax-indicator').show();
    }
  });
  $(document).bind('ajaxComplete', function (event, xhr, settings) {
    $('#ajax-indicator').removeClass('loading');
    $('#ajax-indicator').addClass('done');
  });
  $(document).bind('ajaxStop', function (event, xhr, settings) {
    setTimeout(function(){ $('#ajax-indicator').removeClass('done');}, 1000);
  });
  EASY.utils.initProjectEdit();
  EASY.contextMenu.reloadInit();
  ERUI.document.on('click', '.one-click-select', function () {
    $(this).focus();
    $(this).select();
  });
  var textareaAutoExpand = $('textarea.auto-expand');
  textareaAutoExpand.one('focus', function () {
    var savedValue = this.value;
    this.value = '';
    this.baseScrollHeight = this.scrollHeight;
    this.value = savedValue;
    $(this).trigger('input');
  });
  textareaAutoExpand.on('input', function () {
    var minRows = this.getAttribute('data-min-rows') | 2;
    this.rows = minRows;
    var rows = Math.ceil((this.scrollHeight - this.baseScrollHeight) / 16);
    this.rows = minRows + rows;
  });
  $(document).on('ajaxComplete', function () {
    EASY.dragAndDrop.initHandlers();
    if (ERUI.serviceBarComponentBody.is(':visible')) {
      $('#ajax-modal').trigger("erui_new_dom");
      var servicebar_content = ERUI.serviceBarComponentBody.find('.servicebar-content');
      servicebar_content.each(function () {
        new PerfectScrollbar(this, {
          suppressScrollX: true,
          includePadding: true,
          wheelPropagation: false,
          swipePropagation: false
        });
      });
      servicebar_content.css({overflowY: 'hidden'});

      if (servicebar_content.is('#easy_im_inline_message_history')) {
        ERUI.serviceBarComponentBody.find('.servicebar-content').scrollTop(900000);
      }
    }
  });
  EASY.utils.warnLeaveUnsaved();
  $('.menu--tooltip').each(function(){
    var $this = $(this);
    $this.toggleable({observer: EASY.defaultClickObserver, content: $this.find('ul')});
  });
}, -5);
