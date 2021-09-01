EasyGem.module.module("easyPageModules/others/activityFeed", [], function () {
  return function submitForm (url, data) {
    data = JSON.parse(data);
    var module_id = data['module_id'];
    if(data['load_more']) {
      data['current_limit'] = $('#' + module_id + '_button_load_more').attr('data-current-limit');
      data['event_type_id'] = $('#epm_activity_feed_form_for_' + module_id + ' .easy-activity-selected').attr('data-activity-id');
    }
    $.ajax({
      url: url,
      data: data
    })
  };
});
