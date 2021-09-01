/* Redmine - project management software
   Copyright (C) 2006-2020  Jean-Philippe Lang */

function addFile(inputEl, file, eagerUpload) {
    var $inputEl = $(inputEl);
    var limit;
    if ($inputEl.attr('multiple') === 'multiple') {
      limit = (typeof(window.ATTACHMENT_LIMIT) === 'undefined' ? 10 : window.ATTACHMENT_LIMIT);
    } else {
      limit = 1;
    }

    var attachmentsContainer = $inputEl.closest('.attachments-container');
    var fields = attachmentsContainer.find('#attachments_fields');
    var addAttachment = attachmentsContainer.find('.add_attachment');
    var tagName = attachmentsContainer.attr("data-tag-name");

    if (fields.children('.attachment').length < limit) {

        var attachmentId = addFile.nextAttachmentId++;

        var fileSpan = $('<span>', {
            id: 'attachments_' + attachmentId
        });

        fileSpan.append($('<input>', {
            type: 'text',
            'class': 'filename readonly ' + ($inputEl.data('description-is') ? 'half' : 'full'),
            name: tagName + '[' + attachmentId + '][filename]',
            readonly: 'readonly'
        } ).val(file.name));
        if ($inputEl.data('description-is')) {
            fileSpan.append($('<input>', {
                type: 'text',
                'class': 'description',
                name: tagName + '[' + attachmentId + '][description]',
                maxlength: 255,
                placeholder: $inputEl.data('description-placeholder'),
                required: $inputEl.data('description-is-required')
            } ).toggle(!eagerUpload));
        };
        fileSpan.append($('<a>&nbsp</a>').attr({
            href: "#",
            'class': 'remove-upload icon icon-delete'
        }).click(removeFile).toggle(!eagerUpload));
        var customVersionAttID = $(inputEl).data("custom-version-for-attachment-id");
        if (customVersionAttID) {
            fileSpan.append($("<input>",{type: "hidden", value: customVersionAttID, name: tagName + '[' + attachmentId + '][custom_version_for_attachment_id]'}));
        }
        fileSpan.appendTo(fields);

        if(eagerUpload) {
            ajaxUpload(file, attachmentId, fileSpan, inputEl);
        }

        addAttachment.toggle(fields.children('.attachment').length < limit);

        return attachmentId;
    }
    return null;
}

addFile.nextAttachmentId = 1;

function ajaxUpload(file, attachmentId, fileSpan, inputEl) {

  function onLoadstart(e) {
    fileSpan.removeClass('ajax-waiting');
    fileSpan.addClass('ajax-loading');
    $('input:submit', $(this).parents('form')).attr('disabled', 'disabled');
  }

  function onProgress(e) {
    if(e.lengthComputable) {
      this.progressbar( 'value', e.loaded * 100 / e.total );
    }
  }

  function actualUpload(file, attachmentId, fileSpan, inputEl) {

    ajaxUpload.uploading++;

    uploadBlob(file, $(inputEl).data('upload-path'), attachmentId, {
        loadstartEventHandler: onLoadstart.bind(progressSpan),
        progressEventHandler: onProgress.bind(progressSpan)
      })
      .done(function(result) {
        addInlineAttachmentMarkup(file);
        progressSpan.progressbar( 'value', 100 ).remove();
        fileSpan.find('input.description, a').css('display', 'inline-block');
      })
      .fail(function(result) {
        progressSpan.text(result.statusText);
      }).always(function() {
        ajaxUpload.uploading--;
        fileSpan.removeClass('ajax-loading');
        var form = fileSpan.parents('form');
        if (form.queue('upload').length == 0 && ajaxUpload.uploading == 0) {
          $('input:submit', form).removeAttr('disabled');
        }
        form.dequeue('upload');
      });
  }

  var progressSpan = $('<div>').insertAfter(fileSpan.find('input.filename'));
  progressSpan.progressbar();
  fileSpan.addClass('ajax-waiting');

  var maxSyncUpload = $(inputEl).data('max-concurrent-uploads');

  if(maxSyncUpload == null || maxSyncUpload <= 0 || ajaxUpload.uploading < maxSyncUpload)
    actualUpload(file, attachmentId, fileSpan, inputEl);
  else
    $(inputEl).parents('form').queue('upload', actualUpload.bind(this, file, attachmentId, fileSpan, inputEl));
}

