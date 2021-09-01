window.easyClasses = window.easyClasses || {};

(function () {

    /**
     * callback to call in context
     *
     * @name RegisteredCallback
     * @param {Function} callback
     * @param {Object} context
     * @param {*} [data]
     * @constructor
     */
    function RegisteredCallback(callback, context, data) {
        this.context = context;
        this.callback = callback;
        this.data = data;
    }

    /**
     * @type {Function}
     */
    RegisteredCallback.prototype.callback = null;

    /**
     *
     * @type {Object}
     */
    RegisteredCallback.prototype.context = null;

    /**
     * expando data for solve mutable variable in a cycle
     * @type {*}
     */
    RegisteredCallback.prototype.data = null;

    /**
     * @constructor
     * @name ActiveClass
     * Class for adding setter and getter to another classes
     */
    function ActiveClass() {
        this._onChange = [];
    }

    /**
     * @type {Function}
     * @param {Object} Child
     * @param {Object} Parent
     */
    ActiveClass.prototype.extend = function (Child, Parent) {
        var F = new Function();
        F.prototype = Parent.prototype;
        Child.prototype = new F();
        Child.prototype.constructor = Child;
        Child.superclass = Parent.prototype;
    };

    /**
     * @type {Function}
     * @param {Object} Child
     */
    ActiveClass.extendByMe = function (Child) {
        var F = new Function();
        F.prototype = ActiveClass.prototype;
        Child.prototype = new F();
        Child.prototype.constructor = Child;
        Child.superclass = ActiveClass.prototype;
    };

    /** @type {Object} no idea for what it could be used */
    ActiveClass.prototype._old = null;

    /**
     * @public
     * @param {Object} [object] old object to extend
     * @return {ActiveClass}
     */
    ActiveClass.prototype.init = function (object) {
        if (object) {
            this._old = object;
            $.extend(this, object);
        }
        this._onChange = [];
        this._postInit();
        return this;
    };

    // ActiveClass.prototype.extend = extend;

    /**
     *
     * @private
     */
    ActiveClass.prototype._postInit = function () {
    };

    /**
     * must be null because of shared bugs
     * @type {Array.<RegisteredCallback>}
     * @private
     */
    ActiveClass.prototype._onChange = null;

    /**
     * set will save property and fires change event
     * @public
     * @param {String} key member name of object
     * @param {*} value new member value
     * @return {boolean} say if operation completed successfully
     *
     */
    ActiveClass.prototype.set = function (key, value) {
        // in the case of object as a first parameter:
        // - parameter key is object and parameter val is not used.
        if (typeof key === "object") {
            var nObj = key;
        } else {
            nObj = {};
            nObj[key] = value;
        }
        var rev = {};
        for (var k in nObj) {
            if (!nObj.hasOwnProperty(k))continue;
            var nObjk = nObj[k];
            var thisk = this[k];
            if (nObjk !== thisk) {
                if (thisk && nObjk && nObjk._isAMomentObject && nObjk.isSame(thisk)) {
                    continue;
                }
                rev[k] = thisk;
                if (rev[k] === undefined) {
                    rev[k] = false;
                }
            }
        }
        if ($.isEmptyObject(rev)) {
            return false;
        }
        $.extend(this, nObj);
        this._fireChanges("set", this);
        return true;
    };


    /**
     * @param {Function} callback
     * @param {Object} context
     * @param {*} [data]
     */
    ActiveClass.prototype.register = function (callback, context, data) {
        var input = new RegisteredCallback(callback, context, data);
        for (var i = 0; i < this._onChange.length; i++) {
            if (this._onChange[i].context === context) {
                this._onChange[i] = input;
                return;
            }
        }
        this._onChange.push(input);
    };

    /**
     * @param {Object} context
     */
    ActiveClass.prototype.unRegister = function (context) {
        var noChange = [];
        for (var i = 0; i < this._onChange.length; i++) {
            var reg = this._onChange[i];
            if (reg.context !== context) {
                noChange.push(reg);
            }
        }
        this._onChange = noChange;
    };

    /**
     * will save property, not fire at all
     * if first argument is object, merge with this
     * @public
     * @param {String|Object} key member name of object
     * @param {*} value new member value
     * @return {boolean} say if something has changed. This may be important for cascade event fires.
     */
    ActiveClass.prototype.setSilent = function (key, value) {
        if (typeof key === "object") {
            var different;
            var keyk, thisk;
            for (var k in key) {
                if (!key.hasOwnProperty(k)) continue;
                keyk = key[k];
                thisk = this[k];
                if (keyk === thisk)continue;
                if (thisk && keyk && keyk._isAMomentObject && keyk.isSame(thisk))continue;
                this[k] = keyk;
                different = true;
            }
            return different || false;
            //$.extend(this, key);
        } else {
            if (this[key] === value) return false;
            this[key] = value;
            return true;
        }
    };

    /**
     *
     * @param {String} [event]
     * @param {*} [data]
     * @protected
     */
    ActiveClass.prototype._fireChanges = function (event, data) {
        for (var i = 0; i < this._onChange.length; i++) {
            var cb = this._onChange[i];
            cb.callback.apply(cb.context, [event, data, cb.data]);
        }
    };

    window.easyClasses.ActiveClass = ActiveClass;


    /**
     * @name ActiveCollection
     * @constructor
     * @extends ActiveClass
     */
    function ActiveCollection() {
        this.list = [];
    }

    ActiveClass.extendByMe(ActiveCollection);

    /**
     * @type {Function}
     * @param {Object} Child
     */
    ActiveCollection.extendByMe = function (Child) {
        var F = new Function();
        F.prototype = ActiveCollection.prototype;
        Child.prototype = new F();
        Child.prototype.constructor = Child;
        Child.superclass = ActiveCollection.prototype;
    };


    /**
     *
     * @type {Array}
     *
     */
    ActiveCollection.prototype.list = null;

    /**
     *
     * @param {*} listEntity
     * @param {*} event
     */
    ActiveCollection.prototype.add = function (listEntity, event) {
        this.list.push(listEntity);
        if (event === null || event === undefined) {
            event = "add";
        }
        this._fireChanges(event, listEntity);
    };

    /**
     *
     * @param {*} listEntity
     * @param {*} event
     */
    ActiveCollection.prototype.remove = function (listEntity, event) {
        var index = this.list.indexOf(listEntity);
        if (index > -1) {
            this.list.splice(index, 1);
        }
        if (event === null || event === undefined) {
            event = "remove";
        }
        this._fireChanges(event, listEntity);
    };

    window.easyClasses.ActiveCollection = ActiveCollection;


    /**
     * @name CustomCollection
     * @constructor
     */
    function CustomCollection() {
        this.list = [];
    }


    /**
     * @type {Function}
     * @param {Object} Child
     */
    CustomCollection.extendByMe = function (Child) {
        var F = new Function();
        F.prototype = CustomCollection.prototype;
        Child.prototype = new F();
        Child.prototype.constructor = Child;
        Child.superclass = CustomCollection.prototype;
    };


    /**
     *
     * @type {Array}
     *
     */
    CustomCollection.prototype.list = null;

    /**
     *
     * @param {*} listEntity
     */
    CustomCollection.prototype.add = function (listEntity) {
        this.list.push(listEntity);
    };

    /**
     *
     * @param {*} listEntity
     */
    CustomCollection.prototype.remove = function (listEntity) {
        var index = this.list.indexOf(listEntity);
        if (index > -1) {
            this.list.splice(index, 1);
        }
    };

    window.easyClasses.CustomCollection = CustomCollection;

})();

/**
 * Utility to freeze actual DOM state, for example dropdown menu
 */
function easyBreak() {
    function doBreak() {
        // to freeze current dom write to console easyBreak()
        // you have 3 seconds to get to desired state
        throw "easy break";
    }

    window.setTimeout(doBreak, 3000);
}

// polyfill for IE 11 (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith)
if (!String.prototype.endsWith) {
    String.prototype.endsWith = function(searchString, position) {
        var subjectString = this.toString();
        if (typeof position !== 'number' || !isFinite(position) || Math.floor(position) !== position || position > subjectString.length) {
            position = subjectString.length;
        }
        position -= searchString.length;
        var lastIndex = subjectString.lastIndexOf(searchString, position);
        return lastIndex !== -1 && lastIndex === position;
    };
}
