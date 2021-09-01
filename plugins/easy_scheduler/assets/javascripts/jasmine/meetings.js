
describe("Meetings",function () {
  it("is ordered",function () {
    // expect(document.getElementsByClassName("easy-calendar__meeting").length).toBeGreaterThan(0);
    var user = easyScheduler.assigneeData.getCurrentUser();
    expect(user).toBeDefined();
    var userMeetings = easyScheduler.meetings.userMeetingsMap[user.id];
    expect(userMeetings).toBeDefined();
    expect(userMeetings.start).toBeLessThanOrEqual(easyScheduler.scheduler._min_date.valueOf());
    expect(userMeetings.end).toBeGreaterThanOrEqual(easyScheduler.scheduler._max_date.valueOf());
  });
});