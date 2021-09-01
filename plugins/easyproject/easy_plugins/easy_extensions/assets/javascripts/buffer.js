var key_count_global = null;

// more than 1000 usages in code, left in global scope
window.scrollTo = function(scroll_element, offset) {
  var topOffset = (($(scroll_element).offset() || {}).top || 0) + (offset || 0);
  $('html, body').animate({
    scrollTop: topOffset
  }, 500);
}

window.isIE = function() {
  return getInternetExplorerVersion() !== -1;
}

// From http://msdn.microsoft.com/en-us/library/ms537509%28v=vs.85%29.aspx
window.getInternetExplorerVersion = function () {
  // Returns the version of Internet Explorer or a -1
  // (indicating the use of another browser).
  var rv = -1; // Return value assumes failure.
  if (navigator.appName === 'Microsoft Internet Explorer') {
    var ua = navigator.userAgent;
    var re = new RegExp("MSIE ([0-9]{1,}[.0-9]{0,})");
    if (re.exec(ua) !== null)
      rv = parseFloat(RegExp.$1);
  } else if (!!navigator.userAgent.match(/Trident.*rv[ :]*11\./)) {
    rv = 11;
  }
  return rv;
}


// used from sidebar, left in global scope
window.showFlashMessage = function(type, message) {
  ERUI.content.find(".flash").remove();
  return $("<div/>").attr({"class": "flash"}).addClass(type).html($("<span/>").html(message)).append($("<a/>").attr({
    "href": "javascript:void(0)",
    "class": "icon-close"
  }).click(function (event) {
    $(this).closest('.flash').fadeOut(500, function () {
      $(this).remove();
    });
  })).prependTo($("#content"));
}

window.showFlashErrorsOnFailure = function (response, message) {
    const json = response && response.responseJSON;
    let errors = message;
    if (json.errors) {
        for (var i = 0; i < json.errors.length; i++) {
            errors += '<br/>' + json.errors[i];
        }
    }
    showFlashMessage('error', errors);
};

projectEditAjaxCall = function(url, data, successful, failed) {
  $.ajax({
    type: 'PUT',
    dataType: 'json',
    url: url,
    data: data
  }).done(function () {
    window.location.reload();
    showFlashMessage('notice', successful)
  }).fail(function (response) {
    showFlashErrorsOnFailure(response, failed);
  });
};
