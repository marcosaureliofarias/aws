window.easyTemplates = window.easyTemplates || {};

window.easyTemplates.column = "{{#cols}}<div class='easy-col col{{order}} {{bonusClasses}}'></div>{{/cols}}";
window.easyTemplates.row = "{{#rows}}<div class='easy-row row{{order}} {{bonusClasses}}'></div>{{/rows}}";

window.easyTemplates.kanbanRoot = "" +
  "<div class='agile__group-select'>" +
    "<div class='agile__swimline-select'></div>" +
    "<div class='agile__sprint-select'></div>" +
  "</div>"  +
"<div class='agile__top-container'></div>" +
  "<div class='agile'>" +
    "<div class='agile__row easy-row epic__row'></div>" +
  "</div>";
window.easyTemplates.kanbanSwimLane = "" +
    "<div class='agile__col agile__swimline'>" +
      "{{#name}}" +
        "<div name='{{anchorName}}' class='agile__col__title'>" +
          "<span class='icon easy-icon-select agile__col__title-icon icon-remove'></span>" +
          "{{name}}" +
        "</div>" +
      "{{/name}}" +
      "<hr>" +
      "<div class='agile__row'>" +
        "{{#cols}}" +
          "<div class='agile__col sprint-col col{{.}}'>" +
          "</div>" +
        "{{/cols}}" +
      "</div>" +
    "</div>";

window.easyTemplates.kanbanUserBar = "\
    <div class='agile__user-bar'>\
      {{#users}}\
      <div class='agile_user-{{id}}'></div>\
      {{/users}}\
    </div>";

window.easyTemplates.kanbanUser = "\
      <div class='agile_user_{{id}}_container agile__avatar-container' data-id='{{id}}'>\
        {{{avatarHtml}}}\
        <span class='agile__user-name'>{{name}}</span>\
      </div>";

window.easyTemplates.kanbanStickyLane ="\
    <div class='agile__sticky-selector'>\
      <div class='easy-autocomplete-tag agile__sticky-autocomplete'>\
        <input id='{{stickySelectName}}' style='display: none' value='{{item.id}}'>\
        <input id='{{stickySelectName}}_autocomplete' value='{{item.label}}'>\
      </div>\
      <button data-select='{{stickySelectName}}' class='button button-positive agile__sticky_button_go-to_{{stickySelectName}}'>{{goTo}}</button>\
    </div>\
    <div class='agile__row agile__sticky-cols'>\
      {{#cols}}\
        <div class='agile__col sprint-col col{{.}}'></div>\
      {{/cols}}\
    </div>";



window.easyTemplates.kanbanSwimLaneCol = "{{#first}}<div class='agile__col__title'></div>{{/first}}<div class='agile__col__contents'></div>";

window.easyTemplates.kanbanList = "{{#showName}}<div class='agile__col__title'></div><div class='agile__col__contents'>{{/showName}}<div class='{{bonusClasses}} agile__list' data-column-name='{{columnName}}'>" +
    "{{#items}}" +
    '<div class="agile__item item_{{id}}"></div>' +
    "{{/items}}" +
    "</div>{{#showName}}</div>{{/showName}}";

window.easyTemplates.kanbanGroupSelect = "\
  <label class='agile__swimline-select-label'>{{swimlane}}:</label>\
  <select class='groupselect'>\
    {{#options}}\
      <option value='{{value}}'{{#selected}} selected{{/selected}}>{{name}}</option>\
    {{/options}}\
  </select>";

window.easyTemplates.kanbanSprintSelect ="\
  <label class='agile__sprint-select-label'>{{sprint}}:</label>\
  <div class='easy-autocomplete-tag'>\
    <input id='sprint_autocomplete_{{moduleId}}' placeholder='{{label}}' type='hidden' />\
    <input id='sprint_autocomplete_{{moduleId}}_autocomplete' type='text' value='{{label}}' />\
  </div> ";

window.easyTemplates.kanbanColumnName = "";
window.easyTemplates.kanbanNoAssigneeAvatar = "";
window.easyTemplates.easyToolTip = "<div class='easy-tooltip'></div>";
window.easyTemplates.issueCardWidget = "";
