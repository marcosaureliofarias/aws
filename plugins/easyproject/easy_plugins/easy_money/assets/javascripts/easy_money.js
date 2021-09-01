//= require_self

function computePriceWithVat(price1Id, price2Id, vatId) {
    var price1 = document.getElementById(price1Id);
    var price2 = document.getElementById(price2Id);
    var vat = document.getElementById(vatId);
    var use_vat = document.getElementById('use_vat').checked;
    if (price2 != null && vat != null && price2.value != '' && !isNaN(price2.value) && !isNaN(vat.value)) {
        price1.value = Math.round(parseFloat(price2.value) * (100 + parseFloat(vat.value == '' || !use_vat ? 0 : vat.value))) / 100;
    }
}

function computePriceWithoutVat(price1Id, price2Id, vatId) {
    var price1 = document.getElementById(price1Id);
    var price2 = document.getElementById(price2Id);
    var vat = document.getElementById(vatId);
    var use_vat = document.getElementById('use_vat').checked;
    if (price1 != null && vat != null && price1.value != '' && !isNaN(price1.value) && !isNaN(vat.value)) {
        price2.value = Math.round((parseFloat(price1.value) * 100 / (100 + parseFloat(vat.value == '' || !use_vat ? 0 : vat.value))) * 100) / 100;
    }
}

function toggleMoneySelection(el) {
    var boxes = el.getElementsBySelector('input[type=checkbox]');
    var all_checked = true;
    for (i = 0; i < boxes.length; i++) {
        if (boxes[i].checked == false) {
            all_checked = false;
        }
    }
for (i = 0; i < boxes.length; i++) {
    if (all_checked) {
        boxes[i].checked = false;
        boxes[i].up('tr').removeClassName('context-menu-selection');
    } else if (boxes[i].checked == false) {
        boxes[i].checked = true;
        boxes[i].up('tr').addClassName('context-menu-selection');
    }
}
}

function computeMul(firstId, secondId, price1Id) {
    var first = document.getElementById(firstId);
    var second = document.getElementById(secondId);
    var price1 = document.getElementById(price1Id);
    if (price1 != null && first != null && second != null && first.value != '' && !isNaN(first.value) && second.value != '' && !isNaN(second.value)) {
        price1.value = Number((parseFloat(first.value) * parseFloat(second.value)).toFixed(2));
    }
}

function computeDateDiff(date1Id, date2Id, diffId) {
  var diffEl = $('#' + diffId);
  var date1 = $('#' + date1Id);
  var date2 = $('#' + date2Id);
  var date1val = date1.val();
  var date2val = date2.val();

  if (date1 !== null && date2 !== null && date1val !== '' && date1val !== undefined && date2val !== '' && date2val !== undefined) {
    if (date1val <= date2val) {
      diffEl.prop('value', (((new Date(date2val) - new Date(date1val)) / 86400000) + 1));
    }
  }
}

function easyMoneyOnFormSubmit(formId) {
  $('#' + formId).submit(function() {
    $('input[name="commit"]').focus();
    return true;
  });
}


(function($){
    var Price = function(options) {
        this.init('price', options, Price.defaults);
    };

    $.fn.editableutils.inherit(Price, $.fn.editabletypes.abstractinput);

    $.extend(Price.prototype, {
        render: function () {
            this.$input = this.$tpl.find('input');
            this.renderEasyCurrencySelect();
        },

        renderEasyCurrencySelect: function() {
            var easyCurrencies = $.fn.editabletypes.price.easyCurrencies;

            if(easyCurrencies.length > 0) {
                this.$easyCurrencySelect = this.$tpl.find('select');
                var $option;

                for(var i = 0; i < easyCurrencies.length; i++) {
                    $option = $("<option></option>");
                    $option.html(easyCurrencies[i].name);
                    $option.attr('value', easyCurrencies[i].iso_code);

                    this.$easyCurrencySelect.append($option);
                }
            }
        },

        value2html: function (value, element, display, response) {
            var html = value.unit_rate + ' ' + value.easy_currency_code;

            if(response) {
                var json = JSON.parse(response);
                if(json.easy_money_rate && json.easy_money_rate.formatted_html) {
                    html = json.easy_money_rate.formatted_html;
                }
            }

            this.value2htmlFinal(html, element);
        },

        value2htmlFinal: function(html, element) {
            $(element).html(html)
        },

        html2value: function(html) {
            return null;
        },

        value2str: function(value) {
            var str = '';
            if(value) {
                for(var k in value) {
                    str = str + k + ':' + value[k] + ';';
                }
            }
            return str;
        },

        value2input: function(value) {
            if(!value) {
                return;
            }

            this.$input.val(value.unit_rate);
            if(this.$easyCurrencySelect) {
                this.$easyCurrencySelect.val(value.easy_currency_code)
            }
        },

        input2value: function() {
            var value = {
                unit_rate: this.$input.val()
            };

            if(this.$easyCurrencySelect) {
                value.easy_currency_code = this.$easyCurrencySelect.val()
            }

            return value;
        }
    });

    Price.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
        tpl: "<div class='editable-price'><input type='text'><select></select></div>"
    });
    Price.easyCurrencies = [];
    $.fn.editabletypes.price = Price;

})(jQuery);
