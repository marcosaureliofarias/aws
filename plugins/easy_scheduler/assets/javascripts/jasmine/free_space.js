describe("Free space", function () {
  beforeAll(function () {
    this.helper = easyScheduler.tests;
  });
  xdescribe("findFirstVisibleEvent", function () {
    beforeAll(function () {
      this.helper.setView("2018-02-06", "week");
    });
    var tests = [];
    if (jasmineHelper.hasTag("personal") || jasmineHelper.hasTag("manager")) {
      tests = {
        "2018-02-05 10:00": "easy_meeting-18",
        "2018-02-05 14:00": "easy_meeting-18",
        "2018-02-06 12:30": "6130",
        "2018-02-07 12:30": "6117",
        "2018-02-07 16:30": "easy_meeting-19"
      };
    }
    Object.keys(tests).forEach(function (date) {
      var value = tests[date];
      it(date + " => " + value, function () {
        var event = easyScheduler.scheduler.findFirstVisibleEvent(new Date(date));
        expect(event).toBeDefined();
        expect(event.id.toString()).toBe(value.toString());
      });
    });
  });
  if (jasmineHelper.hasTag("personal") || jasmineHelper.hasTag("manager")) {
    describe("prepareEmptySpaces", function () {
      beforeAll(function () {
        this.helper.setView("2018-02-05", "week");
      });
      var counts = [18, 10, 19];
      it("2018-02-05 week", function () {
        var frees = easyScheduler.scheduler.prepareEmptySpaces();
        expect(frees.length).toBe(counts[0]);
      });
      it("2018-02-05 week filtered", function () {
        var frees = easyScheduler.scheduler.prepareEmptySpaces(function (event) {
          return event.id % 2 === 0;
        });
        expect(frees.length).toBe(counts[1]);
      });
      it("2018-02-05 week limited", function () {
        var frees = easyScheduler.scheduler.prepareEmptySpaces(undefined, {
          start: new Date("2018-02-06"),
          end: new Date("2018-02-08")
        });
        expect(frees.length).toBe(counts[2]);
      });
    });
  }
  describe("findNextEmptySpace", function () {
    var frees = [
      { "start": 1517814000000, "end": 1517828400000 },
      { "start": 1517832000000, "end": 1517844600000 },
      { "start": 1517900400000, "end": 1517913000000 },
      { "start": 1517927400000, "end": 1517931000000 },
      { "start": 1517986800000, "end": 1517994000000 },
      { "start": 1518076800000, "end": 1518080400000 },
      { "start": 1518085800000, "end": 1518103800000 },
      { "start": 1518159600000, "end": 1518166800000 },
      { "start": 1518183000000, "end": 1518190200000 },
      { "start": 1518246000000, "end": 1518249600000 },
      { "start": 1518332400000, "end": 1518339600000 },
      { "start": 1518354000000, "end": 1518363000000 }
    ];
    var tests = {
      "2018-02-05 10:00": { "start": "2018-02-05 10:00", "end": "2018-02-05 12:00" },
      "2018-02-06 12:00": { "start": "2018-02-06 15:30", "end": "2018-02-06 16:30" },
      "2018-02-07 12:00": { "start": "2018-02-08 09:00", "end": "2018-02-08 10:00" },
      "2018-02-08 10:00": { "start": "2018-02-08 11:30", "end": "2018-02-08 16:30" }
    };
    Object.keys(tests).forEach(function (date) {
      it(date, function () {
        var result = easyScheduler.scheduler.findNextEmptySpace(new Date(date).valueOf(), frees);
        if (tests[date]) {
          expect(new Date(result.start)).toEqual(new Date(tests[date].start));
          expect(new Date(result.end)).toEqual(new Date(tests[date].end));
        } else {
          expect(result).toBe(tests[date]);
        }
      });
    });
  });
});
