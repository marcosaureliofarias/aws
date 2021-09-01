window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.resource = ysy.pro.resource || {};
ysy.pro.resource.features = EasyGem.extend(ysy.pro.resource.features, {reallocateButton: "reallocate"});
ysy.pro.resource.reallocate = ysy.pro.resource.reallocate || {};
EasyGem.extend(ysy.pro.resource.reallocate, {
  patch: function () {
    ysy.pro.toolPanel.registerButton(
        {
          id: "rm_reallocate",
          _name: "ReallocateButton",
          bind: function () {
            this.model = ysy.settings.resource;
          },
          func: function () {
            var issues = ysy.data.issues.getArray();
            ysy.history.openBrack();
            for (var i = 0; i < issues.length; i++) {
              issues[i].getAllocationInstance().recalculate(true);
            }
            ysy.history.closeBrack();
          },
          isHidden: function () {
            return !this.model.open;
          }
        }
    );
  }
});