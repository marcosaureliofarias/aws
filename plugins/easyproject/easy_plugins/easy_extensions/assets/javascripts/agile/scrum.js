var scrums = {};
    EasyGem.module.part("easyAgile",function () {

    /**
     * @param {String} targetSelector
     * @param {String} url
     */
    window.easyLoaders.scrum = function (targetSelector, url, swimlane) {
        const reloadAgile = function () {
            window.easyLoaders.scrum(targetSelector, url);
        };
        $.getJSON(url, function (data) {
            window.easyModel = window.easyModel || {};
            window.easyView = window.easyView || {};
            window.easyTemplates.ListItem = data["settings"]["template_card"];
            window.easyTemplates.issueCardWidget = data["settings"]["template_tooltip"];
            window.easyTemplates.kanbanColumnName = data["settings"]["template_column_name"];

            // common model
            var rootModel = easyClasses.root;
            var allMembersMap = rootModel.loadUsers(data["settings"]["project_members"]);
            var issues = new window.easyClasses.Issues();

            issues.loadFromJson(data["entities"], allMembersMap);

            var allIssuesMap = issues.map;

            // kanban model
            var clearColumns = [];
            for (var i = 0; i < data["columns"].length; i++) {
                if (data["columns"][i] != null) {
                    clearColumns.push(data["columns"][i]);
                }
            }

            var isPageModule = targetSelector.match(/module_inside/) ? true : false;
            var scrumRoot = new window.easyClasses.agile.ScrumRoot({
                columnsData: clearColumns,
                update_params_prefix: data.settings.update_params_prefix,
                assign_param_name: data.settings.assign_param_name,
                settings: data.settings,
                url: url,
                swimlane: swimlane,
                i18n: data.i18n,
                allIssuesMap: allIssuesMap,
                allMembersMap: allMembersMap,
                contextMenuUrl: data["settings"]["context_menu_path"],
                dragDomain: targetSelector,
                isPageModule: isPageModule,
                localStorageKey: easyConstants.agileSwimlanesGroupByParameter + targetSelector,
                reloadAgile: reloadAgile
            });

            // model
            // -----
            // view

            var scrum = scrums[targetSelector];
            if (scrum) {
                document.removeEventListener("vueModalIssueChanged",scrum.scrumRoot.reloadAgile, false);
                scrum.scrumRootWidget.destroy();
                scrum.scrumRoot.destroy();
                document.addEventListener("vueModalIssueChanged", reloadAgile);
                // document.removeEventListener()
            } else {
                document.addEventListener("vueModalIssueChanged", reloadAgile);
            }

            var scrumRootWidget = new window.easyClasses.agile.ScrumRootWidget(scrumRoot, true);
            scrumRootWidget.$target = $(targetSelector);
            window.easyView.root.add(scrumRootWidget);
            
            scrums[targetSelector] = {
                scrumRootWidget: scrumRootWidget,
                scrumRoot: scrumRoot
            }
            if (!window.EasyVue || !window.EasyVue.modalData) return;
            setTimeout(window.EasyVue.holdTargetWrapperHeight, 300);
        });
    };

    window.easyLoaders.scrumDestroy = function (selector) {
        var scrum = scrums[selector];
        if (scrum) {
            scrum.scrumRootWidget.destroy();
            scrum.scrumRoot.destroy();
            delete scrums[selector];
        }
    };
    this.scrumLoader = window.easyLoaders.scrum;

    window.easyModel.scrums = scrums;

});
