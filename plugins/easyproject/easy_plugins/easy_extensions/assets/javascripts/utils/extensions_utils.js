EASY.utils.toggleMultiSelect = function (select_id, size) {
  if (typeof event !== 'undefined') {
    $(event.target).toggleClass('open');
  }
  var select = $('#' + select_id.replace(/(:|\.|\[|\])/g, "\\$1"))[0];
  if (select.multiple === true) {
    select.multiple = false;
    select.size = 1;
  } else {
    select.multiple = true;
    select.size = size || 10;
  }
};

EASY.utils.toggleDiv = function (el_or_id) {
  var el;
  if (typeof(el_or_id) === 'string') {
    el = $('#' + el_or_id);
  } else if (typeof(el_or_id) === 'undefined') {
    return;
  } else {
    el = el_or_id;
  }
  el.slideToggle(0).toggleClass('collapsed');
  $(document).trigger("erui_interface_change_vertical");
  $(document).trigger("erui_interface_change_horizontal");
};

EASY.utils.toggleDivAndChangeOpen = function (toggleElementId, changeOpenElement) {
  EASY.utils.toggleDiv(toggleElementId);
  $(changeOpenElement).toggleClass('open');
};

EASY.utils.setStorageItem = function (root, uniq_id, user_id) {
  const item = {'user_id': user_id};

  if (!window.localStorage.getItem(root)) {
    window.localStorage.setItem(root, JSON.stringify({}));
  }

  const localStrg = JSON.parse(window.localStorage.getItem(root));
  const isStorageItem = this.isStorageItem(root, uniq_id);

  isStorageItem ? delete localStrg[uniq_id] : localStrg[uniq_id] = item;
  window.localStorage.setItem(root, JSON.stringify(localStrg));
};

EASY.utils.loadModules = function () {
  const modules = document.querySelectorAll('.easy-page__module.collapsible');

  modules.forEach((module) => {
    const moduleContent = module.querySelector('.module-content');
    const moduleId = moduleContent.id;
    const closed = this.isStorageItem("savedPreferences", moduleId);
    const group = module.querySelector('.group');

    if (closed) {
      if(group)
        group.classList.remove('open');
      moduleContent.style.display = 'none';
    } else {
      if(group)
        group.classList.add('open');
      moduleContent.style.display = 'block';
    }
  });
};

EASY.utils.updateUserPref = function (uniq_id, user_id) {
  this.setStorageItem("savedPreferences", uniq_id, user_id);
};

/*
 * ToggleTableRowVisibility('project_index_', 'project', '55', '51');
 */
EASY.utils.toggleTableRowVisibility = function (uniq_prefix, entity_name, entity_id, user_id, update_user_pref) {
  var uniq_id = uniq_prefix + entity_name + '-' + entity_id;
  var tr = $('#' + uniq_id);
  if (update_user_pref) {
    EASY.utils.updateUserPref(uniq_id, user_id, tr.hasClass('open'));
  }
  if (tr.hasClass('open')) {
    EASY.utils.hideTableRow(uniq_prefix, entity_name, entity_id, true);
  } else {
    EASY.utils.showTableRow(uniq_prefix, entity_name, entity_id, false);
  }
  $(document).trigger("erui_interface_change_vertical");
};

EASY.utils.hideTableRow = function (uniq_prefix, entity_name, entity_id, recursive) {
  var tr = $('#' + uniq_prefix + entity_name + '-' + entity_id);
  tr.removeClass('open');
  $('.' + uniq_prefix + 'parent' + entity_name + '_' + entity_id).each(function () {
    $(this).hide();
    if (recursive && this.id) {
      EASY.utils.hideTableRow(uniq_prefix, entity_name, this.id.substring((uniq_prefix + entity_name + '-').length), recursive);
    }
  });
  $(document).trigger("erui_interface_change_vertical");
};

EASY.utils.showTableRow = function (uniq_prefix, entity_name, entity_id, recursive) {
  var tr = $('#' + uniq_prefix + entity_name + '-' + entity_id);
  tr.addClass('open');
  $('.' + uniq_prefix + 'parent' + entity_name + '_' + entity_id).each(function () {
    $(this).show();
    if (recursive && this.id) {
      EASY.utils.showTableRow(uniq_prefix, entity_name, this.id.substring((uniq_prefix + entity_name + '-').length), uniq_prefix, recursive);
    }
  });
  $(document).trigger("erui_interface_change_vertical");
};


