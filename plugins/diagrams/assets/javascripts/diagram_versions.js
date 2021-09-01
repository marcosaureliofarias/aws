EASY.schedule.require(function () {
  var diagramVersionsSelectBox = $('[name="diagram-version"]');

  diagramVersionsSelectBox.on('change', function() {
    var parentId = $(this).attr('parent-id');
    var selectedValue = $(this).find(":selected").val();

    if (selectedValue === '') {
      return;
    }

    var path = '/diagrams/' + parentId +
               '/toggle_position?position=' + selectedValue +
               '&back_url=' + window.location.href;

    window.location.replace(path);
  });
}, 'jQuery');