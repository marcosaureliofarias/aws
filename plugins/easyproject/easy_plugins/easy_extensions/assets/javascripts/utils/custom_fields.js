EASY.customFields.submitCfLongTextInlineEdit = function(event, form, tagId) {
  event.preventDefault();
  var textArea = $('textarea#' + tagId);
  if (!(typeof CKEDITOR === "undefined")) {
    textArea.val(CKEDITOR.instances[tagId].getData());
  }
  $.ajax({
    url: form.action,
    "type": 'PUT',
    data: $(form).serialize(),
    dataType: 'json',
    tagId: tagId,
    complete: function (data) {
      if (!data.status.toString().startsWith("2")) {
        showFlashMessage("error", (data.responseJSON || {}).errors).prependTo("#ajax-modal");
      } else {
        window.easy_lock_version = data.getResponseHeader('X-Easy-Lock-Version');
        window.easy_last_journal_id = data.getResponseHeader('X-Easy-Last-Journal-Id');
        var valueField = $('span.edited[data-tag-id="' + this.tagId + '"]');
        valueField.html($('textarea#' + this.tagId).val());
        valueField.removeClass('edited');
        hideModal();
        valueField.effect("highlight");
      }
    }
  });
};
