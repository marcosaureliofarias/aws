EASY.schedule.require(function ($) {
  "use strict";

  let assignableEntities = {};
  const entities = ['issue', 'easy_contact', 'easy_crm_case', 'easy_calculation_project_client', 'project'];
  EASY.contacts = EASY.contacts || {};

  EASY.contacts.registerAssignableEntity = function (name, params) {
    assignableEntities[name] = params;
  };

  EASY.contacts.getEntityDataFromDropperTarget = function (dropAction) {
    return $('div.easy-dropper-target[data-drop-action="' + dropAction + '"]').data();
  };

  EASY.contacts.isRegisteredAndCurrent = function (dropAction) {
    return assignableEntities[dropAction] && EASY.contacts.getEntityDataFromDropperTarget(dropAction);
  };

  EASY.contacts.getCurrentEntity = function () {
    let currentEntity = null;
    for (const [index, entity] of entities.entries()) {
      if (EASY.contacts.isRegisteredAndCurrent(entity)) {
        currentEntity = assignableEntities[entity];
        break;
      }
    };
    return currentEntity;
  };

  EASY.contacts.initEasyContactsAssignable = function (options) {
    const toolbarTranslations = EASY.contacts.easyContactToolbarLocalize();
    let params = EASY.contacts.getCurrentEntity();
    if (!params) {
      return;
    }
    const entityData = EASY.contacts.getEntityDataFromDropperTarget(params.dropAction);
    const assignToEntity = (event) => {
      if (params.url) {
        let ajaxParams,
            contactData = $(event.target).closest('li').data(),
            data = params.getAttributes(entityData, contactData);
        ajaxParams = {
          url: params.url,
          data: data,
          type: 'POST',
          complete: (data) => {
            try {
              $.each($.parseJSON(data.responseText), (key, val) => {
                if (val) {
                  let flashContainer = $("<div/>").attr({"class": "flash " + key}).html($("<span/>").text(val));
                  flashContainer.append($("<a/>").attr({
                    "class": "icon-close",
                    "href": "javascript:$(this).closest('.flash').fadeOut(500, function(){$(this).remove()})"
                  }))
                  if ($("#content .flash")[0]) {
                    $("#content .flash").replaceWith(flashContainer);
                  } else {
                    $("#content").prepend(flashContainer);
                  }
                }
              });
            } catch (error) {
              console.error('contacts toolbar:', error.message);
            }
          }
        }
        if (params.ajaxParams) {
          $.extend(ajaxParams, params.ajaxParams);
        }
        $.ajax(ajaxParams);

      } else if (params.callback && typeof params.callback === 'function') {
        params.callback(entityData, contactData);
      } else {
        alert(toolbarTranslations.wrongParams);
      }
    }

    $('#easy_contacts_toolbar_list li.assignable-list-item').each((index, contact) => {
      let contactData = $(contact).data();
      let $container = $('<div class="push-right"><div/>');
      let $link = $('<a></a>', { class: (params.cssIcon || 'icon-relation') + ' assign-contact-link', title: params.assignToTitle });
      $container.append($link);
      $(contact).append($container);
      $($link).click(assignToEntity);
    });
  };
  $.fn.easy_contacts_toolbar = function (options) {
    var defaults = {
          moreToDoLists: false
        },
        opts = $.extend(true, {}, defaults, options);
    var overrides = {
      afterOpen: function () {
        _self.find('input').focus();
      }
    };
    overrides = $.extend(true, {}, overrides, opts);
    var _self = $(this).easySlidingPanel(overrides);
    var expander_panel = _self.find(".expander-panel > .expander-panel-content");
  }
}, 'jQuery');
