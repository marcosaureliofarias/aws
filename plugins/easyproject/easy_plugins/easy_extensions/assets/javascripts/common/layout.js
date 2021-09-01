(function () {
    window.easyView = window.easyView || {};
    /**
     *
     * @constructor
     * @extends {EasyWidget}
     */
    function EasyRowWidget() {
        /** @type {Array.<EasyColWidget>} */
        this.children = [];
        this.rowTemplate = easyTemplates.column;
        this.widgetTemplate = "_";
        this.template = this.rowTemplate;
        this.bonusClasses = "";
        this.isSticky = false;

    }

    window.easyClasses.EasyWidget.extendByMe(EasyRowWidget);


    /**
     * @override
     */
    EasyRowWidget.prototype.setChildTarget = function (child, i) {
        if (this.template == this.widgetTemplate) {
            child.$target = this.$target;
        } else {
            if (this.isSticky && this.$clone) {
                child.$target = this.$clone.find(".col" + i);
            } else {
                child.$target = this.$target.find(".col" + i);
            }

        }

    };

    EasyRowWidget.prototype.destroy = function () {
        if (this.$target && this.$target.length !== 0) {
            window.easyView.sticky.remove(this.$target);
            this.$clone = null;
        }
        window.easyClasses.EasyWidget.prototype.destroy.apply(this);
    };


    EasyRowWidget.prototype._functionality = function () {
        var _self = this;
        if (this.isSticky) {
            if (this.$lastStickyTarget) {
                window.easyView.sticky.remove(this.$lastStickyTarget);
                _self.$clone = null;
            }
            this.$target.addClass("sticky");
            window.easyView.sticky.add(this.$target, {
                onCloneCreated: function ($clone) {
                    _self.$clone = $clone;
                    for (var i = 0; i < _self.children.length; i++) {
                        var child = _self.children[i];
                        _self.setChildTarget(child, i);
                        child.repaintRequested = true;
                    }
                }
            });
            this.$lastStickyTarget = this.$target;
        }
    };

    /**
     * @override
     * @returns {{cols: Array}}
     */
    EasyRowWidget.prototype.out = function () {
        var out = [];
        for (var i = 0; i < this.children.length; i++) {
            out.push({
                "order": i,
                "bonusClasses": this.children[i].bonusClasses
            });
        }
        return {
            cols: out
        }
    };


    /**
     * @return EasyColWidget
     * @param {number} [i]
     */
    EasyRowWidget.prototype.addCol = function (i) {
        var col = new EasyColWidget();
        this.template = this.rowTemplate;
        if (i !== null && (typeof(i)) === "number" && this.children.length > i) {
            col.$target = this.children[i].$target;
            this.children[i].destroy();
            this.children[i] = col;
        } else {
            this.children.push(col);
            this.repaintRequested = true;
        }
        return col;
    };


    /**
     * @param {EasyWidget} widget
     */
    EasyRowWidget.prototype.setWidget = function (widget) {
        this.children = [widget];
        this.template = this.widgetTemplate;
        this.repaintRequested = true;
    };


    /**
     *
     * @param {Widget|int} col
     */
    EasyRowWidget.prototype.removeCol = function (col) {
        this.removeChild(col);
    };

    window.easyClasses.EasyRowWidget = EasyRowWidget;


    /**
     *
     * @constructor
     * @extends {EasyWidget}
     */
    function EasyColWidget() {
        /** @type {Array.<EasyRowWidget>} */
        this.children = [];
        this.colTemplate = easyTemplates.row;
        this.widgetTemplate = "_";
        this.template = this.colTemplate;
        this.bonusClasses = "";
        this.bonusStyle = false;
    }

    window.easyClasses.EasyWidget.extendByMe(EasyColWidget);

    /**
     * @return EasyRowWidget
     */
    EasyColWidget.prototype.addRow = function () {
        var row = new EasyRowWidget();
        this.children.push(row);
        this.template = this.colTemplate;
        this.repaintRequested = true;
        return row;
    };

    /**
     * @param {EasyWidget} widget
     */
    EasyColWidget.prototype.setWidget = function (widget) {
        this.children = [widget];
        this.template = this.widgetTemplate;
        this.repaintRequested = true;
    };

    /**
     * @override
     */
    EasyColWidget.prototype.setChildTarget = function (child, i) {
        if (this.template == this.widgetTemplate) {
            child.$target = this.$target;
        } else {
            child.$target = this.$target.find(".row" + i);
        }
    };
    /**
     * @override
     */
    EasyColWidget.prototype._functionality = function (child, i) {
        if (this.bonusStyle) {
            this.$target.css(this.bonusStyle);
        }
    };

    /**
     *
     * @param {Widget|int} row
     */
    EasyColWidget.prototype.removeRow = function (row) {
        this.removeChild(row);
    };

    /**
     * @override
     * @returns {{rows: Array}}
     */
    EasyColWidget.prototype.out = function () {
        var out = [];
        for (var i = 0; i < this.children.length; i++) {
            out.push({
                "order": i,
                "bonusClasses": this.children[i].bonusClasses
            });
        }
        return {
            rows: out
        }
    };

    /**
     *
     * @param {String} template
     * @param {*} data
     */
    EasyColWidget.prototype.addContent = function (template, data) {
        var widget = new easyClasses.EasyWidget();
        widget.template = template;
        widget.out = function () {
            return data;
        };
        widget.children = [];
        widget.bonusClasses = "";
        this.children.push(widget);
    };
    window.easyClasses.EasyColWidget = EasyColWidget;
})();