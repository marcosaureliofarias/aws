EasyGem.module.part("easyAgile", function () {
  /**
   * @param {String} targetSelector
   * @param {String} url
   * @param {Object} query_data
   */
  window.easyLoaders.epicBacklogLoader = function (targetSelector, url, query_data) {
    const reloadAgile = function () {
      window.easyLoaders.epicBacklogLoader(targetSelector, url);
  };


    function recalculateAutocompleteWidth() {
      const $wrap = $(".sticky_agile_backlog_autocomplete_wrap");
      const $row = $(".agile__row");
      let width;
      if ($row.length === 0) return;
      width = $row.width();
      if (width && width !== 0) {
        $wrap.css({ width: width });
      }
      window.easyView.sticky.rebuild();
    }

    $.getJSON(url, query_data, function (data) {
      let i;
      window.easyModel = window.easyModel || {};
      window.easyView = window.easyView || {};
      window.easyTemplates.ListItem = data["settings"]["template_card"];
      window.easyTemplates.issueCardWidget = data["settings"]["template_tooltip"];
      window.easyTemplates.kanbanColumnName = data["settings"]["template_column_name"];

      if (window.easyModel.epicBacklogRoot) {
        document.removeEventListener("vueModalIssueChanged", window.easyModel.epicBacklogRoot.reloadAgile, false);
        easyClasses.root.clear();
      }

      // common model
      let rootModel = easyClasses.root;
      let projectMembersData = data["settings"]["project_members"];
      for (i = 0; i < projectMembersData.length; i++) {
        let user = projectMembersData[i];
        user.avatar_html = user["avatar"];
        rootModel.addUser(new easyClasses.User(user));
      }

      rootModel.allIssues.loadFromJson(data["entities"], rootModel.allUsers);
      easyClasses.agile.ListWidget.contextMenuUrl = data["settings"]["context_menu_path"];

      const epicBacklogRoot = new window.easyClasses.agile.EpicBacklogRoot(
        rootModel, data["columns"],
        data.settings.update_params_prefix,
        data.settings.assign_param_name,
        data.settings,
        data.i18n,
        data["settings"]["context_menu_path"],
        data["epic"],
        reloadAgile
        );

      window.easyModel.epicBacklogRoot = epicBacklogRoot;

      // model
      // -----
      // view


      if (window.easyView.EpicBacklogRootWidget !== undefined) {
        window.easyView.root.remove(window.easyView.EpicBacklogRootWidget);
        window.easyLoaders.epicBacklogDestroy();
      }

      window.easyView.EpicBacklogRootWidget = new window.easyClasses.agile.EpicBacklogRootWidget(epicBacklogRoot);
      window.easyView.EpicBacklogRootWidget.$target = $(targetSelector);
      window.easyView.root.add(window.easyView.EpicBacklogRootWidget);

      recalculateAutocompleteWidth();
      window.setTimeout(recalculateAutocompleteWidth, 200);
      window.setTimeout(recalculateAutocompleteWidth, 1000);
      window.easyView.root.listenWrapHeightChange(recalculateAutocompleteWidth);
      $(window).resize(recalculateAutocompleteWidth);
      document.addEventListener("vueModalIssueChanged", reloadAgile);
    });
  };


  window.easyLoaders.epicBacklogDestroy = function () {
    easyView.EpicBacklogRootWidget.destroy();
    delete easyView["EpicBacklogRootWidget"];
    delete easyModel["epicBacklogRoot"];
  };

  this.epicBacklogLoader = window.easyLoaders.epicBacklogLoader;
});
