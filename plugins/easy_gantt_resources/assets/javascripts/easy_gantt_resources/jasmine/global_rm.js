describe("Global RM", function () {
  it("should fail anywhere but global RM", function () {
    expect(ysy.settings.global).toBe(true);
    expect(ysy.settings.isResourceManagement).toBe(true);
    expect(ysy.data.loader.loaded).toBe(true);
  });
});
