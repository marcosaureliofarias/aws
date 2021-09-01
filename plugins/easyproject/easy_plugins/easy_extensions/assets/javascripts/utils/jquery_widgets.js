(function ($) {
  $.widget('easy.easytreeview', {
    options: {
      url: null,
      data_attribute: 'id'
    },
    _create: function () {
      var that = this;
      this.options.url = this.options.url || this.element.data('url') || window.location.href;

      $(this.element).on('click', 'span.project-parent-expander', function () {
        that._onRootClick(this);
      });
    },

    _onRootClick: function (el) {
      var $rootEl = $(el),
        tr = $rootEl.closest('tr');
      if ($rootEl.hasClass('open')) {
        var row = tr.next();
        while (parseInt(row.data('level')) > parseInt(tr.data('level'))) {
          row.hide();
          row = row.next();
        }
        $rootEl.removeClass('open');
      } else {
        if ($rootEl.hasClass('preloaded')) {
          $rootEl.addClass('open');
          var row = tr.next();
          while (parseInt(row.data('level')) > parseInt(tr.data('level'))) {
            row.show();
            row = row.next();
          }
          var rows = tr.nextUntil('tr.root');
          var expanders = rows.find('span.project-parent-expander:not(.open)');
          $.each(expanders, function (_, value) {
            var data = $(value).data();
            if (data) {
              $('tr.' + data.prefix + 'parentproject_' + data.id).hide();
            }
          });
        } else {
          $rootEl.addClass('preloaded');
          $.get(this.options.url, {
            root_id: $rootEl.data(this.options.data_attribute)
          }, function (resp) {
            var newRows = $(resp).find('table.projects tbody:first').children("tr");
            $rootEl.addClass('open');
            newRows.filter('.multieditable-container').each(function () {
              initInlineEditForContainer(this);
            });
            newRows.insertAfter(tr);
          });
        }
      }
    }
  });

  function closeServiceBoxComponent() {
    $("#easy_servicebar_component").hide();
    $("#easy_servicebar_component_body").html('');
    ERUI.body.removeClass("servicebar-opened");
    //ERUI.main.trigger($.Event('resize'));
    ERUI.document.off('keydown.easySlidingPanel');
  }

  function showServiceBoxComponent(trigger) {
    var $box = $("#easy_servicebar_component");
    $box.show();
    if (trigger) {
      trigger = $(trigger);
      var top = trigger.offset().top;
      var left = trigger.offset().left;
      var $windowWidth = $(window).width();
      var serviceBarCollapse = EASY.getSassData('media-collapse-menu', 960, true);
      $box.attr({'class': trigger.attr('id')});
      $box.find("#easy_servicebar_component_beak").css({'top': top - $box.offset().top});
      $box.find("#easy_servicebar_component_beak").css({'left': 'auto'});
      //mobile
      if ($windowWidth < serviceBarCollapse) {
            $box.find("#easy_servicebar_component_beak").css({'left': left - $box.offset().left});
      }
      ERUI.body.addClass("servicebar-opened");
      //ERUI.main.trigger($.Event('resize'));
    }
    ERUI.document.on('keydown.easySlidingPanel', function(event) {
      if (event.keyCode === 27) {
        closeServiceBoxComponent();
      }
    });
  }

  $.fn.easySlidingPanel = function(options) {
    var _self = $(this);
    _self.find('#easy_servicebar_close_toggler').click(closeServiceBoxComponent);
    showServiceBoxComponent(options.trigger);
    return _self.find('#easy_servicebar_component_body');
  };
}(jQuery));