ajaxUpload.uploading = 0;

function removeFile() {
  var file = $(this);
  file.closest('.attachments-container').find('.add_attachment').show();
  file.parent('span').remove();
  return false;
}

function uploadBlob(blob, uploadUrl, attachmentId, options) {
  var attachmentsContainer = $('#attachments_' + attachmentId).closest('.attachments-container');
  var tagName = attachmentsContainer.attr('data-tag-name');
  var dummyFileSelector = 'input[name="attachments[dummy][file]"]'
  var customVersionAttachmentId = null;

  if ($('div.modal').is(':visible')) {
    customVersionAttachmentId = parseInt($('div.modal').find(dummyFileSelector).attr('data-custom-version-for-attachment-id'));
  } else if ($(dummyFileSelector).is(':visible')) {
    customVersionAttachmentId = parseInt($(dummyFileSelector).attr('data-custom-version-for-attachment-id'));
  }

  var actualOptions = $.extend({
    loadstartEventHandler: $.noop,
    progressEventHandler: $.noop
  }, options);

  uploadUrl = uploadUrl + '?attachment_id=' + attachmentId;
  if (blob instanceof window.File) {
    uploadUrl += '&filename=' + encodeURIComponent(blob.name);
    if (tagName) {
       uploadUrl += '&tag_name=' + tagName;
    }
    if (customVersionAttachmentId) {
      uploadUrl += '&custom_version_for_attachment_id=' + customVersionAttachmentId;
    }
  }

  return $.ajax(uploadUrl, {
    type: 'POST',
    contentType: 'application/octet-stream',
    beforeSend: function(jqXhr, settings) {
      jqXhr.setRequestHeader('Accept', 'application/js');
      // attach proper File object
      settings.data = blob;
    },
    xhr: function() {
      var xhr = $.ajaxSettings.xhr();
      xhr.upload.onloadstart = actualOptions.loadstartEventHandler;
      xhr.upload.onprogress = actualOptions.progressEventHandler;
      return xhr;
    },
    data: blob,
    cache: false,
    processData: false
  });
}

function addInputFiles(inputEl) {
    var $inputEl = $(inputEl);
    var clearedFileInput = $inputEl.clone().val('');
    var attachmentsContainer = $inputEl.closest(".attachments-container");

    if ($.ajaxSettings.xhr().upload && inputEl.files) {
        // upload files using ajax
        uploadAndAttachFiles(inputEl.files, inputEl);
        $inputEl.remove();
    } else {
        // browser not supporting the file API, upload on form submission
        var attachmentId;
        var aFilename = inputEl.value.split(/\/|\\/);
        attachmentId = addFile(inputEl, {
            name: aFilename[ aFilename.length - 1 ]
        }, false);
        if (attachmentId) {
            $inputEl.attr({
                name: 'attachments[' + attachmentId + '][file]',
                style: 'display:none;'
            }).appendTo('#attachments_' + attachmentId);
        }
    }

    const $addAttachmentContainer = attachmentsContainer.children(".add_attachment")

    $addAttachmentContainer.prepend(clearedFileInput);

    if (inputEl.dataset.onlyOneFile === "true") {
      // It will shown if user remove current attachment
      $addAttachmentContainer.hide()
    }
}

function uploadAndAttachFiles(files, inputEl) {

  var maxFileSize = $(inputEl).data('max-file-size');
  var maxFileSizeExceeded = $(inputEl).data('max-file-size-message');

  var sizeExceeded = false;
  $.each(files, function() {
    if (this.size && maxFileSize != null && this.size > parseInt(maxFileSize)) {sizeExceeded=true;}
  });
  if (sizeExceeded) {
    window.alert(maxFileSizeExceeded);
  } else {
    $.each(files, function() {addFile(inputEl, this, true);});
  }
  return sizeExceeded;
}

function handleFileDropEvent(e) {
  var dataTransfer;
  if (typeof(dataTransfer = e.originalEvent.dataTransfer) === 'undefined') return;
  var self = $(this);
  self.removeClass('fileover');
  blockEventPropagation(e);

  var selector = self.find('input:file.filedrop.file_selector');
  if(selector.length === 0) {
    selector = self.closest('.attachments-container').find('input:file.filedrop.file_selector');
  }
  if ($.inArray('Files', dataTransfer.types) > -1) {
      uploadAndAttachFiles(dataTransfer.files, selector);
  }
}
handleFileDropEvent.target = '';

