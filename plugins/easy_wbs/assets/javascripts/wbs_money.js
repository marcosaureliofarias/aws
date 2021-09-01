(function () {
  var classes = window.easyMindMupClasses;

  /***
   *
   * @param {MindMup} ysy
   * @property {MindMup} ysy
   * @constructor
   */
  function WbsMoney(ysy) {
    /** @type {MindMup} */
    this.ysy = ysy;
    this.init(ysy);
  }

  WbsMoney.prototype.containerName = "mindmup__money";
  WbsMoney.prototype.containerSelector = ".mindmup__money";

  /***
   *
   * @param {MindMup} ysy
   */
  WbsMoney.prototype.init = function (ysy) {
    ysy.eventBus.register("BeforeServerClassInit", function () {
      ysy.toolbar.addChild(new MoneyButton(ysy, ysy.$menu));
    });
  };
  /** @type {string} */
  WbsMoney.prototype.extraMoneyTemplate =
      '\
        \
          <div class="mindmup__money-sum mindmup__money-item{{#sumIsPositive}}--positive{{/sumIsPositive}}{{#sumIsNegative}}--negative{{/sumIsNegative}}\
          {{#detailed}}mindmup__money-sum-detail{{/detailed}}">{{sum}}</div>\
          ';
  /***
   * @param {jQuery} $node
   * @param {boolean} selected
   * @param {ModelEntity} idea
   */
  WbsMoney.prototype.extraElement = function ($node, selected, idea) {
    var self = this;
    var $moneyContainer = $node.find(this.containerSelector);
    var html = Mustache.render(
        this.extraMoneyTemplate,
        this.extraMoneyOut(idea, selected)
    );
    if ($moneyContainer.length === 0) {
      html = '<div class="' + this.containerName + '">' + html + "</div>";
      jQuery(html).appendTo($node);
    } else {
      $moneyContainer.html(html);
    }
    $node.find(".mindmup__money-sum-detail").hammer().off("tap").on("tap", $.proxy(self.detailShow, {
      ysy: this.ysy,
      idea: idea,
      selected: selected
    }));
  };
  /***
   * @param {ModelEntity} idea
   * @param {boolean} selected
   * @return {Object}
   */
  WbsMoney.prototype.extraMoneyOut = function (idea, selected) {
    var ysy = this.ysy;
    var budgetType = ysy.settings.budgetType;
    var budget;
    var value = this.getValue(idea, budgetType);
    var sumIsNegative = false;
    var sumIsPositive = false;
    var showDetail = false;

    if (jQuery.isNumeric(value)) {
      budget = this.formatter(value, idea.width);
      if (selected) {
        showDetail = true;
      }
    } else {
      budget = "-";
    }
    if (budgetType) {
      if ((budgetType.includes('_costs_') && value !== 0) || value < 0) sumIsNegative = true;
      if (!budgetType.includes('_costs_') && value > 0) sumIsPositive = true;
    }
    return {
      sum: budget,
      sumIsPositive: sumIsPositive,
      sumIsNegative: sumIsNegative,
      detailed: showDetail
    };
  };

  /***
   * @param {ModelEntity} idea
   * @param {string} budgetType
   * @return {number} budget value
   */
  WbsMoney.prototype.getValue = function (idea, budgetType) {
    var nodeData = idea.attr.data;
    var nodes = this.ysy.mapModel.getCurrentLayout().nodes;
    var value;

    if (nodeData.hasOwnProperty('budgets') && nodeData.budgets.hasOwnProperty(budgetType)) {
      value = nodeData.budgets[budgetType];
    } else if (nodes.hasOwnProperty(idea.id)) {
      var node = nodes[idea.id];
      if (node.attr.data.hasOwnProperty('budgets')) {
        value = node.attr.data.budgets[budgetType];
      }
    }
    return value;
  };

  /***
   * fire event to open modal Budget with Overview selected
   */
  WbsMoney.prototype.detailShow = function () {
    if (!this.selected) return;
    this.ysy.eventBus.fireEvent('nodeBudgetDetailShow', this.idea, 'overview');
  };

  /***
   * number formatter
   * @param {number} value
   * @param {number} width
   * @return {string}
   */
  WbsMoney.prototype.formatter = function (value, width) {
    var ysy = this.ysy;
    if (value === 0) return "0";
    var units = ["", "k", "M", "G", "T", "P", "E", "Z", "Y"];
    value = Math.abs(value);
    var multiply = 1;
    if (width < 60) {
      multiply = 0.1;
    }
    var rounded;
    var divisor = 1;
    for (var i = 0; i < units.length; i++) {
      if ((value / divisor) < 1000) {
        if (i === 0) {
          rounded = this.roundTo(value, multiply * 10);
          break;
        }
        rounded = this.roundTo(value / divisor, multiply) + units[i];
        break;
      }
      if (i === (units.length - 1)) {
        rounded = this.roundTo(value / divisor, multiply) + units[i];
        break;
      }
      divisor *= 1000;
    }
    if (ysy.settings.selectedCurrency != null) {
      return rounded + ' ' + ysy.settings.selectedCurrency;
    }
    return rounded;
  };

  /***
   * round value to 1 decimal
   * @param {string} value
   * @param {string} multiply
   * @return {string}
   */
  WbsMoney.prototype.roundTo = function (value, multiply) {
    if ((value % 1) < 0.05) return Math.round(value).toString();
    if (value >= 100 * multiply) return Math.round(value).toString();
    return value.toFixed(1);
  };

  classes.WbsMoney = WbsMoney;

  //######################################################################################################################
  /***
   * Button, which shows and hides icons onto nodes
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @constructor
   */
  function MoneyButton(ysy, $parent) {
    this.$element = null;
    this.ysy = ysy;
    this.init(ysy, $parent);
  }

  MoneyButton.prototype.id = "moneyButton";

  /**
   *
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @return {MoneyButton}
   */
  MoneyButton.prototype.init = function (ysy, $parent) {
    var self = this;
    ysy.settings.budgetIsLoading = false;
    ysy.settings.moneyOn = ysy.storage.settings.loadBudget() || false;
    self.ysy.legends.otherBuilders = ysy.settings.moneyOn ? [] : ["project"];
    ysy.settings.cumulativeTasks = ysy.storage.settings.loadCumulativeType() || false;

    /*when wbs is first time rendered, call showBudget*/
    ysy.eventBus.register("TreeLoaded", function () {
      self.showBudget(ysy, true);
    });

    this.$element = $parent.find(".money-toggler");
    this.$moneyTooltip = $parent.find('.mindmup__money-tooltip');
    this.$element.on("click", function () {
      ysy.settings.moneyOn = !ysy.settings.moneyOn;

      /* calls a function that stores the settings in storage */
      ysy.eventBus.fireEvent('budgetToggled', ysy.settings.moneyOn);

      self.$moneyTooltip.toggleClass("hidden", !ysy.settings.moneyOn);
      self.$moneyTooltip.toggleClass("mindmup__menu-item", ysy.settings.moneyOn);
      self.ysy.legends.otherBuilders = ysy.settings.moneyOn ? [] : ["project"];
      self.showBudget(ysy, false)
    });
    this.$moneyTooltip.on("click", function (event) {
      ysy.settings.cumulativeTasks = !$(event.target).hasClass('active');
      ysy.settings.loadNewBudgets = true;

      self.$moneyTooltip.find('.money_cumulative-tasks').toggleClass('active', ysy.settings.cumulativeTasks);

      /* calls a function that stores the settings in storage */
      ysy.eventBus.fireEvent('cumulativeTypeToggled', ysy.settings.cumulativeTasks);

      ysy.repainter.forceRedraw();
    });
    return this;
  };

  /***
   *
   * @param {MindMup}ysy
   * @param {boolean} init
   */
  MoneyButton.prototype.showBudget = function (ysy, init) {
    var listener;
    var self = this;

    /*some partial on Budget modal require Javascript from money plugin */
    if (ysy.settings.moneyOn) {
      EasyGem.dynamic.jsTag(this.ysy.settings.paths.easyMoneyJS);
    }

    /***
     * @private
     * change setting about currency and type of money
     */
    var _moneyTypeChange = function () {
      var currency = $("#money_currency").val();
      var moneyType = $("#money_type").val();
      ysy.settings.budgetType = moneyType + "_" + currency;
      ysy.settings.selectedCurrency = currency;
      ysy.repainter.forceRedraw();
    };


    var $legendSelector = $(".mindmup-color-select");
    var $wbsBudget = $("#wbs_budget");
    var $currencyType = $("#money_currency");
    var budgetCurrencies = ysy.settings.budgetCurrencies;

    /*if true sets all event and add all about budget, if false clear all about budget */
    if (ysy.settings.moneyOn) {
      self.loadMoney(ysy, true);

      /*sets the budget in legend*/
      $legendSelector.append(new Option(ysy.settings.labels.legend.budget, "budget"));
      $legendSelector.val("budget");
      ysy.styles.setColor("budget");

      /*sets event listener to checking when wbs is rerendered load new additional data*/
      ysy.mapModel.addEventListener("layoutChangeComplete", listener = function () {
        self.loadMoney(self.ysy, false);
      });

      /*sets currency selector*/
      if (budgetCurrencies.length > 0) {
        $currencyType.children().remove();
        for (var i = 0; i < budgetCurrencies.length; i++) {
          const currency = budgetCurrencies[i];
          $currencyType.append(new Option(currency.name, currency.iso_code));
          if (currency.is_default || i === 0) {
            $currencyType.val(currency.iso_code);
          }
        }
      }

      $("#money_type").on("change", _moneyTypeChange);
      $("#money_currency").on("change", _moneyTypeChange);
    }
    else if (!init) {
      ysy.$container.find(".mindmup__money").remove();
      $legendSelector.val(ysy.styles.defaultStyle);
      $('.mindmup-color-select option[value="budget"]').remove();
      ysy.styles.setColor(ysy.styles.defaultStyle);
      ysy.mapModel.removeEventListener("layoutChangeComplete", listener, true);
      ysy.repainter.forceRedraw();
      $("#money_type").off("change", _moneyTypeChange);
      $("#money_currency").off("change", _moneyTypeChange);
    }

    $(this.$element).children().toggleClass("active", ysy.settings.moneyOn);
    $wbsBudget.toggleClass("mindmup__menu-item", ysy.settings.moneyOn);
    $wbsBudget.toggleClass("hidden", !ysy.settings.moneyOn);
    $currencyType.toggleClass("hidden", !ysy.settings.budgetEnabled);
    $currencyType.toggleClass("mindmup__menu-item", ysy.settings.budgetEnabled);
  };

  MoneyButton.prototype._render = function () {
    var ysy = this.ysy;
    var isActive = this.ysy.settings.moneyOn;
    this.$element.find("a").toggleClass("active", isActive);
    this.$moneyTooltip.toggleClass("hidden", !isActive);
    this.$moneyTooltip.toggleClass("mindmup__menu-item", isActive);
    this.$moneyTooltip.find('.money_cumulative-tasks').toggleClass('active', ysy.settings.cumulativeTasks);
  };

  /***
   * load money and sets data to nodes
   * @param {MindMup} ysy
   * @param {boolean} isNew
   */
  MoneyButton.prototype.loadMoney = function (ysy, isNew) {
    var currency = $("#money_currency").val();
    var moneyType = $("#money_type").val();

    /*if currency value is undefined sets default currency*/
    if (!currency && ysy.settings.budgetEnabled && ysy.settings.hasOwnProperty('budgetCurrencies')) {
      var currencies = ysy.settings.budgetCurrencies;
      if (currencies.length > 0) {
        currency = currencies[0].iso_code;
        for (var i = 0; i < currencies.length; i++) {
          if (currencies[i].is_default) {
            currency = currencies[i].iso_code;
          }
        }
      }
    }

    var budgetType = moneyType + "_" + currency;
    ysy.settings.budgetType = budgetType;
    ysy.settings.selectedCurrency = currency;
    var params = this._loadNodes(moneyType, currency);

    if (!params) {
      if (isNew) ysy.repainter.forceRedraw();
      return;
    }
    else {
      ysy.settings.budgetIsLoading = true;
      $.ajax({
        url: this.ysy.settings.paths.getBudget,
        type: "POST",
        data: params,
        dataType: "json",
        success: function (data) {
          var idea = ysy.idea;
          ysy.util.traverse(idea, function (node) {
            if (!node.attr.data.hasOwnProperty('budgets')) {
              node.attr.data.budgets = {};
            }

            var nodeBudgets = node.attr.data.budgets;
            var entityType = node.attr.entityType;
            var nodeId = node.attr.data.id;
            var entityData = data[entityType + 's'];

            if (entityData.hasOwnProperty(nodeId)) {
              nodeBudgets[budgetType] = entityData[nodeId][moneyType];
              node.attr.force = true;
            }

          });
          if (isNew) {
            ysy.repainter.forceRedraw();
          } else {
            idea.dispatchEvent("changed");
          }
          ysy.settings.budgetIsLoading = false;
          ysy.settings.loadNewBudgets = false;
        },
        error: function () {
          ysy.settings.budgetIsLoading = false;
        }
      });
    }
  };

  /***
   * Find nodes that do not have data
   * @param {string} moneyType
   * @param {string} currency
   * @return {object/false}
   * @private
   */
  MoneyButton.prototype._loadNodes = function (moneyType, currency) {
    var ysy = this.ysy;
    var nodes = this.ysy.mapModel.getCurrentLayout().nodes;
    var projectIds = [];
    var issueIds = [];
    var budgetType = ysy.settings.budgetType;
    var loadAll = ysy.settings.loadNewBudgets;
    var cumulativeTasks = ysy.settings.cumulativeTasks;

    for (var nodeIndex in nodes) {
      if (nodes.hasOwnProperty(nodeIndex)) {
        var node = nodes[nodeIndex].attr;
        var nodeData = node.data;

        if (loadAll || nodeData.id != null && (!nodeData.hasOwnProperty('budgets') || !nodeData.budgets.hasOwnProperty(budgetType))) {
          if (node.entityType === "project") projectIds.push(nodeData.id);
          if (node.entityType === "issue") issueIds.push(nodeData.id);
        }
      }
    }

    if (issueIds.length === 0 && projectIds.length === 0 || ysy.settings.budgetIsLoading) return false;
    return {
      non_cumulative_tasks: cumulativeTasks ? 0 : 1,
      with_real_profit: moneyType === "real_profit" ? 1 : 0,
      with_planned_profit: moneyType === "planned_profit" ? 1 : 0,
      with_costs: moneyType === "real_costs" ? 1 : moneyType === "planned_costs" ? 1 : 0,
      with_real_revenue: moneyType === "real_revenue" ? 1 : 0,
      with_planned_revenue: moneyType === "planned_revenue" ? 1 : 0,
      currency: currency,
      issue_ids: issueIds,
      project_ids: projectIds
    };
  };
  classes.MoneyButton = MoneyButton;
})();
