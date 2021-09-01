// used in plugin repositories. Do not touch until refactor with plugins.


window.easyModel = window.easyModel || {};
window.easyModel.print = window.easyModel.print || {};

// Additional tokens for sending to the server
window.easyModel.print.tokens = window.easyModel.print.tokens || {};

// Functions which are called before request to print
// For example you can prepare some element and save it to `tokens`
window.easyModel.print.functions = window.easyModel.print.functions || [];

// Elements usually have different width - print need the widest
window.easyModel.print.setWidth = function(width){
  if (!window.easyModel.print.width || width > window.easyModel.print.width) {
    window.easyModel.print.width = width
  }
};

// Prepare elements and redirect to printable template preview
window.easyModel.print.preview = function(link){

  // Trigger all functions for preparation
  for (var i = 0; i < window.easyModel.print.functions.length; i++) {
    window.easyModel.print.functions[i]();
  }

  var form = document.createElement("form");
  form.action = link.href;
  form.method = "POST";

  var token = document.createElement("input");
  token.type = "hidden";
  token.name = $("meta[name='csrf-param']").attr("content");
  token.value = $("meta[name='csrf-token']").attr("content");
  form.appendChild(token);

  if (window.easyModel.print.width) {
    var pageWidth = document.createElement("input");
    pageWidth.type = "hidden";
    pageWidth.name = "pages_width";
    pageWidth.value = window.easyModel.print.width;
    form.appendChild(pageWidth);
  }

  // Add prepared tokens to params
  $.each(window.easyModel.print.tokens, function(key, value) {
    var textarea = document.createElement("textarea");
    textarea.style.display = "none";
    textarea.name = "additional_tokens["+key+"]";
    textarea.innerHTML = value;
    form.appendChild(textarea);
  });

  document.body.appendChild(form);
  form.submit();

  return false;
};
