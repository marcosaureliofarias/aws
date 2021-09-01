(function(){

  // For browser which does not supports URLSearchParams
  //
  var urlSearchParamsDisabled = {
    getGlobalFilter: function(){},
    makeUrl: function(){},
    registerPageBeforeSave: function(){}
  }

  // For modern browser (not-IE) which supports URLSearchParams
  //
  var urlSearchParamsEnabled = {

    _create: function(){
      this.oldValue = this.element.val()
      this.element.on("input", $.proxy(this.urlChanged, this))
      this.ensureParamsTable()
      this.build()

      var $parseLink = $("<a>", { href: "javascript:void(0)", class: "icon icon-integrate block" })
      $parseLink.append(this.options.I18n.parse)
      $parseLink.on("click", $.proxy(this.reBuild, this))
      this.element.after($parseLink)
    },

    _destroy: function() {
      if (this.registeredPageBeforeSave) {
        PageLayout.removeBeforeSave(this.registeredPageBeforeSave[0], this.registeredPageBeforeSave[2])
      }
    },

    registerPageBeforeSave: function(page_module_uuid){
      var self = this
      var beforeSave = function(){
        self.makeUrl()
      }

      PageLayout.beforeSave(page_module_uuid, beforeSave)
      this.registeredPageBeforeSave = [page_module_uuid, beforeSave]
    },

    add: function(name, value){
      var $name = $("<input>", { type: "text", name: "name", value: name, placeholder: this.options.I18n.name })

      var valueOptions = { type: "text", name: "value", placeholder: this.options.I18n.value, value: value }
      var valueMatch

      if (value && (valueMatch = value.match(/^__(.+)__$/))) {
        valueOptions.placeholder = valueMatch[1]
        valueOptions.value = null
      }

      var $value = $("<input>", valueOptions)
      var $tdName = $("<td>").append($name)
      var $tdValue = $("<td>").append($value)

      var $closeLink = $("<a>", { href: "javascript:void(0)", class: "icon icon-close red-icon" })
      var $tdcloseLink = $("<td>").append($closeLink)

      var $tr = $("<tr>").append($tdName, $tdValue, $tdcloseLink)

      $closeLink.on("click", { $tr: $tr }, function(event){
        event.data.$tr.remove()
      })

      this.$addTr.before($tr)
    },

    ensureParamsTable: function(){
      if (typeof(this.options.paramsTable) === "string") {
        switch (this.options.paramsTable) {
          case "afterParent":
            this.$paramsTable = $("<table>", { style: "width: auto" })
            this.element.parent().after(this.$paramsTable)
            break;
          default:
            this.$paramsTable = $(this.options.paramsTable)
        }
      }
      else {
        this.$paramsTable = this.options.paramsTable
      }

      var $add = $("<a>", { href: "javascript:void(0)", class: "icon icon-add" }).append(I18n.buttonAdd)
      $add.on("click", $.proxy(function(){ this.add() }, this))

      this.$addTr = $("<tr>").append(
                        $("<td>"),
                        $("<td>").append($add)
                    )

      this.$paramsTable.append(this.$addTr)
    },

    parseUrl: function(url){
      var urlParser = document.createElement("a")
      urlParser.href = url
      // url = url.replace(urlParser.search, "")

      var pos = url.indexOf("?")
      if (pos !== -1) {
        url = url.slice(0, pos)
      }

      return { base: url, search: urlParser.search }
    },

    reBuild: function(){
      // this.$paramsTable.find("tr").not(this.$addTr).remove()
      this.build()
    },

    build: function(){
      var value = this.element.val()
      if (!value) {
        return
      }

      var url = this.parseUrl(value)
      this.element.val(url.base)

      var searchParams = new URLSearchParams(url.search)

      searchParams = Array.from(searchParams)
      for (var i = 0; i < searchParams.length; i++) {
        var name = searchParams[i][0]
        var value = searchParams[i][1]
        this.add(name, value)
      }
    },

    urlChanged: function(){
      if (this.urlChangedDisabled) return
      var currentValue = this.element.val()

      // Focus
      if (currentValue === this.oldValue) {
        return
      }

      // Textarea was empty
      // Copy content
      else if (this.oldValue.length === 0) {
        this.build()
      }

      // Other typeing
      else {
      }

      this.oldValue = currentValue
    },

    makeUrl: function(){
      var value = this.element.val()
      var url = this.parseUrl(value)

      var searchParams = new URLSearchParams(url.search)

      var name
      var prevType

      this.$paramsTable.find("input").each(function(){
        if (prevType !== "name") {
          name = this.value
          prevType = "name"
        }
        else {
          searchParams.set(name, this.value.trim())
          prevType = "value"
        }
      })

      // This should not trigger any callback but just in case
      this.urlChangedDisabled = true
      this.element.val(url.base + "?" + searchParams.toString())
      this.urlChangedDisabled = false
    },

  }

  if (window.URLSearchParams) {
    var widget = urlSearchParamsEnabled
  }
  else {
    var widget = urlSearchParamsDisabled
  }

  $.widget("EASY.easyUrlBuilder", widget)

})();
