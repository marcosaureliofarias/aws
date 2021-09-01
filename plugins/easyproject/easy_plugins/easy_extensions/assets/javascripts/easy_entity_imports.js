$/**
 * Created by lukas on 29.1.15.
 */
function initEntityImportDragNdrop() {
    $("#easy_entity_import_mappings .easy-import-child").draggable({
        containment: 'window',
        appendTo: 'body',
        helper: function () {
            var el =document.createElement('div');
            el.setAttribute('data-path', this.dataset.path);
            el.className = 'easy-entity-import-draggable';
            el.textContent = this.dataset.name;

            return el;
        }
    });
    $("#easy_entity_import_mappings .splitcontentright .easy-entity-import-attribute-form-field").droppable({
        hoverClass: 'easy-entity-import-droppable-hover',
        drop: function (event, ui) {
            $(this.getElementsByClassName('attribute-value')).val(ui.helper.text());
            $(this.getElementsByClassName('attribute-source')).val(ui.helper.data().path);
            var params = $(this).find('input').serializeArray();
            params.push({name: 'entity_attribute', value: this.dataset.entityAttribute});
            createPostBack($(this));
        }
    });
}
function createPostBack(container) {
    var params = container.find('input').serializeArray();
    params.push({name: 'entity_attribute', value: container[0].dataset.entityAttribute});
    $.post($("#easy_entity_import_mappings").data().updateUrl, params)
}
function showEasyEntityPreview() {
    $("#easy_entity_import_mappings .splitcontentleft").css({"max-height": $(window).height() - $("#easy_entity_import_source_inputs").height()});
    $("#easy_entity_import_mappings .splitcontentright").css({"max-height": $(window).height() - $("#easy_entity_import_source_inputs").height()});
    scrollTo($("#easy_entity_import_mappings"));
    $("#easy_entity_import_mappings")[0].scrollIntoView();
    initEntityImportDragNdrop();
}
$(document).on('change', '.easy-entity-import-attribute-is-custom-toggle', function (event) {
    var p = $(event.target).closest('p');
    var el = p.find('.attribute-value');
    el[0].disabled = !el[0].disabled;
    el.focus();
    var d = p.find('.attribute-default-value');
    d[0].style.visibility = !d[0].disabled ? 'hidden' : 'visible'
    d[0].disabled = !d[0].disabled;
});
$(document).on('change', '.easy-entity-import-attribute-form-field input:text', function(event) {
    createPostBack($(event.target).closest('.easy-entity-import-attribute-form-field'))
})
function toggleUrlNFile(_self) {
    $('#preview_file').prop('disabled',false).show();
    $('#api_url, #easy_entity_import_is_automatic').remove();
    _self.remove();
    $(".buttons button").addClass('synchronous');
    $(".buttons .import-button").show();
}
function fetchPreview(_self) {
    _self.form.action = _self.form.dataset.fetchUrl;
    if (_self.classList.contains('synchronous')) {
        _self.form.submit();
    }
    $('#easy_entity_import_mappings .splitcontentleft p').show();
}
function submitImport(_self) {
    _self.form.action = _self.form.dataset.importUrl;
    $(_self).find('span').addClass('icon-pulse');
    if (_self.classList.contains('synchronous')) {
        _self.form.submit();
    }
}
$(document).on('click', "#easy_entity_import_toggle_advanced", function(event) {
    var link = $(event.target);
    var sources = link.closest("div").find("input.attribute-source");
    if (sources[0].attributes.type.value === "hidden") {
        sources.attr("type", "text");
    } else {
        sources.attr("type", "hidden");
    }
});
