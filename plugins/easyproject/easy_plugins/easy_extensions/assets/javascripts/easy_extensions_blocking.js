//= require 'namespaces'

//= require 'easy_extensions_blocking_asset'
//= require_self

EASY.contextMenu.addContextMenuFor = function (url, element) {

  if (!EASY.contextMenu.initializers) {
    EASY.contextMenu.initializers = [];
  }
  if(url === '') {
      var data = $(element).closest('form').data();
      if(data) { url = data.cmUrl; }
  }
  EASY.contextMenu.initializers.push("contextMenuInit('" + url + "', '" + element + "')");
};
window.jQueryPluginGetter = function (name) {
  return function () {
    return window.jQuery && jQuery.fn[name];
  };
};
if (!window.$) {
  window.$ = function (object) {
    if (object === window) {
      return {
        load: function (body) {
          EASY.schedule.late(body);
        }
      };
    } else if (object === document) {
      return {
        ready: function (body) {
          EASY.schedule.late(body);
        }
      };
    } else if (typeof object === "function") {
      return EASY.schedule.late(object);
    } else if(typeof object === "string"){
      throw "$(\""+object+"\") cannot be executed, jQuery not prepared"
    }
    return null;
  };
}

EASY.utils.isStorageItem = function (rootObj, itemName) {
  const savedPref = window.localStorage.getItem(rootObj);
  if (!savedPref) return false;
  const parsed = JSON.parse(savedPref);
  return !!parsed[itemName];
};

EASY.utils.loadMenu = function () {
  const close = this.isStorageItem("savedPreferences", 'hide_menu');
  const body = document.body;
  const topMenu = document.getElementById('top-menu');

  if (close) {
    body.classList.add('top_menu--collapsed');
    if(topMenu)
      topMenu.classList.add('collapsed');
  } else {
    body.classList.remove('top_menu--collapsed');
    if(topMenu)
      topMenu.classList.remove('collapsed');
  }
};

EASY.utils.loadSidebar = function () {
  // sidebar has opposite behaviour, it is closed in default
  const closed = !this.isStorageItem('savedPreferences', 'open_sidebar');
  const body = document.body;
  closed ? body.classList.add('nosidebar') : body.classList.remove('nosidebar');
};

EASY.utils.loadDetailAttributes = function (modulId) {
  const closed = this.isStorageItem('savedPreferences', modulId);
  if (!closed) return;

  const issueAttributes = document.querySelector(".easy-entity-details-header-attributes");
  if (!issueAttributes) return;

  issueAttributes.classList.toggle("open");
  const toggleButton = issueAttributes.querySelector(".more-attributes-toggler");
  const toggleClasses = ["open", "icon-add", "icon-remove"];
  toggleClasses.forEach(function(toggleClass) {
    toggleButton.classList.toggle(toggleClass);
  });
};
