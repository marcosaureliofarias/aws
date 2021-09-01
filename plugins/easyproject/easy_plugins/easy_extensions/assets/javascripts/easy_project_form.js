$('#project_enabled_module_names_issue_tracking').on('change', function () {
    $('#project_tracker_ids, #project_issue_custom_field_ids').toggle($(this).prop('checked'));
}).trigger('change');

$("#project_enabled_module_names .toolbar > a").on('click', function () {
    $('#project_enabled_module_names_issue_tracking').trigger('change');
});

$('#project_parent_id').on('change', function () {
    $(this).closest('form').find('.inheritance-option').toggle(this.value !== '');
}).trigger('change');

EASY.shortcut.add('Alt+Shift+S', function () {
    if ($('#tab-content-info') && $('#tab-content-info').is(':visible')) {
        $('#save-project-info').click();
    } else if ($('#tab-content-activities') && $('#tab-content-activities').is(':visible')) {
        $('#save-project-activities').click();
    } else if ($('#tab-content-modules') && $('#tab-content-modules').is(':visible')) {
        $('#save-project-modules').click();
    }
});

$('#project_is_planned').on('change', function () {
    $('#send_all_planned_emails_container').toggle(!$(this).prop('checked'));
});

$("input[id^='project_custom_field_ids_']").on('change', function () {
    $.ajax({
        url: $(this).attr('toggle-url'),
        type: 'post',
        data: $("#project-form").serialize()
    }).done(function (data) {
        $("#form-project-custom-fields").html(data);
    });
});

$("#project_custom_field_ids .toolbar > a").on('click', function () {
    $.ajax({
        url: $(this).closest('.toolbar').attr('toggle-url'),
        type: 'post',
        data: $("#project-form").serialize()
    }).done(function (data) {
        $("#form-project-custom-fields").html(data);
    });
});

