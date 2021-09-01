class FixReRelationtypes < EasyExtensions::EasyDataMigration
  def up
    project_ids = ReSetting.distinct.pluck(:project_id)
    project_ids.each do |id|
      parentchild = ReRelationtype.where({ project_id: id, relation_type: 'parentchild' }).first
      unless parentchild.present?
        relation_type = ReRelationtype.create(
          project_id: id,
          relation_type: 'parentchild',
          alias_name: 'parentchild',
          color: '#0000ff',
          is_system_relation: 1,
          is_directed: 1,
          in_use: 1
        )

        artifact_property_ids = ReArtifactProperties.where.not(artifact_type: 'Project').where(project_id: id).distinct.pluck(:id)
        artifact_property_ids.each do |aid|
          source_id = ReArtifactProperties.where(artifact_type: 'Project', artifact_id: id).limit(1).pluck(:id).first
          if source_id
            relationship = ReArtifactRelationship.where(source_id: source_id, sink_id: aid, relation_type: 'parentchild').first
            unless relationship
              ReArtifactRelationship.create(
                source_id: source_id,
                sink_id: aid,
                relation_type: 'parentchild',
                position: 1
              )
            end
          end
        end
      end
    end
  end
end
