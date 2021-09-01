var make_check_preview = false;

function toggle_settings() {
    if ($('show_settings_1').value == '0') {
        $('show_settings_1').value = '1';
    }
    else {
        $('show_settings_1').value = '0';
    }
    Effect.toggle("show_settings", "appear", {
        duration:0.3
    });
}
function toggle_assignment() {
    if ($('show_assignment_1').value == '0') {
        $('show_assignment_1').value = '1';
        if($('show_assignment_2') != null){
            $('show_assignment_2').value = '1';
        }
    }
    else {
        $('show_assignment_1').value = '0';
        if($('show_assignment_2') != null){
            $('show_assignment_2').value = '0';
        }
    }
    Effect.toggle("show_assignment", "appear", {
        duration:0.3
    });
}

function CheckPreview(){
    make_check_preview = true;
    $('check_preview').show();
}