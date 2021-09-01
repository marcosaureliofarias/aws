(function () {
    window.easyClasses = window.easyClasses || {};

    /**
     * @constructor
     * @extends ActiveClass
     * @param {Object} json
     */
    function User(json) {
        this._onChange = [];
        this.fromJson(json);
    }

    window.easyClasses.ActiveClass.extendByMe(User);

    /**
     *
     * @type {String}
     */
    User.prototype.id = null;

    /**
     *
     * @type {String}
     */
    User.prototype.name = null;

    /**
     *
     * @type {String}
     */
    User.prototype.firstName = null;

    /**
     *
     * @type {String}
     */
    User.prototype.lastName = null;
    /**
     *
     * @type {String}
     */
    User.prototype.mail = null;

    /**
     *
     * @type {String}
     */
    User.prototype.language = null;

    /**
     *
     * @type {String}
     */
    User.prototype.avatarHtml = null;

    /**
     *
     * @type {String}
     */
    User.prototype.avatarUrl = null;

    /**
     *
     * @type {int}
     */
    User.prototype.status = null;

    /**
     * Safe getter for name. If first and last name is available, use concatenation, else return name field
     * @return {String}
     */
    User.prototype.getName = function(){
        if(typeof this.firstName === "string" && typeof this.lastName === "string"){
           return this.firstName + " " + this.lastName;
        }
        return this.name;
    };

    /**
     * Method for deserialization
     * @param {Object} json
     */
    User.prototype.fromJson = function(json){
        this.id = json.id.toString();

        if(typeof json.login === "string"){
            this.login = json.login;
        }

        if(typeof json.name === "string"){
            this.name = json.name;
        }

        if(typeof json.firstname === "string"){
            this.firstName = json.firstname;
        }

        if(typeof json.lastname === "string"){
            this.lastName = json.lastname;
        }

        if(typeof json.mail === "string"){
            this.mail = json.mail;
        }

        if(typeof json.avatar_url === "string"){
            this.avatarUrl = json.avatar_url;
        }

        if(typeof json.avatar_html === "string"){
            this.avatarHtml = json.avatar_html;
        }

        if(typeof json.status === "number"){
            this.status = json.status;
        }

        if(typeof json.order === "number"){
            this.order = json.order;
        }

        this._fireChanges();
    };

    window.easyClasses.User = User;

})();
