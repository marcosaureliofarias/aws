window.fillFormTextAreaFromCKEditor = function(id) {
  if (typeof CKEDITOR !== 'undefined') {
    var text = CKEDITOR.instances[id];
    if (text !== undefined) {
      $('textarea#' + id).val(text.getData());
    }
  }
};

window.fillCustomFieldsFormTextAreasFromCKEditor = function(target) {
  if (window.fillFormTextAreaFromCKEditor) {
    $(target).find("textarea").each(function () {
      if (/^time_entry_custom_field_values/.test(this.id)) {
        window.fillFormTextAreaFromCKEditor(this.id);
      }
    });
  }
};
