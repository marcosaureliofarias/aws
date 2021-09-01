require 'easy_extensions/spec_helper'

RSpec.feature 'easy short url' do

  let!(:attachment_for_logged) { FactoryGirl.create(:attachment, :with_short_url) }
  let!(:attachment_for_all) { FactoryGirl.create(:attachment, :with_short_url_external) }

  scenario 'anonymouse access', logged: false do
    # Find created short urls
    for_logged = EasyShortUrl.where(entity_type: 'Attachment', entity_id: attachment_for_logged.id).first
    for_all    = EasyShortUrl.where(entity_type: 'Attachment', entity_id: attachment_for_all.id).first

    # Visit short URL for non-external users
    # Page should be redirected to login page
    visit easy_shortcut_path(for_logged.shortcut)
    expect(current_path).to eq(signin_path)

    # Now visit URL for external
    # Attachment should be downloaded
    target_path = easy_shortcut_path(for_all.shortcut)
    visit target_path
    expect(current_path).to eq(target_path)
  end

end
