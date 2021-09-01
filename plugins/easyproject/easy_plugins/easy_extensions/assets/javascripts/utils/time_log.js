EASY.timeLog.showPeriodDaysField = function (period_selectbox_selector, triggerChange) {
    var triggerChange = typeof triggerChange !== 'undefined' ? triggerChange : false;

    $(document).on('change', period_selectbox_selector, function() {
        var option = $(this).find('option:selected');
        var descriptionHtml = '<em>' + option.data('description') + '</em>';
        var period_days_container = $(period_selectbox_selector + '_days_container');
        var period_days_description_container = $(period_selectbox_selector + '_days_description_container');
        var double_period_days_container = $(period_selectbox_selector + '_days_container_double');
        var double_period_days_description_container = $(period_selectbox_selector + '_days_description_container_double');

        if (option.val() === 'from_m_to_n_days') {
            double_period_days_container.show();
            period_days_container.hide();
            double_period_days_description_container.html(descriptionHtml);
        } else if (option.val().indexOf('n_days') !== -1) {
            period_days_container.show();
            double_period_days_container.hide();
            period_days_description_container.html(descriptionHtml);
        } else {
            period_days_container.hide();
            double_period_days_container.hide();
        }
    });

    if (triggerChange) {
        $(period_selectbox_selector).change();
    }
};
