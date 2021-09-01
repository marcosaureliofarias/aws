function createJSTreeContextmenuItems(node) {
    var items = {
        "create": false,
        "rename": false,
        "remove": false,
        "ccp": false
    };

    if (window.re_options.allowed_to_edit) {
        items.new = {
            "label": window.re_options.create_in_str,
            "separator_before": false,
            "separator_after": false,
            "icon": "new-icon",
            "submenu": window.re_options.new_submenu,
        };

        items.sibling = {
            "label": window.re_options.create_below_str,
            "separator_before": false,
            "separator_after": true,
            "icon": "new-icon",
            "submenu": window.re_options.sibling_submenu,
        };

        items.edit = {
            "label": window.re_options.edit_str,
            "icon": "edit-icon d",
            "action": function (node) {
                var reference_id = $(node.reference).attr("data-id");
                var link = window.re_options.edit_link;
                window.location.href = link + '/' + reference_id + '/edit';
            }
        };

        items.delete = {
            "label": window.re_options.delete_str,
            "icon": "delete-icon",
            "action": function (node) {
                var reference_id = $(node.reference).attr("data-id");
                var link = window.re_options.delete_link;
                window.location.href = link + '/' + reference_id + '/how_to_delete';
            }
        };
    }

    if (window.re_options.bulk_edit) {
        items = {
            change_status: {
                "label": window.re_options.changeStatusStr,
                "icon": "edit-icon d",
                "submenu": window.re_options.change_status_submenu,
                }
        };
    }

    return items;
}

EASY.schedule.late(function () {
    var $tree = $('#tree');


    /*
     * Initialize the jstree
     */
    var options = {
        "core": {
            "multiple": true,
            "data": {
                "url": window.re_options.tree_root_link,
                "data": function (node) {
                    var reference_id = $(node.reference).attr("data-id");
                    return {"id": node.id};
                }
            },
            "check_callback": true,
            "animation": 100,
            "strings": {
                "loading": window.re_options.tree_loading_str
            },
            "themes": {
                "stripes": false,
                "dots": true,
            },
        },
        "types": {
            "#": {
                "max_children": 1,
            },
            "project": {
                "icon": "re_project-icon"
            },
            "re_goal": {
                "icon": "re_goal-icon"
            },
            "re_task": {
                "icon": "re_task-icon"
            },
            "re_subtask": {
                "icon": "re_subtask-icon"
            },
            "re_vision": {
                "icon": "re_vision-icon"
            },
            "re_attachment": {
                "icon": "re_attachment-icon"
            },
            "re_workarea": {
                "icon": "re_workarea-icon"
            },
            "re_user_profile": {
                "icon": "re_user_profile-icon"
            },
            "re_section": {
                "icon": "re_section-icon"
            },
            "re_requirement": {
                "icon": "re_requirement-icon"
            },
            "re_scenario": {
                "icon": "re_scenario-icon"
            },
            "re_processword": {
                "icon": "re_processword-icon"
            },
            "re_rationale": {
                "icon": "re_rationale-icon"
            },
            "re_use_case": {
                "icon": "re_use_case-icon"
            },
            "re_visualization": {
                "icon": "re_visualization-icon"
            },
        },
        "contextmenu": {
            "select_node": false,
            "show_at_node": false,
            "items": createJSTreeContextmenuItems()
        },
        checkbox: {
            three_state : false,
            whole_node : false,
            tie_selection : false
        }
    };

    if (window.re_options.allowed_to_edit) {
        options.plugins = ["dnd", "ui", "contextmenu", "types", "checkbox"];
    } else if (window.re_options.allowed_to_view) {
        options.plugins = ["ui", "contextmenu", "types", "wholerow"];
    }

    $tree.jstree(options);

    $tree.on("close_node.jstree", function (event, data) {
        $.ajax({
            "url": window.re_options.tree_close_link + '/' + data.node.id.replace('node_', '')
        });
    });

    $tree.on("select_node.jstree", function (event, data) {
        var link = data.node.a_attr['data-href'];
        if(link === undefined) return;

        window.location.href = link;
    });

    $tree.on("check_node.jstree uncheck_node.jstree", function (event, data) {
        window.re_options.bulk_edit = data.selected.length !== 0

        $('#tree').jstree(true).settings.contextmenu.items = createJSTreeContextmenuItems();
    });


    $tree.on("open_node.jstree", function (event, data) {
        $.ajax({
            "url": window.re_options.tree_open_link + '/' + data.node.id.replace('node_', '')
        });
    });

    $tree.on("move_node.jstree", function (e, data) {
        var parent_id = data.parent.replace("node_", "");
        var id = data.node.id.replace("node_", "");
        var position = data.position;

        $.ajax({
            async: false,
            type: 'POST',
            url: window.re_options.delegate_tree_drop_link,
            data: {
                "id": id,
                "parent_id": parent_id,
                "position": position,
                "authenticity_token": window.re_options.form_authenticity_token
            }
        });
    });
});