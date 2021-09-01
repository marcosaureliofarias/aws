EASY.schedule.main(function () {
  ERUI.content.on('change', 'input[data-disables], input[data-enables], input[data-shows]', toggleDisabledOnChange);
  toggleDisabledInit();
  setupAjaxIndicator();
  hideOnLoad();
  addFormObserversForDoubleSubmit();
  setupTabs();
  $('input[type=checkbox].toggle-selection').on('change', function(el) {
    EASY.contextMenu.toggleIssuesSelection(el.target);
  });

  function initAutoscroll() {
    $("div.autoscroll").each(function() {
      var $this = $(this);
      if (!$this.parent().hasClass("autoscroll__wrapper")) {
        $this.wrap('<div class="autoscroll__wrapper"></div>');
      }
    });
  }

  // for modal selector
  $.infinitescroll.prototype._nearbottom_modal_selector = function () {
    var opts = this.options;
    return 0.9 < ((opts.binder.scrollTop() + opts.binder.height()) / $(opts.contentSelector).height());
  };

  function onScroll() {
    ERUI.scrollTopLast = ERUI.scrollTop;
    ERUI.scrollTop = $(window).scrollTop();
    affix.read();
    window.requestAnimationFrame(function () {
      //do stuff
      affix.tableScrolls();
      affix.tableHeads();
      // affix.formActions();
      affix.sidebar();
      if (ERUI.scrollTop) {
        ERUI.backToTop.css({opacity: '1'});
      } else {
        ERUI.backToTop.css({opacity: '0'});
      }
      if (ERUI.sideScrollEl && ERUI.sideScrollEl.length > 0) {
        if (!affix.register['sidebar'].attached) {
          ERUI.sideScrollEl.css({
            height: ERUI.sideScrollElHight + ERUI.scrollTop
          });
        } else {
          ERUI.sideScrollEl.css({
           height: ERUI.window.outerHeight() - ERUI.topMenu.outerHeight() - affix.sideScrollElOffs - affix.sass.boxPadding + 2
            //height: ERUI.sideScrollElHight + ERUI.headerHeight - ERUI.sidebarOffsTop + ERUI.onboardHeight
          });
        }
      }
    });
  }

  function mainMenuScrollButtons() {
    var size = 0;
    var index = 0;
    // summarize width if menu items
    $("#main-menu").find("li").each(function () {
      size += $(this).outerWidth();
      index++
    });

    if (( size + index * 5 + 20 ) < ERUI.main.width()) {
      $("#main_menu_scroll_buttons").hide();
    } else {
      $("#main_menu_scroll_buttons").show();
    }
  }
  var responsivizer = EASY.responsivizer;
  responsivizer.init();
  responsivizer.fakeResponsive();
  affix.preInit();
  affix.tableScrolls();
  affix.tableHeads();
  initAutoscroll();
  ERUI.window.scroll(onScroll);
  mainMenuScrollButtons();
  ERUI.window.resize(function () {
    window.requestAnimationFrame(function () {
      responsivizer.fakeResponsive();
      affix.reInit();
      affix.tableScrolls();
      responsivizer.contentWidth = $("#content").width();
      mainMenuScrollButtons();
    });
  });


  ERUI.document.on("erui_new_dom", function (event) {
    ERUI.init();
    responsivizer.init();
    window.requestAnimationFrame(function () {
      responsivizer.fakeResponsive(event.target);
      affix.reInit();
      affix.tableScrolls();
      affix.tableHeads();
      affix.recalculateHeads(ERUI.tableHeads);
      affix.sidebar();
      initAutoscroll();
    });
  });


  ERUI.document.on("erui_interface_change_modal", function () {
    ERUI.document.trigger("erui_new_dom");
  });
  ERUI.document.on("erui_interface_change_vertical", function () {
    responsivizer.fakeResponsive();
    affix.reInit(); // maybe too much workout, but works better with it
    affix.tableScrolls();
    affix.tableHeads();
    affix.sidebar();
  });

  ERUI.document.on('cocoon:after-insert', function (e) {
    ERUI.document.trigger("erui_interface_change_vertical");
  });
  ERUI.document.on('cocoon:after-remove', function (e) {
    ERUI.document.trigger("erui_interface_change_vertical");
  });
  ERUI.document.on('tab-change', function (e) {
    ERUI.document.trigger("erui_new_dom");
  });
  ERUI.document.on('easy-query:after-search', function (e) {
    ERUI.document.trigger("erui_new_dom");
  });
  ERUI.document.on('entity-tabs:after-tab-switch', function (e) {
    ERUI.document.trigger("erui_new_dom");
  });
  ERUI.document.on('easy_attendance_autoscroll', function (e) {
    ERUI.init();
    affix.preInit();
  });

  $('#easy_instant_messages_wrapper').styleChat();
});
