(function(){

  // Dynamic help for chart output > onclick
  //
  $.widget("EASY.easyChartOnlickHelp", {

    _create: function(){
      this.globalFilterRows = {}

      this.fromOptions()
      this.subscribeCallbacks()
    },

    fromOptions: function(){
      var documentFragment = $(document.createDocumentFragment())

      for (var i = 0; i < this.options.tokens.length; i++) {
        var token = this.options.tokens[i]

        var $tdName = $("<td>").append("%" + token.name + "%")
                               .on("click", function(){ easyUtils.selectElementText(this) })
        var $tdDesc = $("<td>").append(token.desc)

        documentFragment.append(
          $("<tr>").append($tdName, $tdDesc)
        )
      }

      this.element.append(documentFragment)
    },

    fromExistingGlobalFilters: function(){
      var definition = EASY.globalFilters.definitions[this.options.tabId]
      if (definition) {
        var allFilters = definition.globalFilters("getAllFilters")
        for (var i = 0; i < allFilters.length; i++) {
          var filter = allFilters[i]
          this.addGlobalFilter(filter)
        }
      }
    },

    fromSavedGlobalFilters: function(globalFilters){
      if (!globalFilters) {
        return
      }

      allFilters = Object.entries(globalFilters)
      for (var i = 0; i < allFilters.length; i++) {
        var filterId = allFilters[i][0]
        var filterOptions= allFilters[i][1]
        filterOptions.active = true
        filterOptions.filterId = filterId

        this.addGlobalFilter(filterOptions)
      }
    },

    subscribeCallbacks: function(){
      var self = this

      ERUI.document.on("globalFilters:newAdded", function(event, options){
        if(options.tabId !== self.options.tabId) return

        self.addGlobalFilter(options)
      })

      ERUI.document.on("globalFilters:nameChanged", function(event, options){
        if(options.tabId !== self.options.tabId) return

        var $tr = self.globalFilterRows[options.filterId]
        if ($tr) {
          $tr.find("td:last").text(options.name)
        }
      })

      ERUI.document.on("globalFilters:tabIdChanged", function(event, options){
        if(options.fromId !== self.options.tabId) return

        self.options.tabId = options.toId
      })

      ERUI.document.on("globalFilters:toggleState", function(event, options){
        if(options.tabId !== self.options.tabId) return

        var $tr = self.globalFilterRows[options.filterId]
        if ($tr) {
          $tr.toggle(options.active)
        }
      })
    },

    addGlobalFilter: function(filter){
      var $tdName = $("<td>").on("click", function(){ easyUtils.selectElementText(this) })
                             .append("%global_filter_" + filter.filterId + "%")
      var $tdDesc = $("<td>").append(filter.name)
      var $tr = $("<tr>").append($tdName, $tdDesc)

      if (!filter.active) {
        $tr.hide()
      }

      this.globalFilterRows[filter.filterId] = $tr
      this.element.append($tr)
    },

  })

})();
