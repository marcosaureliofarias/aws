Rys::Patcher.add('ApplicationHelper') do

  apply_if_plugins :easy_extensions

  included do

    def link_to_easy_oauth2_access_grant(entity, **options)
      "access_grant##{entity.id}"
    end

  end

end
