/**
 * Created by hosekp on 11/28/16.
 */
(function () {
  var classes = window.easyMindMupClasses;

  /**
   * Context menu for WBS
   * @param {WbsMain} ysy
   * @constructor
   */
  function WbsContextMenu(ysy) {
    classes.ContextMenu.call(this, ysy);
  }

  classes.extendClass(WbsContextMenu, classes.ContextMenu);
  /**
   * Prepare Object for Mustache to render context menu
   * @param {ModelEntity} node
   * @override
   * @return {Object}
   */
  WbsContextMenu.prototype.getStructure = async function (node) {
    var ysy = this.ysy;
    var data = ysy.getData(node);
    var isProject = node.attr.entityType === "project";
    var isBulkEdit = ysy.mapModel.getActivatedNodeIds().length > 1;
    var isCollapsed = node.attr.collapsed;
    var trackers, priorities, statuses, assignees, doneRatio;
    const hasSpentTime = ysy.validator.hasSpentTime(node);
    if (!isProject) {
      trackers = ysy.dataStorage.get("trackers").map(function (entity) {
        return {name: entity.name, value: entity.id, previous: data.tracker_id === entity.id}
      });
      priorities = ysy.dataStorage.get("priorities").map(function (entity) {
        return {name: entity.name, value: entity.id, previous: data.priority_id === entity.id};
      });
      const statusesResponse = await fetch(`${window.urlPrefix}/easy_autocompletes/allowed_issue_statuses?issue_id=${data.id}`);
      const statusesData = await statusesResponse.json();
      statuses = statusesData.map(status =>{
        return {name: status.text, value: status.value, previous: data.status_id === status.value};
      });
      assignees = [{name: "<< nobody >>", value: null, previous: !data.assigned_to_id}]
        .concat(ysy.dataStorage.get("users").map(function (entity) {
          return {name: entity.name, value: entity.id, previous: data.assigned_to_id === entity.id}
        }));
      doneRatio = [];
      var dataDoneRatio = data.done_ratio || 0;
      for (var i = 0; i <= 100; i += 10) {
        doneRatio.push({name: i + " %", value: i, previous: dataDoneRatio === i})
      }
    }
    var labels = ysy.settings.labels;
    var ctxLabels = labels.context;
    var nonEditable = node.attr.nonEditable;
    var budgetNotEditable = ysy.settings.moneyOn === false;

    var skipDoneRatio = function(menu, node) {
      const issueIsLeaf = Object.keys(node.ideas).length > 0
    
      return menu.ysy.settings.appSettings.useStatusForIssueDoneRatio ||
      node.attr.nonEditable ||
      node.attr.entityType === "project" ||
      (issueIsLeaf && menu.ysy.settings.appSettings.issueDoneRatioDerived);
    };

    return [
      {
        name: isCollapsed ? ctxLabels.expand : ctxLabels.collapse,
        aClassName: 'easy-mindmup__icon easy-mindmup__icon--' + (isCollapsed ? 'expand' : 'collapse') + ' toggleCollapse',
        skip: _.isEmpty(node.ideas)
      }, {
        name: ctxLabels.goto + " " + (isProject ? labels.types.project : labels.types.issue),
        aClassName: 'easy-mindmup__icon easy-mindmup__icon--follow_url followURL',
        skip: isBulkEdit
      }, {
        name: ctxLabels.rename,
        aClassName: 'easy-mindmup__icon easy-mindmup__icon--rename editNode',
        skip: isBulkEdit || !ysy.validator.validate("nodeRename", node)
      }, {
        name: ctxLabels.editData,
        aClassName: 'easy-mindmup__icon easy-mindmup__icon--edit_data editNodeData',
        skip: isBulkEdit || nonEditable
      },
      this.prepareOption(function () {
        return {
          name: ctxLabels.tracker,
          key: 'tracker_id',
          changer: trackers
        };
      }, nonEditable || isProject),
      this.prepareOption(function () {
        return {
          name: ctxLabels.priority,
          key: 'priority_id',
          changer: priorities
        };
      }, nonEditable),
      this.prepareOption(function () {
        return {
          name: ctxLabels.status,
          key: 'status_id',
          changer: statuses
        };
      }, nonEditable || isProject),
      this.prepareOption(function () {
        return {
          name: ctxLabels.assignee,
          key: 'assigned_to_id',
          changer: assignees
        };
      }, nonEditable || isProject),
      this.prepareOption(function () {
        return {
          name: ctxLabels.doneRatio,
          key: 'done_ratio',
          changer: doneRatio
        };
      }, skipDoneRatio(this, node)),
      {
        name: ctxLabels.budget,
        aClassName: 'easy-mindmup__icon icon icon-money showBudget',
        skip: budgetNotEditable || isBulkEdit
      },
      this.prepareOption(function () {
        if (isProject) {
          return {
            name: ctxLabels.add,
            className: 'folder',
            aClassName: 'easy-mindmup__icon easy-mindmup__icon--add',
            subMenu: [
              {
                name: ctxLabels.addChild,
                className: 'easy-mindmup__icon easy-mindmup__icon--add addSubIdea'
              }
            ]
          };
        } else {
          return {
            name: ctxLabels.add,
            className: 'folder',
            aClassName: 'easy-mindmup__icon easy-mindmup__icon--add',
            subMenu: [
              {
                name: ctxLabels.addChild,
                className: 'easy-mindmup__icon easy-mindmup__icon--add addSubIdea'
              }, {
                name: ctxLabels.addSibling,
                className: 'easy-mindmup__icon easy-mindmup__icon--add_sibling addSiblingIdea'
              }, {
                name: ctxLabels.addParent,
                className: 'easy-mindmup__icon easy-mindmup__icon--insert_between insertIntermediate'
              }
            ]
          };
        }
      }, isBulkEdit),
      {
        name: ctxLabels.remove,
        aClassName: 'easy-mindmup__icon easy-mindmup__icon--remove removeSubIdea',
        skip: nonEditable || hasSpentTime
      }
    ]
  };
  classes.WbsContextMenu = WbsContextMenu;
})();
