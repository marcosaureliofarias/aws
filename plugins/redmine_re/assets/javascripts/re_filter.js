EASY.schedule.late(function () {
    // hidden on init because of UJS
    $('#sidebar_filter_input_nojs').remove();
    $('#sidebar_filter .inputs').show();

    $('#sidebar_filter_input').suggestible({
        ajax: {
            suggestions: {
                url: window.re_options.suggest_path,
                dataType: 'json',
                data: function (value, helpers) {
                    return {query: value};
                },
                loading: function (helpers) {
                    $('#ajax-indicator').show();
                    helpers.elements.textBox.attr('disabled', 'disabled');
                },
                loaded: function (helpers) {
                    $('#ajax-indicator').hide();
                    helpers.elements.textBox.removeAttr('disabled');
                }
            }
        },
        layout: {
            containers: function (selectBox, options) {
                return new SuggestBoxContainers(selectBox, options);
            },
            items: function (helpers) {
                return new DirectArtifactsSuggestBoxItems(helpers);
            }
        }
    });

    var elements = $('#sidebar_filter_input_container').data('elements');
    elements.textBox.attr('name', elements.inputName);
});