(function () {
  window.easyUtils = window.easyUtils || {};

  window.easyUtils.selectElementText = function(element) {
    if (document.selection) {
      var range = document.body.createTextRange();
      range.moveToElementText(element);
      range.select();
    } else if (window.getSelection) {
      var range = document.createRange();
      range.selectNode(element);
      window.getSelection().removeAllRanges();
      window.getSelection().addRange(range);
    }
  }

  window.easyUtils.clipboard = {
    copy: function(text, showFlash) {
      var element = document.createElement('DIV');
      element.textContent = text;
      document.body.appendChild(element);
      easyUtils.selectElementText(element);
      document.execCommand('copy');
      element.remove();

      if (showFlash) {
        showFlashMessage("notice", I18n.labelCopied, 500)
      }
    }
  };}
)();
