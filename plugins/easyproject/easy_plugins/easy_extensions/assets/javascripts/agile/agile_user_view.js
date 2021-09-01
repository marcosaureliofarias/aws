EasyGem.module.part("easyAgile", ["EasyWidget"], function() {
  "use strict";
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   * @constructor
   * @param {Object} user
   * @param {Object} userBar
   * @extends {EasyWidget}
   */
  function UserWidget(user, userBar) {
    this.user = user;
    this.template = window.easyTemplates.kanbanUser;
    this.repaintRequested = true;
    this.userBar = userBar;
    this.children = [];
    this.isAvatar = true;
    this.dragDomain = userBar.model.dragDomain;
    var self = this;
    $(window).on("resize", function() {
      self.repaintRequested = true;
    });
    $(document).on("easySidebarToggled", function() {
      self.repaintRequested = true;
    });
  }

  window.easyClasses.EasyWidget.extendByMe(UserWidget);

  UserWidget.prototype.destroy = function() {
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
  };
  /**
   *
   * @override
   */
  UserWidget.prototype._functionality = function() {
    this.$cont = this.$target;
    // window.easyView.root.dragStartOnDomain(this.dragDomain, this);
    var _self = this;
    this.$target.draggable({
      zIndex: 100000,
      revert: true,
      scope: "UserDrag",
      snap: true,
      scrollSensitivity: 100,
      sroll: true
      });
  };
  /**
   * @overrideisAvatar
   */
  UserWidget.prototype.out = function() {
    return { avatarHtml: this.user.avatarHtml, id: this.user.id, name: this.user.name };
  };

  window.easyClasses.agile.UserWidget = UserWidget;
});
