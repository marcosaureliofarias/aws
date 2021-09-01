describe("Lang",function () {
  it("should not show TRANSLATION MISSING",function () {
    var content = document.body.innerHTML.replace(/<script.*?\/script>/smg,"").replace(/<.*?>/smg,"");
    var index = content.indexOf("translation missing");
    var chunk = content.substring(Math.max(index-30,0),Math.min(index+60,content.length));
    expect(chunk).not.toContain("translation missing");
    expect(index).toBe(-1);
  });
  xit("should not be TRANSLATION MISSING",function () {
    var content = document.body.innerHTML;
    var index = content.indexOf("translation missing");
    var chunk = content.substring(Math.max(index-30,0),Math.min(index+80,content.length));
    expect(chunk).not.toContain("translation missing");
    expect(index).toBe(-1);
  });
});