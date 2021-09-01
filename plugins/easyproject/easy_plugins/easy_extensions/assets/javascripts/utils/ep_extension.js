
window.EPExtensions = {
  setup: function() {
    $('.set_attachment_reminder').each(function(index) {
      EPExtensions.initAttachmentReminder(this);
    });
    $('.checks_other_element').click(function() {
      EPExtensions.checkElement($('#' + $(this).data('checks')));
      $(this).focus();
    });
    //---- Authentication -----
    $('.selectable-authentication').click(function(e) {
      $('.selectable-authentication').removeClass('selected');
      var $form = $(this).closest('form');
      if ($form.length === 0)
        return;
      var name = $(this).closest('.authentications').data('name');
      var id = (name).replace(/\[/, '_').replace(/\]/, '');
      var $elem = $form.find('#' + id);
      var uid = $(this).find('.uid').data('uid');
      if ($elem.length > 0) {
        $elem.attr('value', uid);
      } else {
        $elem = $('<input></input>', {'type': 'hidden', 'id': id, 'name': name, 'value': uid});
        $form.prepend($elem);
      }
      $(this).addClass('selected');
    });
    EPExtensions.onReload();
  },
  // should be called after page element load
  onReload: function() {
    EASY.schedule.require(function (loadAll) {
      loadAll();
    }, function () { return EASY.backgroundServices.loadAll; })
  },
  initAttachmentReminder: function(element) {
    var $form = $(element).parents('form'); //wish it is a single element, but if don't, should not be problem
    var formBlocked = false;
    $form.submit(function() {
      var textareaId = $(element).attr('id');
      var isCK = $(element).data('ck');
      var value = EPExtensions.getDescriptionValue(textareaId, isCK);
      var confirm_message = $(element).data('attachment_reminder_confirm');
      var words = $(element).data('attachment_reminder_words');
      var regex = RegExp(words);
      if (value.match(regex)) {
        if (EPExtensions.hasFileAttached(this)) {
          if(formBlocked){
            formBlocked = false;
            $form.removeAttr('data-submitted');
          }
          return true;
        }
        if (!confirm(confirm_message)) {
          formBlocked = true;
          return false;
        }
      }
    });
  },
  getDescriptionValue: function(elementId, isCK) {
    if (isCK) {
      var instance = CKEDITOR.instances[elementId];
      if (instance) {
        return instance.getData();
      } else {
        return '';
      }
    } else {
      return $('#' + elementId).val();
    }
  },
  hasFileAttached: function(formElement) {
    var hasFile = false;
    $(formElement).find('input[name*="attachments"]').filter(function() {
      return $(this).attr('name').match(/attachments\[p?\d+\]\[token|data\]/);
    }).each(function(index) {
      if ($(this).val() !== "") {
        hasFile = true;
        return true;
      }
    });
    $(formElement).find('input[type="file"],input[type="dropbox-minechooser"]').each(function(index) {
      if ($(this).val() !== "") {
        hasFile = true;
        return true;
      }
    });

    return hasFile;
  },
  checkElement: function(el) {
    $(el).prop("checked", true);
  },
  setAttrToUrl: function(url, name, value) {
    // value = encodeURIComponent(value);
    var attr_regex = RegExp(name + "=[^\&]+");
    if (url.match(attr_regex)) {
      return url.replace(attr_regex, name + '=' + value);
    }

    if (!url.match(/\?/)) {
      url += '?';
    } else if (!url.match(/\&$/)) {
      url += '&';
    }
    var paramHash = {};
    paramHash[name] = value;
    url += $.param(paramHash);
    return url;
  },
  issuesToggleRowGroup: function($element) {
    var tr = $element;
    var n = tr.next();
    tr.toggleClass('open').find('.expander');
    while (n.length !== 0 && !n.hasClass('group')) {
      if (tr.hasClass('open'))
        n.show();
      else
        n.hide();
      n = n.next();
    }
  },
  showEasyModal: function(el, options) {
    var $el = $(el);
    var mh = ERUI.topMenu.outerHeight();
    var wh = window.innerHeight;
    var defaults = {
      width: '90%',
      modal: true,
      resizable: false,
      dialogClass: 'modal',
      maxHeight: wh - mh - 20,
      maxWidth: '100%',
      open: function( event, ui ) {
        ERUI.body.addClass('modal-opened');
        EASY.utils.modalOpened = true;
        initEasyAutocomplete();
      },
      close: function( event, ui ) {
        ERUI.body.removeClass('modal-opened');
        EASY.utils.modalOpened = false;
        $(this).dialog("destroy");
      }
    };
    $el.dialog( $.extend({}, defaults, options) );
  }
};
EASY.schedule.main(EPExtensions.setup, 5);
