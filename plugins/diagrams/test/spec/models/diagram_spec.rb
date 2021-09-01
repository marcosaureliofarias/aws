require_relative "../spec_helper"

RSpec.describe Diagram do
  let(:title) { 'Title 1' }

  subject { FactoryBot.create(:diagram, title: title) }

  let(:base_64) { "data:image/jpeg;base64,/9j/" }

  it "just create" do
    is_expected.not_to be_a_new_record
  end

  it 'should have many diagram_versions' do
    diagram_versions = described_class.reflect_on_association(:diagram_versions)
    expect(diagram_versions.macro).to eq(:has_many)
  end

  it 'should belong_to project' do
    project = described_class.reflect_on_association(:project)
    expect(project.macro).to eq(:belongs_to)
  end

  it 'should belong_to author' do
    author = described_class.reflect_on_association(:author)
    expect(author.macro).to eq(:belongs_to)
  end

  describe '#to_s' do
    it do
      expect(subject.to_s).to eq("Title 1" + " #{I18n.t('diagram_version', version: 1)}")
    end
  end

  describe '#root_xml' do
    subject { FactoryBot.create(:diagram, xml: xml) }

    it 'should return root node of diagram xml' do
      expect(subject.root_xml).to eq(Addressable::URI.encode("<mxGraphModel>#{Nokogiri::XML("<root>\n  <Diagram>1.0</Diagram>\n</root>").xpath('//root').to_xml}</mxGraphModel>"))
    end
  end

  describe '#identifier' do
    it 'makes characters lowercase and replaces gaps with separator'do
      expect(subject.identifier).to eq("#{subject.id}--title-1")
    end

    context 'non ascii characters' do
      let(:title) { '합니다 합니다' }

      it 'makes characters lowercase and replaces gaps with separator'do
        expect(subject.identifier).to eq("#{subject.id}--합니다-합니다")
      end
    end
  end

  describe '#attachment=' do
    it 'creates attachment' do
      subject.create_version!

      expect{subject.attachment = base_64}.to change { Attachment.count }.from(0).to(1)
    end
  end

  describe '#file_name' do
    it do
      expect(subject.file_name).to eq("#{subject.id}--title-1.png")
    end
  end

  describe '#create_version!' do
    it 'creates new diagram version' do
      expect{subject.create_version!}.to change { DiagramVersion.count }.by(1)
    end

    context 'without diagram_versions' do
      it 'should not increment current_position' do
        expect{subject.create_version!}.not_to change { subject.current_position }.from(1)
      end
    end

    context 'with diagram_version' do
      it 'should increment current_position' do
        subject.create_version!

        expect{subject.create_version!}.to change { subject.current_position }.from(1).to(2)
      end
    end
  end

  def xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.root{
        xml.Diagram "1.0"
      }
    end

    builder.to_xml
  end
end