EASY.schedule.late(function () {
  $("#easy_knowledge_toolbar_trigger").droppable({
    hoverClass: 'drag-over',
    tolerance: 'touch',
    accept: '[data-entity-type=issue],[data-entity-type=journal]',
    over: function (event, ui) {
      $(event.target).removeClass('drag-ready');
    },
    out: function (event, ui) {
      $(event.target).addClass('drag-ready');
    },
    drop: function (event, ui) {
      $.get(ui.draggable.data().action, ui.draggable.data().newEasyKnowledgeStory);
    }
  });

});
EASY.schedule.require(function ($) {
  "use strict";

  var dropActions = {};

  EASY.knowledge = EASY.knowledge || {};
  EASY.knowledge.registerDropAction = function (name, params) {
    dropActions[name] = params;
  };

  EASY.knowledge.initDroppable = function (params) {
    return $('#easy_knowledge_toolbar_list').sortable({
      items: "li.movable-list-item",
      cursor: "move",
      placeholder: {
        element: function (currentItem) {
          return $("<li/>").attr({"class": "ui-state-highlight icon-import easy-knowledge-panel-sortable-placeholder"}).text(EASY.knowledge.easyKnowledgeToolbarLocalize().sortablePlaceholder)[0];
        },
        update: function (container, p) {
          return;
        }
      },
      revert: true,
      tolerance: "pointer",
      forcePlaceholderSize: true,
      helper: "clone",
      appendTo: document.body,
      start: function (event, ui) {
        if (!ui.item.hasClass("easy-panel-handler") && !ui.item.data().uiDraggable) {
          $('.easy-dropper-target').each(function (index, item) {
            var params = dropActions[$(item).attr('data-drop-action')],
                zoneData = $(item).data(),
                itemData = ui.item.data(),
                zone;

            if (!params) {
              return;
            }

            zone = createEasyDropZone(item, params.label);

            if (zone) {
              zone.droppable({
                hoverClass: 'easy-target-dropzone-hover',
                accept: '.easy-knowledge-story-toolbar-item',
                drop: function (event, ui) {
                  var ajaxParams;
                  if (params.url) {
                    ajaxParams = {
                      url: params.url,
                      data: params.getAttributes(zoneData, itemData),
                      type: 'POST',
                      complete: function (data) {
                        $('div#content').scrollTop(0);
                        window.location.reload();
                      }
                    };
                    if (params.ajaxParams) {
                      $.extend(ajaxParams, params.ajaxParams);
                    }
                    $.ajax(ajaxParams);
                  } else {
                    alert("Upadlo ti to !");
                  }
                }
              });
            }
          });
        }
      },
      stop: function (event, ui) {
        $('.easy-target-dropzone').remove();
        $(".easy-dropper-target").css({"position": ''});
        if (!ui.item.is(".movable-list-item")) return;

        $.get(ui.item.data().action, ui.item.data().newEasyKnowledgeStory);
        ui.item.replaceWith('');

      }
    });
  };
  $.fn.easy_knowledge_toolbar = function (options) {
    var defaults = {
          moreToDoLists: false,
          trigger: '#easy_knowledge_toolbar_trigger'
        },
        opts = $.extend(true, {}, defaults, options);
    var overrides = {
      afterOpen: function () {
        _self.find('input').focus();
        $._data(EASY.knowledge.initDroppable()[0]).data.sortable.refreshPositions();
      }
    };

    overrides = $.extend(true, {}, overrides, opts);
    var _self = $(this).easySlidingPanel(overrides);
  };
}, "jQuery");
