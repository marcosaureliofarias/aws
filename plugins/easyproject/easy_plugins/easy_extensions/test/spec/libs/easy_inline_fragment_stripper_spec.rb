require 'easy_extensions/spec_helper'

describe 'EasyInlineFragmentStripper', logged: :admin do
  let(:issue) { FactoryGirl.build(:issue) }

  def test_stripped_image(issue)
    issue.reload
    expect(issue.description).not_to include('base64')
    expect(issue.description).to include('logo')
    expect(issue.attachments.count).to eq(1)
    attachment = issue.attachments.first
    expect(attachment.readable?).to eq(true)
    expect(File.zero?(attachment.diskfile)).to eq(false)
  end

  scenario 'page break' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      issue.description = '<div style="page-break-after:always;"></div>'
      expect(issue.save).to eq(true)
      issue.reload
      expect(issue.description).to include('page-break-after')
    end
  end

  scenario 'new issue' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      description       = IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/files', 'inline_image.html'))
      issue.description = description
      expect(issue.save).to eq(true)
      test_stripped_image(issue)
    end
  end

  scenario 'update issue' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      description = IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/files', 'inline_image.html'))
      issue.save
      expect(issue.new_record?).to eq(false)
      expect(issue.update_attribute(:description, description)).to eq(true)
      test_stripped_image(issue)
    end
  end

  scenario 'multiple inline images' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      description       = IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/files', 'inline_image_multiple.html'))
      issue.description = description
      expect(issue.save).to eq(true)
      issue.reload
      expect(issue.description).not_to include('base64')
      expect(issue.attachments.count).to eq(3)
    end
  end

  scenario 'large description' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      issue.description = '<p>text</p>' * 20000
      expect(issue.save).to eq(true)
      issue.reload
      expect(issue.attachments.count).to eq(0)
      expect(issue.description).not_to include('base64')
      expect(issue.description).to include('<p>text</p>')
    end
  end
end
