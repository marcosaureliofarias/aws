EasyGem.module.part("easyAgile", function () {
  /**
   * @param {String} targetSelector
   * @param {String} url
   * @param {Object} query_data
   */
  window.easyLoaders.backlog = function (targetSelector, url, query_data) {
    const reloadAgile = function () {
      window.easyLoaders.backlog(targetSelector, url);
    };

    function recalculateAutocompleteWidth() {
      var $wrap = $(".sticky_agile_backlog_autocomplete_wrap");
      var $row = $(".agile__row");
      var width;
      if ($row.length === 0) return;
      width = $row.width();
      if (width && width !== 0) {
        $wrap.css({width: width});
      }
      window.easyView.sticky.rebuild();
    }


    $.getJSON(url, query_data, function (data) {
      var i;
      window.easyModel = window.easyModel || {};
      window.easyView = window.easyView || {};
      window.easyTemplates.ListItem = data["settings"]["template_card"];
      window.easyTemplates.issueCardWidget = data["settings"]["template_tooltip"];
      window.easyTemplates.kanbanColumnName = data["settings"]["template_column_name"];

      if (window.easyModel.backlogRoot) {
        easyClasses.root.clear();
      }

      // common model
      var rootModel = easyClasses.root;
      var projectMembersData = data["settings"]["project_members"];
      for (i = 0; i < projectMembersData.length; i++) {
        var user = projectMembersData[i];
        user.avatar_html = user["avatar"];
        rootModel.addUser(new easyClasses.User(user));
      }

      rootModel.allIssues.loadFromJson(data["entities"], rootModel.allUsers);
      easyClasses.agile.ListWidget.contextMenuUrl = data["settings"]["context_menu_path"];


      var backlogRoot = new window.easyClasses.agile.BacklogRoot(
          rootModel, data["columns"],
          data.settings.update_params_prefix,
          data.settings.assign_param_name,
          data.settings,
          data["settings"]["context_menu_path"],
          reloadAgile);

      window.easyModel.backlogRoot = backlogRoot;

      // model
      // -----
      // view
      if (window.easyView.backlogRootWidget !== undefined) {
        window.easyView.root.remove(window.easyView.backlogRootWidget);
        window.easyLoaders.backlogDestroy();
      }

      window.easyView.backlogRootWidget = new window.easyClasses.agile.BacklogRootWidget(backlogRoot);
      window.easyView.backlogRootWidget.$target = $(targetSelector);
      window.easyView.root.add(window.easyView.backlogRootWidget);


      recalculateAutocompleteWidth();
      window.setTimeout(recalculateAutocompleteWidth, 200);
      window.setTimeout(recalculateAutocompleteWidth, 1000);
      window.easyView.root.listenWrapHeightChange(recalculateAutocompleteWidth);
      $(window).resize(recalculateAutocompleteWidth);
      document.addEventListener("vueModalIssueChanged", reloadAgile, {once: true});
      if (!window.EasyVue || !window.EasyVue.modalData) return;
      setTimeout(window.EasyVue.holdTargetWrapperHeight, 300);
    });
  };


  window.easyLoaders.backlogDestroy = function () {
    easyView.backlogRootWidget.destroy();
    delete easyView["backlogRootWidget"];
    delete easyModel["backlogRoot"];
  };

  this.backlogLoader = window.easyLoaders.backlog;
});
