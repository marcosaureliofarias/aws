EasyGem.module.part("easyAgile", ['EasyWidget'], function () {
  "use strict";
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   * @constructor
   * @param {StickyLane} model
   * @param {String} [template]
   * @extends {EasyWidget}
   */
  function StickyLaneWidget(model, template) {
    this.children = [];
    this.template = template;
    if (!template) {
      this.template = window.easyTemplates.kanbanStickyLane;
    }
    this.$row = null;
    this.repaintRequested = true;
    this.model = model;
    this.model.register($.proxy(this.onChange, this));
    this.onChange();
    var self = this;
    $(window).on("resize", function () {
      self.repaintRequested = true;
    });
    $(document).on("easySidebarToggled", function () {
      self.repaintRequested = true;
    });
    this.model.kanbanRoot.register(
        /**
         * @param event
         * @param {Issue} issue
         */
        function (event, issue) {
          if (event === "possiblePhases") {
            this.$target.addClass("agile__sticky-lane--drop");
          }
          if (event === "cancelPossiblePhases") {
            this.$target.removeClass("agile__sticky-lane--drop");
          }
        }, this);
  }

  window.easyClasses.EasyWidget.extendByMe(StickyLaneWidget);

  /**
   * @override
   * @param {SwimLaneColWidget} child
   * @param {int} i
   */
  StickyLaneWidget.prototype.setChildTarget = function (child, i) {
    child.$target = this.$target.find(".col" + i);
  };

  /**
   * @return {number}
   */
  StickyLaneWidget.prototype.getColWidth = function () {
    return (100 / this.children.length) - 0.001;
  };
  StickyLaneWidget.prototype.onChange = function () {
    this.repaintRequested = true;
    this.children = [];
    for (var i = 0; i < this.model.cols.length; i++) {
      this.children.push(new window.easyClasses.agile.SwimLaneColWidget(this.model.cols[i], this, null, true, 3));
    }
  };

  StickyLaneWidget.prototype.destroy = function () {
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
    this.model.kanbanRoot.unRegister(this);
  };
  /**
   *
   * @override
   */
  StickyLaneWidget.prototype._functionality = function () {
    var _self = this;
    var dragDomain = this.model.kanbanRoot.dragDomain;
    var stickySelectName = "agile_sticky_select_for_"+ dragDomain.slice(1,-1);
    easyAutocomplete(stickySelectName,function (request,response) {
      var results = $.ui.autocomplete.filter(_self.model.possibleValues, request.term);
      response(results.slice(0, 15));
    }, function (event, ui) {
      if (ui.item && ui.item.id) {
        _self.model.changeValue(ui.item);
      }
    }, this.model.possibleValues[0], {activate_on_input_click: true, no_button: true});

    this.$target.find('input').attr('type','text');
    $(".agile__sticky_button_go-to_" + stickySelectName).on("click", function (event) {
      EasyGem.readAndRender(function () {
        const selectId = $('#' + event.currentTarget.dataset.select).val();
        return {
          anchorName: "[name='" + selectId + '_' + stickySelectName + "']",
          heightFromTop: $("#top-menu").outerHeight() * -1,
        }
      }, function (scrollToParams) {
        scrollTo(
            scrollToParams.anchorName,
            scrollToParams.heightFromTop
        )
      }, _self)
    });
  };

  StickyLaneWidget.prototype._refreshExpanded = function () {
    this.$row.toggle(this.expanded);
    this.$target.find("hr").toggle(!this.expanded);
    this.$target.find(".icon").toggleClass("icon-remove", this.expanded).toggleClass("icon-add", !this.expanded);
  };


  /**
   * @override
   */
  StickyLaneWidget.prototype.out = function () {
    var dragDomain = this.model.kanbanRoot.dragDomain;
    var stickySelectName = "agile_sticky_select_for_"+ dragDomain.slice(1,-1);
    var out = [];
    for (var i = 0; i < this.children.length; i++) {
      out.push(i);
    }
    return {cols: out, item: this.model.item, goTo: I18n.buttonGoTo, stickySelectName: stickySelectName};
  };

  window.easyClasses.agile.StickyLaneWidget = StickyLaneWidget;
});
