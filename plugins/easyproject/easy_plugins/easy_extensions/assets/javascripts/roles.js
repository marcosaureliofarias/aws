function validateDependencies(event) {
    var thisCheckbox = event.target;
    var dependencies = collectDependencies([], thisCheckbox, thisCheckbox.checked);
    if (dependencies.length === 0)
        return true;

    var enables = [];
    var disables = [];

    dependencies.map(function (dependency) {
        if (dependency.value)
            enables.push(dependency.title);
        else
            disables.push(dependency.title);
    })

    var dialogText = '';
    var dialogState = '';

    if(enables.length > 0){
        dialogText = dialogText + '<ul style="margin-bottom: 0; margin-top: 0"><li>' + enables.join("</li><li>") + '</li></ul>';
        dialogState = EASY.RolesI18n.dependencyEnable.replace('%{name}', '').toLowerCase();
    }

    if(disables.length > 0){
        dialogText = dialogText + '<ul style="margin-bottom: 0; margin-top: 0"><li>' + disables.join("</li><li>") + '</li></ul>';
        dialogState = EASY.RolesI18n.dependencyDisable.replace('%{name}', '').toLowerCase()
    }

    $('#ajax-modal').html(dialogText);
    showModal('ajax-modal', '600px', EASY.RolesI18n.textUnsatisfied.replace('%{state}', dialogState));
    $('#ajax-modal').dialog({
        buttons: [
            {
                text: EASY.RolesI18n.buttonApply,
                title: EASY.RolesI18n.buttonApply,
                class: 'button-positive',
                click: function () {
                    dependencies.forEach(function (dependency) {
                        document.getElementById(dependency.id).checked = dependency.value;
                    });
                    $(this).dialog('close');
                }
            },
            {
                text: EASY.RolesI18n.buttonCancel,
                title: EASY.RolesI18n.buttonCancel,
                class: 'button-negative',
                click: function () {
                    thisCheckbox.checked = !thisCheckbox.checked;
                    $(this).dialog('close');
                }
            }
        ]
    });
}

function collectDependencies(dependencies, thisCheckbox, supposedState, alreadyVerified = []) {
    if (alreadyVerified.indexOf(thisCheckbox.id) !== -1)
        return;
    alreadyVerified.push(thisCheckbox.id);

    if (supposedState) {
        var dependsOn = $(thisCheckbox).data('depends-on');
        dependsOn && $(dependsOn).each(function (_, requirementName) {
            var requirementCheckbox = document.getElementById('role_permissions_' + requirementName);
            if (!requirementCheckbox.checked) {
                if (!dependencies.find(function (dependency) {
                    return dependency.name === requirementName;
                })) {
                    dependencies.push({
                        name: requirementName,
                        value: true,
                        id: requirementCheckbox.id,
                        title: "<span class='tooltip-parent' style='display: block; cursor: pointer;'>" + $(requirementCheckbox).closest('label').children('span:not(".permission-tooltip, .permission-flags")').text().trim() +
                            "<span class='tooltip' style='white-space: normal; width: 70%; left: 30%;'>" + $(requirementCheckbox).closest('label').children('.permission-tooltip').text().trim() + "</span></span>"
                    });
                }
                collectDependencies(dependencies, requirementCheckbox, true, alreadyVerified);
            }
        });
    } else {
        $('input[name="role[permissions][]"]').each(function (_, dependencyCheckbox) {
            var $dependencyCheckbox = $(dependencyCheckbox);
            if (dependencyCheckbox.checked && $dependencyCheckbox.data('depends-on') &&
                    $dependencyCheckbox.data('depends-on').indexOf(thisCheckbox.value) !== -1) {
                if (!dependencies.find(function (dependency) {
                    return dependency.name === dependencyCheckbox.value;
                })) {
                    dependencies.push({
                        name: dependencyCheckbox.value,
                        value: false,
                        id: dependencyCheckbox.id,
                        title: "<span class='tooltip-parent' style='display: block; cursor: pointer;'>" + $(dependencyCheckbox).closest('label').children('span:not(".permission-tooltip, .permission-flags")').text().trim() +
                            "<span class='tooltip' style='white-space: normal; width: 70%; left: 30%;'>" + $(dependencyCheckbox).closest('label').children('.permission-tooltip').text().trim() + "</span></span>"
                    });
                }
                collectDependencies(dependencies, dependencyCheckbox, false, alreadyVerified);
            }
        });
    }

    return dependencies;
}

EASY.schedule.late(function () {
    $('input[name="role[permissions][]"]').change(validateDependencies);

    $('.permission-tooltip').each(function (_, permissionTooltip) {
        var $permissionTooltip = $(permissionTooltip);
        new easyClasses.EasyTooltip($permissionTooltip.find('.tooltip').html(), $permissionTooltip, 0, 0);
    });
}, -5);