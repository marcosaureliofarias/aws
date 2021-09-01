(function () {
    window.easyClasses = window.easyClasses || {};
    /**
     * Widget for painting avatar of dragged issue over agile
     * @param {Issue} issue
     * @constructor
     * @extends EasyWidget
     */
    function IssueCardWidget(issue) {
        this.issue = issue;
        this.issue.register(this.onChange, this);
        this.template = window.easyTemplates.issueCardWidget;
        this.children = [];
        this.repaintRequested = true;
    }

    window.easyClasses.EasyWidget.extendByMe(IssueCardWidget);

    IssueCardWidget.prototype.onChange = function () {
        this.repaintRequested = true;
    };

    /**
     *
     * @override
     */
    IssueCardWidget.prototype.out = function () {
        return this.issue;
    };

    IssueCardWidget.prototype._functionality = function () {
        if (this.issue.error && this.issue.errorMessage !== null) {
            this.$target.prepend("<div class=\"flash error\">" + this.issue.errorMessage + "</div>");
        }
    };

    window.easyClasses.IssueCardWidget = IssueCardWidget;

})();