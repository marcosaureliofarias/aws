describe("Balancer tests", () => {
  let assignee;
  let options = {};
  it("Balance for opened user", async () => {
    const res = {
      0: [4, 8, 8, 8, 7],
      1: [0, 0, 0, 0, 35],
      2: [0, 0, 0, 0, 35]
    };
    const alloccations = ysy.data.allocations;
    const user = window.easyJasmine.createUser();
    alloccations.array = window.easyJasmine.createIssueArray();
    const firstDate = Object.keys(alloccations.array[0].allocPack.allocations)[0];
    user.events[firstDate] = [{ hours: 4, type: "Meeting" }];
    ysy.data.assignees.array = [];
    ysy.settings.priorities = ["Urgent", "High", "Normal", "Low"];
    gantt._pull[`a${user.id}`] = user;
    ysy.data.assignees.array.push(user);
    await ysy.pro.resource.balance.balanceTasks();
    alloccations.array.forEach((elem,i) => {
      const options = {
        start_date: elem.issue.start_date,
        end_date: elem.issue.end_date,
      };
      const allocPack = easyJasmine.allocationsToArray(elem.allocPack, options);
      expect(elem.issue.balanced).toBe(true);
      expect(allocPack).toEqual(res[i]);
    });
    document.querySelector("#button_save").click();
  });
});
