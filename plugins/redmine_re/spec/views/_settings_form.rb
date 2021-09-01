shared_examples :settings_form do |action|
  it 'displays settings form' do
    assign(:project, double(Project, id: 1))
    assign(:project_artifact, double(ReArtifactProperties))
    assign(:re_artifact_order, ['ReRequirement'])
    assign(:re_artifact_configs, { 'ReRequirement' => { in_use: true } })
    assign(:re_statuses, [])
    assign(:re_relation_types, [
      double(ReRelationtype,
        id: 1,
        relation_type: 'parentchild',
        is_directed: 1, is_system_relation: 1, in_use: 1,
        alias_name: 'parentchild',
        color: '#111111')
    ])

    render template: "re_settings/#{action}"

    expect(rendered).to match(/Requirements settings/)
    expect(rendered).to match(/Artifact configuration/)
    expect(rendered).to match(/Relation configuration/)
    expect(rendered).to match(/Add relation/)

    expect(rendered).to match(/re_artifact_configs\[ReRequirement\[in_use\]\]/)
    expect(rendered).to match(/re_relation_configs\[parentchild\[is_directed\]\]/)
  end
end
