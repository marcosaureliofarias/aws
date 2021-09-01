EasyGem.module.part("easyAgile",['EasyWidget'],function (EasyWidget) {
  "use strict";
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   * @constructor
   * @param {SwimLane} model
   * @param {String} [template]
   * @param {boolean} [showTimes]
   * @extends {EasyWidget}
   */
  function SwimLaneWidget(model, template, showTimes) {
    this.children = [];
    this.template = template;
    this.expanded = true;
    if (!template) {
      this.template = window.easyTemplates.kanbanSwimLane;
    }
    this.$detail = null;
    this.$tooltip = null;
    this.$row = null;
    this.$clone = null;
    this.repaintRequested = true;
    this.model = model;

    for (var i = 0; i < this.model.cols.length; i++) {
      this.children.push(new SwimLaneColWidget(this.model.cols[i], this, null, showTimes));
    }
    this.top = null;
  }

  EasyWidget.extendByMe(SwimLaneWidget);

  /**
   * @override
   * @param {SwimLaneColWidget} child
   * @param {int} i
   */
  SwimLaneWidget.prototype.setChildTarget = function (child, i) {
    child.$target = this.$target.find(".col" + i);
  };

  /**
   * @return {number}
   */
  SwimLaneWidget.prototype.getColWidth = function () {
    return (100 / this.children.length) - 0.001;
  };

  SwimLaneWidget.prototype.destroy = function () {
    if (this.$header && this.$header.length !== 0) {
      window.easyView.sticky.remove(this.$header);
      this.$header.remove();
    }
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
  };

  /**
   *
   * @override
   */
  SwimLaneWidget.prototype._functionality = function () {
    var _self = this;
    this.$header = this.$target.find(".agile__col__title");
    _self.$row = this.$target.find(".agile__row");
    if (this.$header.length == 0) return;
    this.$header.addClass("sticky80");
    this.$header.addClass("sticky_swimlane");
    var root = _self.model.kanbanRoot;
    _self.expanded = root.isExpanded(_self.model.value + "_" + root.groupBy);

    var toggle = function () {
      _self.expanded = !_self.expanded;
      // if (_self.expanded) {
      //   _self.$target.find("hr").hide();
      // } else {
      //     _self.$target.find("hr").show();
      // }
      root.setIsExpanded(_self.model.value + "_" + root.groupBy, _self.expanded);
      _self._refreshExpanded(_self.$clone);
    };

    this.$header.click(toggle);

    window.easyView.sticky.add(this.$header, {
      topOffset: 30,
      onCloneCreated: function ($clone) {
        _self.$clone = $clone;
        _self._refreshExpanded($clone);
        $clone.click(toggle);
      }
    });
  };
  SwimLaneWidget.prototype._refreshExpanded = function ($clone) {
    if (this.expanded) {
      this.$row.show();
      this.$target.find("hr").hide();
    } else {
      this.$row.hide();
      this.$target.find("hr").show();
    }
    if ($clone) {
      $clone.find(".icon").toggleClass("icon-remove", this.expanded);
      $clone.find(".icon").toggleClass("icon-add", !this.expanded);
    }
    this.$target.find(".sticky_swimlane > .icon").toggleClass("icon-remove", this.expanded);
    this.$target.find(".sticky_swimlane > .icon").toggleClass("icon-add", !this.expanded);
  };


  /**
   * @override
   */
  SwimLaneWidget.prototype.out = function () {
    var dragDomain = this.model.kanbanRoot.dragDomain;
    var stickySelectName = "agile_sticky_select_for_"+ dragDomain.slice(1,-1);
    var out = [];
    for (var i = 0; i < this.children.length; i++) {
      out.push(i);
    }
    return { cols: out, iconType: this.model.iconType, name: this.model.name, anchorName: this.model.value + '_' + stickySelectName };
  };

  window.easyClasses.agile.SwimLaneWidget = SwimLaneWidget;

  /**
   *
   * @constructor
   * @param {IssuesCol} model
   * @param {EasyWidget} parent
   * @param {String} [template]
   * @param {boolean} [showTimes]
   * @param {int} [dropPriority]
   * @extends {EasyWidget}
   */
  function SwimLaneColWidget(model, parent, template, showTimes, dropPriority) {
    this.listWidget = new window.easyClasses.agile.ListWidget(model, false, "", null, showTimes, null,dropPriority);
    this.children = [this.listWidget];
    this.model = model;
    this.repaintRequested = true;
    this.parent = parent;
    this.template = template;
    if (!template) {
      this.template = window.easyTemplates.kanbanSwimLaneCol;
    }

    if (!this.model.agileRootModel.isGroupBySet()) {
      // in case of no swimlanes
      this.nameWidget = new window.easyClasses.agile.ColNameWidget(model, this.model.agileRootModel, null, true, showTimes);
      this.children.push(this.nameWidget);
    }

    var _self = this;
  }

  window.easyClasses.EasyWidget.extendByMe(SwimLaneColWidget);

  /**
   * @override
   */
  SwimLaneColWidget.prototype.out = function () {
    return {
      name: this.model.column.name,
      first: this.model.agileRootModel.isGroupBySet() ? false : this.model.issues.firstInGlobalColumn
    };
  };

  /**
   * @override
   */
  SwimLaneColWidget.prototype.setChildTarget = function (child, i) {
    if (i === 0) {
      child.$target = this.$target.find(".agile__col__contents");
    } else {
      child.$target = this.$target.find(".agile__col__title");
    }
  };

  window.easyClasses.agile.SwimLaneColWidget = SwimLaneColWidget;


  /**
   *
   * @constructor
   * @param {IssuesCol|AgileColumn} model
   * @param {String} [template]
   * @param {KanbanRoot} agileRootModel
   * @param {boolean} [isSticky]
   * @param {boolean} [showTimes]
   * @param {boolean} [showSortButton]
   * @extends {EasyWidget}
   */
  function ColNameWidget(model, agileRootModel, template, isSticky, showTimes, showSortButton) {
    if (showTimes === null) throw "show";
    this.agileRootModel = agileRootModel;
    this.children = [];
    this.repaintRequested = true;
    this.$detail = null;
    this.$tooltip = null;
    this.isSticky = isSticky;
    this.showSortButton = showSortButton;
    this.template = template;
    this.showTimes = showTimes;
    if (!template) {
      this.template = window.easyTemplates.kanbanColumnName;
    }
    this.model = model;
    this.updateTimes = false;
    var column = this.model.column || this.model;
    for (var i = 0; i < column.issuesList.length; i++) {
      column.issuesList[i].register(function () {
        column.recalculateTimes();
        this.updateTimes = true;
      }, this);
    }
  }

  EasyWidget.extendByMe(ColNameWidget);

  /**
   *
   * @type {boolean}
   */
  ColNameWidget.prototype.showSortButton = false;

  ColNameWidget.prototype.onNoRepaint = function () {
    if (this.updateTimes && this.showTimes) {
      this.repaintRequested = true;
      this.updateTimes = false;
    }
  };

  /**
   * @override
   */
  ColNameWidget.prototype.out = function () {
    var column = this.model.column || this.model;
    var out = {
      summableString: column.summableString,
      name: column.name
    };
    out.showSortButton = this.showSortButton;
    out.showTimes = this.showTimes;
    return out;
  };

  ColNameWidget.prototype.destroy = function () {
    if (this.isSticky && this.$target && this.$target.length !== 0) {
      window.easyView.sticky.remove(this.$target);
    }
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
  };

  ColNameWidget.prototype._functionality = function () {
    var _self = this;
    if (this.isSticky) {
      this.$target.addClass("sticky");
      window.easyView.sticky.add(this.$target, {
        onCloneCreated: function ($clone) {
          if (_self.showSortButton) {
            _self.$sortButton = $clone.find(".agile__col-sort");
            _self._bindSortButton();
          }
          _self.$detail = $clone.find(".agile__col__title__details");
          _self.$tooltip = $clone.find(".tooltip");
          if (_self.$tooltip.html() !== "") {
            _self.$detail.mouseenter(function () {
              _self.$tooltip.show();
            });
            $clone.mouseleave(function () {
              _self.$tooltip.hide();
            });
          } else {
            // _self.$detail.hide();
          }
        }
      });
    }
    if (this.showSortButton) {
      this.$sortButton = this.$target.find(".agile__col-sort");
      this._bindSortButton();
    }

    this.$detail = this.$target.find(".agile__col__title__details");
    this.$tooltip = this.$target.find(".tooltip");
    if (this.$tooltip.html() !== "") {
      this.$detail.mouseenter(function () {
        _self.$tooltip.show();
      });
      this.$target.mouseleave(function () {
        _self.$tooltip.hide();
      });
    } else {
      // this.$detail.hide();
    }


  };

  ColNameWidget.prototype._bindSortButton = function () {
    this.$sortButton.click($.proxy(function () {
      this.agileRootModel.sendReorder(this.model.issues, this.model.column);
    }, this));
  };


  window.easyClasses.agile.ColNameWidget = ColNameWidget;
});
