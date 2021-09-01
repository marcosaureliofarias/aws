(function ($) {
  var proto = $.ui.autocomplete.prototype;
  $.extend( proto, {
    _renderItem: function(ul, item) {
      var $div = $('<div><div/>').text(item.label);
      if (item.attendance_status) {
        $div.append($('<span></span>').append($('<small></small>', {class: item.attendance_status_css}).text(item.attendance_status)));
      }
      return $('<li>')
                    .data('item.autocomplete', item)
                    .append($div)
                    .appendTo(ul);
    }
  });
}(jQuery));
