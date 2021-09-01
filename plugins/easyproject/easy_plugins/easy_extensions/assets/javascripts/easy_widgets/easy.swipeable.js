$.widget("EASY.swipeable", $.EASY.Widget, {
  // Name is there for developers comfort especially in error reporting
  name: "Swipe detector and handler",

  currElement: null,

  hammer: null,

  parent: null,

  observer: null,

  _customInit: function () {
    this.currElement = this.element[0];
    this.parent = this.currElement.closest('.module-content');
    var observerDisabled = this.options.observerDisabled || false;

    // hammer initialization
    this.hammer = new Hammer(this.currElement);
    // attach events on swipes
    this.hammer.on("swiperight", this.callPrev.bind(this));
    this.hammer.on("swipeleft", this.callNext.bind(this));

    // mutation observer
    if (!observerDisabled && this.parent) {
      var config = {attributes: false, childList: true, subtree: false};
      this.observer = new MutationObserver(this.initializeWidget);
      this.observer.observe(this.parent, config);
    }
  },
  /**
   * @param {Array.<{target:HTMLElement}>} mutations
   */
  initializeWidget: function (mutations) {
    mutations.forEach(function (mutation) {
      var element = mutation.target.querySelector('.easy-calendar-listing-links');
      if (element) {
        $(element).swipeable();
      }
    });
  },

  // simulate click of next button
  callNext: function () {
    var $element = $(this.currElement);
    var $next = $element.find('a.next');
    if (!$next.length) return false;
    $next.click();
  },

  // simulate click of prev button
  callPrev: function () {
    var $element = $(this.currElement);
    var $prev = $element.find('a.prev');
    if (!$prev.length) return false;
    $prev.click();
  },

  _customDestroy: function () {
    this.hammer.destroy();
    var self = this;
    setTimeout(function () {
      self.observer.disconnect();
    }, 0);
  }
});

EASY.schedule.late(function () {
  $('.easy-calendar-listing-links').each(function () {
    $(this).swipeable();
  });
});
