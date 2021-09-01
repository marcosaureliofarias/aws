(function ($) {
  var DependentList = function (options) {
    this.init('dependentlist', options, DependentList.defaults);
  };
  $.fn.editableutils.inherit(DependentList, $.fn.editabletypes.select);
  DependentList.defaults = $.extend({}, $.fn.editabletypes.select.defaults, {});
  DependentList.defaults.sourceCache = false;
  $.fn.editabletypes.dependentlist = DependentList;

  class DependentCustomFieldList {
    constructor (cfId, tagId, cfValue, dataDependency) {
      this.parentDataDependency = dataDependency;
      this.dependentCustomFieldId = cfId;
      this.dependentCustomFieldValue = cfValue;
      this.$dependentCustomField = document.getElementById(tagId);
      this.init(false);
      var dependencySelector = document.querySelector(`[data-dependency="${dataDependency}"]`);

      if (dependencySelector) {
        dependencySelector.addEventListener('change', () => {
          this.init(true);
        });
      } else {
        this.$dependentCustomField.disabled = true;
      }
    }

    init (change) {
      this.change = change;
      this.selectedParentOptions = document.querySelectorAll(`[data-dependency="${this.parentDataDependency}"] option:checked`);
      this.selectedParentValues = Array.from(this.selectedParentOptions).map(option => option.value);
      this.options = this.$dependentCustomField.options;
      this.options.length = 1;
      if (this.selectedParentValues[0] === '') {
        this.$dependentCustomField.disabled = true;
        this.change = true;
      } else {
        this.$dependentCustomField.disabled = false;
        let collectionValues = [];
        window.dependentCfMatrix[this.dependentCustomFieldId].forEach((value) => {
          if (this.selectedParentValues.indexOf(value[0]) >= 0) {
            if (collectionValues.indexOf(value[1]) >= 0) { return; }
            this.options[this.options.length] = new Option(value[1], value[1], false, this.dependentCustomFieldValue === value[1]);
            collectionValues[collectionValues.length] = value[1];
          }
        });
      }
      if (this.change) {
        let event = new Event('change');
        this.$dependentCustomField.dispatchEvent(event);
      }
    }
  }
  EASY.customFields.DependentCustomFieldList = DependentCustomFieldList;
}(jQuery));
