EASY.schedule.late(function () {
    $("#artifact_types_list").tableDnD({
        onDrop: function (table, row) {
            tableArtifactIdsToJson(table, row, "#re_artifact_order")
        }
    });

    $("#relation_types_list").tableDnD({
        onDrop: function (table, row) {
            tableArtifactIdsToJson(table, row, "#re_relation_order")
        }
    });

    $('.colorpick').colorPicker();

    $(".relationdel").click(function () {
        $(this).parent().parent().remove();
    });
});

function tableArtifactIdsToJson(table, row, field_id) {
    var rows = table.tBodies[0].rows;
    var types = new Array();
    $(rows).each(function (i, r) {
        types.push('"' + this.id.replace(/_[0-9]*$/, '') + '"');
    });
    $(field_id).val("[" + types + "]");
}

function removeRelationFields(field) {
    var answer = confirm("Are you sure?");
    if (answer) {
        $(field).parent().parent().remove();
    }
}