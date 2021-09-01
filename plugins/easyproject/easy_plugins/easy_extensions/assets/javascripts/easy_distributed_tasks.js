/*jslint browser: true*/
/*global jQuery*/
(function ($) {
    "use strict";

    var ps, table, emptyRow, addRow;

    ps = {
        addRow: function () {
            if (emptyRow) {
                addRow.before(emptyRow);
                emptyRow = emptyRow.clone();
            }
        },

        createAddRow: function () {
            var buttonTd;

            addRow = $("<tr/>").appendTo($("tbody", table));
            buttonTd = $("<td/>").appendTo(addRow).attr({colspan: '2'});

            $("<a/>")
                .addClass("icon icon-add button-icon-only")
                .click(ps.addRow)
                .appendTo(buttonTd);

        }
    };

    $.fn.easyDistributedTasks = function () {
        table = this;
        emptyRow = $("tbody > tr:first", this).clone();
        $('input, select', emptyRow).val('');

        ps.createAddRow();

        return this;
    };

}(jQuery));