EasyGem.module.part("easyAgile",[ 'EasyWidget'],function () {
    window.easyClasses = window.easyClasses || {};
    window.easyClasses.agile = window.easyClasses.agile || {};

    function AgileGroupSelectWidget(options, agileRootModel) {
        this.children = [];
        this.repaintRequested = true;
        this.options = options;
        this.template = easyTemplates.kanbanGroupSelect;
        this.agileRootModel = agileRootModel;
        this.labeSwimlane = this.agileRootModel.i18n.swimlane;
    }

    easyClasses.EasyWidget.extendByMe(AgileGroupSelectWidget);

    /**
     * @override
     */
    AgileGroupSelectWidget.prototype.out = function () {
        return {options: this.options, swimlane: this.labeSwimlane};
    };
    /**
     * @override
     */
    AgileGroupSelectWidget.prototype._functionality = function () {
        this.$select = this.$target.find("select");
        var _self = this;
        this.$select.on("change", function () {
            _self.agileRootModel.setGroupBy(this.value);
            window.easyView.sticky.scheduleRebuild();
        });
    };

    window.easyClasses.agile.AgileGroupSelectWidget = AgileGroupSelectWidget;

});