EASY.utils.toggleMyPageModule = function (expander, element, user, ajaxUpdateUserPref) {
  var group = $(expander).parent('div');
  var isOpened = group.hasClass('open');
  const activityFeedSelector = ".easy-activity-feed__activity-event-wrapper";

  const isModuleActivityFeed = () => {
    const module = document.getElementById(element);
    return module && !!module.querySelector(activityFeedSelector);
  };

  group.toggleClass('open');

  if (ajaxUpdateUserPref) {
    EASY.utils.updateUserPref(element, user, isOpened);
  }
  var $module = $('#' + element);
  $module.fadeToggle(function () {
    $(document).trigger("erui_interface_change_vertical",[isOpened, element]);
  });
  affix.recalculateHeads(ERUI.tableHeads);
  EASY.responsivizer.fakeResponsive();
  $module.find('.thumbnails').each(function (index) {
    EASY.utils.initGalereya($(this));
  });
  $module.trigger('easy-module-collapse-changed', [isOpened]);

  if (!isModuleActivityFeed()) return;
  setTimeout(() => {
    new ActivityTimeline(activityFeedSelector);
  }, 0)
};

EASY.utils.openTogglingContainer = function (expander, element) {
  var group = $(expander).parent('div');
  group.addClass('open');
  $('#' + element).fadeIn();
  EASY.responsivizer.fakeResponsive();
  $(document).trigger("erui_interface_change_vertical");
};

/**
 * almighty implementation for dealing with timezones 'automagically'
 * @param date string (optionally with the time and timezone), in format YYYY-MM-DD HH:mm:SSZZZZ
 * @return javascript Date object in the timezone set in users settings
 */
