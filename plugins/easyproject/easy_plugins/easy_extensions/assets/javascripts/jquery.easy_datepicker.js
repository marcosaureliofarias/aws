window.easyDatePicker = function (field_id, html5) {
  var element = $(field_id).addClass('date').attr('autocomplete','off');
  element.prop('type', (html5 ? 'date' : 'text'));
  var className = element.parent().hasClass('inline') ? "input-append inline" : "input-append";
  if (!element.parent().hasClass('input-append')) {
    element.add(element.siblings('label.inline, a, span, button, input, select')
        .not('label:first-child, input[type="radio"], input[type="checkbox"]'))
        .wrapAll("<span class='" + className + "'></span>");
  }
  if (html5) {
    element.datepickerFallback(EASY.datepickerOptions);
  } else {
    element.datepicker(EASY.datepickerOptions);
  }
};
