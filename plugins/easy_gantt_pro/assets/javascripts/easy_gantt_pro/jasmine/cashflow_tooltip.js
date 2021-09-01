xdescribe("Cashflow tooltip", function () {
  var project = {
    _planned_expenses: {"2017-07-01": 1680.0, "2017-07-11": 10680.0},
    _planned_revenues: {"2017-07-11": 3000.0, "2017-07-13": 7584.0, "2017-07-25": 100},
    _real_expenses: {
      "2017-07-12": 6894.0,
      "2017-07-13": 4272.0,
      "2017-07-25": 500,
      "2017-10-24": 6894.0,
      "2017-10-25": 9874.0,
      "2017-10-26": 5689.0
    },
    _real_revenues: {
      "2017-07-11": 2400.0,
      "2017-07-13": 9725.0,
      "2017-07-25": 400,
      "2017-10-23": 4648.0,
      "2017-10-26": 4272.0
    }
  };


  var outFunction = ysy.pro.cashflow.tooltipOut;
  describe("planned", function () {
    var setting = {};
    setting.activeCashflow = "planned";
    it("day", function () {
      var date = "2017-07-11";
      var out = outFunction(project, moment(date), "day", setting);
      expect(out).toEqual({
        dates: [{
          date: moment(date).format("DD MMMM YYYY"),
          expense: 10680,
          revenue: 3000,
          fullPrice: -7680,
          first: true,
          positiveNegativeClass: "negative"
        }]
      });
    });
    it("week", function () {
      var date = "2017-07-11";
      var out = outFunction(project, moment(date), "week", setting);
      expect(out).toEqual({
        dates: [{
          date: moment(date).format("DD MMMM YYYY"),
          expense: 10680,
          revenue: 3000,
          fullPrice: -7680,
          first: true,
          positiveNegativeClass: "negative"
        }, {
          date: moment("2017-07-13").format("DD MMMM YYYY"),
          expense: 0,
          revenue: 7584,
          fullPrice: 7584,
          positiveNegativeClass: "positive"
        }],
        total: -96
      });
    });
    it("month", function () {
      var date = "2017-07-11";
      var out = outFunction(project, moment(date), "month", setting);
      expect(out).toEqual({
            weeks: [{
              dates: [{
                date: moment("2017-07-01").format("DD MMMM YYYY"),
                expense: 1680,
                revenue: 0,
                fullPrice: -1680,
                positiveNegativeClass: "negative"
              }],
              weekFullPrice: -1680,
              weekNumber: '26',
              weekExpenses: 1680,
              weekRevenues: 0,
              weekPositiveNegativeClass: "negative"
            }, {
              dates: [{
                date: moment(date).format("DD MMMM YYYY"),
                expense: 10680,
                revenue: 3000,
                fullPrice: -7680,
                positiveNegativeClass: "negative"
              }, {
                date: moment("2017-07-13").format("DD MMMM YYYY"),
                expense: 0,
                revenue: 7584,
                fullPrice: 7584,
                positiveNegativeClass: "positive"
              }],
              weekFullPrice: -96,
              weekNumber: '28',
              weekExpenses: 10680,
              weekRevenues: 10584,
              weekPositiveNegativeClass: "negative"
            },
              {
                dates: [{
                  date: moment("2017-07-25").format("DD MMMM YYYY"),
                  expense: 0,
                  revenue: 100,
                  fullPrice: 100,
                  positiveNegativeClass: "positive"
                }],
                weekFullPrice: 100,
                weekNumber: '30',
                weekExpenses: 0,
                weekRevenues: 100,
                weekPositiveNegativeClass: "positive"
              }],
            totalPrice: -1676,
            totalPositiveNegativeClass: "negative"
          }
      );
    });
  });
  describe("real", function () {
    var setting = {};
    setting.activeCashflow = "real";
    it("day", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "day", setting);
      expect(out).toEqual({
        dates: [{
          date: moment(date).format("DD MMMM YYYY"),
          expense: 4272,
          revenue: 9725,
          fullPrice: 5453,
          first: true,
          positiveNegativeClass: "positive"
        }]
      });
    });
    it("week", function () {
      var date = "2017-10-24";
      var out = outFunction(project, moment(date), "week", setting);
      expect(out).toEqual({
        dates: [{
          date: moment("2017-10-23").format("DD MMMM YYYY"),
          expense: 0,
          revenue: 4648,
          fullPrice: 4648,
          first: true,
          positiveNegativeClass: "positive"
        }, {
          date: moment(date).format("DD MMMM YYYY"),
          expense: 6894,
          revenue: 0,
          fullPrice: -6894,
          positiveNegativeClass: "negative"
        }, {
          date: moment("2017-10-25").format("DD MMMM YYYY"),
          expense: 9874,
          revenue: 0,
          fullPrice: -9874,
          positiveNegativeClass: "negative"
        }, {
          date: moment("2017-10-26").format("DD MMMM YYYY"),
          expense: 5689,
          revenue: 4272,
          fullPrice: -1417,
          positiveNegativeClass: "negative"
        }],
        total: -13537
      });
    });
    it("month", function () {
      var date = "2017-07-11";
      var out = outFunction(project, moment(date), "month", setting);
      expect(out).toEqual({
            weeks: [{
              dates: [{
                date: moment(date).format("DD MMMM YYYY"),
                expense: 0,
                revenue: 2400,
                fullPrice: 2400,
                positiveNegativeClass: "positive"
              }, {
                date: moment("2017-07-12").format("DD MMMM YYYY"),
                expense: 6894,
                revenue: 0,
                fullPrice: -6894,
                positiveNegativeClass: "negative"
              }, {
                date: moment("2017-07-13").format("DD MMMM YYYY"),
                expense: 4272,
                revenue: 9725,
                fullPrice: 5453,
                positiveNegativeClass: "positive"
              }],
              weekFullPrice: 959,
              weekNumber: '28',
              weekExpenses: 11166,
              weekRevenues: 12125,
              weekPositiveNegativeClass: "positive"
            },
              {
                dates: [{
                  date: moment("2017-07-25").format("DD MMMM YYYY"),
                  expense: 500,
                  revenue: 400,
                  fullPrice: -100,
                  positiveNegativeClass: "negative"
                }],
                weekFullPrice: -100,
                weekNumber: '30',
                weekExpenses: 500,
                weekRevenues: 400,
                weekPositiveNegativeClass: "negative"
              }],
            totalPrice: 859,
            totalPositiveNegativeClass: "positive"
          }
      );
    });
  });
  describe("timeflow", function () {
    var setting = {};
    setting.activeCashflow = "timeflow";
    var today = "2017-07-15";
    it("day before today", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "day", setting, today);
      expect(out).toEqual({
        dates: [{
          date: moment(date).format("DD MMMM YYYY"),
          expense: 4272,
          revenue: 9725,
          fullPrice: 5453,
          first: true,
          positiveNegativeClass: "positive"
        }]
      });
    });
    it("day after today", function () {
      var date = "2017-07-25";
      var out = outFunction(project, moment(date), "day", setting, today);
      expect(out).toEqual({
        dates: [{
          date: moment(date).format("DD MMMM YYYY"),
          expense: 0,
          revenue: 100,
          fullPrice: -100,
          first: true,
          positiveNegativeClass: "negative"
        }]
      });
    });
    it("week", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "week", setting);
      expect(out).toEqual({
        dates: [{
          date: moment("2017-07-11").format("DD MMMM YYYY"),
          expense: 0,
          revenue: 2400,
          fullPrice: 2400,
          first: true,
          positiveNegativeClass: "positive"
        }, {
          date: moment("2017-07-12").format("DD MMMM YYYY"),
          expense: 6894,
          revenue: 0,
          fullPrice: -6894,
          positiveNegativeClass: "negative"
        }, {
          date: moment("2017-07-13").format("DD MMMM YYYY"),
          expense: 4272,
          revenue: 9725,
          fullPrice: 5453,
          positiveNegativeClass: "positive"
        }],
        total: 959
      });
    });
    it("month", function () {
      var date = "2017-07-11";
      var out = outFunction(project, moment(date), "month", setting, today);
      expect(out).toEqual({
            weeks: [{
              dates: [{
                date: moment(date).format("DD MMMM YYYY"),
                expense: 0,
                revenue: 2400,
                fullPrice: 2400,
                positiveNegativeClass: "positive"
              }, {
                date: moment("2017-07-12").format("DD MMMM YYYY"),
                expense: 6894,
                revenue: 0,
                fullPrice: -6894,
                positiveNegativeClass: "negative"
              }, {
                date: moment("2017-07-13").format("DD MMMM YYYY"),
                expense: 4272,
                revenue: 9725,
                fullPrice: 5453,
                positiveNegativeClass: "positive"
              }],
              weekFullPrice: 959,
              weekNumber: '28',
              weekExpenses: 11166,
              weekRevenues: 12125,
              weekPositiveNegativeClass: "positive"
            },
              {
                dates: [{
                  date: moment("2017-07-25").format("DD MMMM YYYY"),
                  expense: 0,
                  revenue: 100,
                  fullPrice: -100,
                  positiveNegativeClass: "negative"
                }],
                weekFullPrice: -100,
                weekNumber: '30',
                weekExpenses: 0,
                weekRevenues: 100,
                weekPositiveNegativeClass: "negative"
              }],
            totalPrice: 859,
            totalPositiveNegativeClass: "positive"
          }
      );
    });
  });
  describe("difference", function () {
    var setting = {};
    setting.activeCashflow = "difference";
    it("day", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "day", setting);
      expect(out).toEqual({
        date: moment(date).format("DD MMMM YYYY"),
        realCashflow: 5453,
        realPositiveNegativeClass: "positive",
        plannedCashflow: 7584,
        plannedPositiveNegativeClass: "positive",
        difference: -2131,
        differencePositiveNegativeClass: "negative"
      });
    });
    it("week", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "week", setting);
      expect(out).toEqual({
        date: '28 week',
        realCashflow: 959,
        realPositiveNegativeClass: "positive",
        plannedCashflow: -96,
        plannedPositiveNegativeClass: "negative",
        difference: 1055,
        differencePositiveNegativeClass: "positive"
      });
    });
    it("month", function () {
      var date = "2017-07-13";
      var out = outFunction(project, moment(date), "month", setting);
      expect(out).toEqual(jasmine.objectContaining({
        realCashflow: 859,
        realPositiveNegativeClass: "positive",
        plannedCashflow: -1676,
        plannedPositiveNegativeClass: "negative",
        difference: 2535,
        differencePositiveNegativeClass: "positive"
      }));
      expect(out.date).toMatch(/(July|červenec) 2017/);
    });
  });
});