EASY.utils.parseDate = (date) => {
  // avoid Lukas's bugfix with toString()
  const skipParsing = (date instanceof Date);
  if(!skipParsing) {
    // Magic start
    const dateHash = date.match(/^([0-9]{4})(-([0-9]{2})(-([0-9]{2})([T ]([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?(Z|(([-+])([0-9]{2})(:?([0-9]{2}))?))?)?)?)?$/);
    const time = dateHash[6];
    const dateTimezone = dateHash[13];
    if (!time) return new Date(date);
    if (!dateTimezone) {
      // when date is send without a timezone it is probably in utc
      // when date is received without a timezone it is probably in utc
      // this line resolves difference between utc and local time
      date = new Date(new Date(date).getTime() - (new Date(date).getTimezoneOffset() * 60 * 1000));
    }
  }

  // Magic end
  const timezone = EASY.currentUser.time_zone_identifier;
  const formattedDate = moment(date).tz(timezone).format("YYYY-MM-DD HH:mm");
  const correctDate = new Date(moment(formattedDate));
  return correctDate;
},

EASY.utils.submitForm = function (form_id, url) {
  var frm = $('#' + form_id);
  frm.attr('action', url);
  frm.submit();
};

/**
 *
 * @param {String} url
 * @param {String} filename
 */
EASY.utils.downloadRemoteDataAsFile = function (url, filename, failMessage) {
  $.ajax({
    url: url,
    dataType: "text",
    success: function(data) {
      EASY.utils.downloadDataAsFile(data, filename);
    },
    error: function() {
      showFlashMessage('error', failMessage, 1500);
    }
  });
};

/**
 *
 * @param {String} data
 * @param {String} filename
 */
EASY.utils.downloadDataAsFile = function (data, filename) {
  var type = 'text/plain';

  var element = document.createElement("a");
  element.setAttribute('download', filename);
  element.setAttribute('type', type);

  var dataBlob = new Blob([data]);
  element.href = URL.createObjectURL(dataBlob);

  element.style.display = 'none';
  document.body.appendChild(element);

  element.click();

  document.body.removeChild(element);
};

(function () {
  /**
   *
   * @param {String} field
   * @param {Array.<int>} indexes
   * @param {String} modul_uniq_id
   */
  function enableValues(field, indexes, modul_uniq_id) {
    var div_values = $('#' + modul_uniq_id + "div_values_" + field);
    div_values.toggle(indexes.length > 0);
  }

  /**
   *
   * @param {String} field
   * @param {String} modul_uniq_id
   */
  EASY.utils.toggleOperator = function (field, modul_uniq_id) {
    var operator = $('#' + modul_uniq_id + "operators_" + field);
    if (typeof(operator.val()) === 'undefined') {
      $('#' + modul_uniq_id + "div_values_" + field).show();
    } else {
      switch (operator.val()) {
        case "!*":
        case "*":
        case "t":
        case "ld":
        case "w":
        case "lw":
        case "l2w":
        case "m":
        case "lm":
        case "y":
        case "o":
        case ">dd":
        case "c":
          enableValues(field, [], modul_uniq_id);
          break;
        case "*o":
        case "!o":
          enableValues(field, [], modul_uniq_id);
          break;
        case "><":
          enableValues(field, [0, 1], modul_uniq_id);
          break;
        case "<t+":
        case ">t+":
        case "><t+":
        case "t+":
        case ">t-":
        case "<t-":
        case "><t-":
        case "t-":
          enableValues(field, [2], modul_uniq_id);
          break;
        case "=p":
        case "=!p":
        case "!p":
          enableValues(field, [1], modul_uniq_id);
          break;
        default:
          enableValues(field, [0], modul_uniq_id);
          break;
      }
    }
  };
})();


// Function for updating textareas to content from CKEDITOR
EASY.utils.updateCKE = function () {
  if (!(typeof CKEDITOR === "undefined")) {
    var instance;
    for (instance in CKEDITOR.instances) {
      CKEDITOR.instances[instance].updateElement();
    }
  }
};

// Function for updating form and sendind data also from CKEDITOR
//
// e.g. onchange status, tracker, ...
EASY.utils.updateForm = function (form, url) {
  EASY.utils.updateCKE();

  $.ajax({
    url: url,
    type: 'post',
    data: $(form).serialize()
  });
};

EASY.utils.submitModalForm = function (modalElement, appendContinue) {
  EASY.utils.updateCKE();
  var frm = $(modalElement).find('form:first');
  if (appendContinue) {
    frm.append('<input type="hidden" value="1" name="continue" />');
  }
  frm.submit();
};

EASY.utils.goToUrl = function (url, e) {
  var target = e.target || e.srcElement;
  if (target && (target.nodeName === 'INPUT' || target.nodeName === 'A' ||
    $(target).parents().hasClass('easy-autocomplete-tag'))) {
    return false;
  }
  if (e !== null && e !== 'undefined') {
    if (!e.ctrlKey && !e.shiftKey && !e.metaKey) {
      window.location = url;
    } else {
      // do nothing
    }
  } else {
    window.location = url;
  }
  return true;
};

EASY.utils.showAndScrollTo = function (element_id, offsetDelta, container_id) {
  if (!offsetDelta) {
    offsetDelta = 0;
  }
  var $container;
  var $el = $('#' + element_id);
  if (container_id) {
    $container = $("#" + container_id);
  } else {
    $container = $el;
  }
  $el.show();
  $('html, body').animate({
    scrollTop: $container.offset().top + offsetDelta
  }, 500);
  $(document).trigger("erui_interface_change_vertical");
};

EASY.utils.displayTabsButtons = function (css_selector) {
  var lis;
  var tabsWidth = 0;
  var liEl;
  $(css_selector).each(function () {
    lis = $(this).find('ul').children('li');
    lis.each(function (index, li) {
      liEl = $(li);
      if (liEl.is(":visible")) {
        tabsWidth += liEl.outerWidth();
      }
    });
    $(this).find('div.tabs-buttons, td.tabs-button').toggle(!((tabsWidth < $(this).width() - 120) && (lis.first().is(":visible"))));
  });
};

EASY.utils.moveTabRight = function (el) {
  var lis = $(el).parents('div.tabs').first().find('ul').children();
  var tabsWidth = 0;
  var i = 0;
  var that;
  lis.each(function () {
    that = $(this);
    if (that.is(':visible')) {
      tabsWidth += that.outerWidth();
    }
  });
  if (tabsWidth < $(el).parents('div.tabs').first().width() - 120) {
    return;
  }
  while (i < lis.length && !lis.eq(i).is(':visible')) {
    i++;
  }
  lis.eq(i).hide();
};

EASY.utils.moveTabLeft = function (el) {
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
};

/**
 *
 * @param {jQuery} $from_el
 * @param {jQuery} $to_el
 */
EASY.utils.switchElements = function ($from_el, $to_el) {
  $from_el.hide();
  $to_el.show();
};

EASY.utils.toggleCheckbox = function (id) {
  var el = $('#' + id);
  if (el) {
    el.prop("checked", !el.is(":checked"));
  }
};

EASY.utils.warnLeaveUnsaved = function () {
  if (window.enableWarnLeavingUnsaved) {

    $('textarea').closest('form').data('changed', 'changed');
    $('form').on('submit', function () {
      $('textarea').closest('form').removeData('changed').attr('data-changed', false);
    });

    var easyBeforeUnload = function(event) {
      var warn = false;
      for (var name in CKEDITOR.instances) {
        var editor = CKEDITOR.instances[name];

        if ($(editor.element.$.form).data() && $(editor.element.$.form).data().changed && CKEDITOR.instances[name].checkDirty())
          warn = true;
      }

      if (warn) {
        event.returnValue = window.I18n.textWarnLeavingUnsaved;
        return window.I18n.textWarnLeavingUnsaved;
      }
    };

    if (window.addEventListener)
      window.addEventListener("beforeunload", easyBeforeUnload, false);
  }
};

EASY.utils.toggleSidebar = function () {
  ERUI.body.toggleClass('nosidebar');
  ERUI.document.trigger('easySidebarToggled');
  // ERUI.main.trigger($.Event('resize'));
  EASY.utils.updateUserPref('open_sidebar', null, ERUI.body.hasClass('nosidebar'));
  EASY.responsivizer.fakeResponsive();
};

(function () {

  function showImportantJournalDetails(journal) {
    journal.find(".journal-details-container ul.details > li").each(function () {
      var self = $(this);
      self.toggle(self.hasClass('important'));
    });
  }

  EASY.journals.collapseUnnecessary = function () {
    var $toggler = $(".journal-details-toggler");
    var journals_to_hide = $toggler.closest('.journal').toArray();
    if ($(journals_to_hide).last()[0] === $(".journal.has-details:last-child").last()[0]) {
      $(journals_to_hide.pop()).find(".expander").parent().toggleClass('open'); // all except last
    }
    $(journals_to_hide).each(function (index, i) {
      var journal = $(i);
      journal.find(".avatar-container img").toggleClass('smallest-avatar');
      showImportantJournalDetails(journal);
    });
    $toggler.click(function (event) {
      var expander = $(event.target);
      EASY.journals.toggleDetails(expander.closest(".journal"));
    });
  };
  EASY.journals.toggleDetails = function (journal) {
    journal.find(".avatar-container img").toggleClass('smallest-avatar');
    journal.find(".journal-details-container ul.details > li:not(.important)").each(function () {
      $(this).toggle();
    });
    journal.find(".expander").parent().toggleClass('open');
  };
})();


EASY.modalSelector.showModal = function (width) {
  showModal('ajax-modal', width || '70%');
};

EASY.contextMenu.reloadInit = function () {
  if (EASY.contextMenu.initializers) {
    $.each(EASY.contextMenu.initializers, function (index, fce) {
      eval(fce);
    });
  }
};

EASY.utils.moveMenuLeft = function () {
  var scroll = ERUI.mainMenu.scrollLeft();
  window.requestAnimationFrame(function () {
    ERUI.mainMenu.scrollLeft(scroll - 120);
  });
};

EASY.utils.moveMenuRight = function () {
  var scroll = ERUI.mainMenu.scrollLeft();
  window.requestAnimationFrame(function () {
    ERUI.mainMenu.scrollLeft(scroll + 120);
  });
};
EASY.utils.delayedRAF = function (callback,delay) {
  return setTimeout(function () {
    window.requestAnimationFrame(callback)
  }, delay);
};

EASY.utils.backToTop = function () {
  $("html, body").animate({
    scrollTop: 0
  }, 200);
};

EASY.utils.contentHeightSwitchable = function (class_name, label_more, label_less) {
  var wikiSelector = '.wiki';
  var contentSelector = '.' + class_name,
    buttonFull = $('<a />').text(label_more).addClass('switchFull'),
    buttonLess = $('<a />').text(label_less).addClass('switchLess');

  $(wikiSelector + " > " + contentSelector).each(function () {
    var block = $(this);

    if (block[0].scrollHeight > block[0].offsetHeight) {
      block.after(buttonFull.clone());
    }
  });

  ERUI.document.on('click', '.switchFull', function () {
    var switchFullLink = $(this);
    switchFullLink.prev(contentSelector).removeClass(class_name);
    switchFullLink.replaceWith(buttonLess.clone());
  });

  ERUI.document.on('click', '.switchLess', function () {
    var switchLessLink = $(this);
    switchLessLink.prev("div").addClass(class_name);
    switchLessLink.replaceWith(buttonFull.clone());
  });
};

EASY.utils.setNameToModuleHead = function (input) {
  var textFromInput;
  if (input.tagName === 'SELECT') {
    textFromInput = $("option:selected", input).text();
  } else {
    textFromInput = input.value;
  }
  $(input).closest('div.easy-page-module.box').find('.module-heading-title').text(textFromInput);
};

EASY.utils.setInfiniteScrollDefaults = function () {
  $.extend($.infinitescroll.defaults, {
    behavior: 'easy',
    previousSelect: null
  });
  $.infinitescroll.prototype._nearbottom_easy = function () {
    var documentHeight = $(document).height();
    var opts = this.options;
    var pixelsFromWindowBottomToBottom = documentHeight - (opts.binder.scrollTop()) - $(window).height();
    var cnt = $(opts.contentSelector);
    var navToBottom = documentHeight - cnt.position().top - cnt.height();
    return pixelsFromWindowBottomToBottom < navToBottom + opts.bufferPx;
  };
  $.infinitescroll.prototype._setup_easy = function () {
    this._binding('bind');
    if (this.options.previousSelect === null || $(this.options.previousSelect).length === 0) {
      $(".infinite-scroll-load-next-page-trigger").parent().show();
    }
    return false;
  };
  $.extend($.infinitescroll.defaults.loading, {
    selector: '#main .infinite-scroll-load-next-page-trigger-container',
    msgText: '',
    localMode: true,
    finishedMsg: '',
    debug: true
  });
};

EASY.utils.initProjectEdit = function () {
  /*
   * Project inline editing with autocomplete.
   */
  $('.project-autocomplete-edit').not('.initialized').on('click', function (evt) {
    evt.stopPropagation();
    var target = $(evt.currentTarget);
    target.siblings('.editable').toggle();
    target.siblings('.easy-autocomplete-tag').toggle();
  }).addClass('initialized');
};

EASY.utils.initFileUploads = function () {
  EASY.schedule.late(function () {
    if (typeof cbImagePaste !== 'undefined' && typeof cbImagePaste.adjustCbpImageParts === "function") {
      cbImagePaste.adjustCbpImageParts();
    }
  });
  return true;
};

(function () {
  function closeBroadcast(broadcastId) {
    $.ajax({
      type: "POST",
      url: (window.urlPrefix + "/easy_broadcasts/mark_as_read.json"),
      noLoader: true,
      data: {id: broadcastId}
    });
  }

  EASY.utils.broadcast.showBroadcastFlashMessage = function (type, message, broadcastId) {
    return $("<div/>").attr({"class": "flash notice"})
      .addClass(type)
      .html($("<span/>").html(message))
      .append($("<a/>").attr({"href": "javascript:void(0)", "class": "icon-close"}).click(function () {
          closeBroadcast(broadcastId);
          $(this).closest('.flash').fadeOut(500, function () {
            $(this).remove();
          });
        }
      ))
      .prependTo($("#content"));
  };
})();

class Fullscreen {
  constructor(contentSelector, triggerButtonSelector) {
    this.content = contentSelector;
    this.state = false;
    this.triggerButton = triggerButtonSelector;
  }

  init() {
    if (!this.content || !this.triggerButton) return;
    this.triggerButton.addEventListener('click', this.setUnsetFullScreen.bind(this));
  }

  setUnsetFullScreen() {
    if (!this.state) {
      if (!this.triggerButton) return;
      this.triggerButton.classList.add('fullscreen__trigger_active');
      this.content.classList.add('fullscreen');
      document.body.classList.add('fullscreen--active');
      this.openBrowserFullscreen();
      $.ajax({url: `?utm_campaign=fullscreen&utm_content=service_bar&utm_term=on`}); // just to send UTM parameter to server
      this.state = !this.state;
    } else {
      if (!this.triggerButton) return;
      this.triggerButton.classList.remove('fullscreen__trigger_active');
      this.content.classList.remove('fullscreen');
      document.body.classList.remove('fullscreen--active');
      $.ajax({url: `?utm_campaign=fullscreen&utm_content=service_bar&utm_term=off`}); // just to send UTM parameter to server
      this.state = !this.state;
      this.closeBrowserFullscreen();
    }
  }

  setFullScreenOnly() {
    this.content.classList.add('fullscreen');
    this.state = !this.state;
  }

  openBrowserFullscreen() {
    const html = document.documentElement;
    if (html.requestFullscreen) {
      html.requestFullscreen();
    } else if (html.mozRequestFullScreen) { /* Firefox */
      html.mozRequestFullScreen();
    } else if (html.webkitRequestFullscreen) { /* Chrome, Safari and Opera */
      html.webkitRequestFullscreen();
    } else if (html.msRequestFullscreen) { /* IE/Edge */
      html.msRequestFullscreen();
    }
  }

  closeBrowserFullscreen() {
    if (document.exitFullscreen) {
      document.exitFullscreen();
    } else if (document.mozCancelFullScreen) { // Firefox */
      document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) { /* Chrome, Safari and Opera */
      document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) { /* IE/Edge */
      document.msExitFullscreen();
    }
  }
}

EASY.utils.FullScreen = Fullscreen;

EASY.utils.EasyChartsOnInit = function () {
  function _chartOnInit(self) {
    self.api.resize();
  }

  var self = this;

  if (window.matchMedia) {
    window.matchMedia('print').addListener(function(media) {
      _chartOnInit(self)
    });
  } else {
    // basically a fallback for < IE11
    window.addEventListener('beforeprint', _chartOnInit(self), false);
  }
}

EASY.utils.shiftStartEndTime = ({endTimeEl, endDateEl, startTimeEl, startDateEl}) => {
  const DATE_FORMAT = "YYYY-MM-DD";
  const TIME_FORMAT = "HH:mm";

  let prevStartDateVal = moment(`${startDateEl.value} ${startTimeEl.value}`);

  const shiftDateTime = () => {
    if (!startTimeEl || !endTimeEl || !startDateEl || !endDateEl) return;
    const startDateTime = moment(`${startDateEl.value} ${startTimeEl.value}`);
    const endDateTime = moment(`${startDateEl.value} ${endTimeEl.value}`);
    if (!startDateTime.isValid || !endDateTime.isValid) return;
    const shift = moment.duration(startDateTime.diff(prevStartDateVal)).asMinutes();
    const shiftedEndDateTime = moment(endDateTime).add(shift, "minutes");
    endDateEl.value = startDateTime.format(DATE_FORMAT);
    endTimeEl.value = shiftedEndDateTime.format(TIME_FORMAT);
    prevStartDateVal = startDateTime;
  }
  startTimeEl.addEventListener("change", shiftDateTime);
  // because of datepicker it has to be jquery,
  // vanilla "change" event is not triggered on date change from picker
  $(startDateEl).on("change", shiftDateTime)
}

EASY.utils.syntaxHighlight = () => {
  EASY.schedule.require(() => {
    $('pre code').each((i, block) => {
      if (hljs) {
        hljs.highlightBlock(block);
        $(block).parent().addClass('pre-default');
      }
    });
  }, function () { return window.hljs; });
};
