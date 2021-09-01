require 'easy_extensions/spec_helper'

RSpec.describe MultipleEmailAddressesValidator, type: :model do

  subject { Struct.new(:email) { include ActiveModel::Validations; validates :email, multiple_email_addresses: true }.new }

  it 'valid' do
    subject.email = 'test@example.com'
    expect(subject).to be_valid
  end

  context 'multiple' do
    it 'comma separated' do
      subject.email = 'test1@example.com, test2@example.com'
      expect(subject).to be_valid
    end

    it 'line break separated' do
      subject.email = "test1@example.com\ntest2@example.com"
      expect(subject).to be_valid
      expect(subject.email).to eq('test1@example.com, test2@example.com')
    end
  end

  context 'named' do
    it 'single' do
      subject.email = 'Test <test@example.com>'
      expect(subject).to be_valid
    end
  
    it 'multiple' do
      subject.email = 'Test1 <test1@example.com>, Test2 <test2@example.com>'
      expect(subject).to be_valid
    end
  end

  context 'clear extra spaces' do
    it 'single' do
      subject.email = ' test@example.com '
      expect(subject).to be_valid
      expect(subject.email).to eq('test@example.com')
    end

    it 'multiple' do
      subject.email = ' test1@example.com  ,  test2@example.com '
      expect(subject).to be_valid
      expect(subject.email).to eq('test1@example.com, test2@example.com')
    end
  end

  it 'skip blanks' do
    subject.email = "test1@example.com, , \n test2@example.com"
    expect(subject).to be_valid
    expect(subject.email).to eq('test1@example.com, test2@example.com')
  end

  context 'invalid' do
    it 'single' do
      subject.email = 'test@example.com!'
      expect(subject).not_to be_valid
    end

    it 'at sign' do
      subject.email = '@test@example.com'
      expect(subject).not_to be_valid
    end

    it 'named' do
      subject.email = 'Test <test1@example.com!>'
      expect(subject).not_to be_valid
    end

    it 'multiple' do
      subject.email = 'test1@example.com!, test2@example.com'
      expect(subject).not_to be_valid
    end
  end

end