(function () {
  /**
   * @param {MindMup} ysy
   * @constructor
   */
  function NodePatch(ysy) {
    this.ysy = ysy;
    this.patch();
    this.initCoreIcons();
  }

  /**
   * Choose icons from [icons] attribute and use it to render.
   * It use the order specified in Array
   * @type {Object.<String,Array.<String>>}
   */
  NodePatch.prototype.iconsForEntity = {
    // issue:["avatar"]
  };
  /**
   * @callback IconBuilder
   * @param {ModelEntity} nodeContent - it is different from ModelEntity, but it share [attr] reference
   */
  /**
   * Object filled with IconBuilders
   * @type {Object.<String,IconBuilder>}
   */
  NodePatch.prototype._icons = {};

  /**
   * @param {String} key
   * @param {IconBuilder} builder
   */
  NodePatch.prototype.addIconBuilder = function (key, builder) {
    this._icons[key] = builder;
  };

  NodePatch.prototype.initCoreIcons = function () {
    /** @type {WbsMain} */
    var ysy = this.ysy;
    this.addIconBuilder("avatar", function (nodeContent) {
      var users = ysy.dataStorage.get("users");
      var assigneeIndex = _.findIndex(users, {
        id: ysy.getData(nodeContent).assigned_to_id
      });
      if (assigneeIndex > -1) {
        var user = users[assigneeIndex];
        var avatarUrl = user.avatar_url ? user.avatar_url : "/plugin_assets/easy_extensions/images/avatar.jpg";
        return '<span class="avatar-container"><img width="64" height="64" alt="' + user.name + '" class="gravatar" src="' + avatarUrl + '"></span>';
      }
    });
  };
  NodePatch.prototype.extraElements = function($node, selected, idea, ysy){
    var $nodeControl = $node.find('.mindmup__node-control');
    if (selected) {
      if ($nodeControl.length === 0) {
        var template = '\
                <div class="mindmup__node-control">\
                  <div class="easy-mindmup__icon easy-mindmup__icon--edit mindmup__node-control-edit "></div>\
                  <div class="easy-mindmup__icon easy-mindmup__icon--add mindmup__node-control-add "></div>\
                </div>';
        jQuery(template)
            .on("click", ".mindmup__node-control-edit", function () {
              if (window.EASY && EASY.utils) {
                EASY.utils.toggleSidebar();
              } else {
                ysy.mapModel.editNodeData('nodeControl');
              }
            })
            .on("click", ".mindmup__node-control-add", function () {
              ysy.mapModel.addSubIdea('nodeControl');
            }).prependTo($node);
      }
    }
    else if ($nodeControl.length > 0) {
      $nodeControl.remove();
    }
  };

  /**
   * Add extra CSS classes to node element
   * @param {ModelEntity} nodeContent
   * @example return nodeContent.attr.isProject ? " wbs-project" : " wbs-issue";
   * @return {String}
   */
  NodePatch.prototype.nodeBonusCss = function (nodeContent) {
    nodeContent.title = "true";
    // Override this for adding special data-specific classes to node
    throw "nodeBonusCss is not defined!";
  };
  /**
   * extract and transform name property from node
   * @param {ModelEntity} nodeContent
   * @return {string}
   */
  var getNodeText = function (nodeContent) {
    if (nodeContent.subject) {
      return nodeContent.subject.trim();
    }
    return nodeContent.title.trim();
  };
  NodePatch.prototype.getNodeText = getNodeText;
  NodePatch.prototype.patch = function () {
    var ysy = this.ysy;
    var nodePatch = this;
    jQuery.fn.updateNodeContent = function (nodeContent, resourceTranslator) {
      'use strict';
      // var MAX_URL_LENGTH = 25,
      var self = jQuery(this),
          title = getNodeText(nodeContent),
          updateText = function (title) {
            // var text = MAPJS.URLHelper.stripLink(title) ||
            //         (title.length < MAX_URL_LENGTH ? title : (title.substring(0, MAX_URL_LENGTH) + '...')),
            var span = self.find('[data-mapjs-role=title]');
            if (span.length === 0) {
              span = jQuery('<span>').attr('data-mapjs-role', 'title').appendTo(self);
            }
            span.text(title);
          },
          setStyles = function () {
            var element = self.find('.mapjs-collapsor');
            var oldClassName = self[0].className;
            self[0].className = "mapjs-node"
                + (oldClassName.indexOf("activated") > -1 ? " activated" : "")
                + (oldClassName.indexOf("selected") > -1 ? " selected" : "")
                + ysy.styles.cssClasses(nodeContent)
                + (nodeContent.x && nodeContent.x + nodeContent.width < 0 ? ' mindmup-node-left' : '')
                + (nodeContent.attr.collapsed && nodeContent.attr.hasChildren ? ' collapsed' : '')
                + ysy.nodePatch.nodeBonusCss(nodeContent)
                + (nodeContent.attr.data.filtered_out ? " mindmup__node--filtered_out" : "")
                + (ysy.filter.isBanned(nodeContent) ? " " + ysy.filter.className : "")
                + (!nodeContent.attr.isFromServer ? " mindmup__node--not-saved": "");
            if (nodeContent.attr.hasChildren) {
              if (element.length === 0) {
                jQuery('<div class="mapjs-collapsor"></div>').hammer().on("tap", function () {
                  var model = ysy.mapModel;
                  model.selectNode(nodeContent.id);
                  model.toggleCollapse();
                  return false;
                }).appendTo(self);
              }
            } else if (element.length > 0) {
              element.remove();
            }

            nodePatch.extraElements(self, self[0].className.indexOf("selected") > 0, nodeContent, ysy);
          },
          // needChangeIcon = function () {
          //   return !!ysy.getData(nodeContent)._old;
          // },
          // setChangeIcon = function ($iconsCont) {
          //   var isEdited = !!ysy.getData(nodeContent)._old;
          //   if (isEdited) {
          //     var $icon = $iconsCont.find(".mindmup-node-icon-is_edited");
          //     if ($icon.length === 0) {
          //       $iconsCont.prepend('<div class="mindmup-node-icon-is_edited" title="' + ysy.settings.labels.titleNodeChanged + '"></div>');
          //     }
          //   } else {
          //     $iconsCont.find(".mindmup-node-icon-is_edited").remove();
          //   }
          // },
          // needIcons = function () {
          //   return ysy.settings.allIcons && self[0].className.indexOf("selected") === -1;
          // },
          updateChildrenNodeIcons = function(resourceTranslator){
            // get dragged idea
            const idea = (resourceTranslator && resourceTranslator.hasOwnProperty("idea")) ? resourceTranslator.idea : null;
            if (idea) {
              // get all idea subideas
              idea.getSubTreeIds(nodeContent.id).forEach((id) => {
                const $nodeId = $(`#node_${id}`);
                // is idea on the left
                const isIdeaLeft = nodeContent.x + nodeContent.width < 0;
                // if idea is on the left then add class else remove class
                isIdeaLeft ? $nodeId.addClass(' mindmup-node-left') : $nodeId.removeClass(' mindmup-node-left');
              });
            }
          },
          setIcons = function ($iconsCont) {
            var creatorName, creator, icon;
            var iconCreators = ysy.nodePatch.iconsForEntity[nodeContent.attr.entityType];
            if (!iconCreators) return;
            var nodePatch = ysy.nodePatch;
            var $icons = $iconsCont.find(".mindmup-node-icons-all");
            let $temporaryIconsBox = $iconsCont.find(".mindmup-node-icons-all_temp-icons");
            if ($icons.length === 0) {
              $icons = $('<div class="mindmup-node-icons-all"></div>');
              $iconsCont.append($icons);
            }
            if ($temporaryIconsBox.length === 0) {
              $temporaryIconsBox  = $('<div class="mindmup-node-icons-all_temp-icons"></div>');
              $icons.append($temporaryIconsBox);
            }
            var lastIconCreatorName = null;
            for (var i = 0; i < iconCreators.length; i++) {
              creatorName = iconCreators[i];
              creator = nodePatch._icons[creatorName];
              if (!creator) continue;
              if (nodeContent.attr.entityType === "issue" && creatorName !== "avatar" && !ysy.settings.allIcons) continue;
              var newIconContent = creator(nodeContent);
              icon = $icons.find(".mindmup-node-icon-" + creatorName);
              if (newIconContent) {
                if (!icon.length) {
                  icon = $('<div class="mindmup-node-icon mindmup-node-icon-' + creatorName + '"></div>');
                  if (!lastIconCreatorName && creatorName === "avatar" ) {
                    if (!$icons.find(icon).length)  {
                      $icons.prepend(icon);
                    }
                  } else {
                    $temporaryIconsBox.prepend(icon);
                  }
                }
                if (typeof newIconContent === "string") {
                  icon.html(newIconContent);
                } else {
                  icon.clear().append(newIconContent);
                }
                lastIconCreatorName = creatorName;
              } else {
                icon.remove();
              }
            }
          };
      if (!self.is(":focus")) {
        var parent = self.parent();
        self.detach();
        var detached = true;
      }
      updateText(title);
      self.data({
        'x': Math.round(nodeContent.x),
        'y': Math.round(nodeContent.y),
        'width': Math.round(nodeContent.width),
        'height': Math.round(nodeContent.height),
        'nodeId': nodeContent.id,
        'title': title
      });

      setStyles();
      updateChildrenNodeIcons(resourceTranslator);
      var $element = self.find('.mindmup-node-icons');
      if ($element.length === 0) {
        $element = $('<div class="mindmup-node-icons"></div>');
        var haveToBeAppended = true;
      }
      //setChangeIcon($element);
      setIcons($element);
      if (haveToBeAppended) {
        $element.appendTo(self);
      }
      if (nodeContent.attr.force) delete nodeContent.attr.force;  // remove force flag if present
      if (detached) {
        parent.append(self);
      }
      return self;
    };
  };
  window.easyMindMupClasses.NodePatch = NodePatch;
})();
