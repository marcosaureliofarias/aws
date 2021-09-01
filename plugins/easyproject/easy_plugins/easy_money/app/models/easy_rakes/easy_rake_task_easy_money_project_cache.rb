class EasyRakeTaskEasyMoneyProjectCache < EasyRakeTask

  def execute
    if (user = User.active.where(admin: true).first)
      user.execute do
        Project.non_templates.has_module(:easy_money).find_each(batch_size: 1) do |project|
          EasyMoneyProjectCache.update_from_project! project
        end
      end
    end

    true
  end

  def category_caption_key
    :label_easy_money
  end

  def registered_in_plugin
    :easy_money
  end

end
