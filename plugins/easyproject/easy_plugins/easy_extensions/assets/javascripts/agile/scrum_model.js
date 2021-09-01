EasyGem.module.part("easyAgile",['ActiveClass'],function () {
    "use strict"
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    /**
     *
     * @param params
     * @extends ActiveClass
     * @mixin easyMixins.agile.root;
     * @constructor
     */
    function ScrumRoot(params) {
        $.extend(this, window.easyMixins.agile.root);
        this._loadFromParams(params);
    }

    easyClasses.ActiveClass.extendByMe(ScrumRoot);

    /**
     *
     * @type {RootModel}
     */
    ScrumRoot.prototype.rootModel = null;

    /**
     *
     * @param {Issue} issue
     * @param {String} columnId
     */
    ScrumRoot.prototype.sendPositionChange = function (issue, columnId) {
        this._sendChange({}, issue, columnId);
    };

    /**
     *
     * @type {{String:AgileColumn}}
     */
    ScrumRoot.prototype.columns = null;

    ScrumRoot.prototype.isBacklog = null;


    ScrumRoot.prototype.isDone = null;
    /**
     *
     * @type {String}
     */
    ScrumRoot.prototype.groupBy = null;

    /**
     *
     * @type {Array.<SwimLane>}
     */
    ScrumRoot.prototype.swimLanes = null;

    /**
     *
     * @type {Issues}
     */
    ScrumRoot.prototype.done = null;


    /**
     *
     * @type {Issues}
     */
    ScrumRoot.prototype.backlog = null;
    /**
     *
     * @type {Issues}
     */
    ScrumRoot.prototype.done = null;

    window.easyClasses.agile.ScrumRoot = ScrumRoot;

});
