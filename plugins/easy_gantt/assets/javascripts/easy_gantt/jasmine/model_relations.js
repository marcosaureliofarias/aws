describe("Model relations", function () {
  var getEndDate = function (startDate, duration) {
    var end = moment(startDate);
    end.add(duration - 1, "days");
    end._isEndDate = true;
    return end;
  };
  var createMockedTask = function (startDate, duration) {
    if (typeof startDate === "string") {
      startDate = moment(startDate);
    }
    return {start_date: startDate, end_date: getEndDate(startDate, duration), duration: duration};
  };
  /** @typedef {{target?:{start_date:Moment,end_date:Moment},actDelay?:number,delay:number}} RelationData */
  /** @typedef {{getTarget:Function,getActDelay:Function,delay:number,type:string}} Relation */
  /**
   * @param {string} type
   * @param {RelationData} data
   * @return {Relation}
   * @private
   */
  var _upgradeRelation = function (type, data) {
    return {
      type: type, delay: data.delay,
      getActDelay: function () {
        return data.actDelay;
      },
      getTarget: function () {
        return data.target;
      }
    };
  };
  /**
   * @param {RelationData} data
   * @return {Relation}
   */
  var createPrecedesLink = function (data) {
    return _upgradeRelation("precedes", data);
  };
  /**
   * @param {RelationData} data
   * @return {Relation}
   */
  var createFinishToFinishLink = function (data) {
    return _upgradeRelation("finish_to_finish", data);
  };
  /**
   * @param {RelationData} data
   * @return {Relation}
   */
  var createStartToStartLink = function (data) {
    return _upgradeRelation("start_to_start", data);
  };
  /**
   * @param {RelationData} data
   * @return {Relation}
   */
  var createStartToFinishLink = function (data) {
    return _upgradeRelation("start_to_finish", data);
  };
  var compareDates = function (date1, date2) {
    if (typeof date2 === "string") {
      date2 = moment(date2);
    }
    expect(date1.valueOf()).toBe(date2.valueOf(), "Expected " + date2.format("YYYY-MM-DD HH:mm") + ", but got " + date1.format("YYYY-MM-DD HH:mm"));
  };

  beforeAll(function () {
    var helper = gantt._working_time_helper;
    // helper.days = {0: true, 1: true, 2: true, 3: true, 4: true, 5: false, 6: false };
    helper.days = {0: false, 1: true, 2: true, 3: true, 4: true, 5: true, 6: false };
    helper.dates = {};
    helper._cache= {};
  });
  afterEach(function () {
    ysy.view.initNonworkingDays();
  });

  describe("moveOneDescendant precedes", function () {
    it("over weekend", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22 12:00", 1), 1, createPrecedesLink({delay: 2}));
      compareDates(result, "2017-11-27");
    });
    it("weekday", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-20 12:00", 1), 1, createPrecedesLink({delay: 2}));
      compareDates(result, "2017-11-23 12:00");
    });
  });
  describe("moveOneDescendant finish_to_finish", function () {
    it("not moved", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22", 1), 2, createFinishToFinishLink({delay: 2}));
      compareDates(result, "2017-11-23");
    });
    it("over weekend", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22 12:00", 1), 2, createFinishToFinishLink({delay: 2}));
      compareDates(result, "2017-11-23 12:00");
    });
    it("weekday", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-20 12:00", 1), 2, createFinishToFinishLink({delay: 2}));
      compareDates(result, "2017-11-21 12:00");
    });
  });
  describe("moveOneDescendant start_to_finish", function () {
    it("not moved", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22", 1), 2, createStartToFinishLink({delay: 3}));
      compareDates(result, "2017-11-23");
    });
    it("over weekend", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22 12:00", 1), 2, createStartToFinishLink({delay: 3}));
      compareDates(result, "2017-11-23 12:00");
    });
    it("weekday", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-20 12:00", 1), 2, createStartToFinishLink({delay: 3}));
      compareDates(result, "2017-11-21 12:00");
    });
  });
  describe("moveOneDescendant start_to_start", function () {
    it("not moved", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22", 1), 2, createStartToStartLink({delay: 1}));
      compareDates(result, "2017-11-23");
    });
    it("over weekend", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-22 12:00", 1), 2, createStartToStartLink({delay: 1}));
      compareDates(result, "2017-11-23 12:00");
    });
    it("weekday", function () {
      var result = gantt.moveOneDescendant(createMockedTask("2017-11-20 12:00", 1), 2, createStartToStartLink({delay: 1}));
      compareDates(result, "2017-11-21 12:00");
    });
  });
  describe("getMinimizedDelay", function () {
    describe("precedes", function () {
      it("returns actDelay for weekdays", function () {
        var relation = createPrecedesLink({delay: 0, actDelay: 2, target: createMockedTask("2017-11-24", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(2);
      });
      it("returns 0 for weekend", function () {
        var relation = createPrecedesLink({delay: 0, actDelay: 2, target: createMockedTask("2017-11-27", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(0);
      });
      it("returns 1 for day + weekend", function () {
        var relation = createPrecedesLink({delay: 0, actDelay: 3, target: createMockedTask("2017-11-27", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(1);
      });
      it("returns 4 for day + weekend + day", function () {
        var relation = createPrecedesLink({delay: 0, actDelay: 4, target: createMockedTask("2017-11-28", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(4);
      });
    });
    describe("finish_to_finish", function () {
      it("returns actDelay for weekdays", function () {
        var relation = createFinishToFinishLink({delay: 0, actDelay: 2, target: createMockedTask("2017-11-24", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(2);
      });
      it("returns 0 for weekend", function () {
        var relation = createFinishToFinishLink({delay: 0, actDelay: 3, target: createMockedTask("2017-11-27", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(0);
      });
      it("returns 1 for day + weekend", function () {
        var relation = createFinishToFinishLink({delay: 0, actDelay: 4, target: createMockedTask("2017-11-27", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(1);
      });
      it("returns 4 for day + weekend + day", function () {
        var relation = createFinishToFinishLink({delay: 0, actDelay: 5, target: createMockedTask("2017-11-28", 1)});
        expect(ysy.pro.relations.getMinimizedDelay(relation)).toBe(5);
      });
    });
  });
});