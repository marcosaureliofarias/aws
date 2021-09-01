require_relative "../spec_helper"

RSpec.describe DiagramVersion do
  let(:project) { FactoryBot.create(:project, is_public: false, enabled_module_names: ['diagrams']) }
  let(:diagram) { FactoryBot.create(:diagram, project: project) }

  subject { FactoryBot.create(:diagram_version, diagram: diagram) }

  let(:base_64) { "data:image/jpeg;base64,/9j/" }

  it 'should belong_to diagram' do
    diagram = described_class.reflect_on_association(:diagram)
    expect(diagram.macro).to eq(:belongs_to)
  end

  describe 'position_with_timestamp' do
    let(:created_at) { Date.new(2019, 1, 1) }

    before do
      allow_any_instance_of(described_class).to receive(:created_at).and_return(created_at)
    end

    it 'returns position with formatted created_at' do
      expect(subject.position_with_timestamp).to eq('1 - Jan 1 2019, 00:00')
    end
  end

  describe 'attachment_exists?' do
    it 'returns true if diagram has any attachments' do
      create_attachment!

      expect(subject.attachment_exists?).to be true
    end
  end

  describe 'attachment' do
    it 'returns first attachment' do
      create_attachment!

      expect(subject.attachment).to eq(Attachment.first)
    end
  end

  describe 'def attachments_visible?' do
    it 'returns true' do
      expect(subject.attachments_visible?(User.current)).to be true
    end
  end

  describe ' attachment_path' do
    it 'returns relative path to attachment file' do
      attachment = create_attachment!

      expect(subject.attachment_path).to eq("/attachments/download/#{attachment.id}/#{attachment.try(:filename)}")
    end
  end

  describe 'attachment=' do
    context 'argument is image blob' do
      it 'creates attachment' do
        expect{subject.attachment = base_64}.to change { subject.attachments.count }.from(0).to(1)
      end
    end

    context 'argument is base_64 string' do
      it 'creates attachment' do
        file = create_tempfile(base_64)
        expect{subject.attachment = file}.to change { subject.attachments.count }.from(0).to(1)
        file.close
      end
    end
  end

  def create_attachment!
    subject.attachment = base_64
    subject.attachment
  end

  def create_tempfile(image)
    image_data = decode_base_64(image)

    file = Tempfile.new(['identifier', ".png"])
    file.binmode
    file.write(image_data)
    file
  end

  def decode_base_64(data)
    data = data.remove('data:image/png;base64,')
    data = data.sub(' ', '+')
    Base64.decode64(data)
  end
end