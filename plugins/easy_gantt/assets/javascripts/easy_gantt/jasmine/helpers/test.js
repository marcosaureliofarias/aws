jasmineHelper.lock("gantt_data");
window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.test = {
  patch: function () {
    ysy.data.loader.register(function () {
      setTimeout(function () {
        jasmineHelper.unlock("gantt_data");
      }, 0);
    }, this);
  }
};
