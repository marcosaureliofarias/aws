/**
 * Created by hosekp on 6/12/17.
 */
describe("encodeLayout", function () {
  beforeAll(function () {
    this.ysy = jasmineHelper.ysy;
  });
  it("small", function () {
    var layout = {"p25": {}, "i2280": {"rank": 1}, "i3027": {"rank": 5, "position": [808.5, 111.25, 1]}};
    var encoded = this.ysy.storage.extra._encodeLayout(layout);
    var decoded = this.ysy.storage.extra._decodeLayout(encoded);
    expect(typeof decoded).toEqual("object");
    expect(Object.keys(decoded).length).toEqual(3);
    expect(decoded).toEqual(layout);
  });
  it("random", function () {
    var length = 1000;
    var layout = {};
    for (var i = 0; i < length; i++) {
      var data = {"rank": i % 10+1};
      if (i % 11 === 0) {
        data.position = [Math.random() * 1000, Math.random() * 1000, 1];
      }
      layout["i" + (256 + i)] = data;
    }
    var encoded = this.ysy.storage.extra._encodeLayout(layout);
    var decoded = this.ysy.storage.extra._decodeLayout(encoded);
    expect(typeof decoded).toEqual("object");
    expect(Object.keys(decoded).length).toEqual(length);
    expect(decoded).toEqual(layout);
  });
});
