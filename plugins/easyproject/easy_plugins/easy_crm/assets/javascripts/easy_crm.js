//= require_self
//= require easy_contacts

EASY.crm.add_decimal_correction = function (name, unit, price_id) {
  let insertion_node = $('.easy_crm_case_items-association-insertion-node');

  let total = 0;
  let prices = $(".easy_crm_case_item_total");
  for (let i = 0; i < prices.length; i++) {
    total += +prices[i].value;
  }
  let correction = Math.round((total - total.toFixed()) * 100) / 100;
  if (correction < 0.5) correction *= -1;
  $('.add_fields').click();

  let price_per_unit = insertion_node.find('input.easy_crm_case_item_price_per_unit:last');
  insertion_node.find('input.easy_crm_case_item_amount:last').val('1.0');
  insertion_node.find('input.easy_crm_case_item_price_id:last').val(price_id);
  insertion_node.find('input.easy_crm_case_item_unit:last').val(unit);
  insertion_node.find('input.easy_crm_case_item_name:last').val(name);
  price_per_unit.val(correction);
  insertion_node.find('input.easy_crm_case_item_discount:last').val('0.0');

  EASY.crm.recalculateCrmCaseItemTotalPrice(price_per_unit);
};

EASY.crm.recalculateCrmCaseItemTotalPrice = function (target) {
  var item = $(target).closest('tr');
  var amount_value = item.find('input[id$=_amount]').val();
  var discount_value = item.find('input[id$=_discount]').val();
  var price_per_unit_value = item.find('input[id$=_price_per_unit]').val();
  var total_price = item.find('input[id$=_total_price]');
  var total_price_value = amount_value * price_per_unit_value * (1.0 - discount_value / 100.0);
  if (isNaN(total_price_value)) {
    total_price_value = 0;
  }
  total_price.val(total_price_value.toFixed(2));

  var $items_container = $(target).closest('tbody');
  var $tfoot_total = $(target).closest('table').find('tfoot td.total_sum span');
  var $items = $items_container.find('input[id$=_total_price]');
  var currency = $items_container.find('.easy_crm_case_item_currency').html();
  var sum = 0;
  $items.each(function() {
    sum += parseFloat($(this).val())
  });
  $tfoot_total.html(sum + ' ' + currency)
};

EASY.crm.toggleHiddableAttributes = function(el) {
  $('.attribute-hidden').toggle('highlight', 'slow');
  $(el).prev().toggleClass('open');
  $('.toggle-box').toggleClass('box');
  initEasyAutocomplete();
  ERUI.document.trigger( "erui_interface_change_vertical" );
};

EASY.schedule.late(function () {
  $('#easy_crm_case_currency').change(function () {
    $('.easy_crm_case_item_currency').html($(this).val());
  });
  $('.easy_crm_case_items-association-insertion-node').on('cocoon:before-insert', function (e, insertedItem) {
    insertedItem.find(".easy_crm_case_item_currency").html($('#easy_crm_case_currency').val());
  });
});

EASY.crm.repeatButton = function(e) {
    var tr = $(e).closest('tr');
    var class_name = $(e).attr('data-class');
    var selected = tr.find('.' + class_name).val();
    tr.nextAll('tr').find('.' + class_name).val(selected).trigger('change');
};
