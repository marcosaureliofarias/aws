(function () {

  EASY.search = EASY.search || (EASY.search = {});

  EASY.search.version = "suggester-items-1.0.0";

  EASY.search.settings = {
    $menu: ''
  };

  var getSuggesterItems = function () {
    var result;

    try {
      result = JSON.parse(localStorage.getItem(EASY.search.version));
    } catch (e) {
    }

    return result || [];
  };

  EASY.search.suggesterItemSelect = function (item) {
    var $this = $(this);
    var currentItem = item;
    if (currentItem.category != "latest") {
      currentItem.psedocategory = currentItem.category;
      currentItem.category = "latest";
    }
    if (!currentItem.id) return;
    var items = getSuggesterItems();
    var cutPosition = currentItem.id.indexOf('?');
    if (cutPosition !== -1) {
      currentItem.id = currentItem.id.substring(0, cutPosition);
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i].id === currentItem.id) {
        items[i] = null;
      }
    }

    items = items.filter(function (i) {
      return !!i;
    });
    items.unshift(currentItem);
    items.splice(5);

    localStorage.setItem(EASY.search.version, JSON.stringify(items));
  };

  EASY.search.suggesterItem = function (ul, item) {
    var content = document.createElement("a");

    if (item.id != null) {
      content.setAttribute("href", item.id);
      content.setAttribute('data-category', item.category);
      content.setAttribute('data-id', item.id);
      content.setAttribute('data-label', item.label);
      content.setAttribute('data-value', item.value);
      if (item.issue_id != null) {
        content.setAttribute('data-issue_id', item.issue_id);
      }
    } else {
      content.setAttribute("href", "javascript:void(false);");
    }
    var itemValue = document.createElement("div").appendChild(document.createTextNode(item.value)).parentNode.innerHTML;
    if (item.label) {
      var itemLabel = document.createElement("div").appendChild(document.createTextNode(item.label)).parentNode.innerHTML;
    } else if (item.category) {
      var itemLabel = document.createElement("div").appendChild(document.createTextNode(item.category)).parentNode.innerHTML;
    } else {
      var itemLabel = document.createElement("div").appendChild(document.createTextNode(" ")).parentNode.innerHTML;
    }
    if (item.psedocategory) {
      content.innerHTML = itemValue + "<small>" + "<br>" + "<span class='ui-autocomplete-pseudo_category'>" + item.psedocategory + " " + "</span>" + itemLabel + "</small>";
    } else {
      content.innerHTML = itemValue + "<small>" + "<br>" + itemLabel + "</small>";
    }

    return $("<li>")
      .addClass((item.closed === true) ? "jumpbox-project-closed" : "")
      .data("ui-autocomplete-item", item)
      .html(content)
      .appendTo(ul);
  };

  EASY.search.suggesterChange = function (href) {
    if (href !== null && href.length > 0) {
      window.location = href;
    }
  };

  EASY.search.suggesterFocus = function () {
    var menuIsOpen = this.settings.$menu === "" ? false : this.settings.$menu.is(":visible");
    if (menuIsOpen) return;
    var $input = $("#search_q_autocomplete");
    var items = getSuggesterItems();

    if (items.length) {
      var originalSource = $input.data().easySuggester.source;
      $input.suggester({
        source: items
      }).suggester("search");
      $input.data().easySuggester.source = originalSource;
    }
  };

  $.widget("easy.catcomplete", $.ui.autocomplete, {
    _create: function () {
      this._super();
      this.widget().menu("option", "items", "> :not(.ui-autocomplete-category)");
      // this.element.attr( "autocomplete", "nope" );
      this._on({
        "mousedown .ui-menu-item-wrapper": function (e) {
          if (e.which === 2) {
            EASY.search.suggesterItemSelect(e.currentTarget.dataset);
          }
          e.preventDefault();
          return false;
        }
      });
    },
    _renderMenu: function (ul, items) {
      var that = this,
        currentCategory = "";
      $.each(items, function (index, item) {
        var li;
        if (item.category != currentCategory && item.category != undefined) {
          ul.append("<li class='ui-autocomplete-category'>" + item.category + "</li>");
          currentCategory = item.category;
        }
        li = that._renderItemData(ul, item);
        if (item.category) {
          li.attr("aria-label", item.category + " : " + item.label);
        }
      });
    }
  });

  $.widget("easy.suggester", $.easy.catcomplete, {
    _create: function () {
      this._super();
      var menu = $(this.menu.activeMenu[0]);
      menu.addClass("ui-menu-fixed"); //fixed position for main searchbar menu
      EASY.search.suggesterInitialized = true;
    },
    _renderMenu: function (ul, items) {
      EASY.search.settings.$menu = ul;
      var that = this,
        currentCategory = "";
      $.each(items, function (index, item) {
        var li;
        if (item.category !== undefined && item.category !== currentCategory) {
          const category = item.category === "latest" ? window.I18n.labelLatest : item.category;
          ul.append(`<li class='ui-autocomplete-category'> ${category} </li>`);
          currentCategory = item.category;
        }
        li = EASY.search.suggesterItem(ul, item);
        if (item.category) {
          li.attr("aria-label", item.category + " : " + item.label);
        }
      });
    }
  });

})();

