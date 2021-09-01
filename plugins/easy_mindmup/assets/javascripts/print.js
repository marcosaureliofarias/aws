(function () {
  function Print(ysy) {
    this.printReady = false;
    this.$area = null;
    this.ysy = ysy;
    this.patch(ysy);
  }

  Print.prototype.margins = {
    left: 10,
    right: 10,
    top: 20,
    bottom: 10
  };
  Print.prototype.patch = function (ysy) {
    var self = this;
    var mediaQueryList = window.matchMedia('print');
    mediaQueryList.addListener(function (mql) {
      if (mql.matches) {
        self.beforePrint();
      } else {
        self.afterPrint();
      }
    });
    window.onbeforeprint = $.proxy(this.beforePrint, this);
    window.onafterprint = $.proxy(this.afterPrint, this);

    if (ysy.settings.paths.print) {
      window.easyModel = window.easyModel || {};
      window.easyModel.print = window.easyModel.print || {};
      window.easyModel.print.functions = window.easyModel.print.functions || [];

      // This function should be added only once
      window.easyModel.print.functions.push(this.prepareForTemplate.bind(this));
      this.initControls();
    }
  };
  Print.prototype.directPrint = function () {
    this.beforePrint();
    window.print();
    this.afterPrint();
  };
  Print.prototype.beforePrint = function (isCompact) {
    if (this.printReady) return;
    this.ysy.mapModel.resetView();
    this.$area = isCompact ? this.createCompactArea() : this.createPrintArea();
    $("body").append(this.$area);
    $("#wrapper").hide();
    this.printReady = true;
    return this.$area;
  };
  Print.prototype.afterPrint = function () {
    if (!this.printReady) return;
    this.$area.remove();
    $("#wrapper").show();
    this.ysy.mapModel.resetView();
    this.printReady = false;
  };
  Print.prototype.createPrintArea = function () {
    var $stage = this.ysy.$container.children();
    // var width = $stage.width();
    // var height = $stage.height();
    var stripWidth = 330;
    var children = $stage.children(":not(:hidden)");
    var dims = this.getStageDims(children);
    var $area = $('<div id="mindmup__print-area" class="mindmup__print-area mindmup__print-area--stripped scheme-by-' + this.ysy.styles.setting + '"></div>');
    for (var p = dims.left - this.margins.left; p < dims.right + this.margins.right; p += stripWidth) {
      $area.append(this.createStrip(children, dims, p, p + stripWidth));
    }
    return $area;
  };
  Print.prototype.createStrip = function (children, dims, start, end) {
    /* start can be negative*/
    if (end <= start) return null;
    // var stageOffset = $stage.height();
    var $strip = $('<div class="mindmup__print-strip" style="height:' + (dims.bottom - dims.top + this.margins.top + this.margins.bottom) + 'px;width:' + (end - start) + 'px"></div>');
    // var children = $stage.children(":not(:hidden)");
    var added = 0;
    var topEdge = dims.top - this.margins.top;
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var left = parseInt(child.style.left);
      var width = child.offsetWidth;
      if (left > end + 5) continue;
      if (left + width < start - 5) continue;
      added++;
      $strip.append(
          $(child)
              .clone()
              .css({
                left: left - start,
                top: parseInt(child.style.top) - topEdge,
                width: width
              })
      );
    }
    if (!added) return null;
    return $strip;
  };
  Print.prototype.getStageDims = function (children) {
    var dims = {
      left: Infinity,
      top: Infinity,
      right: -Infinity,
      bottom: -Infinity
    };
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var left = parseInt(child.style.left);
      var top = parseInt(child.style.top);
      var width = child.offsetWidth;
      var height = child.offsetHeight;
      if (left < dims.left) dims.left = left;
      if (top < dims.top) dims.top = top;
      if (left + width > dims.right) dims.right = left + width;
      if (top + height > dims.bottom) dims.bottom = top + height;
    }
    return dims;
  };
  Print.prototype.createCompactArea = function () {
    var $stage = this.ysy.$container.children();
    var children = $stage.children(":not(:hidden)");
    var dims = this.getStageDims(children);
    var leftEdge = dims.left - this.margins.left;
    var topEdge = dims.top - this.margins.top;
    var $area = $('<div id="mindmup__print-area" class="mindmup__print-area mindmup__print-area--compact scheme-by-' + this.ysy.styles.setting + '" style="'
        + 'height:' + (dims.bottom - dims.top + this.margins.top + this.margins.bottom) + 'px;'
        + 'width:' + (dims.right - leftEdge + this.margins.right) + 'px"></div>');
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      $area.append(
          $(child)
              .clone()
              .css({
                left: parseInt(child.style.left) - leftEdge,
                top: parseInt(child.style.top) - topEdge,
                width: child.offsetWidth + 1
              })
      );
    }
    return $area;
  };
  Print.prototype.initControls = function () {
    var $controls = $("#easy_mindmup__print_controls");
    this.$templateSelector = $controls.find(".mindmup__print-template-selector");
    var $button = $controls.find(".mindmup__print-button");
    $button.click(this.printableTemplatePrint.bind(this));
  };

  Print.prototype.prepareForTemplate = function () {
    // Fit is always enabled now
    // var printFit = $("#print_fit_checkbox").is(":checked");
    var printFit = true;
    var printElement = this.beforePrint(printFit);
    var width = printElement.width();
    var printIncludes = this.ysy.settings.templates.printIncludes;
    var includes = document.createElement("head");
    includes.innerHTML = printIncludes;
    includes.querySelectorAll("link").forEach(function(link){
      // Link must have an aboslute URL
      //
      // For example:
      //   link = <link href="/style.css">
      //   link.href => "http://localhost/style.css"
      link.href = link.href;
    });

    var content = printElement[0].outerHTML + includes.innerHTML;

    if (printFit) {
      content = '<div class="easy-print-page-fitting">' + content + '</div>';
    }

    window.easyModel.print.tokens['easy_wbs_current'] = content;
    window.easyModel.print.setWidth(width);
  };
  Print.prototype.printableTemplatePrint = function () {
    var value = this.$templateSelector.val();
    if (value === "") return false;
    var url = this.ysy.settings.paths.print.replace(":id", value);

    window.easyModel.print.preview({href: url})
  };

  window.easyMindMupClasses.Print = Print;
  //####################################################################################################################
  /**
   * Button, which prepare Mind Map into printable version
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @constructor
   */
  function PrintButton(ysy, $parent) {
    this.$element = null;
    this.ysy = ysy;
    this.init(ysy, $parent);
  }

  PrintButton.prototype.id = "PrintButton";

  /**
   *
   * @param {MindMup} ysy
   * @param {jQuery} $parent
   * @return {PrintButton}
   */
  PrintButton.prototype.init = function (ysy, $parent) {
    this.$element = $parent.find(".mindmup-button-print");
    var self = this;
    this.$element.click(function () {
      self.ysy.print.directPrint();
    });
    return this;
  };
  PrintButton.prototype._render = function () {
  };

  window.easyMindMupClasses.PrintButton = PrintButton;

})();
