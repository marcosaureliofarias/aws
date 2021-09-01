
EASY.resources.updateAvailability = function(date, hour, uuid, available, desc_msg) {
    $('#date-' + uuid).val(date);
    $('#hour-' + uuid).val(hour ? hour : '');
    $('#available-' + uuid).val(available ? '1' : '');
    var uf = $('#resource-availibility-update-form-' + uuid);
    var cancelAjax = false;
    if (!available) {
        var promptResult = prompt(desc_msg);
        cancelAjax = promptResult === null;
        $('#description-' + uuid).val(promptResult);
    }
    if (!cancelAjax) {
        $.post(uf.attr('action'), uf.serialize(), function() {
            $('#module_inside_' + uuid).load('/my/update_my_page_module_view', $('#resource-availability-form-' + uuid).serialize());
        });
    }
};
