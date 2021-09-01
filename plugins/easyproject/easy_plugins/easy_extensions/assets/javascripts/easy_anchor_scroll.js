EASY.schedule.late(function () {
    function filterPath(string) {
        return string
            .replace(/^\//, '')
            .replace(/(index|default).[a-zA-Z]{3,4}jQuery/, '')
            .replace(/\/jQuery/, '');
    }
    var locationPath = filterPath(location.pathname);
    //----------------------------------------------------
    // Animate scroll on anchors
    //----------------------------------------------------
    jQuery('a[href*=\\#]').not('a[data-toggle], a[href=\\#]').each(function () {
        jQuery(this).click(function (event) {
            var thisPath = filterPath(this.pathname) || locationPath;
            if (locationPath === thisPath
                && (location.hostname === this.hostname || !this.hostname)
                && this.hash.replace('#', '')) {
                var $target = jQuery(this.hash), target = this.hash, $targetByName = jQuery('[name='+this.hash.replace('#', '')+']');
                if ($target) {
                    var targetOffset = ERUI.topMenu.outerHeight();
                    event.preventDefault();
                    if($targetByName.length > 0){
                        scrollTo($targetByName, -targetOffset - 20);
                    }else{
                        scrollTo($target, -targetOffset - 20);
                    }
                }
            }
        });
    });
    //----------------------------------------------------
    // Animate scroll on page load when hash in location
    //----------------------------------------------------
    if(location.hash.length > 1){
        EASY.utils.delayedRAF(function(){
            var targetOffset = ERUI.topMenu.outerHeight();
            try {
                var $target = jQuery(location.hash), $targetByName = jQuery('[name='+location.hash.replace('#', '')+']');
            } catch (e) {
              return;
            }
            if($targetByName.length > 0){
                scrollTo($targetByName, -targetOffset - 20);
            }else{
                scrollTo($target, -targetOffset - 20);
            }
        },1000);
    }
});
