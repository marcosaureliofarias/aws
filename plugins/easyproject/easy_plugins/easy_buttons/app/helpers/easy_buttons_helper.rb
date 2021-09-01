module EasyButtonsHelper

  def easy_button_link_to_add_token(token, editor_id)
    js = %{
      var editor = $('##{editor_id}');
      editor.val(editor.val() + '#{token}');
    }
    link_to_function(token, js)
  end

end
