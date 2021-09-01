function removeRelation (relation) {
    var answer = confirm(window.re_options.answer);
    if (answer) {
        $("#relation_"+relation).after('<input type="hidden" name="new_relation['+relation+'][_destroy]" value="true">');
        $("#relation_"+relation).remove()
    }
}

function removeTmpRelation (relation) {
    var answer = confirm(window.re_options.answer);
    if (answer) {
        $("#"+relation).remove();
    }
}

function createRelation (sink_record) {
    // Get relation type by current selection
    var relation_type = $("[name='re_artifact_relationship[relation_type]']").filter(":checked").val();

    if (relation_type === null || typeof relation_type == 'undefined') return;

    var relation_description = $("[name='re_artifact_relationship[relation_type]']").filter(":checked").data("alias-name");
    var element_id = "relation_"+sink_record.id+"_"+relation_type;
    var link = window.re_options.artifact_properties_path;
    var hidden_fields = '<input type="hidden" name="new_relation['+sink_record.id+'][relation_type][]" value="'+relation_type+'" />';

    $("#outgoing_relations").append('<li id="'+element_id+'">[ <a class="icon icon-del" href="javascript: removeTmpRelation(\''+element_id+'\')">'+window.re_options.remove+'</a> ] '+relation_description+' to <a href="'+link+'/'+sink_record.id+'/edit" class="icon '+sink_record.icon+'">'+sink_record.name+'</a>'+hidden_fields+'</li>');
}
