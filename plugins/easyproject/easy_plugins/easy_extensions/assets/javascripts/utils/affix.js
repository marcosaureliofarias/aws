window.affix = {
  sass:{
    boxPadding: EASY.getSassData('box-padding', 24, true)
  },
  register: [],
  enabled: {
    tableScrollbars: false,
    sidebar: false,
    formActions: false
  },
  prepareHeads: function ($theads) {
    $theads.each(function () {
      var css = [];
      var $this = $(this);
      var $rows = $this.find('tr');
      $rows.each(function () {
        var $this = $(this);
        var $parent = $this.parent();
        var $cells = $this.find('th,td');

        $cells.each(function (index) {
          var $this = $(this);
          css[index] = {
            paddingTop: $this.css("paddingTop"),
            paddingRight: $this.css("paddingRight"),
            paddingBottom: $this.css("paddingBottom"),
            paddingLeft: $this.css("paddingLeft")
          };
        });

        $this.detach();
        $cells.each(function (index) {
          var $this = $(this);
          $this.append('<div class="affix-cell-wrap" style="padding:' + css[index].paddingTop + ' ' + css[index].paddingRight + ' ' + css[index].paddingBottom + ' ' + css[index].paddingLeft + '; z-index: 1;">' + $this.html() + '</div>');
          $this.find('.affix-cell-wrap .editable-parent span.icon-edit').remove();
        });
        $parent.append($this);
      });
    });
    return $theads;
  },
  recalculateHeads: function ($theads) {
    return;
  },
  preInit: function () {
    affix.register['main'] = false;
    affix.register['document'] = false;
    affix.register['topMenu'] = false;
    affix.register['sidebar'] = false;
    affix.register['tableScrolls'] = false;
    affix.register['tableHeads'] = false;
    // affix.register['formActions'] = false;
    affix.prepareHeads(ERUI.tableHeads);
    $(document).on("erui_interface_change_horizontal", function () {
      affix.recalculateHeads(ERUI.tableHeads);
    });
    affix.init(true);
  },
  reInit: function () {
    affix.init(false);
  },
  init: function (reset) {
    affix.register['window'] = {height: window.innerHeight};
    if (!$.fx.off && !ERUI.isMobile) {
      if (ERUI.main && ERUI.main.length > 0) {
        var main = {
          element: ERUI.main,
          position: ERUI.main[0].getBoundingClientRect(),
          scroll: 0
        };
        affix.register['main'] = main;
      }

      if (ERUI.html && ERUI.html.length > 0) {
        var document = {
          element: ERUI.html,
          position: ERUI.html[0].getBoundingClientRect(),
          scroll: 0
        };
        affix.register['document'] = document;
      }

      if (ERUI.topMenu && ERUI.topMenu.length > 0) {
        var topMenu = {};
        topMenu.element = ERUI.topMenu;
        topMenu.position = topMenu.element[0].getBoundingClientRect();
        affix.register['topMenu'] = topMenu;
      }

      if (ERUI.sidebar && ERUI.sidebar.length > 0 && reset) {
        var sidebar = {};
        sidebar.element = ERUI.sidebar;
        sidebar.position = sidebar.element[0].getBoundingClientRect();
        sidebar.fix = {};
        sidebar.attached = affix.register['sidebar'].attached || false;
        sidebar.fix.element = sidebar.element.find('#sidebar_inner,#easy_grid_sidebar_inner').not('.edit');
        if (sidebar.fix.element && sidebar.fix.element.length > 0) {
          sidebar.fix.position = sidebar.fix.element[0].getBoundingClientRect();
          sidebar.fix.parent = {};
          sidebar.fix.parent.element = sidebar.fix.element.parent();
          if (sidebar.fix.parent.element && sidebar.fix.parent.element.length > 0) {
            sidebar.fix.parent.position = sidebar.fix.parent.element[0].getBoundingClientRect();
            sidebar.fix.width = sidebar.fix.element[0].clientWidth;
            sidebar.fix.next = sidebar.fix.element.next();
            if (reset) {
              sidebar.fix.element.css({
                zIndex: 2,
                position: 'relative',
                willChange: 'transform',
                width: sidebar.fix.width,
                MsTransform: 'translate(0,0)',
                WebkitTransform: 'translate(0,0)',
                transform: 'translate(0,0)'
              });
            }
            affix.enabled.sidebar = true;
            sidebar.offset = 20;
            affix.register['sidebar'] = sidebar;
          }
        }

        var sideScrollEl = ERUI.sidebar.find('#sidebar_content, #easy_grid_sidebar_content').not('.edit');
        if (sideScrollEl && sideScrollEl.length > 0) {
          var footerEl = sideScrollEl.next('#sidebar_footer');
          var footerHeight = footerEl.outerHeight();
          var windowHeight = ERUI.window.outerHeight();
          ERUI.headerHeight = ERUI.header.outerHeight();
          var headerHeight = ERUI.headerHeight;
          ERUI.pageTabsHeight = ERUI.pageTabs.outerHeight();
          ERUI.onboardHeight = ERUI.onboardingBar.outerHeight();
          affix.sideScrollEl = sideScrollEl;
          affix.sideScrollElOffs = sideScrollEl[0].offsetTop;
          var sidebarOffsTop = ERUI.sidebar.children().first()[0].offsetTop;
          ERUI.sidebarOffsTop = sidebarOffsTop;
          var sideScrollElHight = windowHeight - ERUI.sidebar[0].offsetTop - affix.sideScrollElOffs - affix.sass.boxPadding - 1 ;
          ERUI.sideScrollElHight = headerHeight ? sideScrollElHight : (sideScrollElHight);

          sideScrollEl = sideScrollEl.children('.easy-scroller');
          ERUI.sideScrollEl = sideScrollEl;
          sideScrollEl.children().first().css({paddingBottom: footerHeight + this.sass.boxPadding});
          sideScrollEl.css({
            height: ERUI.sideScrollElHight,
            overflow: 'hidden',
            position: 'relative'
          });

          sideScrollEl.each(function () {
            new PerfectScrollbar(this, {
              suppressScrollX: true,
              includePadding: true,
              wheelPropagation: true,
              swipePropagation: true
            });
          });

          footerEl.css({
            position: 'absolute',
            left: 0,
            right: 0,
            bottom: 0
          });
        }

      }

      if (ERUI.tableScrolls && ERUI.tableScrolls.length > 0) {
        var tableScrolls = {};
        tableScrolls.wrappers = {};
        tableScrolls.xbars = {};
        tableScrolls.wrappers.element = ERUI.tableScrolls;
        tableScrolls.wrappers.position = [];
        tableScrolls.xbars.element = [];
        tableScrolls.xbars.position = [];
        tableScrolls.xbars.element = tableScrolls.wrappers.element.children(".ps__rail-x");
        if(tableScrolls.wrappers.element.length === tableScrolls.xbars.element.length ) {
          tableScrolls.wrappers.element.each(function (index) {
            tableScrolls.wrappers.position[index] = tableScrolls.wrappers.element[index].getBoundingClientRect();
            tableScrolls.xbars.position[index] = tableScrolls.xbars.element[index].getBoundingClientRect();
          });
        }
        if (reset) {
          tableScrolls.xbars.element.css({
            willChange: 'transform',
            MsTransform: 'translate(0,0)',
            WebkitTransform: 'translate(0,0)',
            transform: 'translate(0,0)'
          });
          affix.register['tableScrolls'] = tableScrolls;
        }
      }

      if (ERUI.tableHeads && ERUI.tableHeads.length > 0) {
        var tableHeads = {};
        tableHeads.element = ERUI.tableHeads;
        tableHeads.parent = {};
        tableHeads.fake = {};
        tableHeads.position = [];
        tableHeads.parent.element = [];
        tableHeads.parent.position = [];
        tableHeads.fake.elements = [];
        tableHeads.element.each(function (index) {
          if (tableHeads.element[index].parentNode === null) {
            return;
          }
          tableHeads.parent.element[index] = tableHeads.element[index].parentNode;
          tableHeads.position[index] = tableHeads.element[index].getBoundingClientRect();
          tableHeads.parent.position[index] = tableHeads.parent.element[index].getBoundingClientRect();
          tableHeads.fake.elements[index] = $(this).find('.affix-cell-wrap');
          if (reset) {
            tableHeads.fake.elements[index].each(function () {
              this.style.willChange = 'transform';
              this.style.MsTransform = 'translate(0,0)';
              this.style.WebkitTransform = 'translate(0,0)';
              this.style.transform = 'translate(0,0)';
            });
          }
        });
        affix.register['tableHeads'] = tableHeads;
      }
    }
  },
  read: function () {
    var sidebar = affix.register['sidebar'];
    if (sidebar && sidebar.fix.element) {
      sidebar.position = sidebar.element[0].getBoundingClientRect();
      sidebar.fix.position = sidebar.fix.element[0].getBoundingClientRect();
      sidebar.fix.parent.position = sidebar.fix.parent.element[0].getBoundingClientRect();
    } else {
      affix.enabled.sidebar = false;
    }

    var tableScrolls = affix.register['tableScrolls'];
    if (tableScrolls && tableScrolls.wrappers.element) {
      tableScrolls.wrappers.element.each(function (index) {
        tableScrolls.wrappers.position[index] = tableScrolls.wrappers.element[index].getBoundingClientRect();
      });
    }
    var tableHeads = affix.register['tableHeads'];
    if (tableHeads && tableHeads.element) {
      tableHeads.element.each(function (index) {
        if (tableHeads.parent.element[index] === undefined)
          return;
        tableHeads.position[index] = tableHeads.element[index].getBoundingClientRect();
        tableHeads.parent.position[index] = tableHeads.parent.element[index].getBoundingClientRect();
      });
    }
  },
  tableScrolls: function () {
    var tableScrolls = affix.register['tableScrolls'];
    if (tableScrolls) {
      var scroller = affix.register['window'];
      tableScrolls.xbars.element.each(function (index) {
        var wrapperPosition = tableScrolls.wrappers.position[index];
        if(!wrapperPosition) return;
        var formBottomDistance = -1 * (scroller.height + 1 - wrapperPosition.top - wrapperPosition.height);
        if (formBottomDistance > 0) {
          this.style.MsTransform = 'translate(0,' + (-formBottomDistance) + 'px)';
          this.style.WebkitTransform = 'translate(0,' + (-formBottomDistance) + 'px)';
          this.style.transform = 'translate(0,' + (-formBottomDistance) + 'px)';
        } else {
          this.style.MsTransform = 'translate(0,0)';
          this.style.WebkitTransform = 'translate(0,0)';
          this.style.transform = 'translate(0,0)';
        }
      });
    }
  },
  tableHeads: function () {
    var tableHeads = affix.register['tableHeads'];
    if (tableHeads) {
      var menuPosition = affix.register['topMenu'].position;
      var mh;
      if (menuPosition) {
        mh = menuPosition.height;
      } else {
        mh = affix.register['main'].offsetTop;
      }
      tableHeads.element.each(function (index) {
        var wrapperPosition = tableHeads.parent.position[index];
        var formTopDistance = mh - wrapperPosition.top - 1;
        if (wrapperPosition.top < mh && wrapperPosition.top + wrapperPosition.height - 2 * tableHeads.position[index].height > mh) {
          tableHeads.fake.elements[index].each(function () {
            this.style.MsTransform = 'translate(0,' + (formTopDistance) + 'px)';
            this.style.WebkitTransform = 'translate(0,' + (formTopDistance) + 'px)';
            this.style.transform = 'translate(0,' + (formTopDistance) + 'px)';
            //this.style.opacity = '1';
          });
        } else {
          tableHeads.fake.elements[index].each(function () {
            this.style.MsTransform = 'translate(0,0)';
            this.style.WebkitTransform = 'translate(0,0)';
            this.style.transform = 'translate(0,0)';
            //this.style.opacity = '0';
          });
        }
      });
    }
  },
  sidebar: function () {
    if (affix.enabled.sidebar) {
      var topMenu = affix.register['topMenu'];
      var sidebar = affix.register['sidebar'];
      var position = sidebar.position.top - topMenu.position.height; //+ sidebar.offset;
      if (position < 0) {
        if (!sidebar.attached) {
          ERUI.document.trigger("erui_affix_sidebar_attached");
          sidebar.attached = true;
          sidebar.fix.element.css({
            position: 'fixed',
            top: topMenu.position.height + sidebar.offset + 'px'
          });
        }
      } else {
        if (sidebar.attached) {
          ERUI.document.trigger("erui_affix_sidebar_detached");
          sidebar.attached = false;
          sidebar.fix.element.css({
            position: 'relative',
            top: 'auto'
          });
        }
      }
    }
  }
};
