//= require widget_global_filters
//= require widget_query_global_filters

(function(){

  EASY.globalFilters = {};

  EASY.globalFilters.openEdit = function(link){
    $(".definition-global-filters").show()
  };

  EASY.globalFilters.apply = function (link) {
    var filtersData = $(".global-filter__field select, .global-filter__field input").serializeArray();
    var additionalData = $(".additional-data-for-module-reloading").serializeArray();
    var validFilters = filtersData.filter(isFilterValid).concat(additionalData);

    ERUI.document.trigger("globalFilters:before-apply");

    if ($('.after-apply-global-filters-module-need-reloading')[0]) {
      setGlobalFiltersToUrl(validFilters, filtersData);
      window.location.reload();
    } else {
      $.ajax({
        url: link.dataset.applyUrl,
        data: validFilters,
        success: function (data) {

          setGlobalFiltersToUrl(validFilters, filtersData);
          $("#easy_jquery_tab_panel-" + link.dataset.tabId).html(data);

          ERUI.document.trigger("tab-change");
          ERUI.document.trigger("globalFilters:after-apply")
        }
      });
    }
  };

  isFilterValid = function (item) {
    return item.value !== "" && item.value !== "in-modules"
  };

  setGlobalFiltersToUrl = function (filtersData, allFilters) {
    if (window.URLSearchParams) {
      var searchParams = new URLSearchParams(window.location.search);

      for (var i = 0; i < allFilters.length; i++) {
        var filters = allFilters[i];
        searchParams.delete(filters.name)
      }

      for (var i = 0; i < filtersData.length; i++) {
        var filterData = filtersData[i];

        if (isFilterValid(filterData)) {
          searchParams.set(filterData.name, filterData.value)
        } else {
          searchParams.delete(filterData.name)
        }
      }

      var newPath = window.location.pathname + '?' + searchParams.toString();
      history.pushState(null, '', newPath);
    }
  };

  EASY.globalFilters.getLink = function(link){
    if (!window.URLSearchParams) {
      return location.pathname + location.search;
    }

    var searchParams = new URLSearchParams(location.search)

    var filters = document.querySelectorAll(".global-filter")
    for (var i = 0; i < filters.length; i++) {
      var filter = filters[i]
      var value = filter.querySelector(".global-filter__name").textContent
      // *= because of autocomplete
      var filterElement = filter.querySelector(".global-filter__field select[name*=filter], .global-filter__field input[name*=filter], .global-filter__field select[name*=global_currency]")

      if (!filterElement) {
        continue
      }

      var name = filterElement.name
      value = "__" + value.toUpperCase().replace(/\s+/g, "_") + "__"
      searchParams.set(name, value)
    }

    return decodeURIComponent(window.location.pathname + '?' + searchParams.toString())
  };

  // Queue for ensuring initializing EASY.queryGlobalFilters after
  // EASY.globalFilters is fully loaded.
  //
  // This is necessary because of
  // - queries are loaded after EASY.globalFilters
  // - globalFilters can be empty or not
  // - you can add new one from ajax
  //
  // EASY.globalFilters.waitQueue = {
  //   ready: {},
  //   queue: {},
  //
  //   ensureQueue: function(tabId){
  //     this.queue[tabId] || (this.queue[tabId] = [])
  //   },
  //
  //   init: function(tabId){
  //     this.ensureQueue(tabId);
  //     this.ready[tabId] = true;
  //
  //     var queue = this.queue[tabId];
  //     for (var i = 0; i < queue.length; i++) {
  //       queue[i]()
  //     }
  //   },
  //
  //   push: function(tabId, func){
  //     if (this.ready[tabId]) {
  //       func()
  //     } else {
  //       this.ensureQueue(tabId);
  //       this.queue[tabId].push(func)
  //     }
  //   }
  // }

  EASY.globalFilters.definitions = {}

})();
