//= require easy_knowledge_toolbar
//= require_self

EASY.knowledge.toggleTreeVisibility = function (uniq_prefix, entity_name, entity_id, user_id, update_user_pref, expander_parent) {
  var uniq_id = uniq_prefix + entity_name + '-' + entity_id;
  var ul = $('#' + uniq_id);
  expander_parent = $(expander_parent);
  var isOpen = expander_parent.hasClass('open');
  if (update_user_pref) {
    EASY.utils.updateUserPref(uniq_id, user_id, isOpen);
  }
  if (isOpen) {
    ul.hide();
    expander_parent.removeClass('open');
  } else {
    ul.show();
    expander_parent.addClass('open');
  }
  $(document).trigger("erui_interface_change_vertical");
};
