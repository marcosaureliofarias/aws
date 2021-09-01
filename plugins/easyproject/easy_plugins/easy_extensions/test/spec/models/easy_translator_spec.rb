require "easy_extensions/spec_helper"

# class DummyModel
#   include ActiveModel::Model
#   include ActiveModel::Attributes
#
#   attr_accessor :id, :name
#
#   def self.has_many *args
#     # stub
#   end
#
#   def self.reflect_on_all_associations *args
#     [] # stub
#   end
#
#   def self.after_save *args
#     # stub
#   end
#
#   include EasyExtensions::EasyTranslator
#   acts_as_easy_translate
#
# end

RSpec.describe EasyExtensions::EasyTranslator do

  let(:issue_status) { FactoryBot.create(:issue_status, name: 'New') }

  let!(:translation) { issue_status.easy_translations.create(entity_column: "name", value: "Novinka", lang: "cs") }

  subject do
    # m = DummyModel.new id: 1, name: "boy"
    # allow(m).to receive(:easy_translations).and_return(EasyTranslation.where(id: translation.id))
    # m
  end

  it "translation works" do
    I18n.with_locale "cs" do
      expect(issue_status.name).to eq "Novinka"
    end

    I18n.with_locale "en" do
      expect(issue_status.name).to eq "New"
    end

    I18n.with_locale "de" do
      expect(issue_status.name).to eq "New"
    end
  end

  it 'bug dublications insert' do
    issue_status

    allow_any_instance_of(IssueStatus).to receive(:strip!) do |record|
      record.write_attribute(:name, record.name.strip)
    end
    issue_status.write_attribute(:name, 'progress ')
    issue_status.strip!
    expect { issue_status.save }.not_to raise_error #ActiveRecord::RecordNotUnique
  end
end
