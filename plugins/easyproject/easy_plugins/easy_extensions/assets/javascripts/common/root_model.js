(function () {
    window.easyClasses = window.easyClasses || {};

    /**
     *
     * @constructor
     * @name RootModel
     */
    function RootModel() {
        if (easyClasses.root) {
            throw ("only one instance of root model is permitted");
        }
        // all issues are now mean as a all issues for agile board, also with computations. !!!!
        this.allIssues = new easyClasses.Issues();
        this.allIssues.init();
        this.allIssues.rootModel = this;
        this.allUsers = {};
    }

    /**
     *
     * @param {User} user
     * @return User
     */
    RootModel.prototype.addUser = function (user) {
        if (this.allUsers.hasOwnProperty(user.id.toString())) {
            return this.allUsers[user.id.toString()];
        } else {
            this.allUsers[user.id.toString()] = user;
            return user;
        }
    };

    RootModel.prototype.loadUsers = function (users) {
        var allMembersMap = {};
        for (var i = 0; i < users.length; i++) {
            var user = users[i];
            user.avatar_html = user["avatar"];
            user.order = i;
            var createdUser = this.addUser(new easyClasses.User(user));
            allMembersMap[createdUser.id] = createdUser;
        }
        return allMembersMap;
    };

    RootModel.prototype.clear = function () {
        this.allIssues = new easyClasses.Issues();
        this.allIssues.init();
        this.allIssues.rootModel = this;
        this.allUsers = {};
    };

    /**
     * type {Issues}
     */
    RootModel.prototype.allIssues = null;

    /**
     *
     * @type {{User}}
     */
    RootModel.prototype.allUsers = null;

    window.easyClasses.root = new RootModel();
    window.easyClasses.RootModel = RootModel;
})();
