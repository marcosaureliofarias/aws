if (!window.easyView || !window.easyView.root) {
    throw "View root must be loaded before sticky";
}


(function (view) {
    var stickies = [];
    var toDelete = [];
    var heightChangeListened = false;
    var scrollTop = view.root.actualWindowScroll;

    var Sticky = {
        resolveMode: function () {
            if (!this.boxRecalculated) {
                this.recalculateBox();
            }
            var box = this.box;
            if ((box.height < 1 || box.width < 1) && this.doClone) {
                this.$clone.hide();
            } else if (this.doClone) {
                this.$clone.show();
            }
            var offset = this.offset;
            var parentBox = this.parentBox;
            var bottom = offset.top + parentBox.height - this.topOffset - this.bottomBreak;
            var top = offset.top - this.startOffset;

            if (top < scrollTop && scrollTop < bottom) {
                this.setFixed();
            } else {
                this.setStatic();
            }
        },
        setStatic: function () {
            if (this.mode === "static")return false;
            this.mode = "static";
            if (this.doClone) {
                this.$clone.css({position: "absolute", top: this.offset.top});
                this.$clone.removeClass("stuck");
            } else {
                this.$element.css({
                    position: "static"
                });
                this.$element.removeClass("stuck");

            }
            return true;
        },
        setFixed: function () {
            if (this.mode === "fixed")return false;
            this.mode = "fixed";
            var box = this.box;
            var offset = this.offset;
            var css = {
                position: "fixed",
                left: offset.left,
                width: box.width,
                top: this.topOffset
            };
            if (this.doClone) {
                this.$clone.css(css);
                this.$clone.addClass("stuck");
            } else {
                this.$element.css(css);
                this.$element.addClass("stuck");
            }
            return true;
        },
        checkParent: function () {
            var parent = this.$element.parent();
            if (parent == null || parent.length === 0) {
                // remove unused stickies
                toDelete.push(this);
                return false;
            }
            return true;
        },
        destroy: function () {
            if (this.destroyed)return;
            this.destroyed = true;
            // it is possible to destroy sticky with not created clone yet
            if (this.$clone)this.$clone.remove();
        },
        scrolled: function () {
            this.resolveMode();
        },
        recalculateBox: function () {
            if (this.destroyed) {
                throw "recalculate on destroyed sticky";
            }
            this.boxRecalculated = true;
            this.box = {};
            this.box.height = this.$element.height();
            this.box.width = this.$element.width();
            this.offset = this.$element.offset();
            // this.parentPosition = this.$element.position();
            this.parentBox = this.$element.parent()[0].getBoundingClientRect();
            if (!this.doClone)return;
            var wasCloneCreated = false;
            if (!this.$clone) {
                this.$clone = this.$element.clone().appendTo(getStickies());
                wasCloneCreated = true;
            }
            this.$clone.css({
                left: this.offset.left,
                width: this.box.width,
                height: this.box.height
                //overflow: "hidden"
            });
            if(wasCloneCreated){
                this.onCloneCreated(this.$clone);
            }
        }
    };

    var $stickiesDiv;

    function getStickies() {
        if (!$stickiesDiv) {
            $stickiesDiv = $("<div>").css({
                position: "absolute",
                top: 0,
                left: 0,
                overflow: 'hidden'
            }).addClass("stickyClones").appendTo(document.body);
        }
        return $stickiesDiv;
    }

    var defaultSettings = {
        topOffset: 0,
        startOffset: null,
        bottomBreak: 0,
        mode: "none",
        doClone: true,
        onCloneCreated: function ($clone) {
        }
    };

    /**
     *
     * @param {jQuery} $element
     * @param {defaultSettings} [settings]
     */
    function addSticky($element, settings) {
        if(!heightChangeListened){
            view.root.listenWrapHeightChange(rebuild);
            heightChangeListened = true;
        }

        if ($element.attr("id")) {
            throw "Id is forbidden for sticky element"
        }
        if (!settings) {
            settings = {};
        }
        if (defaultSettings) {
            defaultSettings.bottomBreak = $element.height();
        }
        var sticky = $.extend({$element: $element}, Sticky, defaultSettings, settings);
        if (!settings.topOffset) settings.topOffset = 0;
        sticky.topOffset = settings.topOffset + defaultSettings.topOffset;
        if (sticky.startOffset === null) {
            sticky.startOffset = sticky.topOffset;
        }
        stickies.push(sticky);
        return sticky;
    }

    view.root.onWindowScroll.push(function () {
        scrollTop = view.root.actualWindowScroll;
        fireChanges();
    });

    function fireChanges() {
        for (var i = 0; i < stickies.length; i++) {
            stickies[i].checkParent();
        }
        for (i = 0; i < toDelete.length; i++) {
            var index = stickies.indexOf(toDelete[i]);
            if (index > -1) {
                stickies[index].destroy();
                stickies.splice(index, 1);
            }
        }
        toDelete = [];
        for (i = 0; i < stickies.length; i++) {
            stickies[i].scrolled();
        }
    }

    var rebuildTimeout = null;

    function rebuild() {
        if (rebuildTimeout !== null) {
            window.clearTimeout(rebuildTimeout);
            rebuildTimeout = null;
        }
        for (var i = 0; i < stickies.length; i++) {
            var sticky = stickies[i];
            if (sticky.checkParent()) {
                sticky.recalculateBox();
                sticky.mode = "none";
            }
        }
        fireChanges();

        $('.agile__main-col .agile__row.row0').on('scroll', function(event){
            $('.agile__main-col .agile__row:not(.row0):not(.easy-row)').scrollLeft(event.target.scrollLeft)
        });
    }

    function remove($element) {
        for (var i = 0; i < stickies.length; i++) {
            if (stickies[i].$element === $element) {
                stickies[i].destroy();
                stickies.splice(i, 1);
                return;
            }
        }
    }

    function scheduleRebuild() {
        if (rebuildTimeout !== null) {
            return;
        }
        rebuildTimeout = window.setTimeout(function () {
            rebuild();
        }, 10);
    }

    $(document).on("resize", scheduleRebuild);
    $(document).on("erui_interface_change_vertical", scheduleRebuild);

    function stickyGetSassData(){
        if(typeof(ERUI.sassData['topmenu-height']) !== 'undefined') {
            if(ERUI.sassData['topmenu-height'].indexOf("rem")>-1 && typeof(ERUI.sassData['font-size']) !== 'undefined'){
                defaultSettings.topOffset = parseInt(ERUI.sassData['topmenu-height'])*parseInt(ERUI.sassData['font-size']);
            }else{
                defaultSettings.topOffset = parseInt(ERUI.sassData['topmenu-height']);
            }
            for( var i = 0; i < stickies.length; i++){
                stickies[i].topOffset += defaultSettings.topOffset;
            }
            scheduleRebuild();
        }
    }

    if (ERUI){
        if (ERUI.sassDataComputed){
            stickyGetSassData();
        }else{
            ERUI.onSassDataComputed.push(stickyGetSassData);
        }
    }else{
        throw 'ERUI must be loaded';
    }

    view.sticky = {
        add: addSticky,
        rebuild: rebuild,
        scheduleRebuild: scheduleRebuild,
        remove: remove
    };

})(window.easyView);
