function createEasyDropZone(target, label) {
  target = $(target).css('position', 'relative');
  return $("<div/>").addClass("easy-target-dropzone").html(label).appendTo(target);
}


(function($) {
  var easy_register_panel_handler_targets = [];
  window.registerPanelHandlerTarget = function(target) {
    easy_register_panel_handler_targets.push(target);
  };
  window.getRegisterPanelHandlerTargets = function() {
    return easy_register_panel_handler_targets;
  };
}(jQuery));


EASY.dragAndDrop.initReorders = function (selector, options) {
  $(selector || ".list.reorder tbody").sortable($.extend({
    handle: ".easy-sortable-list-handle",
    helper: function (event, currentItem) {
      var t = $("<tr/>").css({border: 'none'});
      t.append($("<td/>").html("<span class=\"icon-reorder\"></span>"));
      t.append($("<td/>").attr({
        "class": "name",
        colspan: currentItem.find("td").length - 1
      }).text(currentItem.find("td.name").text()));

      return t.attr({"class": "easy-sortable-helper"});
    },
    placeholder: {
      element: function (currentItem) {
        var t = $("<tr/>");
        t.append($("<td/>")).append($("<td/>").attr({
          "class": "name",
          colspan: currentItem.find("td").length - 1
        }).html("&nbsp;"));

        return t.attr({"class": "easy-sortable-placeholder"});
      },
      update: function (container, p) {

      }
    },
    update: function (event, ui) {
      var handler = ui.item.find(".easy-sortable-list-handle");
      var params = {data: {format: 'json'}};
      params.data[handler.data().name] = {reorder_to_position: ui.item.index() + 1};

      $.ajax({url: handler.data().url, data: params.data, type: 'PUT'});
    }
  }, options || {}));
};

EASY.dragAndDrop.initHandlers = function () {
  $("*[data-handler=true]").not(".easy-panel-handler-container").each(function (i, handler) {
    var $handler = $(handler);
    var $firstTd;
    if ($handler.parents('table').length !== 0) {
      $firstTd = $handler.parents('tr').children('td').first();
      $firstTd.addClass('easy-panel-handler-container');
    }
    $handler.addClass('easy-panel-handler-container');
    var $handle = $("<span/>").attr({
      "class": 'easy-panel-handler icon-draggable',
      "data-entity-type": $handler.data().entityType.toLowerCase(),
      "data-entity-id": $handler.data().entityId
    });
    $.each(getRegisterPanelHandlerTargets(), function (index, item) {
      if (item.handlerAllowed($handler)) {
        $handle.attr(item.dataAttributes($handler));
        if ($firstTd) {
          $firstTd.append($handle);
        } else {
          $handler.append($handle);
        }
      }
    });
  });

  var available_types = $.map($(".easy-panel-handler-container .easy-panel-handler"), function (n) {
    return $(n).data().entityType;
  });

  if (available_types[0]) {
    $.each($.unique(available_types), function (index, type) {
      $(".easy-panel-handler-container .easy-panel-handler[data-entity-type=" + type + "]").draggable({
        cursorAt: {
          top: 1,
          left: 1
        },
        connectToSortable: $.map(getRegisterPanelHandlerTargets(), function (item, i) {
          if (item.allowedEntity(type))
            return item.connectToSortable();
        }).join(','),
        revert: "invalid",
        zIndex: 101,
        scroll: false,
        appendTo: 'body',
        containmentType: 'easy_servicebar',
        helper: function (event) {
          var $this = $(this);
          if ($this.parents('table').length !== 0) {
            var text = $this.parent().siblings().find("*[data-handler=true]").text();
          } else {
            text = $this.parent().text();
          }
          return $('<li class="movable-list-item ui-state-default" style="width: auto; height: auto; min-width: 100px;">' + text + '</li>').data($this.data());
        },
        start: function (event, ui) {
          $.each(getRegisterPanelHandlerTargets(), function (index, item) {
            if (item.allowedEntity(type)) {
              var trigger = $(item.easyServicebarTrigger);
              if (trigger) {
                trigger.addClass('drag-ready');
              }
              // $("#"+item.containerName+" .clicker-panel > span").bind('mouseover', function(e) {
              //     $(e.target).click();
              // })
            }
          });
        },
        stop: function (event, ui) {
          $.each(getRegisterPanelHandlerTargets(), function (index, item) {
            // $("#"+item.containerName+" .clicker-panel > span").unbind('mouseover');
            var trigger = $(item.easyServicebarTrigger);
            if (trigger) {
              trigger.removeClass('drag-ready');
            }
          });
        }
      });
    });
  }
};
