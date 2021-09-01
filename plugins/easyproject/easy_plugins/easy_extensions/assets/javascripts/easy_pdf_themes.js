$(function() {
	var headerColor = $('#header_color');
	var headerFontColor = $('#header_font_color');
	var preview = $('#header_style_preview');

	function isColor(string) {
		return !!string.match(/#(\d|[a-f]){6}/i);
	}

	$('#header_colorpicker').farbtastic(function(color) {
		headerColor.val(color);
		preview.css('background-color', color);
	});
	var headerColorPicker = $.farbtastic('#header_colorpicker');
	$('#header_font_colorpicker').farbtastic(function(color) {
		headerFontColor.val(color);
		preview.css('color', color);
	});
	var headerFontColorPicker = $.farbtastic("#header_font_colorpicker");

	if (isColor(headerColor.val())) {
		headerColorPicker.setColor(headerColor.val());
	}
	if (isColor(headerFontColor.val())) {
		headerFontColorPicker.setColor(headerFontColor.val());
	}
});
