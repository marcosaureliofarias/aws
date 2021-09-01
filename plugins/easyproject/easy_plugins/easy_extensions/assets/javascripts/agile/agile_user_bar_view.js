EasyGem.module.part("easyAgile", ["EasyWidget"], function() {
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   *
   * @constructor
   * @param {IssuesCol} model
   * @param {Array} [members]
   * @extends {EasyWidget}
   */
  function UserBarWidget(model, members) {
    this.users = members;
    this.template = window.easyTemplates.kanbanUserBar;
    this.members = [];
    this.repaintRequested = true;
    this.model = model;
    this.childTarget = ".agile__top-container";
    this.children = [];
    this.isAvatar = true;
    var self = this;
    this._createChildren();
  }

  window.easyClasses.EasyWidget.extendByMe(UserBarWidget);

  UserBarWidget.prototype._createChildren = function() {
    let i = 0;
    this.users.forEach(user => {
      this.members.push({
        name: user.name,
        id: user.id,
        avatarHtml: user.avatar
      });
      this.children.push(
        new window.easyClasses.agile.UserWidget(this.members[i], this)
      );
      i++;
    });
  };

  UserBarWidget.prototype.destroy = function() {
    window.easyClasses.EasyWidget.prototype.destroy.apply(this);
  };

  UserBarWidget.prototype.setChildrenTarget = function() {
    var i = 0;
    for (i; i < this.children.length; i++) {
      this.children[i].$target = this.$target.find(
        ".agile_user-" + this.children[i].user.id
      );
    }
  };

  /**
   * @override
   */
  UserBarWidget.prototype.out = function() {
    return { users: this.members };
  };

  UserBarWidget.prototype._functionality = function() {};

  /**
   *
   * @type {string}
   */
  UserBarWidget.prototype.bonusClasses = "";

  window.easyClasses.agile.UserBarWidget = UserBarWidget;
});
