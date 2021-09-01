describe("Allocators (corner cases)", function () {
  /**
   * @function moment
   * @param {*} [arg1]
   * @return {{}}
   */
  /**
   * @typedef {{issue?:{},estimated?:number,start_date?:{},end_date?:{},assignee?:ysy.data.Assignee,allocator?:String,resources?:{},today?:String}} Options
   */
  var assignee;
  var options = {};
  beforeAll(function () {
    assignee = new ysy.data.Assignee();
    assignee.init({
      estimated_ratio: 1,
      events: {
        '2017-08-01': [{name: "Dovolená", type: "nonworking_attendance"}],
        '2017-08-02': [{name: "Dovolená", type: "nonworking_attendance"}],
        '2017-08-03': [{name: "Dovolená", type: "nonworking_attendance"}],
        '2017-08-04': [{name: "Dovolená", type: "nonworking_attendance"}]
      },
      resources_sums: {},
      week_hours: [8, 8, 8, 8, 8, 0, 0]
    });
    /** @type {Options} */
    $.extend(options, {
      start_date: moment("2017-08-01"),
      end_date: moment("2017-08-06"),
      allocator: "from_start",
      estimated: 46,
      assignee: assignee,
      resources: {},
      today: '2017-08-03'
    });
  });
  var enhanceOptions = window.easyJasmine.enhanceOptions;
  var allocationsToArray = window.easyJasmine.allocationsToArray;
  var dayTypesToArray = window.easyJasmine.dayTypesToArray;
  it("Non-working", function () {
    var results = {
      from_start: [0, 0, 0, 0, 0, 46],
      from_end: [0, 0, 0, 0, 0, 46],
      evenly: [0, 0, 0, 0, 0, 46],
      future_from_start: [0, 0, 0, 0, 0, 46],
      future_from_end: [0, 0, 0, 0, 0, 46],
      future_evenly: [0, 0, 0, 0, 0, 46]
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {allocator: allocator}));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    });
  });
  it("Non-working + Custom", function () {
    var results = {
      from_start: [0, 0, 0, 6, 0, 40],
      from_end: [0, 0, 0, 6, 0, 40],
      evenly: [0, 0, 0, 6, 0, 40],
      future_from_start: [0, 0, 0, 6, 0, 40],
      future_from_end: [0, 0, 0, 6, 0, 40],
      future_evenly: [0, 0, 0, 6, 0, 40]
    };
    var resources = {
      "2017-08-04": {hours: 6, custom: true}
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {
        allocator: allocator,
        resources: resources
      }));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    });
  });
  it("Full custom", function () {
    var results = {
      from_start: [6, 6, 6, 6, 6, 16],
      from_end: [6, 6, 6, 6, 6, 16],
      evenly: [6, 6, 6, 6, 6, 16],
      future_from_start: [6, 6, 6, 6, 6, 16],
      future_from_end: [6, 6, 6, 6, 6, 16],
      future_evenly: [6, 6, 6, 6, 6, 16]
    };
    var dayTypes = ["fixed", "fixed", "fixed", "fixed", "fixed", "overAllocation"];
    var resources = {
      "2017-08-01": {hours: 6, custom: true},
      "2017-08-02": {hours: 6, custom: true},
      "2017-08-03": {hours: 6, custom: true},
      "2017-08-04": {hours: 6, custom: true},
      "2017-08-05": {hours: 6, custom: true},
      "2017-08-06": {hours: 6, custom: true}
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {
        allocator: allocator,
        resources: resources
      }));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
      expect(dayTypesToArray(result, options)).toEqual(dayTypes);
    });
  });

});
