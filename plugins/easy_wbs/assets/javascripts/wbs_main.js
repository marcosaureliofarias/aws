/**
 * Created by hosekp on 11/14/16.
 */
(function () {
  var classes = window.easyMindMupClasses;

  /**
   * @extends {MindMup}
   * @param {Object} settings
   * @constructor
   */
  function WbsMain(settings) {
    classes.MindMup.call(this, settings);
    var self = this;
    EASY.schedule.require(function () {
      self.helperInit();
      self.patch();
      self.init();
      // this.settings.noSave = true;
      if (window.easyTests) {
        easyTests.ysyInstance = this;
      }
    }, 'jQuery', function () {
      return jQuery.fn.domMapWidget
          && jQuery.fn.mapToolbarWidget
          && jQuery.fn.simpleDraggableContainer
          && MAPJS.DOMRender;
    });
  }

  classes.extendClass(WbsMain, classes.MindMup);


  WbsMain.prototype.patch = function () {
    /** @type {WbsLoader} */
    this.loader = new classes.WbsLoader(this);
    /** @type {WbsNodeVuePatch} */
    if (window.EasyVue && EasyVue.showModal){
      this.vuePatch = new classes.WbsNodeVuePatch(this);
    }
    /** @type {WbsNodePatch} */
    this.nodePatch = new classes.WbsNodePatch(this);
    /** @type {WbsNodePatch} */
    this.storage = new classes.WbsStorage(this);
    /** @type {WbsSaver} */
    this.saver = new classes.WbsSaver(this);
    /** @type {WbsStyles} */
    this.styles = new classes.WbsStyles(this);
    /** @type {WbsValidator} */
    this.validator = new classes.WbsValidator(this);
    /** @type {WbsContextMenu} */
    this.contextMenu = new classes.WbsContextMenu(this);
    /** @type {WbsModals} */
    this.modals = new classes.WbsModals(this);
    /** @type {WbsMoney} */
    if (this.settings.budgetEnabled) {
      this.wbsMoney = new classes.WbsMoney(this);
      /** @type {WbsMoneyModals} */
      this.wbsMoneyModals = new classes.WbsMoneyModals(this);
    }

  };
  /**
   * Modify getIdOfIdea(), so it use proper prefixes
   */
  WbsMain.prototype.getIdOfIdea = function (idea) {
    var id = idea.attr.data.id;
    if (idea.attr.entityType === "project") {
      return "p" + id;
    } else {
      return "i" + id;
    }
  };
  WbsMain.prototype.creatingEntity = "issue";

  classes.WbsMain = WbsMain;
})();
