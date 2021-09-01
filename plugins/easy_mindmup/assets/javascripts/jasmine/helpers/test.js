(function () {
  /**
   * Class responsible for Jasmine testing
   * @param {MindMup} ysy
   * @property {MindMup} ysy
   * @constructor
   */
  function JasmineTests(ysy) {
    this.ysy = ysy;
    jasmineHelper.ysy = ysy;
    ysy.eventBus.register("TreeLoaded",function () {
      jasmineHelper.unlock("WBS_data");
    });
  }
  easyMindMupClasses.JasmineTests = JasmineTests;
})();
