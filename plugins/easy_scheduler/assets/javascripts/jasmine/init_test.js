jasmineHelper.lock("tasks");
describe("Init",function () {
  beforeEach(jasmineHelper.initPageMatchers);
  it("tasks inited",function () {
    expect(".easy-calendar__task-list").toExistsOnPage();
    expect(".easy-calendar__task").toExistsOnPage();
    expect(easyScheduler.taskData.tasks.length).toBeGreaterThan(0);
  });
});
