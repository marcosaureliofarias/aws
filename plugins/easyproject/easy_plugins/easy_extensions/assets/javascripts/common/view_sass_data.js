(function () {
    window.easyClasses = window.easyClasses || {};
    window.easyView = window.easyView || {};

    // breakpoint functions
    // ==========================================================================
    // some craxy regex to deal with how browsers pass the JSON through CSS
    function removeQuotes(string) {
        if (typeof string === 'string' || string instanceof String) {
            string = string.replace(/^['"]+|\s+|\\|(;\s?})+|['"]$/g, '');
        }
        return string;
    }

    // get the breakpoint labels from the body's css generated content
    function getSassData() {
        var style = null;
        // modern browser can read the label
        if (window.getComputedStyle) {
            style = window.getComputedStyle(document.getElementsByTagName('head')[0]);
            style = style.getPropertyValue('font-family');
        } else {
            // older browsers need some help
            var getComputedFallback = function (el) {
                this.el = el;
                this.getPropertyValue = function (prop) {
                    var re = /(\-([a-z]){1})/g;
                    if (re.test(prop)) {
                        prop = prop.replace(re, function () {
                            return arguments[2].toUpperCase();
                        });
                    }
                    return el.currentStyle[prop] ? el.currentStyle[prop] : null;
                };
                return this;
            };

            // fallback label is added as a font-family to the head, thanks Jeremy Keith
            style = getComputedFallback(document.getElementsByTagName('head')[0]);
            style = style.getPropertyValue('font-family');
        }
        var out = {};
        try {
            var dirty = removeQuotes(style);
            if(dirty.length>0){
                dirty = dirty.substring(0,dirty.length-1);
            }
            var startString = "{";
            if(dirty.substring(0,1)!=="\""){
                startString+="\"";
            }
            out = JSON.parse(startString+dirty+"}");
        } catch (e) {

        }

        return out;

    }

    window.easyView.sassDataComputed = false;
    window.easyView.onSassDataComputed = [];

    window.ERUI = window.ERUI || {};
    EasyGem.extend(window.ERUI, {
        "sassDataComputed": false,
        "sassData": null,
        "onSassDataComputed": []
    });

    EASY.schedule.main(function () {
        window.easyView.sassDataComputed = true;
        window.easyView.sassData = getSassData();

        EasyGem.extend(window.ERUI, {
            "sassDataComputed": true,
            "sassData": getSassData()
        });

        for (var i = 0; i < window.easyView.onSassDataComputed.length; i++) {
            window.easyView.onSassDataComputed[i]();
        }
        for (i = 0; i < window.ERUI.onSassDataComputed.length; i++) {
            window.ERUI.onSassDataComputed[i]();
        }
    });

  /**
   *
   * @param {String} varName
   * @param {Number} defaultValue
   * @param {boolean} noUnit
   */
  EASY.getSassData = function (varName, defaultValue, noUnit) {
    if (ERUI.sassData && ERUI.sassData[varName]) {
      var retVal = ERUI.sassData[varName];
      if (noUnit) {
        retVal = parseFloat(retVal);
      }
      return retVal;
    } else {
      return defaultValue;
    }
  };

})();
