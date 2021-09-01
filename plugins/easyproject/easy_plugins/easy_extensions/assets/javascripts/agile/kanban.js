EasyGem.module.part("easyAgile",function () {
    window.easyModel = window.easyModel || {};
    window.easyView = window.easyView || {};
    var kanbans = {};

    /**
     * @param {String} targetSelector
     * @param {String} url
     */
    window.easyLoaders.kanban = function (targetSelector, url, swimlane) {
        const reloadAgile = function () {
            window.easyLoaders.kanban(targetSelector, url);
        };
        $.getJSON(url, function (data) {
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

            var kanbanRoot = new window.easyClasses.agile.KanbanRoot({
                columnsData: clearColumns,
                update_params_prefix: data.settings.update_params_prefix,
                assign_param_name: data.settings.assign_param_name,
                settings: data.settings,
                i18n: data.i18n,
                url: url,
                swimlane: swimlane,
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

            var kanban = kanbans[targetSelector];
            if (kanban) {
                kanban.kanbanRootWidget.destroy();
                kanban.kanbanRoot.destroy();
            } else {
                document.addEventListener("vueModalIssueChanged", reloadAgile);
            }

            var kanbanRootWidget = new window.easyClasses.agile.KanbanRootWidget(kanbanRoot);
            kanbanRootWidget.$target = $(targetSelector);
            window.easyView.root.add(kanbanRootWidget);

            kanbans[targetSelector] = {
                kanbanRootWidget: kanbanRootWidget,
                kanbanRoot: kanbanRoot
            }
            if (!window.EasyVue || !window.EasyVue.modalData) return;
            setTimeout(window.EasyVue.holdTargetWrapperHeight, 300);
        });
    };

    window.easyLoaders.kanbanDestroy = function (selector) {
        var kanban = kanbans[selector];
        if (kanban) {
            kanban.kanbanRootWidget.destroy();
            kanban.kanbanRoot.destroy();
            delete kanbans[selector]
        }
    };

    this.kanbanLoader = window.easyLoaders.kanban;

    window.easyModel.kanbans = kanbans;

});
