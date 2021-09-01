jasmineHelper.lock("WBS_data");
describe("Test framework", function () {
  it("should load", function () {
    expect(true).toBe(true);
    // expect(false).toBe(true);
  });

  it("should start after mindmup is loaded", function () {
    expect($("#node_1").length).toBe(1);
  });
  it("should handle long tests", function (done) {
    setTimeout(function () {
      expect(true).toBe(true);
      done();
    }, 100);
  });
});
