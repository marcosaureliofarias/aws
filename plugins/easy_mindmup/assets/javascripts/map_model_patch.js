/**
 * Created by hosekp on 11/14/16.
 */
(function () {
  /**
   * Class responsible for modification of mapModel code
   * @param {MindMup} ysy
   */
  function MapModelPatch(ysy) {
    this.ysy = ysy;
    this.init(ysy);
    this.selectPersist = new SelectionPersist(ysy);
  }

  /**
   * @param {MindMup} ysy
   */
  MapModelPatch.prototype.init = function (ysy) {
    var self = this;
    ysy.eventBus.register("MapInited", function (mapModel) {
      self.selectPersist.init(mapModel);
      mapModel.getYsy = function () {
        return ysy;
      };
      mapModel.save = function (origin) {
        ysy.saver.save();
      };
      mapModel.modalIncome = function (origin) {
        this.modalBudget('other_revenue');
      };
      mapModel.modalExpense = function (origin) {
        this.modalBudget('other_expense');
      };
      mapModel.modalOverview = function (origin) {
        this.modalBudget('overview');
      };

      mapModel.modalBudget = function (type) {
        var ysy = this.getYsy();
        if (!ysy.settings.moneyOn) return;
        ysy.saver.save();
        var selectedIdea = this.findIdeaById(this.getSelectedNodeId());
        ysy.eventBus.fireEvent('nodeBudgetDetailShow', selectedIdea, type)
      };

      /**
       * Open new page with entity detail.
       * Expect pathUrl with key [entityPage] and value [.../:entityID/...]
       * @param {number|string} id
       * @return {boolean}
       */
      mapModel.followURL = function (id) {
        if (id === 'toolbar') {
          id = mapModel.getCurrentlySelectedIdeaId();
        }
        /** @type {ModelEntity} */
        var idea = ysy.mapModel.findIdeaById(id);
        var data = ysy.getData(idea);
        if (!data.id) return false;
        if (data.default_url) {
          window.open(data.default_url);
        } else {
          var templateUrl = ysy.settings.paths[idea.attr.entityType + "Page"];
          if (templateUrl === undefined) throw "entityPage URL is not defined";
          window.open(templateUrl.replace(":" + idea.attr.entityType + "ID", data.id));
        }
        return true;
      };
      mapModel.editNodeData = function (source) {
        if (!mapModel.getEditingEnabled() || !mapModel.getInputEnabled()) {
          return false;
        }
        ysy.eventBus.fireEvent('nodeEditDataRequested', mapModel.getCurrentlySelectedIdeaId());
      };
      mapModel.toggleOneSide = function (source) {
        var idea = ysy.idea;
        var targetState = !self.ysy.settings.oneSideOn;
        self.ysy.settings.oneSideOn = targetState;
        idea.updateOneSide(idea, true);
        self.ysy.eventBus.fireEvent("saveOneSideOn", targetState);
      };
      /** prevent scroll jumping after deselecting node while editing */
      mapModel.addEventListener('inputEnabledChanged', function (canInput, holdFocus) {
        if (canInput && !holdFocus) {
          // console.log("inputEnabledChanged without focus");
          mapModel.dispatchEvent('inputEnabledChanged', true, true);
          return false;
        }
      }, 5);

      mapModel.showBudget = function (source) {
        var ysy = this.getYsy();
        var node = ysy.mapModel.findIdeaById(ysy.mapModel.getCurrentlySelectedIdeaId());
        ysy.eventBus.fireEvent('nodeBudgetDetailShow', node, 'overview');
      };

      var oldResetView = mapModel.resetView;
      mapModel.resetView = function (source) {
        ysy.domPatch.resetRootPosition();
        oldResetView(source);
      };

      // original dropNode ensures the target node is expanded after the drop
      // we don't want that because it may contain a lot of sub nodes which distorts the user view
      var oldDropNode = mapModel.dropNode;
      mapModel.dropNode = function (nodeId, dropTargetId, shiftKey) {
        var dropTargetNode = mapModel.getIdea().findSubIdeaById(dropTargetId);
        var collapsed = dropTargetNode.getAttr('collapsed');

        mapModel.pause();
        var result = oldDropNode(nodeId, dropTargetId, shiftKey);
        if (collapsed) {
          mapModel.getIdea().updateAttr(dropTargetId, 'collapsed', true);
        }
        mapModel.resume();

        return result;
      }
    });
  };
  window.easyMindMupClasses.MapModelPatch = MapModelPatch;

  //####################################################################################################################
  /**
   *
   * @param {MindMup} ysy
   * @constructor
   */
  function SelectionPersist(ysy) {
    this.ysy = ysy;
    this.preLastSelectedNode = null;
    this.lastSelectedNode = null;
  }

  SelectionPersist.prototype.init = function (mapModel) {
    var self = this;
    var selectHandler = function (id, added) {
      if (added) {
        self.preLastSelectedNode = self.lastSelectedNode;
        self.lastSelectedNode = id;
      }
      mapModel.getYsy().eventBus.fireEvent("nodeSelectionChanged", id, added);
      var layout = mapModel.getCurrentLayout();
      if (!layout.nodes[id]) return;
      $("#node_" + id).updateNodeContent(layout.nodes[id]);
    };
    var resetViewHandler = function () {
      self.preLastSelectedNode = self.preLastSelectedNode || self.ysy.idea.id;
      self.lastSelectedNode = self.preLastSelectedNode;
      mapModel.selectNode(self.preLastSelectedNode);
    };

    mapModel.addEventListener('nodeSelectionChanged', selectHandler);
    mapModel.addEventListener('mapViewResetRequested', resetViewHandler, 5);
  }
})();
