(function () {
  window.easyClasses = window.easyClasses || {};
  window.easyView = window.easyView || {};

  /**
   * for all root Widgets
   * @constructor
   * @extends ActiveCollection
   */
  function ViewRoot() {
    this.list = [];
    this._onChange = [];
    this._pageLoaded = false;
    this._repaintLoopRunning = false;
    this._repaintSensorRunning = false;
    this.onWindowScroll = [];
    this._onWrapHeightChange = [];
    var $window = $(window);
    this.$window = $window;
    var _self = this;
    this.hoverDropzone = null;
    this.draggedItem = null;

    function fireScroll() {
      EasyGem.readAndRender(function () {
        // noinspection JSPotentiallyInvalidUsageOfThis
        return this.$window.scrollTop();
      }, function (newTop) {
        if (this.actualWindowScroll === newTop) return;
        this.actualWindowScroll = newTop;
        for (var i = 0; i < this.onWindowScroll.length; i++) {
          this.onWindowScroll[i](this.actualWindowScroll);
        }
        this._recalculateRectangles();
      }, _self);

    }

    $window.scroll(fireScroll);

    // fix flickering
    window.addEventListener('wheel', function () {
      setTimeout(function () {
        fireScroll();
      }, 0);
    });

    $(function () {
      _self._pageLoaded = true;
      if (_self._onWrapHeightChange.length > 0) {
        _self._bindRepaintSensor();
      }
    });


    this.dragCollections = {};
    this.register(function () {
      if (!_self._repaintLoopRunning) {
        _self._repaintLoopRunning = true;
        window.requestAnimationFrame($.proxy(_self.repaint, _self));
      }
    });
  }

  window.easyClasses.ActiveCollection.extendByMe(ViewRoot);


  ViewRoot.prototype._bindRepaintSensor = function () {
    var _self = this;
    if (_self._repaintSensorRunning) {
      return;
    }
    _self._repaintSensorRunning = true;
    ResizeSensor($("#wrapper"), function () {
      for (var i = 0; i < _self._onWrapHeightChange.length; i++) {
        _self._onWrapHeightChange[i]();
      }
    });
  };

  ViewRoot.prototype.listenWrapHeightChange = function (callback) {
    this._onWrapHeightChange.push(callback);
    if (this._pageLoaded) {
      this._bindRepaintSensor();
    }
  };

  /**
   *
   * @param {String} domain
   * @param item
   * @param {number} priority
   */
  ViewRoot.prototype.addItemToDragCollection = function (domain, item, priority) {
    item.dropablePriority = priority;
    this.dropablesSorted = false;
    if (!this.dragCollections.hasOwnProperty(domain)) {
      this.dragCollections[domain] = [item];
    } else {
      this.dragCollections[domain].push(item);
    }
  };

  ViewRoot.prototype.removeItemFromDragCollection = function (domain, item) {
    if (!this.dragCollections.hasOwnProperty(domain)) return;
    var index = this.dragCollections[domain].indexOf(item);
    if (index !== -1) {
      this.dragCollections[domain].splice(item, 1);
    }
  };

  /**
   *
   * @param {String} domain
   * @param {*} draggedItem
   */
  ViewRoot.prototype.dragStartOnDomain = function (domain, draggedItem) {
    this.dropablesSorted = false;
    this.draggedItem = draggedItem;
    this.activeDomain = domain;
    this._recalculateRectangles();
  };

  ViewRoot.prototype._recalculateRectangles = function () {
    if (!this.activeDomain) return;
    var i, item;
    var clearList = [];
    var collection = this.dragCollections[this.activeDomain];
    for (i = 0; i < collection.length; i++) {
      item = collection[i];
      if (!item.$target || item.$target.parent) {
        clearList.push(item);
      }
    }
    for (i = 0; i < clearList.length; i++) {
      item = clearList[i];
      // IE check
      if (item.$target && item.$target[0].getClientRects().length) {
        var boundingRect = item.$target[0].getBoundingClientRect();
        item.dropableRectangle = {
          x: boundingRect.left + this.$window.scrollLeft(),
          y: boundingRect.top + this.$window.scrollTop(),
          width: boundingRect.width,
          height: boundingRect.height
        }
      } else {
        item.dropableRectangle = null;
      }
    }
    this.dragCollections[this.activeDomain] = clearList;
  };

  /**
   *
   * @param {String} domain
   */
  ViewRoot.prototype.dragStopOnDomain = function (domain) {
    if (this.hoverDropzone !== null) {
      this.hoverDropzone.setDropHover(false);
    }
    this.activeDomain = null;
  };

  ViewRoot.prototype.getCurrentDragTargetWidget = function (x, y) {
    if (!this.activeDomain) {
      throw "No drag started";
    }
    var list = this.dragCollections[this.activeDomain];
    if (!this.dropablesSorted) {
      list.sort(function (a, b) {
        return b.dropablePriority - a.dropablePriority;
      });
      this.dropablesSorted = true;
    }
    var i;
    for (i = 0; i < list.length; i++) {
      var item = list[i];
      if (item.dropableRectangle) {
        var r = item.dropableRectangle;
        if (r.x < x && r.x + r.width > x && r.y < y && r.y + r.height > y) {
          if (this.hoverDropzone !== item) {
            if (this.hoverDropzone !== null) {
              this.hoverDropzone.setDropHover(false);
            }
            this.hoverDropzone = item;
            item.setDropHover(true);
          }
          return item;
        }
      }
    }
    return null;
  };


  /**
   * request repaints of all widgets on all anim frames
   */
  ViewRoot.prototype.repaint = function () {
    var _self = this;
    var repaintImpl = function () {
      for (var i = 0; i < _self.list.length; i++) {
        _self.list[i].repaint();
      }
      window.requestAnimationFrame(repaintImpl);
    };
    repaintImpl();
  };

  /**
   * on scroll callback list new top position is in argument
   * @type {Array}
   */
  ViewRoot.prototype.onWindowScroll = [];

  /**
   *
   * @type {number}
   */
  ViewRoot.prototype.actualWindowScroll = 0;


  // singleton
  window.easyView.root = new ViewRoot();


})();
