(function () {
  /**
   *
   * @constructor
   * @param {EasyWidget | String} widget
   * @param {jQuery} $positionTo
   * @param {number} [topDelta]
   * @param {number} [leftDelta]
   * @param {number} [minHeight]
   * @extends EasyWidget
   */
  function EasyTooltip(widget, $positionTo, topDelta, leftDelta, minHeight) {
    var delayTime = 500;
    this.magicLeftBarConstant = 20;
    this.minWidth = 150;
    this.minHeight = 265;
    if(minHeight){
      this.minHeight = minHeight;
    }
    this.suppress = false;
    this.childIsWidget = true;

    EasyTooltip.positionsTo = EasyTooltip.positionsTo || [];
    if (EasyTooltip.positionsTo.indexOf($positionTo) !== -1) {
      return;
    }
    this.children = [widget];
    this.$positionTo = $positionTo;
    if (!topDelta) {
      topDelta = 0;
    }
    if (!leftDelta) {
      leftDelta = 0;
    }

    this.topDelta = topDelta;
    this.leftDelta = leftDelta;
    var _self = this;

    var opened = false;
    var resolving = false;
    var enterTime = Date.now();
    var positions = [];

    function resolveTooltip() {
      if (!resolving || opened || _self.suppress)return;
      var maxTime = Date.now();
      if (maxTime - enterTime < delayTime) {
        window.setTimeout(resolveTooltip, 100);
        return;
      }
      var minTime = maxTime - delayTime - 100;
      var filteredPositions = [];
      for (var i = 0; i < positions.length; i++) {
        var position = positions[i];
        if (position.time > minTime) {
          filteredPositions.push(position);
        }
      }
      var delta = 0;
      for (i = 0; i < filteredPositions.length - 1; i++) {
        var prev = filteredPositions[i];
        var next = filteredPositions[i + 1];
        delta += Math.abs(prev.event.pageY - next.event.pageY);
        delta += Math.abs(prev.event.pageX - next.event.pageX);
      }
      if (delta < 60) {
        _self.init.apply(_self);
        opened = true;
        return;
      }
      window.setTimeout(resolveTooltip, 100);
    }

    $positionTo.on("mouseenter.issueAgileItem", function () {
      if (_self.suppress)return;
      $positionTo.on("mousemove.issueAgileItem", function (event) {
        if (opened) {
          var lastPosition = positions[positions.length - 1];
          if (!lastPosition)return;
          var delta = 0;
          delta += Math.abs(lastPosition.event.pageY - event.pageY);
          delta += Math.abs(lastPosition.event.pageX - event.pageX);
          if (delta > 80) {
            $positionTo.off("mousemove.issueAgileItem");
            resolving = false;
            if (opened) {
              _self.destroy();
              opened = false;
            }
            positions = [];
          }
        } else {
          positions.push({
            time: Date.now(),
            /** @type MouseEvent */
            event: event
          });
        }
      });
      enterTime = Date.now();
      resolving = true;
      window.setTimeout(resolveTooltip, 100);
    });
    $positionTo.on("mouseleave.issueAgileItem", function () {
      $positionTo.off("mousemove.issueAgileItem");
      resolving = false;
      if (opened) {
        _self.destroy();
        opened = false;
      }
      positions = [];
    });
  }

  window.easyClasses.EasyWidget.extendByMe(EasyTooltip);


  EasyTooltip.prototype.init = function () {
    if (!$.contains(document, this.$positionTo[0])) {
      return;
    }
    $(".easy-tooltip").remove();
    var offset = this.$positionTo.offset();
    var width = this.$positionTo.outerWidth();
    var height = this.$positionTo.outerHeight();
    var left = offset.left + width + this.leftDelta;
    if (window.innerWidth < left + this.minWidth) {
      left = window.innerWidth - this.minWidth;
    }
    this.$target = $(window.easyTemplates.easyToolTip).css({
      top: offset.top + height + this.topDelta,
      left: left,
      zIndex: 1500
    });
    $(document.body).append(this.$target);
    window.easyView.root.add(this);
    var child = this.children[0];
    if (typeof child.requestRepaint === "function") {
      child.requestRepaint();
    } else {
      this.childIsWidget = false;
      this.$target.html(child);
    }
    this.windowWidth = window.innerWidth - this.magicLeftBarConstant;
    // need to put method for position compution to next animation frame, to have proper tooltip dimensions
    setTimeout(() => {
      this.moveToScreen();
    }, 0)
  };

  EasyTooltip.prototype.destroy = function () {
    if (this.$target) {
      this.$target.remove();
    }
    window.easyView.root.remove(this);
  };

  /**
   * @override
   */
  EasyTooltip.prototype.repaint = function () {
    if (this.childIsWidget) {
      this.children[0].$target = this.$target;
      this.children[0].repaint();
    }
  };

  EasyTooltip.prototype.moveToScreen = function() {
    var proportions = {};
    EasyGem.readAndRender(function() {
        proportions.width = this.$target.outerWidth();
        if (proportions.width < this.minWidth) {
          proportions.width = this.minWidth;
        }
        proportions.height = this.$target.outerHeight();
        if (proportions.height < this.minHeight) {
          proportions.height = this.minHeight;
        }
        proportions.offset = this.$target.offset();
        proportions.windowWidth = this.windowWidth;
        proportions.columnWidth = this.$positionTo.outerWidth();
        proportions.columnOffset = this.$positionTo.offset();
        proportions.innerHeight = window.innerHeight;
        proportions.scrollTop = $(window).scrollTop();
      }, function() {
        if (proportions.windowWidth < proportions.offset.left + proportions.width) {
          this.$target.css({
            left:
              proportions.columnOffset.left -
              proportions.width -
              this.magicLeftBarConstant +
              this.leftDelta
          });
        }
        if (proportions.innerHeight + proportions.scrollTop < proportions.offset.top + proportions.height) {
          this.$target.css({
            top:
              proportions.innerHeight +
              proportions.scrollTop -
              proportions.height
          });
        }
      }, this);
  };


  window.easyClasses.EasyTooltip = EasyTooltip;
})();
