$(function() {
    $(document).on("change", ".easy-query-epm-query-type", function(event){
        var radio = $(event.target);
        toggleEasyQueryType(radio);
    });
});
function toggleEasyQueryType(radio) {
    var moduleC = radio.closest(".module-content");
    radio.next("span").find("input, select").attr("disabled", false);
    moduleC.find("input.easy-query-epm-query-type:radio:not(:checked)").next("span").find("input, select").attr("disabled", true);
    moduleC.find(".easy-query-type-settings-container .easy-query-type-settings-container-filters, .easy-query-type-settings-container .easy-query-type-settings-container-column-options").toggle(moduleC.find('[id$="query_type_2"]').prop('checked'));
}
var PageLayout = {
    current_tab: 1,
    tab_element: false,
    tabs_initialized : false,
    __panelID: 'easy_jquery_tab_panel',
    __tabOptions: {},
    __easytabsOptions: {},
    getActiveTab: function() {
        var result = PageLayout.tab_element && PageLayout.tab_element.find("#easy_page_tabs li.selected");
        if( result.length >= 1 )
            return result;
        return false;
    },
    getActiveTabId: function() {
        var activeTab = PageLayout.getActiveTab();
        if(activeTab && activeTab.find("span[data-tab-id]")) {
            return activeTab.find("span[data-tab-id]").data().tabId;
        }
        else
            return false;
    },
    getActivePanel: function() {
        var options = PageLayout.__tabOptions
        var result = PageLayout.tab_element && PageLayout.tab_element.find('.'+options.panelID+'.'+options.activeClass);
        if( result.length >= 1 )
            return result;
        else
            return false;
    },
    getActivePanelId: function() {
        var activeTab = PageLayout.getActiveTab();
        if(activeTab && activeTab.find("span[data-tab-id]")) {
            return PageLayout.__panelID + '-' + activeTab.find("span[data-tab-id]").data().tabId;
        } else if (activeTab){
          activeTab.tabId = activeTab[0].id.match(/\d+/g);
          return PageLayout.__panelID + '-' + activeTab.tabId[0];
        }
        else
            return PageLayout.__panelID + '-0';
    },
    initEditableTabs: function(options) {

        var o = $.extend({}, {
            active: 0,
            activeID: 0,
            elementID: 'easy_page_tabs',
            tabsContainerSelector: 'div.tabs-container',
            tabID: 'easy_jquery_tab',
            panelID: 'easy_jquery_tab_panel', //panelid = panelID-<tab id> expect to panels have class panelID
            activeClass: 'selected'
        }, options);

        PageLayout.__panelID = o.panelID;
        PageLayout.__tabOptions = jQuery.extend(true, {}, o);
        PageLayout.__easytabsOptions = {
            tabs: o.tabsContainerSelector+' > ul > li',
            defaultTab: '#'+o.tabID+'-'+o.activeID,
            tabActiveClass: o.activeClass,
            panelActiveClass: o.activeClass,
            panelClass: o.panelID,
            panelContext: $('#easy_jquery_tabs_panels')
        };
        setAttrToUrl = PageLayout.setAttrToUrl;

        var easy_jquery_tabs = $('#'+o.elementID).easytabs(PageLayout.__easytabsOptions);
        //EVENTS
        easy_jquery_tabs.on('easytabs:before', function(evt, tab, panel, data) {
            $oldPanel = PageLayout.getActivePanel();
            if($oldPanel)
                PageLayout.checkPanelCKeditorsDirty($oldPanel);
        });
        easy_jquery_tabs.on('easytabs:ajax:complete', function(e, clicked, panel, response, status, xhr) {
            // $(ui.tab).attr("href", '#' + $(ui.panel).find('.'+o.panelID).attr('id'));
            if (status == "error") {
                var msg = "Sorry but there was an error: ";
                //$("#error").html(msg + xhr.status + " " + xhr.statusText);
            } else {
                var $edit_link = $(clicked).closest("li").find(".icon-edit");
                var href = $edit_link.attr("href");
                href = setAttrToUrl(href, 'is_preloaded', true)
                $edit_link.attr('href', href);
            }
        });

        PageLayout.tab_element = easy_jquery_tabs;
        // Tabs are sortable
        easy_jquery_tabs.find( "ul" ).sortable({
            //axis: "x",
            update: function(event, ui) {
              var handler = ui.item.find(".easy-sortable-list-handle");
              var params = {data:{format:'json'}};
              // params.data[handler.data().name] = {reorder_to_position: ui.item.index() + 1}
              params.data['reorder_to_position'] = ui.item.index() + 1;

              $.ajax(handler.data().url, {data : params.data, type : 'PUT'});
              PageLayout.refreshTabs();
              PageLayout.change_link_current_tab($(".add-tab-button"));

              var $edit_link = $(ui.item).find(".icon-edit");
              var href = $edit_link.attr("href");
              href = setAttrToUrl(href, 'is_preloaded', false)
              $edit_link.attr('href', href);
            }
        });

        easy_jquery_tabs.on( "ajax:success", "a.icon-del", function() {
            var $tab = $( this ).closest( "li" );
            panelID = PageLayout.getPanelIDforTab($tab);

            $tab.remove();
            $( "#" + panelID ).remove();
            PageLayout.refreshTabs();
        });

        easy_jquery_tabs.on("change", "input, select, textarea", function(e){
            $(this).closest(".easy-page-module-form").attr('data-changed', true);
        });
        PageLayout.tabs_initialized = true
    },
    refreshAddModule: function() {
        $(".add-module-select").off('change').change(function(evt){
            evt.preventDefault();
            PageLayout.addModule.call(this);
        });
    },
    refreshTabs: function() {
        et = PageLayout.tab_element.data('easytabs');
        et.getTabs();
        // PageLayout.tab_element.removeData('easytabs');
        // PageLayout.tab_element.easytabs(PageLayout.__easytabsOptions);
    },
    getPanelIDforTab: function($tab) {
        $a = $tab.children('a');
        panelID = $a.data('target');

        // If the tab has a `data-target` attribute, and is thus an ajax tab
        if ( panelID !== undefined && panelID !== null ) {
          $tab.data('easytabs').ajax = $a.attr('href');
        } else {
          panelID = $a.attr('href');
        }
        panelID = panelID.match(/#([^\?]+)/)[1];
        return panelID;
    },

    initSortable: function(options) {
        var o = $.extend({}, {
            tabIdPrefix: 'easy_jquery_tab_panel',
            tabPos: false,
            tab_id: false,
            zoneName: false, // name of zone to become sortable
            updateUrl: false // url for ajax request when modules in zone are reordered
        }, options);

        if( o.tab_id === false || o.tabPos === false || !o.zoneName || !o.updateUrl){
             if( typeof console != typeof undefined)
                 console.warn('Zone ' + o.zoneName + 'was not initialized.')
             return;
        }
        var tabId = o.tabIdPrefix + '-' + o.tab_id;
        if( $("#tab"+o.tabPos+"-list-" + o.zoneName).parent().hasClass('grid-stack-zone') ) {
            return;
        }

        $("#tab"+o.tabPos+"-list-" + o.zoneName).sortable({
            connectWith: '#' + tabId +" .easy-page-zone",
            handle: '.handle',
            start: function(event, ui){
                var cked = $(ui.item).find(".cke");
                if(cked.length > 0) {
                    var ck = CKEDITOR.instances[cked.attr("id").replace(/^cke_/, '')];
                    current_ck_text = ck.getData();
                    current_ck_config = ck.config;
                    ck.destroy()
                }
            },
            stop: function(event, ui){
                var cked = $(ui.item).find("textarea");
                if(cked.length > 0) {
                    try	{
                        EASY.ckeditor.init(cked[0], current_ck_config, function (instance) {
                          instance.setData(current_ck_text);
                        });
                    } catch(exception){}
                }
            },
            update: function() {
                var serialized = $(this).sortable("serialize", {
                    key: "list-" + o.zoneName + "[]",
                    expression: /module_(.*)/
                });
                $.post(o.updateUrl + "&" + serialized);
            }
        });
    },

    addModule: function(url, $page_zone, module_id) {
        var select, form, additional_data;
        if( typeof url == 'undefined' ) {
            select = $(this);
            form = select.parent('form');
            url = PageLayout.url_with_current_tab_param(select.data('url'));
            additional_data = form.serializeArray();
            $page_zone = form.closest('.easy-page-zone');
        } else {
            additional_data = {module_id: module_id};
            form = $page_zone.find('.add-module-edit-content form');
            select = form.find('select');
        }
        $.ajax( url, {
            method: 'POST',
            data: additional_data,
            success: function(data) {
                $module = $(data)
                if( form.length > 0 )
                    form.parent().after($module);
                else
                    $page_zone.prepend($module);
                if ( select.length > 0 )
                    select[0].selectedIndex = 0;
                $page_zone.find(".easy-page-module-form:first").attr('data-changed', true);
                $page_zone.trigger('easy_page:module_added', {page_module: $module, page_zone: $page_zone});
            }
        });
    },

    returnModule: function(url, module_id, $container, callback) {
        $.ajax( url, {
            method: 'POST',
            data: {module_id: module_id},
            success: function(data) {
                var $module = $(data);
                $container.append($module);
                callback();
            },
            error: function(req, err){ console.log('Cannot find module' + err); }
        });
    },

    cloneModuleWithUrl: function($page_zone, $cloned, url) {
        var page_url = PageLayout.url_with_current_tab_param(url);
        $.post(page_url, function(data) {
            var $module = $(data);
            $page_zone.prepend($module);
            $page_zone.find(".easy-page-module-form:first").attr('data-changed', true);
            $page_zone.trigger('easy_page:module_added', {page_module: $module, page_zone: $page_zone, clone: $cloned});
        })
    },

    removeModule: function(button) {
        PageLayout.removeModuleWithUrl(button, $(button).attr('href'));
    },

    removeModuleWithUrl: function(button, url, ask) {
        var $button = $(button);

        if (ask) {
            if (!confirm(ask)) return;
        }
        $.post(url, function() {
            var $module = $button.closest(".easy-page-module");
            $module.fadeOut('fast', function() {
                $module.closest('.easy-page-zone').trigger('easy_page:module_removed', {page_module: $module});
                $module.remove();
            });
        });
    },

    prepareSubmitModules: function() {
        var activePanelId = PageLayout.getActivePanelId();
        var activeTab = PageLayout.getActiveTab();
        $("#t").val(activeTab ? activeTab.index() + 1 : 1);

        PageLayout.checkPanelCKeditorsDirty($("#" + activePanelId));
        var frmSettings = $("#easy-page_modules-settings-form");
        var $dataForms = $(".easy-page-module-form[data-changed=true], #easy_jquery_tab_panel-0 .easy-page-module-form").not("#easy_grid_sidebarClone .easy-page-module-form");

        $dataForms.each(function(){
            var $this = $(this);
            var uuid = $this.attr("data-uuid")

            // Old way callbacks
            var moduleCallbackName = "before_submit_module_inside_" + uuid;
            if (typeof window[moduleCallbackName] === "function") {
                window[moduleCallbackName]();
            }

            // New way callbacks
            PageLayout.runCallbacks("beforeSave", uuid);

            // Moving data to forms which will be submited
            // input.serialize - there are fields that should be serialized
            //                   but are jquery autocomplete
            $("input:not(.ui-autocomplete-input), input.serialize, select, textarea:not(.wiki-edit)", this).each(function(){
                var $this = $(this)

                $this.clone()
                     .hide()
                     .appendTo(frmSettings)
                     .val($this.val());
            });

            // Serialize wiki board
            $(".wiki-edit", this).each(function(){
                var boardValue;

                if (typeof CKEDITOR === "undefined" || !CKEDITOR.instances[this.id]) {
                    boardValue = $(this).val();
                }
                else {
                    boardValue = CKEDITOR.instances[this.id].getData();
                }
                $("<input>").attr("type", "hidden")
                            .attr("name", this.name)
                            .val(boardValue)
                            .appendTo(frmSettings);
            });
        });

        // Serialize - global filters definition
        //           - page tab settings
        $(".definition-global-filters, .page-tab-settings").find("input, select, textarea").not(":disabled").each(function(){
            $(this).clone()
                   .hide()
                   .appendTo(frmSettings)
                   .val(this.value);
        });
    },

    submitModules: function() {
        $("#easy-page_modules-settings-form").submit();
    },

    addTab: function() {
        $("#easy_page_editable_tabs_container").load($(this).attr('href'));
        return false;
    },

    editTab: function(button, tab) {
        $(button).closest('li').load($(button).attr('href'));
        return false;
    },

    // ----- HELPERS -----
    change_link_current_tab: function($element) {
        var url = PageLayout.url_with_current_tab_param($element.attr('href'));
        $element.attr('href', url);
    },
    url_with_current_tab_param: function(url) {
        $tab = PageLayout.getActiveTab();
        if( $tab !== false ) {
            url = PageLayout.setAttrToUrl(url, 'tab_id', $tab.find('.easy_tab_id').data('tab-id'));
        }
        return url;
    },
    checkPanelCKeditorsDirty: function($panel) {
        if(typeof CKEDITOR === typeof undefined)
            return true;
        $panel.find("textarea").each(function(index){
            var instance = CKEDITOR.instances[$(this).attr('id')];
            if( typeof instance === typeof undefined )
                return true;
            if(instance.checkDirty())
                $(this).closest(".easy-page-module-form").attr('data-changed', true);
        });
    },
    setAttrToUrl: function(url, name, value) {
        var attr_regex = RegExp(name+"=[^\&]+");
        if(url.match(attr_regex)) {
            return url.replace(attr_regex, name+'='+value);
        }

        if(!url.match(/\?/)) {
            url += '?';
        } else if (!url.match(/\&$/)) {
            url += '&';
        }
        url += name+'='+value;
        return url;
    },


    //
    // Callbacks
    //
    callbacks: { beforeSave: {} },

    runCallbacks: function(type, uuid){
        var callbacksForType = this.callbacks[type]
        if (!callbacksForType) return

        uuid = uuid.replace(/-/g, '_')
        var callbacksForUuid = callbacksForType[uuid]
        if (!callbacksForUuid) return

        for (var i = 0; i < callbacksForUuid.length; i++) {
            callbacksForUuid[i]()
        }
    },

    beforeSave: function(uuid, func){
        var callbacks = this.callbacks.beforeSave
        uuid = uuid.replace(/-/g, '_')

        callbacks[uuid] || (callbacks[uuid] = [])
        callbacks[uuid].push(func)
    },

    removeBeforeSave: function(uuid, func){
        var callbacks = this.callbacks.beforeSave
        uuid = uuid.replace(/-/g, '_')

        callbacks[uuid] || (callbacks[uuid] = [])
        callbacks[uuid] = callbacks[uuid].filter(function(saved){
            saved !== func
        })
    }

};
