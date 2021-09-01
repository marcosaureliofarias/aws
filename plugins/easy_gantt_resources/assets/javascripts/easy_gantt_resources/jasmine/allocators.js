window.easyJasmine = window.easyJasmine || {};
/**
 * @param {{allocations:{},types:{}}} allocPack
 * @param {Options} options
 */
easyJasmine.allocationsToArray = function (allocPack, options) {
  var allocations = allocPack.allocations;
  var mover = moment(options.start_date);
  var result = [];
  while (!mover.isAfter(options.end_date)) {
    var allocation = allocations[mover.format("YYYY-MM-DD")] || 0;
    result.push(allocation);
    mover.add(1, "day");
  }
  return result;
};
/**
 *
 * @param {Options} defaultOptions
 * @param {Options} otherOptions
 * @return {Options}
 */
easyJasmine.enhanceOptions = function (defaultOptions, otherOptions) {
  return $.extend({}, defaultOptions, otherOptions);
};
/**
 * @param {{allocations:{},types:{}}} allocPack
 * @param {Options} options
 */
easyJasmine.dayTypesToArray = function (allocPack, options) {
  var dayTypes = allocPack.types;
  var mover = moment(options.start_date);
  var result = [];
  while (!mover.isAfter(options.end_date)) {
    result.push(dayTypes[mover.format("YYYY-MM-DD")] || "");
    mover.add(1, "day");
  }
  return result;
};
/**
 * @param {{from_start:Array,from_end:Array,evenly:Array,future_from_start:Array,future_from_end:Array,future_evenly:Array}} results
 * @param {Function} body
 */
easyJasmine.forAllAllocators = function (results, body) {
  var allocators = Object.getOwnPropertyNames(results);
  for (var i = 0; i < allocators.length; i++) {
    body(allocators[i]);
  }
};
/**
 * @param {{from_start:Array,from_end:Array,evenly:Array,future_from_start:Array,future_from_end:Array,future_evenly:Array}} results
 * @param {Function} bodyBuilder
 */
easyJasmine.forAnyAllocators = function (results, bodyBuilder) {
  var allocators = Object.getOwnPropertyNames(results);
  for (var i = 0; i < allocators.length; i++) {
    it("Allocator " + allocators[i], bodyBuilder(allocators[i]));
  }

};

easyJasmine.allocationStartEndDates = function() {
  const today = new Date;
  let startDate = window.easyJasmine.setDate(today,1);
  let dueDate = window.easyJasmine.addDays(startDate, 4);
  const dates = {
    startDate,
    dueDate
  };
  return dates;
};

easyJasmine.allocationPackDatesGenerator = function(){
  const today = new Date;
  let startDate = window.easyJasmine.setDate(today,1);
  let allocations = {};
  for (let i = 0; i < 5; i++) {
    const date = window.easyJasmine.addDays(startDate, i);
    const allocDate = moment(date).format().substr(0, 10);
    allocations[allocDate] = 7;
  }
  return allocations;
};
easyJasmine.resourcePackGenerator = function() {
  const allocations = window.easyJasmine.allocationPackDatesGenerator();
  Object.keys(allocations).forEach(key => {
    allocations[key] = { hours: allocations[key], custom: false}
  });
  return allocations;
};

easyJasmine.setDate = function(date, dayOfWeek) {
  date = new Date(date.getTime ());
  date.setDate(date.getDate() + (dayOfWeek + 7 - date.getDay()) % 7);
  return date;
};

