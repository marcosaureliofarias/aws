require File.expand_path('../../spec_helper', __FILE__)

describe User do
  let(:user_stubbed) { FactoryGirl.build_stubbed(:user) }
  let(:user) { FactoryGirl.create(:user) }
  
  let(:project) { FactoryGirl.create(:project, members: [user]) }
  let(:project_template) { FactoryBot.create(:project, :template, members: [user]) }

  context 'password enforcement' do
    it 'password must differ from the last n used' do
      with_easy_settings('unique_password_counter': 2) do
        first_passwd  = 'TestPassword1.'
        second_passwd = 'TestPassword2.'
        third_passwd  = 'TestPassword3.'

        user.password = first_passwd
        expect(user.save).to be_truthy
        user.password = second_passwd
        expect(user.save).to be_truthy
        user.password = first_passwd
        expect(user.save).to be_falsey
        user.password = third_passwd
        expect(user.save).to be_truthy
        user.password = first_passwd
        expect(user.save).to be_truthy
      end
    end
  end

  context 'log time' do
    it 'is allowed on a non-template project' do
      expect(user.allowed_to?(:log_time, project)).to be(true)
    end

    it 'is not allowed on a template project' do
      expect(user.allowed_to?(:log_time, project_template)).to be(false)
    end
  end

end
