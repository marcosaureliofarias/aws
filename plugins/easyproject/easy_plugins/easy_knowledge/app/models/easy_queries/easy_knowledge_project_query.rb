class EasyKnowledgeProjectQuery < EasyProjectQuery

  def query_after_initialize
    super
    self.add_additional_statement("EXISTS(SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='easy_knowledge' AND em.project_id = #{Project.table_name}.id)")
  end

end

