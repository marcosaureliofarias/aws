EasyGem.module.part("easyAgile", ['EasyWidget'], function () {
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   *
   * @param {Issue} issue
   * @param {ListWidget} listWidget
   * @param {bool} [isAvatar]
   * @constructor
   * @extends EasyWidget
   */
  function IssueItemWidget(issue, listWidget, isAvatar) {
    this.maxDistanceToClick = 30;
    this.timeToContextMenu = 1000;
    this.maxTimeToContextMenu = 4000;
    this.maxDistanceCancelingContextMenu = 50;
    this.issue = issue;
    this.listWidget = listWidget;
    this.maxDistance = 0;
    this.template = window.easyTemplates.ListItem;
    this.showTooltip = !!window.easyTemplates.issueCardWidget;
    this.children = [];
    this.repaintRequested = true;
    this.selected = false;
    this.$overlay = null;
    this.$a = null;
    this.modalOpenable = true;
    this.actualY = null;
    this.actualX = null;
    this.shiftKey = false;
    this.doScrollUp = false;
    this.doScrollDown = false;
    this.isPossibleTarget = false;
    this.hover = false;
    this.aTouched = false;
    this.isScrum = this._isScrum(listWidget);
    this.itemSettings = this._itemSettings();
    this.capacityAttribute = this._capacityAttribute();
    this.dragDomain = listWidget.model.agileRootModel.dragDomain;
    this.isPageModule = listWidget.model.agileRootModel.isPageModule;
    this.touchTimeout = null;
    this.clickTimeout = null;
    this.touchDrag = false;
    if (this._isNewIssue()) {
      this.issue.showCapacityAttribute = true;
    }
    if (!isAvatar) {
      this.issue.register(this.onChange, this);
      window.easyView.root.addItemToDragCollection(this.dragDomain, this, 2);
    }
    this.isAvatar = isAvatar;
    this.destroyed = false;
  }

  window.easyClasses.EasyWidget.extendByMe(IssueItemWidget);

  IssueItemWidget.prototype._functionality = function () {

    this.$cont = this.$target.find(".agile__card");
    if (this.isAvatar) return;
    this.$a = this.$target.find("a");
    this.setDropHover(this.hover);
    this.setWrapperHeight();
    this._select(this.selected);
    var _self = this;
    if (this.showTooltip) {
      if (this.issueCardWidget) {
        this.toolTip.destroy();
      } else {
        this.issueCardWidget = new window.easyClasses.IssueCardWidget(this.issue);
      }
      this.toolTip = new window.easyClasses.EasyTooltip(this.issueCardWidget, this.$target, -80);
      _self._suppressTooltipForAWhile();
    }
    if(!!this.issue.agile_column_filter_value){
      this.$cont.droppable({
        hoverClass: "agile__card__drop-hover",
        scope: "UserDrag",
        activeClass: "agile__card-droppable",
        drop: function (event, ui){
          if (!ui.draggable.context.lastChild.attributes[1].nodeValue) return
          const id = ui.draggable.context.lastChild.attributes[1].nodeValue
          const data = {
            assigned_to_id: id,
            sprint_id: _self.issue.easy_sprint_id
          }
          self.easyMixins.agile.root._sendChange(data, _self.issue, null, true, true, _self);
        }
      });
    }
    this.$target.off("contextmenu.listItem");
    this.$target.on("contextmenu.listItem", function (e) {
      if (ERUI.isMobile) return false;
      e.preventDefault();
      _self.actualX = e.pageX - $(window).scrollLeft();
      _self.actualY = e.pageY - $(window).scrollTop();
      _self._contextMenu(e);
      return false;
    });
    this.$target.find(".agile__capacity__button").off("click").on("click", function () {
      var ajaxData = {
        url: _self.issue.show_path + '.xml',
        method: 'PUT',
        data: {
          issue: {}
        }
      };
      ajaxData.data.issue[_self.capacityAttribute] = _self.$target.find(".easy_agile_rating").val();
      _self.issue.old = _self.issue[_self.capacityAttribute + "_raw"];
      var ajaxDone = {
        showCapacityAttribute: false
      };
      ajaxDone[_self.capacityAttribute] = _self.$target.find(".easy_agile_rating").val();
      ajaxDone[_self.capacityAttribute + "_raw"] = parseInt(_self.$target.find(".easy_agile_rating").val());
      ajaxDone[_self.capacityAttribute + "_int"] = parseInt(_self.$target.find(".easy_agile_rating").val());
      $.ajax(ajaxData).done(function () {
        _self.issue.set(ajaxDone);
        _self._capacityLoad(_self.issue, "input");
      });
    });
    this.$target.find('.agile__close__button').off('click').on('click', function(){
      _self.issue.set("showCapacityAttribute", false);
      _self.listWidget.repaintRequested = true;
    });
    if (this.issue.showCapacityAttribute) {
      $(_self.$target[0]).find('.agile__capacity__input').focus();
    }
    this.$target.off("mousedown.listItem");
    this.$target.on("mousedown.listItem", function (e) {
      _self.shiftKey = e.shiftKey;
      if (e.target.parentElement.tagName === "A") {
        _self.modalOpenable = false;
        if (e.which === 2) {
          return true;
        } else {
          _self.aTouched = true;
        }
      }
      if (e.target.tagName === "INPUT" || e.target.tagName === "BUTTON") {
        _self.modalOpenable = false;
        if (e.which === 1) {
          return true;
        }
      }
      e.preventDefault();
      if (e.which === 3 || (e.target.tagName === "SPAN" && e.target.dataset.contextMenu === "true")) {
        _self.modalOpenable = false;
        _self.actualX = e.pageX - $(window).scrollLeft();
        _self.actualY = e.pageY - $(window).scrollTop();
        _self._contextMenu(e);
      } else {
        _self.actualX = e.pageX - $(window).scrollLeft();
        _self.actualY = e.pageY - $(window).scrollTop();
        _self.down(e.pageX, e.pageY);
      }
      return false;
    });

    this.$target.off("touchstart.listItem");
    this.$target.on("touchstart.listItem", this.handleTouchStart.bind(this));
    this.$target.off("touchend.listItem");
    this.$target.on("touchend.listItem", this.handleTouchEnd.bind(this));
    this.$target.off("touchmove.listItem");
    this.$target.on("touchmove.listItem", function (e) {
      _self.modalOpenable = false;
      if (!_self.touchDrag) return true;
      e.preventDefault();
      var touch = e.originalEvent.touches[0];
      _self._suppressTooltipForAWhile();
      if (!touch) {
        return false;
      }
      _self.move(touch.pageX, touch.pageY);
      return false;
    });

    if (this.issue.error) {
      this.$cont.addClass("agile__card--error");
    }
  };

  IssueItemWidget.prototype.setWrapperHeight = function() {
    const dragDomain = document.querySelector(this.dragDomain);
    if (dragDomain) {
      dragDomain.style.minHeight = `${dragDomain.getBoundingClientRect().height}px`;
    }
  }

  IssueItemWidget.prototype.handleTouchStart = function(e) {
    this.touchTimeout = setTimeout(() => {
      e.preventDefault();
      this.touchDrag = true;
      if (e.target.parentElement.tagName === "A") {
        this.modalOpenable = false;
        this.aTouched = true;
      }
      if (e.target.tagName === "SPAN" && e.target.dataset.contextMenu === "true") {
        this.modalOpenable = false;
        this.actualX = e.pageX - $(window).scrollLeft();
        this.actualY = e.pageY - $(window).scrollTop();
        this._contextMenu(e);
        return false;
      }
      this._suppressTooltipForAWhile();
      var touch = e.originalEvent.touches[0];
      if (!touch) return false;
      this.actualX = touch.pageX - $(window).scrollLeft();
      this.actualY = touch.pageY - $(window).scrollTop();
      this.down(touch.pageX, touch.pageY, false);
      return false;
    }, 500);
  };

  IssueItemWidget.prototype.handleTouchEnd = function(e) {
    e.preventDefault();
    if (this.touchTimeout) {
      window.clearTimeout(this.touchTimeout);
    }
    this.touchDrag = false;
    this.up();
    return false;
  };

  IssueItemWidget.prototype._isScrum = function (listWidget) {
    if (listWidget.nameWidget) {
      if (listWidget.nameWidget.agileRootModel.paramPrefix === "issue_easy_sprint_relation") return true;
    }
    if (listWidget.model) {
      if (listWidget.model.agileRootModel.paramPrefix === "issue_easy_sprint_relation") return true;
    }
    return false;
  };
  IssueItemWidget.prototype._openModal = function () {
    if (window.testEnviroment) return;
    if(window.EasyVue && EasyVue.showModal ) {
      EasyVue.showModal("issue",this.issue.id);

      /*
      We need to set fixed height of agile wrapper element until agile is reloaded and rendered,
      because when user close modal, it reloads agile and if no height is set then page would jump to the start of
      document after reload.
      Setting height back to "auto" is in EasyVue.holdTargetWrapperHeight() method and it is called after agile render.
      */
      const agile = this.$target.closest(".agile")[0];
      const agileWrapper = agile.parentElement;
      if (!agileWrapper) return;
      EasyVue.modalData.openedFromElement = agileWrapper;
      EasyVue.modalData.pageOffsetY = window.pageYOffset;
      agileWrapper.style.height = `${agileWrapper.offsetHeight}px`;
    }
  };
  IssueItemWidget.prototype._capacityAttribute = function () {
    if (this.isScrum && !!this.itemSettings.capacity_attribute) {
      return this.itemSettings.capacity_attribute;
    }
    return "estimated_hours";
  };

  IssueItemWidget.prototype._itemSettings = function () {
    return this.listWidget.model.agileRootModel.settings;
  };

  IssueItemWidget.prototype._isNewIssue = function () {
    var settings = this.itemSettings;
    var issue = this.issue;
    if (settings.check_capacities != "1" || issue.agile_column_filter_value != -1 ||
        issue.read || issue[this.capacityAttribute] > 0) return false;
    return true;
  };

  IssueItemWidget.prototype._suppressTooltipForAWhile = function () {
    var _self = this;
    if (!this.toolTip) return;
    this.toolTip.suppress = true;
    if (this._suppressTooltipTimout) {
      window.clearTimeout(this._suppressTooltipTimout);
    }
    this._suppressTooltipTimout = window.setTimeout(function () {
      _self.toolTip.suppress = false;
    }, 1000);
  };

  IssueItemWidget.prototype.doScroll = function () {
    if (this.doScrollDown) {
      window.scrollBy(0, 9);
    } else if (this.doScrollUp) {
      window.scrollBy(0, -9);
    } else {
      return;
    }
    window.setTimeout($.proxy(this.doScroll, this), 100);

  };

  IssueItemWidget.prototype.down = function (x, y) {
    // this.startX = x;
    // this.startY = y;
    this.$dragedCard = this.issue;
    this.maxDistance = 0;
    this.startX = x - $(window).scrollLeft();
    this.startY = y - $(window).scrollTop();
    this.startTime = Date.now();
    this.actionActive = true;
    var _self = this;
    window.easyView.root.dragStartOnDomain(this.dragDomain, this);

    // create overlay div
    this.$overlay = $("<div>").css({
      position: "fixed",
      top: 0,
      left: 0,
      width: window.innerWidth,
      height: window.innerHeight,
      zIndex: 10000,
      cursor: "move"
    });
    $(document.body).append(this.$overlay);


    this.$overlay.on("mouseup.listItem", function (e) {
      e.preventDefault();
      _self.up();

    });
    if(window.testEnviroment){
      this.$overlay.on("mousemove.listItem", function (e) {
        e.preventDefault();
        _self.move(e.pageX, e.pageY);
      });
    }
    this.clickTimeout = setTimeout(() => {
    this.$overlay.on("mousemove.listItem", function (e) {
      e.preventDefault();
      _self.move(e.pageX, e.pageY);
    });}, 300)
  };
  IssueItemWidget.prototype.move = function (x, y) {
    if (!this.actionActive) return;
    this.modalOpenable = false;
    var $window = $(window);
    var scrollY = $window.scrollTop();
    var scrollX = $window.scrollLeft();

    if ((y - scrollY) < 80) {
      this.doScrollUp = true;
      this.doScroll();
    } else {
      this.doScrollUp = false;
    }
    var bottomPos = window.innerHeight - y + scrollY;
    var widthPosition = true;
    var $backlogs = $('.backlog-column');
    if ($backlogs.length > 0 && this.dragDomain != 'agileBacklog') {
      widthPosition = false;
      for (var i = 0; i < $backlogs.length; i++) {
        var backlog = $backlogs[i];
        if (backlog.offsetLeft < x && (backlog.offsetLeft + backlog.offsetWidth) > x) {
          widthPosition = true;
          break;
        }
      }

    }
    if (bottomPos < 100 && bottomPos > 0 && widthPosition) {
      this.doScrollDown = true;
      this.doScroll();
    } else {
      this.doScrollDown = false;
    }

    this.actualX = x - scrollX;
    this.actualY = y - scrollY;
    if (this.moveDistance() > 15 && !this.avatar) {
      this.createAvatar();
      this.listWidget.model.agileRootModel.firePossiblePhases(this.issue);
    }
    if (this.avatar) {
      this.moveAvatar();
    }
    this.currentDropTarget = window.easyView.root.getCurrentDragTargetWidget(x, y);
    if (this.currentDropTarget) {
      this.$target.hide();
      var targetCard = $(this.currentDropTarget.$target[0]);
      var blankCard = document.getElementById('agile__place_holder');
      if (!blankCard) {
        blankCard = "<div id='agile__place_holder' style='height: 100px'></div>";
      }
      if (targetCard.hasClass("agile__item")) {
        if (this.$dragedCard.agile_column_position > this.currentDropTarget.issue.agile_column_position || this.$dragedCard.agile_column_filter_value != this.currentDropTarget.issue.agile_column_filter_value) {
          $(blankCard).insertBefore(targetCard);
        } else {
          $(blankCard).insertAfter(targetCard);
        }
      } else if (blankCard) {
        $(blankCard).remove();
      }
    } else {
      $('#agile__place_holder').remove();
    }
  };
  IssueItemWidget.prototype.up = function () {
    this.doScrollDown = false;
    this.doScrollUp = false;
    if (this.clickTimeout) {
      window.clearTimeout(this.clickTimeout);
    }
    if (this.$overlay) {
      this.$overlay.remove();
      if (this.avatar) {
        this.avatar.destroy();
      }
      this.avatar = null;
    }
    if (this.modalOpenable && !event.ctrlKey && !event.metaKey ) {
      this._openModal();
    } else {
      this.modalOpenable = true;
    }
    window.easyView.root.dragStopOnDomain(this.dragDomain);
    this.listWidget.cancelPossiblePhases();
    this.actionActive = false;

    if (this.destroyed) return;
    $(this.$target).show();
    $('#agile__place_holder').remove();

    if (this.forceContextMenu) {
      this._contextMenu(e);
      return;
    }

    if (this.moveDistance() < this.maxDistanceToClick) {
      if (Date.now() - this.startTime < this.timeToContextMenu) {
        if (this.aTouched) {
          this._openModal();
          this.aTouched = false;
        } else {
          var last = window.easyView.root.lastSelectedIssueItemWidget;
          if (this.shiftKey && last && last !== this && last.listWidget === this.listWidget) {
            var startIndex = this.listWidget.children.indexOf(this);
            var endIndex = this.listWidget.children.indexOf(last);
            if (startIndex > endIndex) {
              var shiftIndex = startIndex;
              startIndex = endIndex;
              endIndex = shiftIndex;
            }
            for (var i = startIndex; i <= endIndex; i++) {
              this.listWidget.children[i]._select(true);
            }
          } else {
            this._select();
          }
        }
      } else if (Date.now() - this.startTime < this.maxTimeToContextMenu && this.maxDistance < this.maxDistanceCancelingContextMenu) {
        this._contextMenu(e);
      }
    } else {
      this._drop();
    }
    this.currentDropTarget = null;
  };

  IssueItemWidget.prototype.setDropHover = function (state) {
    if (this.destroyed) return;
    this.hover = state;
    if (state) {
      this.listWidget.setDropHover(true);
    } else {
      this.listWidget.setDropHover(false);
    }
  };

  IssueItemWidget.prototype.onChange = function () {
    this.repaintRequested = true;
  };
  IssueItemWidget.prototype._select = function (selected) {
    window.easyView.root.mapOfPossibleSelectedIssueItemWidgets = window.easyView.root.mapOfPossibleSelectedIssueItemWidgets || {};
    window.easyView.root.lastSelectedIssueItemWidget = window.easyView.root.lastSelectedIssueItemWidget || {};
    if (typeof selected === "undefined") {
      this.selected = !this.selected;
    } else {
      this.selected = selected;
    }
    if (this.selected) {
      window.easyView.root.mapOfPossibleSelectedIssueItemWidgets[this.issue.id] = this;
      window.easyView.root.lastSelectedIssueItemWidget = this;
      this.$cont.addClass("agile__card--selected");
    } else {
      this.$cont.removeClass("agile__card--selected");
    }
  };
  IssueItemWidget.prototype._contextMenu = function (event) {
    if (this.destroyed) return;
    var i;
    this.event = event;
    var _self = this;
    if (this._contextMenuOpened || this.listWidget.model.agileRootModel.contextMenuUrl === null) {
      return;
    }
    this._contextMenuOpened = true;
    this._suppressTooltipForAWhile();

    var selected = window.easyView.root.mapOfPossibleSelectedIssueItemWidgets;
    var selectedList = [];
    for (var key in selected) {
      if (!selected.hasOwnProperty(key) || !selected[key].selected) continue;
      selectedList.push(selected[key].issue.id);
    }
    selectedList.push(this.issue.id);

    $.ajax({
      url: this.listWidget.model.agileRootModel.contextMenuUrl,
      data: {
        ids: selectedList,
        show_story_points: true
      },
      success: function (data) {
        if (_self.destroyed) return;
        var closeContextMenu = function () {
          _self._contextMenuOpened = false;
          $(window).unbind("mousedown.contextMenu");
          $overlay.remove();
          $menu.remove();
        };
        _self.closeContextMenu = closeContextMenu;
        $("#context-menu").remove();
        var $menu = $("<div>");
        var $overlay = $("<div>").css({
          position: "fixed",
          top: 0,
          left: 0,
          width: window.innerWidth,
          height: window.innerHeight,
          zIndex: 1
        });
        $menu.attr("id", "context-menu");
        $menu.html(data);
        $menu.find(".context-menu-autocomplete").remove();
        window.setTimeout(function () {
          EASY.contextMenu.contextMenuCalculatePosition(_self.event, $menu);

          $(window).bind("mousedown.contextMenu", function (e) {
            if ($(e.target).closest("#context-menu").length == 0) {
              window.setTimeout(function () {
                closeContextMenu();
              }, 50);
            }
          });

          $menu.find(".agile__context__edit__atribute").off("click").on("click", function () {
            _self.issue.set("showCapacityAttribute", true);
            _self.listWidget.repaintRequested = true;
            closeContextMenu();
          });

          $menu.find("a").each(function (k, v) {
            var $a = $(v);
            if (v.href.indexOf("bulk_update") !== -1) {
              $a.mousedown(function (e) {
                e.preventDefault();
                e.stopPropagation();
                return false;
              }).mouseup(function (e) {
                e.preventDefault();
                e.stopPropagation();
                return false;
              }).click(function (e) {
                e.preventDefault();
                e.stopPropagation();
                _self.listWidget.model.agileRootModel.sendBulkUpdate(v.href, function () {
                  $(window).unbind("mousedown.contextMenu");
                  closeContextMenu();
                });
                return false;
              });

            }
          });
        }, 30);
        $(document.body).append($menu);
        // create overlay div

        $overlay.mousedown(function () {
          closeContextMenu();
        });

        $overlay.on("touchstart", function () {
          closeContextMenu();
        });
        $(document.body).append($overlay);
        window.initEasyAutocomplete();
      }
    });
  };

  IssueItemWidget.prototype._drop = function () {
    if (this.destroyed) return;
    if (!this.currentDropTarget) return;
    var targetIssues;
    var selected = window.easyView.root.mapOfPossibleSelectedIssueItemWidgets;
    this.selected = true;
    selected[this.issue.id] = this;

    var toProcess = {};
    this.isPossibleTarget = false;
    for (var key in selected) {
      if (!selected.hasOwnProperty(key)) continue;
      var sourceWidget = selected[key];
      if (!sourceWidget.selected) continue;
      var issue = sourceWidget.issue;

      var originalPosition = issue.agile_column_position;
      var sourceIssues = issue.issues;
      var newColumnPosition = null;
      var issueColModel;

      if (this.currentDropTarget.issue !== undefined) {
        issueColModel = this.currentDropTarget.listWidget.model;
      } else {
        issueColModel = this.currentDropTarget.model;
      }
      var phase = issueColModel.column.entityValue;
      if (!issueColModel.issueCanBePlacedHere(issue)) {

        continue;
      }
      if (this.dragDomain === "agileBacklog") {

        this._capacityLoad(issue, phase);
      }
      this.isPossibleTarget = true;

      if (this.currentDropTarget.issue !== undefined) {
        // drop target is ListWidget
        var targetIssue = this.currentDropTarget.issue;
        targetIssues = targetIssue.issues;
        var isPrev = targetIssues.moveIssueOntoThisIssue(issue, targetIssue);
        issue.next_item_id = isPrev ? null : targetIssue.id;
        issue.prev_item_id = isPrev ? targetIssue.id : null;
        issue["agile_column_filter_value"] = phase;
      } else {
        // drop target is ListItemWidget
        targetIssues = this.currentDropTarget.model.issues;
        var prevIssue;
        issue.prev_item_id = null;
        if (targetIssues.temporarySortedList.length !== 0) {
          prevIssue = targetIssues.temporarySortedList[targetIssues.temporarySortedList.length - 1];
          issue.prev_item_id = prevIssue.id;
          newColumnPosition = prevIssue.agile_column_position + 1;
        }
        issue.next_item_id = null;
      }
      issue["agile_column_filter_value"] = phase;
      (function (issue, sourceIssues, lastPosition) {
        issue.undo = function () {
          issue.agile_column_position = lastPosition;
          issue.issues.remove(issue);
          sourceIssues.add(issue);
        };
      })(issue, sourceIssues, originalPosition);

      if (newColumnPosition) {
        issue.agile_column_position = newColumnPosition;
      }
      toProcess[key] = {
        sourceIssues: sourceIssues,
        targetIssues: targetIssues,
        issue: issue
      };

    }
    for (key in toProcess) {
      if (!selected.hasOwnProperty(key)) continue;
      selected[key]._select(false);
      targetIssues = toProcess[key].targetIssues;
      sourceIssues = toProcess[key].sourceIssues;
      issue = toProcess[key].issue;
      if (targetIssues === sourceIssues) {

        $.proxy(this.listWidget.model.sendPositionChange(issue), this.listWidget.model);
        this.listWidget.requestRepaint();
      } else {
        sourceIssues.remove(issue);
        targetIssues.add(issue);
      }
    }
    if (this.currentDropTarget.children.length < 2 && phase != -1){
      this.listWidget.model.agileRootModel._fireChanges("groupBySet");
    }
    window.easyView.sticky.scheduleRebuild();
  };

  IssueItemWidget.prototype._capacityLoad = function (issue, phase) {
    if (!this.isScrum) return;
    var prevPhase = issue.agile_column_filter_value;
    var issueRating = 0;
    var settings = this.itemSettings;
    if (this.capacityAttribute === "estimated_hours") {
      issueRating = issue.estimated_hours_raw;
    } else if (this.capacityAttribute === "easy_story_points") {
      issueRating = issue.easy_story_points_raw;
    }

    if (phase === "input") {
      settings.sum_easy_agile_rating = settings.sum_easy_agile_rating - issue.old;
      settings.sum_easy_agile_rating = settings.sum_easy_agile_rating + issueRating;
    }
    // noinspection EqualityComparisonWithCoercionJS
    else if (prevPhase == -1 && phase != -1) {
      settings.sum_easy_agile_rating = settings.sum_easy_agile_rating - issueRating;
      issue.showCapacityAttribute = false;
      if (settings.sum_easy_agile_rating < 0) {
        settings.sum_easy_agile_rating = 0;
      }
    }
    // noinspection EqualityComparisonWithCoercionJS
    else if (prevPhase != -1 && phase == -1) {
      settings.sum_easy_agile_rating = settings.sum_easy_agile_rating + issueRating;
      if (issueRating === 0 || !issueRating) {
        issue.showCapacityAttribute = true;
      }
    }
    if (!issue.showCapacityAttribute) {
      this._capacityWidgetChange(settings.capacity, settings.sum_easy_agile_rating);
    }
    this.listWidget.repaintRequested = true;
  };

  IssueItemWidget.prototype._capacityWidgetChange = function (capacity, sumCapacity) {
    var elementCapacity = $("#current-load");
    var elementCapacityValue = elementCapacity.find('.load-value');
    if (sumCapacity < 0) sumCapacity = 0;
    elementCapacityValue.html(sumCapacity);
    var isNegative = sumCapacity > capacity;
    elementCapacity.toggleClass('color-positive', !isNegative);
    elementCapacity.toggleClass('color-negative', isNegative);
  };

  IssueItemWidget.prototype.moveDistance = function () {
    if (this.actualX == null) {
      return 0;
    }
    var distance = Math.sqrt(Math.pow(this.actualX - this.startX, 2) + Math.pow(this.actualY - this.startY, 2));
    if (distance > this.maxDistance) {
      this.maxDistance = distance;
    }
    return distance;
  };

  IssueItemWidget.prototype.destroy = function () {
    window.easyView.root.removeItemFromDragCollection(this.dragDomain, this);
    this.issue.unRegister(this);
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
    delete window.easyView.root.mapOfPossibleSelectedIssueItemWidgets[this.issue.id];
    this.issue = null;
    this.listWidget = null;
    this.destroyed = true;
    if (this.$overlay) {
      this.$overlay.remove();
      this.$overlay = null;
    }
    if (this.avatar) {
      this.avatar.destroy();
      this.avatar = null;
    }
    this.$a = null;
    if (this.toolTip) {
      this.toolTip.destroy();
      this.toolTip = null;
    }
    if (this.closeContextMenu) {
      this.closeContextMenu();
      this.closeContextMenu = null;
    }

    if (this._suppressTooltipTimout) {
      window.clearTimeout(this._suppressTooltipTimout);
    }
    this.toolTip = null;
  };

  IssueItemWidget.prototype.createAvatar = function () {
    if (this.destroyed) return;
    this.avatar = new IssueItemWidget(this.issue, this.listWidget, true);
    this.avatar.$target = this.$overlay;
    this.avatar.repaint();
    this.avatar.$cont.addClass("agile__card-avatar");
    var background = this.$cont.css("backgroundColor");
    if (background === "rgba(0, 0, 0, 0)" || background === "transparent") {
      background = "rgba(255, 255, 255, 0.5)";
    }
    this.avatar.$cont.css({
      position: "absolute",
      top: this.actualY,
      left: this.actualX,
      zIndex: -1,
      height: this.$target.height(),
      width: this.$target.closest(".agile__list").width(),
      backgroundColor: background
    });
  };

  IssueItemWidget.prototype.moveAvatar = function () {
    this.avatar.$cont.css({
      position: "absolute",
      top: this.actualY,
      left: this.actualX
    });
  };

  /**
   *
   * @override
   */
  IssueItemWidget.prototype.out = function () {
    return this.issue;
  };

  window.easyClasses.agile.IssueItemWidget = IssueItemWidget;

});
