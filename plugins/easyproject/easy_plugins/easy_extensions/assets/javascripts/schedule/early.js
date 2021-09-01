EASY.schedule.late(function () {
  $("#custom_settings_button").click(function () {
    $("#egtes_wrap_inner").toggle();
  });

  $("#egtes_select").change(function () {
    $.ajax({
      url: $("#egtes_wrap").attr('data-ajax-url'),
      type: 'get',
      data: $('#egtes_select').serialize(),
      complete: toggleDisabledInit
    });
  });

  ERUI.document.on('click', '.objects-selection li', function (event) {
    var target = $(event.target);
    if (target.is('label')) {
      event.preventDefault();
    }
    var li = target.closest("li");
    var chck = li.find("input:checkbox");
    li.toggleClass('checked');
    if (event.target !== chck[0] && !chck.is(":disabled")) {
      chck.prop("checked", !chck.is(":checked"));
    }
  });
});
