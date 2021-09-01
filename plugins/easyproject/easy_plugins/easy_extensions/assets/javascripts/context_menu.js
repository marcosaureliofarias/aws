EASY.schedule.late(function () {

  var contextMenuObserving;
  var contextMenuUrl;
  var contextMenuRegister = [];

  function windowSize() {
    var w;
    var h;
    if (window.innerWidth) {
      w = window.innerWidth;
      h = window.innerHeight;
    } else if (document.documentElement) {
      w = document.documentElement.clientWidth;
      h = document.documentElement.clientHeight;
    } else {
      w = document.body.clientWidth;
      h = document.body.clientHeight;
    }
    return {width: w, height: h};
  }

  function contextMenuAddSelection(tr, target) {
    tr.addClass('context-menu-selection');
    contextMenuCheckSelectionBox(tr, true, target);
    contextMenuClearDocumentSelection();
    contextMenuRegister.push(tr.attr('id'));
  }

  function contextMenuCheckSelectionBox(tr, checked) {
    var input = tr.find('.checkbox input[type="checkbox"], .checkbox input[type="radio"], input.checkbox').prop('checked', checked);
    input.change();
  }

  function contextMenuClearDocumentSelection() {
    if (document.selection) {
      document.selection.empty(); // IE
    } else {
      window.getSelection().removeAllRanges();
    }
  }

  function contextMenuIsSelected(tr) {
    return tr.hasClass('context-menu-selection');
  }

  function contextMenuCreate() {
    if ($('#context-menu').length < 1) {
      var menu = document.createElement("div");
      menu.setAttribute("id", "context-menu");
      menu.setAttribute("style", "display:none;");
      document.getElementById("content").appendChild(menu);
    }
  }

  function contextMenuToggleSelection(tr) {
    if (contextMenuIsSelected(tr)) {
      EASY.contextMenu.contextMenuRemoveSelection(tr);
    } else {
      contextMenuAddSelection(tr);
    }
  }

  function contextMenuUnselectAll() {
    $('input[type=checkbox].toggle-selection').prop('checked', false);
    $('.hascontextmenu').each(function () {
      EASY.contextMenu.contextMenuRemoveSelection($(this));
    });
    $('.cm-last').removeClass('cm-last');
  }

  function contextMenuSetLastSelected(tr) {
    $('.cm-last').removeClass('cm-last');
    tr.addClass('cm-last');
  }

  function contextMenuShow(event) {

    var menu = $('#context-menu');
    // menu.css('left', (render_x + 'px'));
    // menu.css('top', (render_y + 'px'));
    // menu.html('');

    $.ajax({
      url: $.data($(event.target).closest(".context-menu-container")[0], 'contextMenuUrl'),
      data: $(event.target).closest('form').first().find('input:not(.easy-autocomplete-tag input)').serialize(),
      success: function(data, textStatus, jqXHR) {
        menu.html(data);
        EASY.contextMenu.contextMenuCalculatePosition(event,menu);
        initEasyAutocomplete();
      }
    });
  }

  EASY.contextMenu.contextMenuPositionSubmenu = function (menu, sub_selector, window_height, window_width) {
    menu.find(sub_selector).each(function(index){
      var $this = $(this);
      var rect = this.getBoundingClientRect();
      var parect = this.parentElement.getBoundingClientRect();
      var a = (rect.top + rect.height - window_height);
      var b = (rect.left + rect.width - window_width);
      var max = rect.height - parect.height;
      if(a > 0){
        if(a > max){
          $this.css('top', -max);
        }else{
          $this.css('top', -a);
        }
      }
      if(b > 0){
        $this.css('left', '-99%');
        //$this.css('left', 'auto');
      };
    });
  };

  EASY.contextMenu.contextMenuCalculatePosition = function (event, menu) {
    var main =  ERUI.main;
    var mouse_x = event.pageX;
    var mouse_y = event.pageY;
    var mouse_y_client = event.clientY;
    var render_x = mouse_x;
    var render_y = mouse_y;
    var dims;
    var menu_width;
    var menu_height;
    var window_width;
    var window_height;
    var max_width;
    // var max_height;
    var topmenu_height;
    var max_height_client;
    var max_height_reverse;

    menu_width = menu.width();
    menu_height = menu.height();
    max_width = mouse_x + menu_width;
    // max_height = mouse_y + menu_height;
    max_height_client = mouse_y_client + menu_height;
    topmenu_height = ERUI.topMenu[0].offsetHeight;
    max_height_reverse = menu_height + topmenu_height;

    window_width = main.width();//ws.width;
    window_width = windowSize().width;//ws.width;

    window_height = document.documentElement.clientHeight;
    /* display the menu above and/or to the left of the click if needed */
    if (max_width > window_width) {
      render_x -= menu_width;
      menu.addClass('reverse-x');
    } else {
      menu.removeClass('reverse-x');
    }
    if (max_width + menu_width > window_width) {
      menu.addClass('reverse-submenu-x');
    } else {
      menu.removeClass('reverse-submenu-x');
    }
    // if (max_height > window_height) {
    if (max_height_client > window_height && mouse_y > max_height_reverse) {
      render_y -= menu_height;
      menu.addClass('reverse-y');
    } else {
      menu.removeClass('reverse-y');
    }
    // if (render_x <= 0)
    //     render_x = 1;
    // if (render_y <= 0)
    //     render_y = 1;
    // if (render_y < -60) {
    //     render_y = 1;
    // } else if (-60 < render_y < 0) {
    //     render_y = -1;
    // }

    // fallback on mobile devices
    // mobile devices does not have event "mouseDown" but "touchstart", so variables render_x and render_y are undefined
    if (!render_x || !render_y) {
      var $targetOffset = $(event.target).offset();
      render_x = $targetOffset.left;
      render_y = $targetOffset.top;
    }

    menu.css('left', (render_x + 'px'));
    menu.css('top', (render_y + 'px'));
    menu.show();

    EASY.contextMenu.contextMenuPositionSubmenu(menu, 'li.folder > ul', window_height, window_width);


    //if (window.parseStylesheets) { window.parseStylesheets(); } // IE

  };

  EASY.contextMenu.contextMenuRightClick = function (event) {
    if (!$(event.target).closest(".context-menu-container")[0]) {
      return;
    }
    var ctx_url = $.data($(event.target).closest(".context-menu-container")[0], 'contextMenuUrl');
    if (ctx_url === '')
      return;
    var target = $(event.target);
    if (target.is('a') && !target.hasClass('icon-more-horiz') && !target.hasClass('js-contextmenu') && !target.parents('tr').hasClass('context-menu-selection')) {
      return;
    }
    var tr = target.parents('tr').first();
    if (!tr.hasClass('hascontextmenu')) {
      return;
    }
    event.preventDefault();
    if (!contextMenuIsSelected(tr)) {
      contextMenuUnselectAll();
      contextMenuAddSelection(tr);
      contextMenuSetLastSelected(tr);
    }
    contextMenuShow(event);
  };

  EASY.contextMenu.contextMenuClick = function (event) {
    var target = $(event.target);
    var lastSelected;

    if ((target.is('a') && target.hasClass('submenu')) ||
      target.parents().hasClass('easy-autocomplete-tag')) {
      event.preventDefault();
      return;
    }
    if (target.is('input') && !target.closest('.checkbox').length) {
      return;
    }
    $('#context-menu').hide();
    if (target.is('a') || target.is('img') || target.hasClass('expander') || target.hasClass('expander-root')) {
      return;
    }
    if (event.which === 1 || (navigator.appVersion.match(/\bMSIE\b/))) {
      var tr = target.parents('tr').first();
      if (tr.length && tr.hasClass('hascontextmenu')) {
        // a row was clicked
        if (target.is('td.checkbox')) {
            // the td containing the checkbox was clicked, toggle the checkbox
            target = target.find('input').first();
            target.prop("checked", !target.prop("checked"));
        }
        if (target.is('input')) {
          // a input may be clicked
          if (target.is('input[type="radio"]')) {
            contextMenuUnselectAll();
            if (!target.prop('checked')) {
              contextMenuAddSelection(tr, target);
            }
          }
          else if (target.prop('checked')) {
            contextMenuAddSelection(tr);
          } else {
            EASY.contextMenu.contextMenuRemoveSelection(tr);
          }
        } else {
          if (event.ctrlKey || event.metaKey) {
            contextMenuToggleSelection(tr);
          } else if (event.shiftKey) {
            lastSelected = $('.cm-last').first();
            if (lastSelected.length) {
              var toggling = false;
              $('.hascontextmenu').each(function () {
                if (toggling || $(this).is(tr)) {
                  contextMenuAddSelection($(this));
                }
                if ($(this).is(tr) || $(this).is(lastSelected)) {
                  toggling = !toggling;
                }
              });
            } else {
              contextMenuAddSelection(tr);
            }
          } else {
            contextMenuUnselectAll();
            contextMenuAddSelection(tr, target);
          }
          contextMenuSetLastSelected(tr);
        }
      } else {
        // click is outside the rows
        if (contextMenuRegister.length > 0) {
          if (!target.is('a') || !(target.hasClass('disabled') || target.hasClass('submenu')) || target.is('input')) {
            if (!target.closest(".ui-dialog-content").is('*')) {
              contextMenuUnselectAll();
            }
          }
        }
      }
    }
  };

  EASY.contextMenu.init = function(url, element) {
    var context_menu_parent = $(element);
    if (context_menu_parent[0]) {
      var has_el_context_menu = (url !== '');
      context_menu_parent.each(function () {
        $.data(this, 'contextMenuUrl', url);
        $(this).addClass("context-menu-container");
      });
      contextMenuCreate();
      if (!contextMenuObserving) {
        ERUI.document.click(EASY.contextMenu.contextMenuClick);
        if (has_el_context_menu) {
          ERUI.document.contextmenu(EASY.contextMenu.contextMenuRightClick);
        }
        contextMenuObserving = true;
      }
    }
  };

  EASY.contextMenu.toggleIssuesSelection = function (el) {
    var boxes = $(el).parents('form').find('input[type=checkbox]:not(.toggle-selection):visible');
    var all_checked = true;
    boxes.each(function () {
      if (!$(this).prop('checked')) {
        all_checked = false;
      }
    });
    boxes.each(function () {
      var $this = $(this);
      if (all_checked) {
        $this.prop('checked', false);
        $this.parents('tr').removeClass('context-menu-selection');
      } else if (!$(this).prop('checked')) {
        $this.prop('checked', true);
        $this.parents('tr').addClass('context-menu-selection');
      }
    });
  };

  EASY.contextMenu.contextMenuRemoveSelection = function (tr, target) {
    tr.removeClass('context-menu-selection');
    contextMenuCheckSelectionBox(tr, false, target);
    contextMenuRegister = $.grep(contextMenuRegister, function (value) {
      return value != tr.attr('id');
    });
  };

  // fallback for redmine plugins
  window.contextMenuInit = EASY.contextMenu.init;
});
