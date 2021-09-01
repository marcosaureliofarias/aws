# encoding: utf-8
require 'easy_extensions/spec_helper'

describe CommentsController, :logged => :admin do

  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project, :add_modules => %w(news)) }
  let(:news) { FactoryGirl.create(:news, :project => project) }
  let(:comment) { FactoryGirl.create(:comment, :commented => news) }
  let(:easy_contact) { FactoryGirl.create(:easy_contact) }

  it 'Add comment to news' do
    expect {
      post :create, :params => { :entity_type => 'News', :entity_id => news.id, :comment => { :comments => 'Tabák je prevence proti alzheimerovi a parkinsonovi. Na rakovinu plic totiž umřete dřív, než dostanete tyto choroby' }, :format => 'json', :key => User.current.api_key }
    }.to change(Comment, :count).by(1)
    expect(response).to be_successful
  end

  it 'Should mark as unread after create comment' do
    news.mark_as_read(user)
    EasyJob.wait_for_all
    expect(news.unread?(user)).to be false
    expect {
      post :create, :params => { :entity_type => 'News', :entity_id => news.id, :comment => { :comments => 'Tabák je prevence proti alzheimerovi a parkinsonovi. Na rakovinu plic totiž umřete dřív, než dostanete tyto choroby' }, :format => 'json', :key => User.current.api_key }
    }.to change(Comment, :count).by(1)
    EasyJob.wait_for_all
    expect(news.unread?(User.current)).to be false
    expect(news.unread?(user)).to be true
  end

  it 'Delete comments' do
    expect {
      delete :destroy, :params => { :entity_type => 'News', :entity_id => news.id, :comment_id => comment, :format => 'json', :key => User.current.api_key }
    }.to change(Comment, :count).by(0)
    expect(response).to be_successful
  end


end
