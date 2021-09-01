# encoding: UTF-8
require 'easy_extensions/spec_helper'

RSpec.describe EasyTranslation do

  let(:issue_status) { FactoryBot.create(:issue_status, name: 'New') }

  # before(:each) { I18n.locale = :cs }
  around :each do |example|
    I18n.with_locale :cs do
      example.run
    end
  end

  it 'creates a translation for given entity' do

    easy_translation = EasyTranslation.set_translation(
        issue_status,
        'name',
        'Nový / aktivovat',
        :cs
    )
    easy_translation.save

    expect(IssueStatus.find(issue_status.id).name).to eq(easy_translation.value)
  end

  it '.set_translation invalidates cache when translation is changed' do
    easy_translation = EasyTranslation.set_translation(
        issue_status,
        'name',
        'Nový / aktivovat',
        :cs
    )
    easy_translation.save

    expect(IssueStatus.find(issue_status.id).name).to eq(easy_translation.value)

    changed_translation = 'Nový'
    EasyTranslation.set_translation(
        issue_status,
        'name',
        changed_translation,
        :cs
    ).save

    expect(IssueStatus.find(issue_status.id).name).to eq(changed_translation)
  end

  describe ".get_translation" do
    let(:entity) { issue_status }

    it "no translation" do
      e = described_class.get_translation(issue_status, "name")
      expect(e).to be_nil
    end

    context "with translation" do
      let!(:translation) { issue_status.easy_translations.create(entity_column: "name", value: "czech new", lang: "cs") }
      it "en no exist" do
        e = described_class.get_translation(issue_status, "name", "en")
        expect(e).to be_nil
      end

      it "cs is new" do
        e = described_class.get_translation(issue_status, "name", "cs")
        expect(e).to eq "czech new"
      end
    end
  end

  describe "#expire_cache" do
    let!(:translation) { issue_status.easy_translations.create(entity_column: "name", value: "czech new", lang: "cs") }

    it "after destroy expire cache" do
      expect { translation.destroy }.not_to raise_error
    end
  end

end
