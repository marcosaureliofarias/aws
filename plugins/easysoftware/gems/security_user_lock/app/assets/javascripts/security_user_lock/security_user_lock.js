EASY.security_user_lock = EASY.security_user_lock || {};

EASY.security_user_lock.init_settings = function() {
    $('#easy_setting_notify_all_admins').change(function () {
        var admins = $('#easy_setting_lock_admins_to_notify');
        if ($(this).is(':checked')) {
            admins.val('').prop('disabled', true);
        } else {
            admins.removeAttr('disabled');
        }
    }).trigger('change');

    $('#easy_setting_enable_lock_user').change(function () {
        var settings = $('#lock_user');
        var attempts = $('#easy_setting_user_login_attempts');
        if ($(this).is(':checked')) {
            settings.show();
        } else {
            attempts.val('0');
            settings.hide();
        }
    }).trigger('change');

    $('#easy_setting_user_login_attempts').change(function () {
        var settings = $('#lock_user_settings');
        var val = $(this).val();
        if (val === '0' || val === '') {
            settings.hide();
        } else {
            settings.show();
        }
    }).trigger('change');
};