function dragOverHandler(e) {
  $(this).addClass('fileover');
  blockEventPropagation(e);
  e.dataTransfer.dropEffect = 'copy';
}

function dragOutHandler(e) {
  $(this).removeClass('fileover');
  blockEventPropagation(e);
}

function setupFileDrop() {
    if (window.File && window.FileList && window.ProgressEvent && window.FormData && window.FileReader) {

        $.event.addProp('dataTransfer');

        $('form').has('input:file.filedrop').each(function () {
            var self = $(this);
            if (!self.data().fileDropsInitialized) {
                self.on({
                    dragover: dragOverHandler,
                    dragleave: dragOutHandler,
                    drop: handleFileDropEvent
                });
                self.data().fileDropsInitialized = true;
            }
        });
    }
}

function addInlineAttachmentMarkup(file) {
  // insert uploaded image inline if dropped area is currently focused textarea
  if($(handleFileDropEvent.target).hasClass('wiki-edit') && $.inArray(file.type, window.wikiImageMimeTypes) > -1) {
    var $textarea = $(handleFileDropEvent.target);
    var cursorPosition = $textarea.prop('selectionStart');
    var description = $textarea.val();
    var sanitizedFilename = file.name.replace(/[\/\?\%\*\:\|\"\'<>\n\r]+/, '_');
    var inlineFilename = encodeURIComponent(sanitizedFilename)
      .replace(/[!()]/g, function(match) { return "%" + match.charCodeAt(0).toString(16) });
    var newLineBefore = true;
    var newLineAfter = true;
    if(cursorPosition === 0 || description.substr(cursorPosition-1,1).match(/\r|\n/)) {
      newLineBefore = false;
    }
    if(description.substr(cursorPosition,1).match(/\r|\n/)) {
      newLineAfter = false;
    }

    $textarea.val(
      description.substring(0, cursorPosition)
      + (newLineBefore ? '\n' : '')
      + inlineFilename
      + (newLineAfter ? '\n' : '')
      + description.substring(cursorPosition, description.length)
    );

    $textarea.prop({
      'selectionStart': cursorPosition + newLineBefore,
      'selectionEnd': cursorPosition + inlineFilename.length + newLineBefore
    });
    $textarea.parents('.jstBlock')
      .find('.jstb_img').click();

    // move cursor into next line
    cursorPosition = $textarea.prop('selectionStart');
    $textarea.prop({
      'selectionStart': cursorPosition + 1,
      'selectionEnd': cursorPosition + 1
    });

  }
}

function copyImageFromClipboard(e) {
  if (!$(e.target).hasClass('wiki-edit')) { return; }
  var clipboardData = e.clipboardData || e.originalEvent.clipboardData
  if (!clipboardData) { return; }
  if (clipboardData.types.some(function(t){ return /^text/.test(t); })) { return; }

  var items = clipboardData.items
  for (var i = 0 ; i < items.length ; i++) {
    var item = items[i];
    if (item.type.indexOf("image") != -1) {
      var blob = item.getAsFile();
      var date = new Date();
      var filename = 'clipboard-'
        + date.getFullYear()
        + ('0'+(date.getMonth()+1)).slice(-2)
        + ('0'+date.getDate()).slice(-2)
        + ('0'+date.getHours()).slice(-2)
        + ('0'+date.getMinutes()).slice(-2)
        + '-' + randomKey(5).toLocaleLowerCase()
        + '.' + blob.name.split('.').pop();
      var file = new Blob([blob], {type: blob.type});
      file.name = filename;
      var inputEl = $('input:file.filedrop').first()
      handleFileDropEvent.target = e.target;
      addFile(inputEl, file, true);
    }
  }
}

//$(document).ready(setupFileDrop);
//$(document).ready(function(){
//  $("input.deleted_attachment").change(function(){
//    $(this).parents('.existing-attachment').toggleClass('deleted', $(this).is(":checked"));
//  }).change();
//});

function unbindSetupFileDrop() {
    $('form div.box').each(function() {
        $(this).off('dragover').off('dragleave').off('drop');
    });
}

EASY.schedule.late(function() {
    unbindSetupFileDrop();
    setupFileDrop();
});
