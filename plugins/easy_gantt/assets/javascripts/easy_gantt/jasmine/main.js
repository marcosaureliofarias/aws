describe("Test framework", function () {
  it("should load", function () {
    expect(true).toBe(true);
    // expect(false).toBe(true);
  });

  it("should start after gantt is loaded", function () {
    expect($(".gantt_data_area").length).toBe(1);
  });
  it("should handle long tests", function (done) {
    setTimeout(function () {
      expect(true).toBe(true);
      done();
    }, 100);
  });
  it("should load extra tests", function () {
    var page = $("html").html();
    var tags = Object.keys(jasmineHelper.data.tags);
    expect(true).toBeTruthy();
    tags.forEach(function (tag) {
      var splitted = tag.split("/");
      if (splitted.length === 1) return;
      var plugin = splitted[0];
      var file = splitted[1];
      if (!["easy_gantt", "easy_gantt_pro", "easy_gantt_resources"].includes(plugin)) return;
      expect(page).toContain(plugin + "/jasmine/" + file + ".js");
      console.log(plugin + file);
    });
  });
});
