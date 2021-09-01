(function(){

  // EASY.globalFilters
  //
  // Global filters definitions
  // On page is only one instance
  //
  $.widget("EASY.globalFilters", {

    options: {
      tabId: null,
      availableFilters: null,
      savedFilters: {},
      lastFilterId: null,
      I18n: {},
      settings: {}
    },

    _create: function(){
      this.allRows = {};
      this.allFilters = {};
      this.filterIds = [];
      this.$select = this.element.find("select:first");
      this.$select.on("change", $.proxy(this.addNew, this));
      this.$tbody = this.element.find("tbody");
      this.$settings = this.element.find(".definition-global-filters__settings")

      // To avoid adding class "fake-responsive" (this code is run later)
      this.$settings.addClass("tabular")

      if (this.options.savedFilters) {
        var addSaved = function(filterId, filterOptions){
          const options = {
            type: filterOptions.type,
            name: filterOptions.name,
            translatedName: filterOptions.translated_name,
            possibleValues: filterOptions.possible_values,
            selectedValue: filterOptions.selected_value
          };
          this.add(filterId, options)
        };
        $.each(this.options.savedFilters, $.proxy(addSaved, this))
      }

      // Widget is ready so query can be initialized
      // EASY.globalFilters.waitQueue.init(this.options.tabId);

      this.initSettings()
      this.addKeepInput()

      EASY.globalFilters.definitions[this.options.tabId] = this.element
    },

    // Select all queries for current tab
    //
    // queries: function(tabId){
    //   if (tabId === undefined) {
    //     tabId = this.options.tabId
    //   }

    //   return $(".query-global-filters[data-tab-id='"+tabId+"']")
    // },

    initSettings: function(){
      this.initCurrency()
    },

    initCurrency: function(){
      var self = this
      var inputId = "global_currency" + this.options.tabId
      var inputName = "global_currency["+this.options.tabId+"]"

      var $container = $("<p>")
      var $keepCheckbox = $("<input>", {
        type: "hidden",
        name: inputName,
        value: '0',
      })
      var $checkbox = $("<input>", {
        type: "checkbox",
        name: inputName,
        id: inputId,
        value: '1',
        checked: (self.options.settings.global_currency == '1'),
      })

      const defaultInputName = `global_currency_defaults[${this.options.tabId}]`
      const $defaultValue = $("<select>", {
        name: defaultInputName,
        hidden: (self.options.settings.global_currency != '1'),
      })

      $defaultValue.append(
        $("<option>", { value: "-", readonly: true }).append(this.options.I18n.actionview_instancetag_blank_option)
      )

      for (let i = 0; i < self.options.availableCurrencies.length; i++) {
        const value = self.options.availableCurrencies[i]

        $defaultValue.append(
          $("<option>", { value: value[1], selected: (value[1] == self.options.settings.global_currency_defaults) }).append(value[0])
        )
      }

      $checkbox.on("change", function(){
        self.options.settings.global_currency = (this.checked ? '1' : '0')
        $defaultValue.attr("hidden", !this.checked)
      })

      var $label = $("<label>", { for: inputId }).append(this.options.I18n.label_easy_currency)

      $container.append($label, $keepCheckbox, $checkbox, $defaultValue)
      this.$settings.append($container)
    },

    // Add new filter, called from select tag
    //
    addNew: function(){
      var filterId = (new Date).getTime();
      var type = this.$select.val();

      this.add(filterId, { type });
      this.$select.val("");

      ERUI.document.trigger("globalFilters:newAdded", {
        tabId: this.options.tabId,
        filterId: filterId,
        type: type,
        active: true
      })

      // this.queries().queryGlobalFilters("add", filterId, type)
    },

    // Add new or saved filter
    // type, name, translatedName, possibleValues, selectedValue
    add: function(filterId, filterOptions) {
      const type = filterOptions.type;
      const name = filterOptions.name;
      const translatedName = filterOptions.translatedName;
      let possibleValues = filterOptions.possibleValues;
      let selectedValue = filterOptions.selectedValue;

      var self = this;
      var inputName = function(key){
        return "global_filters["+self.options.tabId+"]["+filterId+"]["+key+"]"
      };

      // State checkbox

      var $state = $("<input>", { type: "checkbox", checked: true, class: "definition-global-filter__state" });
      $state.on("change", { filterId: filterId }, function(event){
        self.toggleDefinitionState(event.data.filterId, this.checked);
        self.toggleQueriesState(event.data.filterId, this.checked)
      });

      // Filter name

      var filterDefinition = this.options.availableFilters[type];
      var $label = $("<label>").append($state, filterDefinition.name);
      var $td1 = $("<td>");

      const $name = $("<input>", { type: "text", placeholder: I18n.textPleaseFillName+" ...", name: inputName("name"), value: translatedName });
      const $hiddenName = $("<input>", { type: 'hidden', name: inputName("name"), value: name });

      const nameChanged = function (filterId, event) {
        const widgetInstance = this;
        const target = event.target;
        const translatedName = target.tagName === 'SELECT' ? target.options[target.selectedIndex].text : target.value;

        widgetInstance.allFilters[filterId].name = target.value;
        widgetInstance.allFilters[filterId].translatedName = translatedName;
        // widgetInstance.queries().queryGlobalFilters("nameChanged", event.data.filterId, this.value)

        ERUI.document.trigger("globalFilters:nameChanged", {
          tabId: widgetInstance.options.tabId,
          filterId: filterId,
          name: translatedName
        })
      };

      const nameInput = $name[0];
      const hiddenName = $hiddenName[0];
      nameInput.addEventListener('keyup', async event => {
        if (event.target.value == 'I18n:') {
          const labelsForEasyGlobalFiltersPath = `${window.urlPrefix}/easy_business_dashboards/labels_for_easy_global_filters.json`;
          const response = await fetch(labelsForEasyGlobalFiltersPath);
          const data = await response.json();
          const newSelect = document.createElement('select');
          newSelect.setAttribute('name', nameInput.getAttribute('name'));
          Object.keys(data).map(key => {
            const value = data[key];
            const option = document.createElement("option");
            option.setAttribute('value', `I18n:${key}`);
            option.text = value;
            newSelect.add(option);
          });

          if(hiddenName.parentNode) hiddenName.parentNode.removeChild(hiddenName);

          if (nameInput.parentNode) {
            nameInput.parentNode.replaceChild(newSelect, nameInput);
            newSelect.addEventListener('change', nameChanged.bind(this, filterId));
            newSelect.dispatchEvent(new Event('change'));
          }
        } else {
          if (hiddenName) hiddenName.value = event.target.value;
        }
      });
      nameInput.addEventListener('keyup', nameChanged.bind(this, filterId));

      // Defaul values

      var $default
      selectedValue || (selectedValue = "")

      if (filterDefinition.autocomplete) {
        var id = "ac_" + type + "_" + filterId

        var $span = $("<span>", { class: "easy-multiselect-tag-container" })
        var $field = $("<input>", { id: id, name: inputName("default_value"), type: "text" })

        if (!selectedValue) {
          selectedValue = [{id: "", value: "--- " + this.options.I18n.label_in_modules + " ---"}]
        }

        var initAutocomplete = function(){
          $("#" + id).easymultiselect({
            preload: false,
            multiple: false,
            select_first_value: false,
            selected: selectedValue,
            source: filterDefinition.autocomplete_path,
            rootElement: filterDefinition.autocomplete_root_element,
          });
        }

        $default = $span.append($field)
      }
      else if (filterDefinition.select_values) {
        $default = $("<select>", { name: inputName("default_value") })

        if (filterDefinition.select_values_grouped) {
          for (var i = 0; i < filterDefinition.select_values.length; i++) {
            var data = filterDefinition.select_values[i]
            var label = data[0]
            var values = data[1]
            var $optGroup = $("<optgroup>", { label: label })

            for (var j = 0; j < values.length; j++) {
              var value = values[j]
              $optGroup.append(
                $("<option>", { value: value[1], selected: (selectedValue == value[1]) }).append(value[0])
              )
            }

            $default.append($optGroup)
          }
        }
        else {
          for (var i = 0; i < filterDefinition.select_values.length; i++) {
            var value = filterDefinition.select_values[i]
            $default.append(
              $("<option>", { value: value[1], selected: (selectedValue == value[1]) }).append(value[0])
            )
          }
        }
      }
      else if (filterDefinition.manual_values) {
        $default = $("<input>", { id: id, name: inputName("default_value"), type: "text", value: selectedValue })
      }
      else if (filterDefinition.date_period_from_to) {
        var fromInputId = inputName("default_value") + '[from]';
        var toInputId   = inputName("default_value") + '[to]';
        var fromInput   = $("<input>", { id: fromInputId, name: fromInputId, type: "date", value: selectedValue['from'] });
        var toInput     = $("<input>", { id: toInputId, name: toInputId, type: "date", value: selectedValue['to'] });

        $default = fromInput.add(toInput);

        var initEasyDatePicker = function (element, html5) {
          element.addClass('date');
          element.prop('type', (html5 ? 'date' : 'text'));
          var className = element.parent().hasClass('inline') ? "input-append inline" : "input-append";
          if (!element.parent().hasClass('input-append')) {
            element.add(element.siblings('label.inline, a, span, button, input, select')
              .not('label:first-child, input[type="radio"], input[type="checkbox"]'))
              .wrapAll("<span class='" + className + "'></span>");
          }
          if (html5) {
            element.datepickerFallback(EASY.datepickerOptions);
          } else {
            element.datepicker(EASY.datepickerOptions);
          }
        };
      }

      // Make row

      var $type = $("<input>", { type: "hidden", value: type, name: inputName("type") });
      var $td2 = $("<td>");

      var $tr = $("<tr>")
                  .append($td1
                    .append($label))
                  .append($td2
                    .append($name, $hiddenName, $default, $type));

      // Manual values

      if (filterDefinition.manual_values) {
        possibleValues || (possibleValues = "");

        var $pTd1 = $("<td>", { style: "vertical-align: top" });
        var $pLabel = $("<label>").append(I18n.fieldPossibleValues);
        var $pTd2 = $("<td>");
        var $pTextarea = $("<textarea>", { name: inputName("possible_values"), cols: 10, rows: 10, style: "max-width: 350px" }).append(possibleValues);

        $pTextarea.on("keyup", { filterId: filterId, self: this }, function(event){
          var self = event.data.self;
          self.allFilters[filterId].possibleValues = this.value
        });

        var $pTr = $("<tr>", { style: "border: none" })
                     .append($pTd1
                       .append($pLabel))
                     .append($pTd2
                       .append($pTextarea));

        $tr = $tr.add($pTr)
      }

      this.$tbody.append($tr)
      initAutocomplete && initAutocomplete()
      if (initEasyDatePicker) {
        initEasyDatePicker(fromInput, filterDefinition.html5_dates);
        initEasyDatePicker(toInput, filterDefinition.html5_dates);
      }

      this.filterIds.push(filterId)
      this.allRows[filterId] = $tr
      this.allFilters[filterId] = { type: type, name: name, active: true, possibleValues: possibleValues, translatedName: translatedName }

      ERUI.document.trigger("globalFilters:added", {
        tabId: this.options.tabId,
        filterId: filterId,
        name: name
      })
    },

    // Query widgets are calling this method for self-initializing
    //
    initQuery: function(element){
      var updateElement = function(filterId, filterOptions){
        this.queryGlobalFilters("add", filterId, filterOptions.type, filterOptions.translatedName);
        this.queryGlobalFilters("toggleState", filterId, filterOptions.active)
      };
      $.each(this.allFilters, $.proxy(updateElement, element))
    },

    getAllFilters: function(){
      var result = []

      $.each(this.allFilters, function(filterId, filterOptions){
        result.push({
          filterId: filterId,
          name: filterOptions.name,
          type: filterOptions.type,
          active: filterOptions.active
        })
      })

      return result
    },

    // Page may not have tab but user could add one
    //
    tabIdChanged: function(fromId, toId){
      if (fromId != this.options.tabId) {
        return
      }

      this.element.attr("data-tab-id", toId);
      this.options.tabId = toId;

      // Remove current
      $.each(this.allRows, function(id, $tr){
        $tr.remove()
      });

      this.allRows = {};

      // Add previously added
      var addSaved = function(filterId, filterOptions){
        this.add(filterId, filterOptions);
        this.toggleDefinitionState(filterId, filterOptions.active)
      };
      $.each(this.allFilters, $.proxy(addSaved, this));

      // Reset settings
      this.$settings.empty()
      this.initSettings()

      // Keep input must reflext page id change
      this.addKeepInput()

      // Definition must be registered before children's annoucement
      EASY.globalFilters.definitions[fromId] = null
      EASY.globalFilters.definitions[this.options.tabId] = this.element

      // If definition is fully reloaded -> tell it to children
      ERUI.document.trigger("globalFilters:tabIdChanged", {
        fromId: fromId,
        toId: toId,
      })
    },

    // User may delete all filters
    //
    addKeepInput: function(){
      var $input = $("<input>", { type: "hidden", name: "global_filters["+this.options.tabId+"][__keep__]", value: "" });
      this.element.prepend($input)
    },

    toggleDefinitionState: function(filterId, active){
      var $tr = this.allRows[filterId];
      var $state = $tr.find(".definition-global-filter__state");

      this.allFilters[filterId].active = active;

      $state.prop("checked", active);
      $tr.find("input, select, textarea").not($state).prop("disabled", !active)
    },

    toggleQueriesState: function(filterId, active){
      // this.queries().queryGlobalFilters("toggleState", filterId, active)

      ERUI.document.trigger("globalFilters:toggleState", {
        tabId: this.options.tabId,
        filterId: filterId,
        active: active,
      })
    }

  });

})();
