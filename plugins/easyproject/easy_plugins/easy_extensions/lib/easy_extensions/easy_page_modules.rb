EpmActivityFeed.register_to_all
EpmAttendance.register_to_scope(:user, :plugin => :easy_attendances)
EpmAttendance.register_to_page('easy-attendances-overview', :plugin => :easy_attendances)
EpmAttendance.register_to_user_defined(:plugin => :easy_attendances)
EpmAttendanceReport.register_to_page('easy-attendances-overview', :plugin => :easy_attendances)
EpmAttendanceReport.register_to_user_defined(:plugin => :easy_attendances)
EpmAttendanceUserList.register_to_page('easy-attendances-overview', :plugin => :easy_attendances)
EpmAttendanceUserList.register_to_user_defined(:plugin => :easy_attendances)
EpmDocuments.register_to_all
EpmIframe.register_to_all
EpmGenericGauge.register_to_all
EpmTrends.register_to_all
EpmIssueQuery.register_to_all
EpmIssueTimersQuery.register_to_all
# EpmIssuesAssignedToMe.register_to_scope(:user)
EpmIssuesReportedByMe.register_to_scope(:user)
EpmIssuesWatchedByMe.register_to_scope(:user)
EpmIssuesCreateNew.register_to_all
EpmMyCalendar.register_to_scope(:user)
# EpmMyProjectsSimple.register_to_scope(:user)
EpmNews.register_to_page('my-page')
EpmNoticeboard.register_to_all
EpmProjectsQuery.register_to_all
EpmSavedQueries.register_to_scope(:user)
EpmTimelogCalendar.register_to_scope(:user)
EpmTimelogCalendar.register_to_page('easy-attendances-overview', :plugin => :easy_attendances)
EpmTimelogCalendar.register_to_user_defined
EpmTimelogQuery.register_to_page('my-page')
EpmTimelogQuery.register_to_page('project-overview')
EpmTimelogQuery.register_to_user_defined
EpmTimelogSimple.register_to_scope(:user)
EpmTimelogSimple.register_to_page('easy-attendances-overview', :plugin => :easy_attendances)
EpmTimelogSimple.register_to_user_defined
EpmGoogleMaps.register_to_scope(:project)
EpmProjectHistory.register_to_scope(:project)
EpmProjectInfo.register_to_scope(:project)
EpmProjectIssues.register_to_scope(:project)
EpmProjectNews.register_to_scope(:project)
EpmProjectSidebarAllUsersQueries.register_to_scope(:project)
EpmProjectSidebarFamilyInfo.register_to_scope(:project)
EpmProjectSidebarProjectInfo.register_to_scope(:project)
EpmProjectSidebarProjectMembers.register_to_scope(:project)
EpmProjectSidebarSavedQueries.register_to_scope(:project)
EpmProjectTree.register_to_scope(:project)
EpmResourceAvailability.register_to_all
EpmTagCloud.register_to_all
EpmTranslatableNoticeboard.register_to_all
EpmUsersQuery.register_to_scope(:project)
EpmUsersQuery.register_to_user_defined
EpmVersionQuery.register_to_all

EpmLineChartQuery.register_to_all
EpmBarChartQuery.register_to_all
EpmPieChartQuery.register_to_all
EpmListQuery.register_to_all
EpmReportQuery.register_to_all
EpmTimeSeriesChart.register_to_all

EasyExtensions::AfterInstallScripts.add(:first => true) do
  EasyPageModule.ensure_all_registered_modules
end

EasyExtensions::AfterInstallScripts.add do
  page          = EasyPage.where(:page_name => 'my-page').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    # EasyPageTemplateModule.create_template_module(page, page_template, EpmIssuesAssignedToMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 1)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmIssuesReportedByMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 2)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmIssuesWatchedByMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 3)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmSavedQueries.first, 'middle-right', HashWithIndifferentAccess.new, 1)
    # EasyPageTemplateModule.create_template_module(page, page_template, EpmMyProjectsSimple.first, 'middle-right', HashWithIndifferentAccess.new, 2)
  end
end

EasyExtensions::AfterInstallScripts.add do
  page          = EasyPage.where(:page_name => 'project-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectSidebarProjectInfo.first, 'right-sidebar', HashWithIndifferentAccess.new, 1)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectSidebarFamilyInfo.first, 'right-sidebar', HashWithIndifferentAccess.new, 2)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectSidebarProjectMembers.first, 'right-sidebar', HashWithIndifferentAccess.new, 3)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectInfo.first, 'top-left', HashWithIndifferentAccess.new('action' => 'description'), 1)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectNews.first, 'top-left', HashWithIndifferentAccess.new, 2)
    EasyPageTemplateModule.create_template_module(page, page_template, EpmProjectIssues.first, 'top-left', HashWithIndifferentAccess.new, 3)
  end
end

EasyExtensions::AfterInstallScripts.add do
  page          = EasyPage.where(:page_name => 'easy-resource-booking-module').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmResourceAvailability.first, 'top-middle', HashWithIndifferentAccess.new(:name => 'Resource name', :day_start_time => '9', :day_end_time => '20'), 1)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

EasyExtensions::AfterInstallScripts.add do
  page          = EasyPage.where(:page_name => 'easy-attendances-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    calendar_tab = EasyPageTemplateTab.create(:page_template_id => page_template.id, :name => I18n.t(:label_calendar))
    list_tab     = EasyPageTemplateTab.create(:page_template_id => page_template.id, :name => I18n.t(:label_list))
    report_tab   = EasyPageTemplateTab.create(:page_template_id => page_template.id, :name => I18n.t(:label_report))

    calendar_module = EasyPageTemplateModule.create_template_module(page, page_template, EpmAttendance.first, 'top-left', HashWithIndifferentAccess.new('output' => 'calendar', 'settings' => { 'period' => 'month' }), 1)
    calendar_module.update_column(:tab_id, calendar_tab.id)
    user_list_module = EasyPageTemplateModule.create_template_module(page, page_template, EpmAttendanceUserList.first, 'right-sidebar', HashWithIndifferentAccess.new(), 1)
    user_list_module.update_column(:tab_id, calendar_tab.id)
    list_module = EasyPageTemplateModule.create_template_module(page, page_template, EpmAttendance.first, 'top-left', HashWithIndifferentAccess.new('row_limit' => '10'), 1)
    list_module.update_column(:tab_id, list_tab.id)
    report_module = EasyPageTemplateModule.create_template_module(page, page_template, EpmAttendanceReport.first, 'top-left', HashWithIndifferentAccess.new(), 1)
    report_module.update_column(:tab_id, report_tab.id)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

EasyExtensions::AfterInstallScripts.add(:last => true) do
  page = EasyPage.where(:page_name => 'my-page').first

  if (page_template = page.default_template) && !page.all_modules.exists?
    User.pluck(:id).each do |user_id|
      EasyPageZoneModule.create_from_page_template(page_template, user_id)
    end
  end
end

EasyExtensions::AfterInstallScripts.add(:last => true) do
  page = EasyPage.where(:page_name => 'project-overview').first

  if (page_template = page.default_template) && !page.all_modules.exists?
    Project.pluck(:id).each do |project_id|
      EasyPageZoneModule.create_from_page_template(page_template, nil, project_id)
    end
  end
end
