window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.cashflow = ysy.pro.cashflow || {};
EasyGem.extend(ysy.pro.cashflow, {
  name: "CashFlow",
  styles: {
    positive: {textColor: "#484848", fontStyle: "12px Courier"},
    negative: {textColor: "#ff0000", fontStyle: "12px Courier"}
  },
  doNotCloseToolPanel: true,
  registeredOnLoader: false,
  buttonExtendee: {
    id: "cashflow",
    bind: function () {
      if (window.EASY && EASY.getSassData ){
        ysy.pro.cashflow.styles = {
          positive: {textColor: EASY.getSassData("resource-color-text", "#484848" , false), fontStyle: "12px Courier"},
          negative: {textColor: EASY.getSassData("resource-color-text-over-allocations", "#ff0000" , false), fontStyle: "12px Courier"}
        }
      }
      this.model = ysy.settings.cashflow;
      this._register(ysy.settings.resource);
       if (this.isOn()) {
        ysy.pro.cashflow.open();
      }
    },
    func: function () {
      if (!this.isOn()) {
        ysy.pro.cashflow.open();
      } else {
        ysy.pro.cashflow.close();
      }
       ysy.data.storage.savePersistentData('cashflow', ysy.settings.cashflow.active);
    },
    isOn: function () {
      return ysy.main.checkForStorageValue('cashflow', ysy.settings.cashflow.active);
    },
    isHidden: function () {
      return ysy.settings.resource.open;
    }
  },
  patch: function () {
    // do not load feature if there is no Cashflow button
    if (!$("#easy_gantt_menu").find("#button_cashflow").length) {
      ysy.pro.cashflow = null;
      return;
    }
    ysy.view.Toolbars.prototype.childTargets["CashFlowPanelWidget"] = "#cashflow_panel";
    ysy.proManager.register("initToolbar", this.initToolbar);
    ysy.settings.cashflow = new ysy.data.Data();
    ysy.settings.cashflow.init({
      _name: "CashFlow",
      active: false,
      open: false,
      activeCashflow: null,
      realLoaded: false,
      plannedLoaded: false
    });
    ysy.proManager.register("close", this.close);
    if (ysy.settings.global) {
      ysy.view.AllButtons.prototype.extendees.cashflow = this.buttonExtendee;
    } else {
      ysy.pro.toolPanel.registerButton(this.buttonExtendee);
    }

    ysy.pro.sumRow.summers.cashflow = {
      day: function (date, project) {
        if (!project.isProject) return 0;
        if (project.parent_id) return 0;
        if (project.start_date.isAfter(date)) return 0;
        if (project.end_date.isBefore(date)) return 0;
        if (project._shift) {
          date = moment(date).subtract(project._shift, "days");
        }
        var cashData = ysy.pro.cashflow.cashRenderer(project);
        return cashData[date.format("YYYY-MM-DD")] || 0;
      },
      week: function (first_date, last_date, project) {
        if (!project.isProject) return 0;
        if (project.parent_id) return 0;
        if (project.start_date.isAfter(last_date)) return 0;
        if (project.end_date.isBefore(first_date)) return 0;
        var sum = 0;
        var mover = moment(first_date);
        var cashData = ysy.pro.cashflow.cashRenderer(project);
        if (project._shift) {
          mover.subtract(project._shift, "days");
          last_date = moment(last_date).subtract(project._shift, "days");
        }
        while (mover.isBefore(last_date)) {
          var cash = cashData[mover.format("YYYY-MM-DD")];
          if (cash) sum += cash;
          mover.add(1, "day");
        }
        return sum;
      },
      formatter: ysy.pro.cashflow.formatter,
      entities: ["projects"],
      title: "CashFlow"
    };
  },
  open: function () {
    var setting = ysy.settings.cashflow;
    if (setting.setSilent("active", true)) {
      var cashflowClass = ysy.pro.cashflow;
      cashflowClass.showCashflow("real");
      ysy.view.bars.registerRenderer("project", this.outerRenderer);
      ysy.settings.sumRow.setSummer("cashflow");
      cashflowClass.eventId = gantt.attachEvent("onTaskClick", cashflowClass.showTooltip);
      ysy.proManager.closeAll(this);
      if (!this.registeredOnLoader) {
        this.registeredOnLoader = true;
        ysy.data.loader.register(function () {
          var typeCashflow = setting.activeCashflow;
          if (!setting.active) return;
          this._resetProjects();
            this.showCashflow(typeCashflow);

        }, this);
      }
      ysy.settings.critical.open = false;
      ysy.settings.addTask.open = false;
      ysy.data.storage.savePersistentData('criticalType', ysy.settings.critical.open);
      ysy.data.storage.savePersistentData('addTask', ysy.settings.addTask.open);

      setting._fireChanges(this, "toggle");
    }
  },
  close: function () {
    var setting = ysy.settings.cashflow;
    if (setting.setSilent("active", false)) {
      ysy.view.bars.removeRenderer("project", ysy.pro.cashflow.outerRenderer);
      ysy.pro.cashflow.setProjectDateBack();
      setting.setSilent("activeCashflow", "nothing");
      setting.setSilent("open", false);
      ysy.settings.sumRow.removeSummer("cashflow");
      gantt.detachEvent(ysy.pro.cashflow.eventId);
      setting._fireChanges(this, "toggle");
    }
  },
  setProjectDateBack: function () {
    let projects = ysy.data.projects.array;
    for (array in projects){
     if (!projects.hasOwnProperty(array)) continue;
      let project = projects[array];
      if (!project.cashflow) continue;
      let cashflowData = project.cashflow;
      if (cashflowData.originStartDate && project.start_date.isBefore(cashflowData.originStartDate) && project.start_date === cashflowData.cashflowStartDate){
        project.setSilent("start_date", cashflowData.originStartDate);
      }
      if (cashflowData.originEndDate && project.end_date.isAfter(cashflowData.originEndDate) && project.end_date === cashflowData.cashflowEndDate){
        project.setSilent("end_date", cashflowData.originEndDate);
      }
    }
  },
  showTooltip: function (projectId, e) {
    var setting = ysy.settings;
    var $target = $(e.target);
    if (!$target.hasClass("gantt-task-bar-canvas")) return true;
    var project = gantt._pull[projectId];
    if (!project) return true;
    var graphOffset = $target.closest(".gantt_bars_area").offset();
    var zoom = setting.zoom.zoom;
    var date = moment(gantt.dateFromPos2(e.pageX - graphOffset.left)).startOf(zoom === "week" ? "isoWeek" : zoom);
    var out = ysy.pro.cashflow.tooltipOut(project.widget.model, date, zoom);
    if (setting.cashflow.activeCashflow === "difference") {
      if (!out.difference) return true;
      ysy.view.tooltip.show("gantt-tooltip-cashflow", e, ysy.view.templates.differenceCashflowTooltip, out);
    }
    else {
      if (zoom === "month") {
        if (out.weeks.length === 0) return true;
        ysy.view.tooltip.show("gantt-tooltip-cashflow", e, ysy.view.templates.monthCashflowTooltip, out);

      } else {
        if (out.dates.length === 0) return true;
        ysy.view.tooltip.show("gantt-tooltip-cashflow", e, ysy.view.templates.CashflowTooltip, out);
      }
    }
    var $targets = $("#gantt_tooltip");
    $targets.off("click").on("click", "h4", function (event) {
      $(this).parent().children("div").toggleClass("hidden");
    });
    return false;
  },
  noHtmlFormatter: function (value, width) {
    return ysy.pro.cashflow.formatter(value, width, true);
  },
  formatter: function (value, width, noHtml) {
    if (value === 0) return "0";
    var units = ["", "k", "M", "G", "T", "P", "E", "Z", "Y"];
    var negative = value < 0;
    value = Math.abs(value);
    var multiply = 1;
    if (width < 50) {
      multiply = 0.1;
    }
    var rounded;
    var divisor = 1;
    for (var i = 0; i < units.length; i++) {
      if ((value / divisor) < 1000) {
        if (i === 0) {
          rounded = ysy.pro.cashflow.roundTo(value, multiply * 10);
          break;
        }
        rounded = ysy.pro.cashflow.roundTo(value / divisor, multiply) + units[i];
        break;
      }
      if (i === (units.length - 1)) {
        rounded = ysy.pro.cashflow.roundTo(value / divisor, multiply) + units[i];
        break;
      }
      divisor *= 1000;
    }

    if (width > 35 && negative) {
      rounded = "-" + rounded;
    }
    if (noHtml) {
      return rounded;
    }
    if (negative) {
      return '<span title="-' + value + '" class="gantt-sum-row-negative">' + rounded + '</span>';
    }
    return '<span title="' + value + '">' + rounded + '</span>';
  },
  roundTo: function (value, multiply) {
    if ((value % 1) < 0.05) return Math.round(value).toString();
    if (value >= 100 * multiply) return Math.round(value).toString();
    return value.toFixed(1);
  },
  outerRenderer: function (task, next) {
    var div = next().call(this, task, next);
    var cashDiv = ysy.pro.cashflow._projectRenderer.call(gantt, task);
    ysy.view.bars.insertCanvas(cashDiv,div);
    return div;
  },
  cashRenderer: function (project,settings) {
    var setting = settings || ysy.settings.cashflow;
    var cash = {};
    var sign = -1;
    var typeKey = "nothing";
    var type = null;
    var date = null;
    var i = 0;
    if (setting.activeCashflow === "planned") {
      var keys = ["_planned_expenses", "_planned_revenues"];
    } else if (setting.activeCashflow === "real") {
      keys = ["_real_expenses", "_real_revenues"];
    } else {
      keys = ["_planned_expenses", "_planned_revenues", "_real_expenses", "_real_revenues"];
    }
    if (setting.activeCashflow === "timeflow") {
      var today = moment().format('YYYY-MM-DD');
      for (i = 0; i < keys.length; i++) {
        typeKey = keys[i];
        type = project[typeKey];
        for (date in type) {
          if (!type.hasOwnProperty(date)) continue;
          if (!cash[date]) {
            cash[date] = 0;
          }
          if (typeKey === "_planned_expenses" || typeKey === "_planned_revenues") {
            if (date >= today) {
              cash[date] += type[date] * sign;
            }
          }
          if (typeKey === "_real_expenses" || typeKey === "_real_revenues") {
            if (date < today) {
              cash[date] += type[date] * sign;
            }
          }

        }
        sign *= -1;
      }
    } else if (setting.activeCashflow === "difference") {
      for (i = 0; i < keys.length; i++) {
        typeKey = keys[i];
        type = project[typeKey];
        for (date in type) {
          if (!type.hasOwnProperty(date)) continue;
          if (!cash[date]) {
            cash[date] = 0;
          }
          if (typeKey === "_real_expenses" || typeKey === "_real_revenues") {
            cash[date] += type[date] * sign;
          }
          if (typeKey === "_planned_expenses" || typeKey === "_planned_revenues") {
            cash[date] -= type[date] * sign;
          }

        }
        sign *= -1;
      }
    } else {
      for (i = 0; i < keys.length; i++) {
        typeKey = keys[i];
        type = project[typeKey];
        for (date in type) {
          if (!type.hasOwnProperty(date)) continue;
          if (!cash[date]) {
            cash[date] = 0;
          }
          cash[date] += type[date] * sign;
        }
        sign *= -1;
      }
    }
    return cash;
  },
  _projectRenderer: function (task) {
    var cashClass = ysy.pro.cashflow;
    var project = task.widget && task.widget.model;
    var canvasList = ysy.view.bars.canvasListBuilder();
    canvasList.build(task, this);
    var cashList = ysy.pro.cashflow.cashRenderer(project);
    if (ysy.settings.zoom.zoom !== "day") {
      $.proxy(cashClass._projectWeekRenderer, this)(task, cashList, canvasList, project._shift);
    } else {
      $.proxy(cashClass._projectDayRenderer, this)(task, cashList, canvasList, project._shift);
    }
    var element = canvasList.getElement();
    element.className += " project";
    return element;
  },
  _projectDayRenderer: function (task, cashList, canvasList, shift) {
    var cashClass = ysy.pro.cashflow;
    for (var date in cashList) {
      if (!cashList.hasOwnProperty(date)) continue;
      if (!cashList[date]) continue;
      var cash = cashList[date];
      if (shift) {
        var momentDate = moment(date).add(shift, "days");
        if (!canvasList.inRange(momentDate)) continue;
        date = momentDate.format("YYYY-MM-DD");
      } else {
        if (!canvasList.inRange(date)) continue;
      }

      canvasList.fillFormattedTextAt(date, cashClass.noHtmlFormatter, cash, cash < 0 ? cashClass.styles.negative : cashClass.styles.positive);
    }
  },
  _projectWeekRenderer: function (task, cashList, canvasList, shift) {
    var cashClass = ysy.pro.cashflow;
    var weekCash = cashClass.weekCashSummer(cashList, ysy.settings.zoom.zoom, task.start_date, task.end_date, shift);
    for (var date in weekCash) {
      if (!weekCash.hasOwnProperty(date)) continue;
      var cash = weekCash[date];
      canvasList.fillFormattedTextAt(date, cashClass.noHtmlFormatter, cash, cash < 0 ? cashClass.styles.negative : cashClass.styles.positive);
    }
  },
  weekCashSummer: function (cashList, unit, minDate, maxDate, shift) {
    var barsClass = ysy.view.bars;
    var minDateValue = minDate.valueOf();
    var maxDateValue = moment(maxDate).add(1, "days").valueOf();
    var weekCash = {};
    for (var date in cashList) {
      if (!cashList.hasOwnProperty(date)) continue;
      var dateMoment = barsClass.getFromDateCache(date);
      var cash = cashList[date];
      if (shift) {
        dateMoment = moment(dateMoment).add(shift, "days");
        date = dateMoment.format("YYYY-MM-DD");
      }
      if (+dateMoment < minDateValue) continue;
      if (+dateMoment > maxDateValue) continue;
      if (!cash) continue;
      var firstMomentDate = moment(dateMoment).startOf(unit === "week" ? "isoWeek" : unit);
      var firstDate = firstMomentDate.toISOString();
      if (weekCash[firstDate] === undefined) {
        weekCash[firstDate] = cash;
      } else {
        weekCash[firstDate] += cash;
      }
    }
    return weekCash;
  },
  initToolbar: function (ctx) {
    var cashFlowPanel = new ysy.view.CashFlowPanel();
    cashFlowPanel.init(ysy.settings.cashflow);
    ctx.children.push(cashFlowPanel);
  },
  tooltipOut: function (project, date, zoom, setting, today) {
    var today = today || moment().format('YYYY-MM-DD');
    setting = setting || ysy.settings.cashflow;
    var cashData = ysy.pro.cashflow.cashRenderer(project,setting);
    var allExpenses = {};
    var allRevenues = {};
    if (setting.activeCashflow === "planned") {
      allExpenses = project._planned_expenses;
      allRevenues = project._planned_revenues;
    }
    if (setting.activeCashflow === "real") {
      allExpenses = project._real_expenses;
      allRevenues = project._real_revenues;
    }
    var dates = [];
    var weeks = [];
    var shift = project._shift;
    if (shift) {
      date.add(shift, "days");
    }
    var totalPrice = 0;
    var realCash = 0;
    var plannedCash = 0;
    var mover = moment(date).startOf(zoom === "week" ? "isoweek" : zoom);
    var endDate = moment(mover).add(1, zoom);
    while (mover.isBefore(endDate)) {
      var dateString = mover.format("YYYY-MM-DD");
      if (!cashData[dateString]) {
        mover.add(1, "day");
        continue;
      }
      var expense = 0;
      var revenue = 0;
      if (setting.activeCashflow === "planned" || setting.activeCashflow === "real") {
        if (allExpenses && allExpenses[dateString]) {
          expense += allExpenses[dateString];
        }
        if (allRevenues && allRevenues[dateString]) {
          revenue += allRevenues[dateString];
        }
      }
      if (setting.activeCashflow === "timeflow") {
        if (project._planned_expenses[dateString] && today < dateString) {
          expense += project._planned_expenses[dateString];
        }
        if (project._real_expenses[dateString] && dateString <= today) {
          expense += project._real_expenses[dateString];
        }
        if (project._planned_revenues[dateString] && today < dateString) {
          revenue += project._planned_revenues[dateString];
        }
        if (project._real_revenues[dateString] && dateString <= today) {
          revenue += project._real_revenues[dateString];
        }
      }
      if (setting.activeCashflow === "difference") {
        if (project._planned_expenses[dateString]) {
          plannedCash -= project._planned_expenses[dateString];
        }
        if (project._real_expenses[dateString]) {
          realCash -= project._real_expenses[dateString];
        }
        if (project._planned_revenues[dateString]) {
          plannedCash += project._planned_revenues[dateString];
        }
        if (project._real_revenues[dateString]) {
          realCash += project._real_revenues[dateString];
        }
      }
      var fullPrice = cashData[dateString];
      totalPrice += fullPrice;
      if (expense || revenue) {
        dates.push({
              date: mover.format("DD MMMM YYYY"),
              expense: expense,
              revenue: revenue,
              fullPrice: fullPrice,
              positiveNegativeClass: fullPrice < 0 ? "negative" : "positive"
            }
        );
        if (dates.length === 1) {
          dates[0].first = true;
        }
      }
      if (setting.activeCashflow === "difference") {
        var dayWeekMonth = null;
        if (zoom === "day") dayWeekMonth = mover.format("DD MMMM YYYY");
        if (zoom === "week") dayWeekMonth = mover.isoWeek() + " week";
        if (zoom === "month") dayWeekMonth = mover.format("MMMM YYYY");
      }
      mover.add(1, "day");
    }
    if (setting.activeCashflow === "difference") {
      if (realCash === 0 && plannedCash === 0) return;
      return {
        date: dayWeekMonth,
        realCashflow: realCash,
        realPositiveNegativeClass: realCash < 0 ? "negative" : "positive",
        plannedCashflow: plannedCash,
        plannedPositiveNegativeClass: plannedCash < 0 ? "negative" : "positive",
        difference: totalPrice,
        differencePositiveNegativeClass: totalPrice < 0 ? "negative" : "positive"
      };
    }
    var weekExpenses = {};
    var weekRevenues = {};
    var weekFullPrice = {};
    var weekDatesCollection = {};
    if (zoom === "day") return {dates: dates};
    if (zoom === "week") return {dates: dates, total: totalPrice};
    if (zoom === "month") {
      for (var i = 0; i < dates.length; i++) {
        var day = dates[i];
        var weekNumber = moment(day.date, "DD MMMM YYYY").isoWeek();
        expense = day.expense;
        revenue = day.revenue;
        fullPrice = day.fullPrice;
        if (!weekExpenses[weekNumber]) {
          weekExpenses[weekNumber] = 0;
        }
        if (expense) {
          weekExpenses[weekNumber] += expense;
        }

        if (!weekRevenues[weekNumber]) {
          weekRevenues[weekNumber] = 0;
        }
        if (revenue) {
          weekRevenues[weekNumber] += revenue;
        }
        if (!weekFullPrice[weekNumber]) {
          weekFullPrice[weekNumber] = 0;
        }
        weekFullPrice[weekNumber] += fullPrice;
        if (!weekDatesCollection[weekNumber]) {
          weekDatesCollection[weekNumber] = [];
        }
        weekDatesCollection[weekNumber].push({
          date: day.date,
          expense: expense,
          revenue: revenue,
          fullPrice: fullPrice,
          positiveNegativeClass: fullPrice < 0 ? "negative" : "positive"
        });


      }
      for (weekNumber in weekFullPrice) {
        weeks.push({
              weekNumber: weekNumber,
              weekExpenses: weekExpenses[weekNumber],
              weekRevenues: weekRevenues[weekNumber],
              weekFullPrice: weekFullPrice[weekNumber],
              weekPositiveNegativeClass: weekFullPrice[weekNumber] < 0 ? "negative" : "positive",
              dates: weekDatesCollection[weekNumber]
            }
        );
      }
      return {
        weeks: weeks,
        totalPrice: totalPrice,
        totalPositiveNegativeClass: totalPrice < 0 ? "negative" : "positive"
      };
    }
  }
});
//#############################################################################################
ysy.view = ysy.view || {};
ysy.view.CashFlowPanel = function () {
  ysy.view.Widget.call(this);
};
ysy.main.extender(ysy.view.Widget, ysy.view.CashFlowPanel, {
  name: "CashFlowPanelWidget",
  templateName: "CashFlowPanel",
  _repaintCore: function () {
    var sett = ysy.settings.cashflow;
    var target = this.$target;
    if (sett.active) {
      target.show();
    } else {
      target.hide();
    }
    this.toolbar();
    this.tideFunctionality();
  },
  tideFunctionality: function () {
    var that = this;
    this.$target.find("#cashflow_planned").off("click").on("click", function (event) {
      ysy.pro.cashflow.showCashflow("planned");
      that.toolbar();
    });
    this.$target.find("#cashflow_real").off("click").on("click", function (event) {
      ysy.pro.cashflow.showCashflow("real");
      that.toolbar();
    });
    this.$target.find("#cashflow_timeflow").off("click").on("click", function (event) {
      ysy.pro.cashflow.showCashflow("timeflow");
      that.toolbar();
    });
    this.$target.find("#cashflow_difference").off("click").on("click", function (event) {
      ysy.pro.cashflow.showCashflow("difference");
      that.toolbar();
    });
    this.$target.find("#button_cashflow_help").off("click").on("click", ysy.proManager.showHelp);
  },
  toolbar: function () {
    var sett = ysy.settings.cashflow;
    var target = this.$target;
    if (sett.activeCashflow === "planned") {
      target.find("#cashflow_planned").addClass("active");
    } else {
      target.find("#cashflow_planned").removeClass("active");
    }
    if (sett.activeCashflow === "real") {
      target.find("#cashflow_real").addClass("active");
    } else {
      target.find("#cashflow_real").removeClass("active");
    }
    if (sett.activeCashflow === "timeflow") {
      target.find("#cashflow_timeflow").addClass("active");
    } else {
      target.find("#cashflow_timeflow").removeClass("active");
    }
    if (sett.activeCashflow === "difference") {
      target.find("#cashflow_difference").addClass("active");
    } else {
      target.find("#cashflow_difference").removeClass("active");
    }
  }
});
