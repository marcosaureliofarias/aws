EasyGem.module.part("easyAgile",['ActiveClass'],function () {

    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     *
     * @param params
     * @extends ActiveClass
     * @mixin easyMixins.agile.root;
     * @constructor
     */
    function KanbanRoot(params) {
        $.extend(this, window.easyMixins.agile.root);
        this._loadFromParams(params);
    }


    easyClasses.ActiveClass.extendByMe(KanbanRoot);

    /**
     *
     * @type {RootModel}
     */
    KanbanRoot.prototype.rootModel = null;

    /**
     *
     * @param {Issue} issue
     * @param {String} columnId
     */
    KanbanRoot.prototype.sendPositionChange = function (issue, columnId) {
        this._sendChange({}, issue, columnId);
    };

    /**
     *
     * @type {{String:AgileColumn}}
     */
    KanbanRoot.prototype.columns = null;

    KanbanRoot.prototype.isBacklog = null;


    KanbanRoot.prototype.isDone = null;
    /**
     *
     * @type {String}
     */
    KanbanRoot.prototype.groupBy = null;

    /**
     *
     * @type {Array.<SwimLane>}
     */
    KanbanRoot.prototype.swimLanes = null;

    /**
     *
     * @type {Issues}
     */
    KanbanRoot.prototype.done = null;


    /**
     *
     * @type {Issues}
     */
    KanbanRoot.prototype.backlog = null;
    /**
     *
     * @type {Issues}
     */
    KanbanRoot.prototype.done = null;

    window.easyClasses.agile.KanbanRoot = KanbanRoot;


});
