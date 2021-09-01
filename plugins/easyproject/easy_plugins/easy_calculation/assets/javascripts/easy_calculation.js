//= require_self
EASY.schedule.require(function ($) {
    "use strict";

    $(function () {
        var editedRow = null;

        function initSolutionInlineEdits() {
            var hs = $(".calculation-header-setting, .calculation-title-editable").editable().wrap('<span class="editable-parent"></span>');
            var cd = $(".calculation-date").editable({
                emptytext: moment().format(momentjsFormat),
                emptyclass: ''
            }).wrap('<span class="editable-parent"></span>');
            var pcde = $(".calculation-project-discount-editable").editable({
                type: 'discount',
                params: function (x) {
                    return x.value;
                },
                success: reloadCalculation
            }).wrap('<span class="editable-parent"></span>');
            $('<span/>')
              .addClass('icon icon-edit')
              .insertAfter(cd)
              .insertAfter($.merge($.merge(hs, cd), pcde))
              .click(function () {
                  $(this).prev().editable('toggle');
                  return false;
              });

            $(".issue-solution-row, .item-solution-row").each(function () {
                var data = $(this).data(),
                  se = $(".solution-editable", this).editable($.extend(data, {
                      success: reloadCalculation
                  })).wrap('<span class="editable-parent"></span>');
                var data = $(this).data(),
                  cde = $(".calculation-discount-editable", this).editable($.extend(data, {
                      type: 'discount',
                      params: function (x) {
                          return x.value;
                      },
                      success: reloadCalculation
                  })).wrap('<span class="editable-parent"></span>');
                var data = $(this).data(),
                  ue = $(".calculation-unit-editable", this).editable($.extend(data, {
                      type: 'unit',
                      params: function (x) {
                          return x.value;
                      },
                      success: reloadCalculation
                  })).wrap('<span class="editable-parent"></span>');
                $('<span/>')
                  .addClass('icon-edit')
                  .insertAfter($.merge($.merge(se, cde), ue))
                  .click(function () {
                      $(this).prev().editable('toggle');
                      return false;
                  });
            });

          EASY.dragAndDrop.initReorders();
        }
        initSolutionInlineEdits();

        // submit and hide project settings when project is set to be planned
        $("#project_is_planned").change(function () {
            if ($(this).is(":checked")) {
                $("#project-settings-form").submit();
                $("#project-settings-container").remove();
            }
        });

        $("#calculation-actions > form").submit(function () {
            $(this).removeAttr("data-submitted");
        });

        function reloadCalculation() {
            $("#calculation_container").load(window.location.href + ' #calculation_container', function () {$("#calculation_container").children().unwrap(); initSolutionInlineEdits();});
        };

        function reloadServiceBox() {
            $("#easy_page_layout_service_box").load(window.location.href + ' #easy_page_layout_service_box');
        };

        // create easy money from calculation
        $("a.save-to-revenues").click(function () {
            var moneyDialog = $("<div/>"),
              buttons = {};

            moneyDialog.load($(this).attr("href") + ' .easy-money-expected-revenue-container', function () {
                $("#money-type-select, p.links, h2", moneyDialog).hide();
                $("form", moneyDialog).submit(function () {
                    var $this = $(this),
                      data = $this.serializeArray();

                    data.push({name: 'format', value: 'json'});
                    $.ajax({
                        url: $this.attr("action"),
                        type: $this.attr("method"),
                        data: data,
                        complete: function (jqXHR) {
                            var flash;
                            $(".flash").remove();
                            if (jqXHR.status === 422) {
                                var flash = $("<div/>")
                                  .addClass("flash error")
                                  .html($.parseJSON(jqXHR.responseText).errors.join('\n'))
                                  .prependTo(moneyDialog);
                            } else {
                                moneyDialog.dialog("close");
                                $("<div/>").addClass("flash notice").html(window.I18n.saveSuccess).prependTo($("#content"));
                            }
                        }
                    });
                    return false;
                });

                buttons[window.I18n.buttonCreate] = function () {
                    $("form", moneyDialog).submit();
                };
                buttons[window.I18n.buttonCancel] = function () {
                    moneyDialog.dialog("close");
                };

                moneyDialog.dialog({
                    width: 700,
                    title: $("h2", moneyDialog).text(),
                    buttons: buttons,
                    open: function (event, ui) {
                        //initFileUploads();
                        //setupFileDrop();
                    }
                });
            });
            return false;
        });

        // project client - edit using contacts toolbar
        $("a.edit-client").on("click", function () {
            $("#clicker_easy_contacts_toolbar_container").click();
            return false;
        });

        $(document).on("click", "a.save-calculation", function() {
            var row = $(this).closest("tr"),
              params = $("input", row).serializeArray();

            $.ajax({
                url: $(this).attr("href"),
                type: $(this).attr("data-save-method"),
                data: params,
                complete: function (xhr) {
                    var data;
                    if (xhr.status > 300) {
                        data = $.parseJSON(xhr.responseText);
                        alert(data.errors.join("\n"));
                    } else {
                        editedRow = null;
                        reloadServiceBox();
                        reloadCalculation();
                    }
                }
            });

            return false;
        });

        function cancelCurrentEdit() {
            if (editedRow) {
                editedRow.cancel();
                editedRow = null;
            }
        }

        $("a.edit-calculation").on("click", function () {
            var row = $(this).closest("tr");

            cancelCurrentEdit();

            $.get($(this).attr("href"), function (response) {
                var editRow = $(response);
                row.replaceWith(editRow);
                editedRow = {
                    cancel: function () {
                        editRow.replaceWith(row);
                    }
                };
                $("a.cancel-calculation-edit").click(function () {
                    cancelCurrentEdit();
                    editedRow = null;
                    return false;
                });
            });
            return false;
        });

        $(document).on("click", "a.destroy-calculation", function() {
            $.ajax({
                url: $(this).attr("href"),
                type: "DELETE",
                complete: function () {
                    reloadCalculation();
                }
            });
            return false;
        });
        $(document).on("click", "a.add-calculation", function() {
            $.ajax({
                url: $(this).attr("href"),
                type: "POST",
                complete: function () {
                    reloadCalculation();
                }
            });
            return false;
        });

        $("a.edit-issue-calculation").on("click", function () {
            var row = $(this).closest("tr"),
              displayHtml = row.html(),
              url = $(this).attr("href"),
              td, val;

            cancelCurrentEdit();
            editedRow = {
                cancel: function () {
                    row.html(displayHtml);
                }
            };

            // hours
            td = $("td:nth-child(3)", row);
            val = td.text();
            td.empty();
            $("<input/>")
              .val(val)
              .attr("id", "easy_calculation_item_hours")
              .appendTo(td);

            // rate
            td = $("td:nth-child(4)", row);
            val = td.hasClass("custom-rate") ? td.text() : '';
            td.empty();
            $("<input/>")
              .val(val)
              .attr("id", "easy_calculation_item_rate")
              .appendTo(td);

            // buttons
            td = $("td:last", row).empty();
            $("<a/>")
              .addClass("icon icon-save")
              .appendTo(td)
              .click(function () {
                  $.ajax({
                      url: url,
                      type: "PUT",
                      data: {
                          issue: {
                              estimated_hours: $("#easy_calculation_item_hours", row).val(),
                              calculation_rate: $("#easy_calculation_item_rate", row).val()
                          }
                      },
                      complete: function (xhr) {
                          var data;
                          if (xhr.status > 300) {
                              data = $.parseJSON(xhr.responseText);
                              alert(data.errors.join("\n"));
                          } else {
                              reloadCalculation();
                          }
                      }
                  });
                  return false;
              });
            $("<a>")
              .addClass("icon icon-cancel")
              .appendTo(td)
              .click(function () {
                  cancelCurrentEdit();
                  editedRow = null;
                  return false;
              });

            return false;
        });
    });

    var DiscountEditable = function (options) {
        this.init('discount', options, DiscountEditable.defaults);
    };

    var UnitEditable = function (options) {
        this.init('unit', options, UnitEditable.defaults);
    };

    $.fn.editableutils.inherit(DiscountEditable, $.fn.editabletypes.abstractinput);
    $.fn.editableutils.inherit(UnitEditable, $.fn.editabletypes.abstractinput);

    $.extend(DiscountEditable.prototype, {
        render: function () {
            var names = $(this.options.scope).data('name').split(',');
            var mock_form = $('#discount_editable');
            $.each(mock_form.find('input'), function (i, e) {
                $(e).prop('name', names[i].trim());
            });
            this.$tpl.html($('#discount_editable').html());
        },
        input2value: function () {
            return $('input', this.$input).serialize();
        },
        value2input: function (value) {
            var values = value.split(',');
            if (values.length === 2) {
                this.$input.find('input.discount-text').val(values[0].trim());
                this.$input.find('input.discount-radio1').prop('checked', values[1] === 'true');
                this.$input.find('input.discount-radio2').prop('checked', values[1] === 'false');
            }
            return this.$input;
        },
        value2html: function () {
            return '';
        }
    });

    $.extend(UnitEditable.prototype, {
        render: function () {
            var names = $(this.options.scope).data('name').split(',');
            var mock_form = $('#unit_editable');
            $.each(mock_form.find('input'), function (i, e) {
                $(e).prop('name', names[i].trim());
            });
            this.$tpl.html($('#unit_editable').html());
        },
        input2value: function () {
            return $('input', this.$input).serialize();
        },
        value2input: function (value) {
            var values = value.split(',');
            if (values.length === 2) {
                this.$input.find('input.value-text').val(values[0].trim());
                this.$input.find('input.unit-text').val(values[1].trim());
            }
            return this.$input;
        },
        value2html: function () {
            return '';
        }
    });

    DiscountEditable.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
        tpl: '<div class="editable-discount"></div>'
    });

    UnitEditable.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
        tpl: '<div class="editable-unit"></div>'
    });

    $.fn.editabletypes.discount = DiscountEditable;
    $.fn.editabletypes.unit = UnitEditable;

}, 'jQuery');
