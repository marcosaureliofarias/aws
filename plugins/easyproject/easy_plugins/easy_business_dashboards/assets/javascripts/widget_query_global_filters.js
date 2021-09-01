(function(){

  // EASY.queryGlobalFilters
  //
  // Every query has instance of this widget
  //
  $.widget("EASY.queryGlobalFilters", {

    options: {
      tabId: null,
      blockName: null,
      globalFilters: {},
      availableFilters: null
    },

    _create: function(){
      this.$table = this.element.find("table.filters-table tbody");
      this.reload()

      var self = this;

      ERUI.document.on("globalFilters:newAdded", function(event, options){
        if(options.tabId !== self.options.tabId) return

        self.add(options.filterId, options.type)
      })

      ERUI.document.on("globalFilters:nameChanged", function(event, options){
        if(options.tabId !== self.options.tabId) return

        self.nameChanged(options.filterId, options.name)
      })

      ERUI.document.on("globalFilters:tabIdChanged", function(event, options){
        if(options.fromId !== self.options.tabId) return

        self.tabIdChanged(options.fromId, options.toId)
      })

      ERUI.document.on("globalFilters:toggleState", function(event, options){
        if(options.tabId !== self.options.tabId) return

        self.toggleState(options.filterId, options.active)
      })
    },

    definition: function(){
      return EASY.globalFilters.definitions[this.options.tabId]
    },

    add: function(filterId, type, name){
      var filters = this.options.availableFilters[type];
      if (!filters) { return }

      var self = this;
      var inputName = function(key){
        return self.options.blockName + "[global_filters]["+filterId+"]["+key+"]"
      };

      name || (name = "---");

      this.options.globalFilters[filterId] || (this.options.globalFilters[filterId] = {});
      var thisFilter = this.options.globalFilters[filterId];

      var $label = $("<label>").text(name);
      this.labelsByFilterId[filterId] = $label;

      var $td1 = $("<td>");

      var $select = $("<select>", { name: inputName("filter"), "data-filter-id": filterId });
      $select.on("change", { filterId: filterId, thisFilter: thisFilter }, function(event){
        event.data.thisFilter.filter = this.value
      });

      $select.append("<option></option>");
      for (var i = 0; i < filters.length; i++) {
        var filter = filters[i];
        var $option = $("<option>", { value: filter.filter, selected: (thisFilter.filter === filter.filter) }).text(filter.name);
        $select.append($option)
      }

      if (type === "date_period") {
        var $previousPeriod = $("<input>", {
          type: "checkbox",
          name: inputName("set_previous_period"),
          value: "1",
          checked: (thisFilter.set_previous_period === "1")
        });

        var $controls = $("<div>").append(
          $("<label>").append($previousPeriod, I18n.labelChangePreviousPeriod)
        )
      }

      var $td2 = $("<td>");

      var $tr = $("<tr>")
                 .append($td1
                   .append($label))
                 .append($td2
                   .append($select, $controls));

      this.$table.append($tr);
      this.allRows[filterId] = $tr
    },

    // Callback called from EASY.globalFilters
    //
    nameChanged: function(filterId, name){
      var $label = this.labelsByFilterId[filterId];
      if ($label) {
        $label.text(name)
      }
    },

    // Callback called from EASY.globalFilters
    //
    toggleState: function(filterId, state){
      var $tr = this.allRows[filterId];
      if ($tr) {
        // Force to change because of "data-changed"
        $tr.find("input, select").prop("disabled", !state).change()
      }
    },

    // Page may not have tab but user could add one
    // This method is called from definition
    //
    tabIdChanged: function(fromId, toId){
      if (fromId == this.options.tabId) {
        this.element.attr("data-tab-id", toId);
        this.options.tabId = toId;
        this.reload()
      }
    },

    reload: function(){
      this.$table.empty();
      this.labelsByFilterId = {};
      this.allRows = {};

      this.definition().globalFilters("initQuery", this.element)
    }

  });

})()
