EasyGem.module.module("easy_ckeditor", [], function () {
  return function (fieldId, options, afterCallback) {
    var editor = CKEDITOR.instances[fieldId];
    if (editor) {
      editor.destroy();
    }
    var instance = CKEDITOR.replace(fieldId, options);
    if (afterCallback) {
      afterCallback(instance);
    }
  };
});
(function () {
  var orig_allowInteraction = $.ui.dialog.prototype._allowInteraction;
  $.ui.dialog.prototype._allowInteraction = function (event) {
    if ($(event.target).closest('.cke_dialog').length) return true;
    return orig_allowInteraction.apply(this, arguments);
  };
})();
