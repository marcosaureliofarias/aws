(function () {
    window.easyClasses = window.easyClasses || {};
    window.easyView = window.easyView || {};

    /**
     *
     * @constructor
     * @name EasyWidget
     */
    function EasyWidget() {
        this.children = [];
    }

    EasyWidget.extendByMe = function (Child) {
        var F = new Function();
        F.prototype = EasyWidget.prototype;
        Child.prototype = new F();
        Child.prototype.constructor = Child;
        Child.superclass = EasyWidget.prototype;
    };

    /**
     *
     * @type {EasyWidget}
     */
    EasyWidget.prototype.parent = null;

    /**
     * @type {jQuery}
     */
    EasyWidget.prototype.$target = null;

    /**
     *
     * @type {Array.<EasyWidget>}
     */
    EasyWidget.prototype.children = null;

    /**
     *
     * @type {string}
     */
    EasyWidget.prototype.template = "";

    /**
     * repaint requested stacks repaints on repaint loop. Disable repaint if false, process repaint, if parent repainted
     * @type {boolean}
     */
    EasyWidget.prototype.repaintRequested = null;

    /**
     * freeze repaints on repaintRequested=true
     * @type {boolean}
     */
    EasyWidget.prototype.keepPaintedState = null;

    /**
     * sets repaintRequested to true
     */
    EasyWidget.prototype.requestRepaint = function () {
        this.repaintRequested = true;
    };

    /**
     * recursive repaint on all widgets can be denied by repaintRequested if force is not true
     * @param {boolean} [force]
     */
    EasyWidget.prototype.repaint = function (force) {
        if (this.keepPaintedState) {
            this.onNoRepaint();
            return;
        }
        if (this.repaintRequested || force) {
            this.repaintRequested = !!this._repaintCore();
        } else {
            this.onNoRepaint();
            for (var i = 0; i < this.children.length; i++) {
                this.children[i].repaint();
            }
        }
    };

    /**
     * render html
     * @returns {boolean}
     * @protected
     */
    EasyWidget.prototype._repaintCore = function () {
        if (!this.template) {
            if (!window.hasOwnProperty("ysy")) {
                throw "missing template in Widget above in console";
            }
            var template = ysy.view.getTemplate(this.templateName);
            if (template) {
                this.template = template;
            } else {
                return true;
            }
        }
        if (this.$target === null || this.$target.length === 0) {
            throw "Target is null for " + (this.templateName ? this.templateName : this.template);
        }
        this.$target.html(Mustache.render(this.template, this.out()));
        this._functionality();
        var child;
        for (var i = 0; i < this.children.length; i++) {
            child = this.children[i];
            this.setChildTarget(child, i);
        }
        this.setChildrenTarget();
        // targeting MUST BE SEPARATED from repainting because of searching inside rendered children
        for (i = 0; i < this.children.length; i++) {
            child = this.children[i];
            child.repaint(true);
        }
    };

    /**
     * method to override to place individual functionality
     * @protected
     */
    EasyWidget.prototype._functionality = function () {

    };
    /**
     * method to override to place individual functionality
     */
    EasyWidget.prototype.destroy = function () {
        if (this.destroyed)return;
        this.$target = null;
        for (var i = 0; i < this.children.length; i++) {
            this.children[i].destroy();
        }
    };

    /**
     *
     * @param {Widget|int} listEntity
     */
    EasyWidget.prototype.removeChild = function (listEntity) {
        var index;
        if (typeof  listEntity === "number") {
            index = listEntity;
        } else {
            index = this.list.indexOf(listEntity);

        }
        if (index > -1) {
            this.list.splice(index, 1);
        }
        this.repaintRequested = true;
    };

    /**
     * prepare data for mustache
     * @return {Object}
     */
    EasyWidget.prototype.out = function () {
        return {};
    };

    /**
     *
     * @param {EasyWidget} child
     * @param {int} i
     */
    EasyWidget.prototype.setChildTarget = function (child, i) {
    };

    EasyWidget.prototype.setChildrenTarget = function () {
    };

    /**
     * method to be overridden called on every repaint loop without repaint
     * useful for manual content change
     */
    EasyWidget.prototype.onNoRepaint = function () {

    };

    window.easyClasses.EasyWidget = EasyWidget;
})();
