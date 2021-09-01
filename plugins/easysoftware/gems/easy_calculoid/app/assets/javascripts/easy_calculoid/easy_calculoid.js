//= require_self

EASY.schedule.late(() => {
  function clearFields(module) {
    module.find('.calculator-name').empty();;
    module.find('.calculator-fields').empty();;
  };

  function renderField(field, fieldsTarget, trend, savedValues, i18n, trendValues, block) {
    var name = $('<p class="calculoid-field-' + field['id'] + '"><label>'+ field['name'] +'</label></p>');
    var savedValue = savedValues['F' + field['id']] || '';
    var fieldName = '[F' + field['id'] + ']';
    var defaultValue = $(' \
        <input type="text" title="' + i18n.default_value + '" placeholder="' + i18n.default_value + '" value="'+ savedValue +
        '" name="' + block + '[data]' + fieldName + '"> \
        </input>');
    var trendSelect = trend.clone().attr('name', block + '[trends]' + fieldName).removeClass('calculator-trend').val(trendValues['F' + field['id']]).show();
    name.appendTo(fieldsTarget);
    defaultValue.appendTo(name);
    trendSelect.appendTo(name);
  }

  EASY.reloadCalculoid = function(element) {
    var module = $(element).closest('.easy-page-module');
    if (module.length === 0) {
      console.log('calculoid: module not found');
      return;
    };

    var calculoidSettings = module.find('.calculoid-settings');
    var dataSettings = calculoidSettings.data().settings;
    var dataTrends = calculoidSettings.data().trends;
    var dataI18n = calculoidSettings.data().i18n;
    var dataBlock = calculoidSettings.data().block;
    if (!dataSettings || !dataI18n || !dataBlock) {
      console.log('calculoid: data not found');
      return clearFields(module);
    };

    var calculatorId = module.find('.calculoid-id').val();
    var calculatorUrl = module.find('.calculoid-url').val();
    if (!calculatorId || calculatorId === '' || !calculatorUrl || calculatorUrl === '') {
      //console.log('calculoid: url or id not defined');
      return clearFields(module);
    };

    var apiKey = module.find('.calculoid-api-key').val();
    $.ajax({url: calculatorUrl + "/calculator/" + calculatorId + '&apiKey=' + apiKey, type: 'get', dataType: 'json'}).done(function (response) {
      var nameTarget = module.find('.calculator-name');
      var fieldsTarget = module.find('.calculator-fields');
      var trend = module.find('.calculator-trend');
      clearFields(module);

      if (!response['fields']) {
        console.log('calculoid: bad data');
        console.log(response);
        return;
      };
      var fields = Object.values(response['fields']);
      var editableFields = fields.filter(function (v) {
        return v['type'] !== 'formula';
      });

      var calcName = response['name'];
      nameTarget.html($('<p>'+ calcName +'</p>'));

      for (var i = 0; i < editableFields.length; i++) {
        renderField(editableFields[i], fieldsTarget, trend, dataSettings, dataI18n, dataTrends, dataBlock);
      };

      return;
    }).fail(function () {
      console.log('calculoid: bad response');
      clearFields(module);
    });
  };

  $(".calculoid-settings").each(function() {
    EASY.reloadCalculoid(this);
  });
});