EASY.schedule.main(function () {
    var $richMenuParent = $("#top-menu-rich-more").attr('data-widget-content','#top-menu-rich-more-list');
    //var $richMenuAnchor = $richMenuParent.find(">a");
    //var $richMenuMenu = $richMenuParent.find(">ul.menu-children");
    var $topMenuContainer = $("#top-menu-container");
    var $topMenuParents = $topMenuContainer.find(".with-easy-submenu");
    var $moreGroup = document.querySelector('.top-menu-rich-more-group');
    if($moreGroup) {
      new PerfectScrollbar($moreGroup, {
          suppressScrollX: true,
          includePadding: true,
          wheelPropagation: false,
          swipePropagation: false
      });
      $moreGroup.style.overflowY = 'hidden';
    };

    EASY.schedule.require(function(){
        $richMenuParent.toggleable({observer: EASY.defaultClickObserver, content: $(this).attr('data-widget-content'), openCallback: function () {
            $('body').addClass('left-menu-opened');
        }, closeCallback: function () {
            $('body').removeClass('left-menu-opened');
        }});
        $topMenuParents.each(function (index, parent) {
            var $parent = $(parent);
            var $trigger = $parent.find(".easy-top-menu-more-toggler");
            var $content = $parent.find(".easy-menu-children");
            $trigger.toggleable({observer: EASY.defaultClickObserver, content: $content});
        });
    },function () {
        return EASY.defaultClickObserver;
    });
});