easyJasmine.addDays = function (date, days){
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

easyJasmine.createIssueArray = function() {
  const issues = [];
  const { allocationStartEndDates, allocationPackDatesGenerator, resourcePackGenerator } = window.easyJasmine;
  const firstIssue = {
    allocPack: {
      allocations: allocationPackDatesGenerator(),
      types: {}
    },
    allocator: "future_evenly",
    id: 798,
    issue: {
      allocator: "future_evenly",
      assigned_to_id: 38,
      columns: {
        project: "Resource project 2",
        subject: "Large bug fix D",
        priority: "Normal"
      },
      end_date: moment(`${allocationStartEndDates().dueDate}`),
      estimated_hours: 35,
      id: 798,
      name: "Large bug fix D",
      project_id: 55,
      resources: resourcePackGenerator(),
      start_date:  moment(`${allocationStartEndDates().startDate}`),
      _changed: false,
      balanced: false
    },
    resources: resourcePackGenerator(),
    _changed: false
  };
  const secondIssue = {
    allocPack: {
      allocations: allocationPackDatesGenerator(),
      types: {}
    },
    allocator: "future_evenly",
    id: 1383,
    issue: {
      allocator: "future_evenly",
      assigned_to_id: 38,
      columns: {
        project: "Resource project 3",
        subject: "Long duration task 3",
        priority: "Normal"
      },
      end_date: moment(`${allocationStartEndDates().dueDate}`),
      estimated_hours: 35,
      id: 1383,
      name: "Long duration task 3",
      project_id: 56,
      resources: resourcePackGenerator(),
      start_date: moment(`${allocationStartEndDates().startDate}`),
      _changed: false,
      balanced: false
    },
    resources: resourcePackGenerator(),
    _changed: false
  };
  const thirdIssue = {
    allocPack: {
      allocations: allocationPackDatesGenerator(),
      types: {},
    },
    allocator: "future_evenly",
    id: 662,
    issue: {
      allocator: "future_evenly",
      assigned_to_id: 38,
      columns: {
        project: "SCRUM - Custom software development",
        subject: "Image 3",
        priority: "Normal"
      },
      end_date: moment(`${allocationStartEndDates().dueDate}`),
      estimated_hours: 35,
      id: 662,
      name: "Image 3",
      project_id: 42,
      resources: resourcePackGenerator(),
      start_date: moment(`${allocationStartEndDates().startDate}`),
      _changed: false,
      balanced: false
    },
    resources: resourcePackGenerator(),
    _changed: false
  };
  issues.push(thirdIssue, secondIssue, firstIssue);
  return issues;
};

easyJasmine.createUser = function () {
  const assignee = {
    id: 38,
    name: "Dante IT Expert",
    needLoad: false,
    $open:true,
    week_hours: [8, 8, 8, 8, 8, 0, 0],
    events: {}
  };
  return assignee;
};
//######################################################################################################################
describe("Allocators", function () {
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
        '2017-07-05': [{name: "Den slovanských věrozvěstů Cyrila a Metoděje", type: "easy_holiday_event"}],
        '2017-07-06': [{name: "Den upálení mistra Jana Husa", type: "easy_holiday_event"}]
      },
      resources_sums: {},
      week_hours: [4, 2, 0, 8, 6, 0, 0]
    });
    /** @type {Options} */
    $.extend(options, {
      start_date: moment("2017-06-28"),
      end_date: moment("2017-07-15"),
      allocator: "from_start",
      estimated: 46,
      assignee: assignee,
      resources: {},
      today: '2017-07-03'
    });
  });
  var enhanceOptions = window.easyJasmine.enhanceOptions;
  var allocationsToArray = window.easyJasmine.allocationsToArray;
  //####################################################################################################################
  it("Full", function () {
    var results = {
      from_start: [0, 8, 6, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 6, 0],
      from_end: [0, 8, 6, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 6, 0],
      evenly: [0, 8, 6, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 6, 0],
      future_from_start: [0, 0, 0, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 20, 0],
      future_from_end: [0, 0, 0, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 20, 0],
      future_evenly: [0, 0, 0, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 8, 20, 0]
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {allocator: allocator}));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    });
    // easyJasmine.forAnyAllocators(results,function (allocator) {
    //   return function () {
    //     var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {allocator: allocator}));
    //     expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    //   }
    // });
  });
  it("Half", function () {
    var results = {
      from_start: [0, 8, 6, 0, 0, 4, 2, 0, 0, 2.5, 0, 0, 0, 0, 0, 0, 0, 0],
      from_end: [0, 0, 0, 0, 0, 0, 0, 0, 0, 2.5, 0, 0, 4, 2, 0, 8, 6, 0],
      evenly: [0, 2, 2, 0, 0, 2.5, 2, 0, 0, 3, 0, 0, 3, 2, 0, 3, 3, 0],
      future_from_start: [0, 0, 0, 0, 0, 4, 2, 0, 0, 6, 0, 0, 4, 2, 0, 4.5, 0, 0],
      future_from_end: [0, 0, 0, 0, 0, 0, 0, 0, 0, 2.5, 0, 0, 4, 2, 0, 8, 6, 0],
      future_evenly: [0, 0, 0, 0, 0, 3, 2, 0, 0, 3.5, 0, 0, 4, 2, 0, 4, 4, 0]
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {
        allocator: allocator,
        estimated: 22.5
      }));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    });
  });
  it("Fixed half", function () {
    var results = {
      from_start: [0, 8, 4.5, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      from_end: [0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 6.5, 6, 0],
      evenly: [0, 1, 1, 0, 0, 1, 10, 0, 0, 1.5, 0, 0, 2, 2, 0, 2, 2, 0],
      future_from_start: [0, 0, 0, 0, 0, 4, 10, 0, 0, 6, 0, 0, 2.5, 0, 0, 0, 0, 0],
      future_from_end: [0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 6.5, 6, 0],
      future_evenly: [0, 0, 0, 0, 0, 2, 10, 0, 0, 2, 0, 0, 2, 2, 0, 2, 2.5, 0]
    };
    easyJasmine.forAllAllocators(results, function (allocator) {
      var result = ysy.pro.resource.calculateAllocations({}, enhanceOptions(options, {
            allocator: allocator,
            estimated: 22.5,
            resources: {'2017-07-04': {hours: 10, custom: true}}
          }
      ));
      expect(allocationsToArray(result, options)).toEqual(results[allocator]);
    });
  });
});
