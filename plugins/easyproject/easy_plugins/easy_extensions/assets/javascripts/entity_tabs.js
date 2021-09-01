/*
  You can use events, triggered when tab is changed.
  Events are triggered on linksContext element.

  Examples:
  $(".entity-tabs").on('entity-tabs:before-tab-switch', function(event, container, link, id){
    alert('New tab id: ' + id);
  });

  $("#issue-detail").find(".entity-tabs").on('entity-tabs:before-tab-switch', function(event, container, link, id){
  });

  $(EntityTabs.linksContext).on('entity-tabs:before-tab-switch', function(event, container, link, id){
  });
*/

window.EntityTabs = {
  linksContext: ".entity-tabs",
  panelContext: ".entity-tabs-content",
  dialog_head: ".ui-dialog-title",

  init: function (tabsContext) {

    if (this.linksInModalHead()) {
      var $linksContainer = $(this.dialog_head).find(this.linksContext);
    } else {
      $linksContainer = $('#' + tabsContext).find(this.linksContext);
    }

    $linksContainer.data('tabs-context', tabsContext);

    if (this.lastTab($linksContainer)) {
      var $link = $linksContainer.find('a[data-tab-id="' + this.lastTab($linksContainer) + '"]');

      // Tab could not exist
      if ($link.length) {
        $link.click();
        return;
      }
    }

    // Fallback to first tab
    $linksContainer.find("a").first().click();
  },

  linksInModalHead: function () {
    // return $(this.linksContext).parent().is($(this.dialog_head));
    return false;
  },

  linksContainer: function (link) {
    return link.closest(this.linksContext);
  },

  panelContainer: function (link) {
    if (this.linksInModalHead()) {
      return $('#' + this.tabsContext(this.linksContainer(link))).find(this.panelContext);
    } else {
      return link.closest(this.linksContext).parent().find(this.panelContext);
    }
  },

  tabsContext: function ($linksContainer) {
    return $linksContainer.data('tabs-context');
  },

  lastTab: function ($linksContainer) {
    if (typeof(Storage) !== "undefined") {
      return localStorage.getItem(this.tabsContext($linksContainer) + "-tab");
    }
  },

  saveTab: function (value, $linksContainer) {
    if (typeof(Storage) !== "undefined") {
      localStorage.setItem(this.tabsContext($linksContainer) + "-tab", value);
    }
  },

  // Show full journal history
  showHistory: function (link) {
    this.showTab(link, ".tab-history-content");
    var journals = $('.journal');
    for (var i = 0; i < journals.length; i++) {
      var that = $(journals[i]);
      if (that.hasClass('has-details')) {
        if (that.hasClass('has-notes')) {
          that.find('.details').removeClass('hidden');
          that.find('.expander').removeClass('hidden');
        }
        else {
          that.removeClass('hidden');
        }
      }
    }
  },

  // Only journal comments
  showComments: function (link) {
    this.showTab(link, ".tab-history-content");
    var journals = $('.journal');
    for (var i = 0; i < journals.length; i++) {
      var that = $(journals[i]);
      if (that.hasClass('has-details')) {
        if (that.hasClass('has-notes')) {
          that.find('.details').addClass('hidden');
          that.find('.expander').addClass('hidden');
        }
        else {
          that.addClass('hidden');
        }
      }
    }
  },

  // Load remote html first
  showAjaxTab: function (link, ajaxUrl) {
    var $link = $(link);

    var $panelContainer = this.panelContainer($link);

    var $content = $panelContainer.find("." + $link.data('tab-id') + "-content");

    this.showTab(link);
    var self = this;

    if (!$content.data("loaded")) {
      $.ajax(ajaxUrl).done(function (html) {
        $content.html(html);
        $content.data("loaded", "true");
        self.resetPosition($content);
        $content.trigger('easy_entitytab_new_dom');
      });
    }

  },

  showTab: function (link, id) {
    var $link = $(link);

    if (typeof(id) === "undefined") {
      id = "." + $link.data('tab-id') + "-content";
    }

    var $linksContainer = this.linksContainer($link);
    $linksContainer.trigger('entity-tabs:before-tab-switch', [$linksContainer, link, id]);

    var $panelContainer = this.panelContainer($link);

    $linksContainer.find("a").removeClass("selected");
    $panelContainer.children().addClass("hidden");

    $(link).addClass("selected");
    $panelContainer.find(id).removeClass("hidden");

    this.saveTab($link.data('tab-id'), $linksContainer);
    $linksContainer.trigger('entity-tabs:after-tab-switch', [$linksContainer, link, id]);

    if (typeof(EASY.utils.initGalereya) === "function") {
      EASY.utils.initGalereya($('.thumbnails:visible'));
    }
    this.resetPosition($panelContainer);
  },

  resetPosition: function ($dialogPart) {
    var $dialog = $dialogPart.closest(".ui-dialog-content");
    if ($dialog.length !== 0) {
      //$dialogPart.closest(".ui-dialog-content").dialog('widget').position({my: "center", at: "center", of: window});
    }
  }
};
