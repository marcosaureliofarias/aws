$.extend(window.ERUI, {
  init: function () {
    ERUI.document = $(document);
    ERUI.html = $("html");
    ERUI.window = $(window);
    ERUI.body = $("body");
    ERUI.main = $("#main");
    ERUI.content = $("#content");
    ERUI.sidebar = $("#sidebar,#easy_grid_sidebar");
    ERUI.topMenu = $("#top-menu");
    ERUI.onboardingBar = $(".epm_onboarding");
    ERUI.header = $("#header");
    ERUI.pageTabs = $("#easy_page_tabs");
    ERUI.mainMenu = $("#main-menu");
    ERUI.scrollTop = $(window).scrollTop();
    ERUI.formActions = $(".form-actions").not(".wiki .form-actions, #filter_buttons");
    ERUI.tableScrolls = $(".autoscroll").not(".easy-printable-template-page .autoscroll");

    EASY.schedule.late(function () {
      if (ERUI.mobileScreen()) {
        return;
      }

      ERUI.tableScrolls.toArray().forEach(autoscroll => {
        new PerfectScrollbar(autoscroll, {
          includePadding: true,
          suppressScrollY: true,
          useSelectionScroll: true,
          overideTouchPropagation: true
        });
      });
    });

    ERUI.tableHeads = $("" +
       "table.list:not(.no-table-head) > thead:first-child").not("" +
       ".easy-printable-template-page table.list > thead, " +
       "#ajax-modal table.list > thead, " +
       ".dmsf_list > thead" +
      "");
    ERUI.backToTop = $("#back_to_top");
    ERUI.serviceBarComponentBody = $("#easy_servicebar_component_body");
    ERUI.boxPadding = ERUI.content.css("paddingLeft").slice(0, -2);

    $(document).on("easy_pagemodule_new_dom", function (event) {
      $(event.target).trigger("erui_new_dom");
    });
  },

  /**
   * detects resolution for mobile devices, same as SASS does. Fallbacks to backend implementation in case of problem.
   * @returns {boolean|*} true for mobile screen
   */
  mobileScreen: function () {
    let sassScreenBreakpoint = EASY.getSassData("breakpoint-small") || "0px";
    sassScreenBreakpoint = parseInt(sassScreenBreakpoint.replace("px", ""));
    if (sassScreenBreakpoint > 0) {
      return window.innerWidth < sassScreenBreakpoint;
    }

    console.warn("resolution based on SASS breakpoint doesn't work");
    return ERUI.isMobile; // fallback to implementation of "device" resolution sent from the backend
  }
});

EASY.schedule.main(ERUI.init, 4);

