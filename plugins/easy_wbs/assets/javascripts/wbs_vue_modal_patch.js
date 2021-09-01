(function () {
  var classes = window.easyMindMupClasses;

  /**
   * @extends {NodePatch}
   * @param {WbsMain} ysy
   * @constructor
   */
  function WbsNodeVuePatch(ysy) {
    document.addEventListener("vueModalIssueChanged", ysy.loader.load.bind(ysy.loader));
    document.addEventListener("vueModalProjectChanged", ysy.loader.load.bind(ysy.loader));
  }

  classes.NodePatch.prototype.extraElements = function ($node, selected, idea, ysy) {
    var $nodeControl = $node.find('.mindmup__node-control');
    if (selected) {
      if ($nodeControl.length === 0) {
        let editTitle = "";
        if (idea.attr.entityType === "issue") {
          editTitle = ysy.settings.labels.title.save_and_open_task_detail;
        } else if (idea.attr.entityType === "project") {
          editTitle = ysy.settings.labels.title.save_and_open_project_detail;
        }
        var template = '\
                <div class="mindmup__node-control">\
                  <div title="' + editTitle + '" class="easy-mindmup__icon easy-mindmup__icon--edit mindmup__node-control-edit "></div>\
                  <div class="easy-mindmup__icon easy-mindmup__icon--add mindmup__node-control-add "></div>\
                </div>';
        jQuery(template)
          .on("click", ".mindmup__node-control-edit", function () {
            ysy.mapModel.editNodeData('nodeControl');
          })
          .on("click", ".mindmup__node-control-add", function () {
            ysy.mapModel.addSubIdea('nodeControl');
          }).prependTo($node);
      }
    } else if ($nodeControl.length > 0) {
      $nodeControl.remove();
    }
  };


  classes.WbsNodeVuePatch = WbsNodeVuePatch;
})();
