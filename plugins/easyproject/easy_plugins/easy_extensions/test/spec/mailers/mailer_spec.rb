require "easy_extensions/spec_helper"
RSpec.describe Mailer do
  context "Issue" do

    let(:issue) { FactoryBot.build_stubbed(:issue, id: 1, created_on: Time.now) }

    context 'locales', logged: :admin do
      let(:journal) { FactoryBot.build_stubbed(:journal, journalized: issue, created_on: Time.now) }
      let(:issue_edit_mail) { described_class.issue_edit(User.current, journal) }
      let(:issue_add_mail) { described_class.issue_add(User.current, issue) }

      before(:each) do
        role = Role.anonymous
        role.add_permission! :view_issues
      end

      after(:each) do
        allow(User.current).to receive(:language).and_call_original
      end

      ['0', '1'].each do |plain|
        I18n.available_locales.each do |locale|
          it "issue_edit generate #{locale} #{plain == '1' ? 'plain' : 'html'}" do
            with_settings(plain_text_mail: plain) do
              allow(User.current).to receive(:language).and_return(locale)
              expect(issue_edit_mail.body.encoded).not_to be_blank
            end
          end

          it "issue_add generate #{locale}" do
            with_settings(plain_text_mail: plain) do
              allow(User.current).to receive(:language).and_return(locale)
              expect(issue_add_mail.body.encoded).not_to be_blank
            end
          end
        end

        context 'assigned' do
          let(:issue) { FactoryBot.build_stubbed(:issue, id: 1, created_on: Time.now, assigned_to: User.current) }

          I18n.available_locales.each do |locale|
            it "issue_edit generate #{locale} #{plain == '1' ? 'plain' : 'html'}" do
              with_settings(plain_text_mail: plain) do
                allow(User.current).to receive(:language).and_return(locale)
                expect(issue_edit_mail.body.encoded).not_to be_blank
              end
            end

            it "issue_add generate #{locale}" do
              with_settings(plain_text_mail: plain) do
                allow(User.current).to receive(:language).and_return(locale)
                expect(issue_add_mail.body.encoded).not_to be_blank
              end
            end
          end
        end
      end
    end

    describe "#issue_edit" do
      let(:journal) { FactoryBot.build_stubbed(:journal, journalized: issue, created_on: Time.now) }
      let(:mail) { described_class.issue_edit(User.current, journal) }

      let(:milestone) { FactoryBot.create(:version, id: 1, name: "Hardstone") }

      before(:each) do
        role = Role.anonymous
        role.add_permission! :view_issues
      end

      it "body with version" do
        issue.fixed_version = milestone
        expect(mail.body.encoded.include?("Hardstone")).to eq(true)
      end

      context "CF link_to_<entity> in mail" do
        let(:user) { FactoryBot.create(:user, firstname: "Bozek") }
        let(:cf_user) { FactoryBot.create(:issue_custom_field, field_format: "user", name: "Random user", trackers: [issue.tracker]) }
        let(:cf_milestone) { FactoryBot.create(:issue_custom_field, field_format: "version", name: "Found in version", trackers: [issue.tracker]) }

        it "version" do
          issue.custom_field_values = { cf_milestone.id => milestone.id }
          expect(issue.custom_value_for(cf_milestone)).not_to be_blank
          body = mail.html_part.body.raw_source
          expect(body.include?("Hardstone")).to eq(true)
          expect(body.include?("http://localhost:3000/versions/#{milestone.id}")).to eq(true)
        end

        it "user", logged: :admin do
          issue.custom_field_values = { cf_user.id => user.id }
          expect(issue.custom_value_for(cf_user)).not_to be_blank
          body = mail.html_part.body.raw_source
          expect(body.include?("Bozek")).to eq(true)
          expect(body.include?("http://localhost:3000/users/#{user.id}")).to eq(true)
        end

        context "easy_lookup" do

          shared_examples "easy_lookup for" do |entity, attribute|

            subject { FactoryBot.create(entity, attribute => "Pink #{entity}") }

            def create_cf(entity, option)
              FactoryBot.create(:issue_custom_field, field_format: "easy_lookup", name: "Pink #{entity}", trackers: [issue.tracker], settings: { "entity_type" => entity.classify, "entity_attribute" => option })
            end

            it "#{attribute} of #{entity}" do
              cf                        = create_cf(entity, attribute)
              issue.custom_field_values = { cf.id => subject.id }
              expect(issue.custom_value_for(cf)).not_to be_blank
              expect(mail.html_part.body.raw_source.include?("Pink #{entity}")).to eq(true)
            end

            it "link_with_#{attribute} of #{entity}" do
              cf = create_cf(entity, "link_with_#{attribute}")

              issue.custom_field_values = { cf.id => subject.id }
              expect(issue.custom_value_for(cf)).not_to be_blank
              body = mail.html_part.body.raw_source
              expect(body.include?("Pink #{entity}")).to eq(true)
              expect(%r{https?:\/\/localhost\:3000\/#{entity}s?\/#{subject.id}}.match?(body)).to eq(true)
            end

            it "name_and_cf of #{entity}" do
              cf = create_cf(entity, "name_and_cf")

              issue.custom_field_values = { cf.id => subject.id }
              expect(issue.custom_value_for(cf)).not_to be_blank
              body = mail.html_part.body.raw_source
              expect(body.include?("Pink #{entity}")).to eq(true)
              expect(%r{https?:\/\/localhost\:3000\/#{entity}s?\/#{subject.id}}.match?(body)).to eq(true)
            end
          end

          it_behaves_like "easy_lookup for", "document", "title"
          it_behaves_like "easy_lookup for", "group", "lastname"
          it_behaves_like "easy_lookup for", "easy_contact", "name" do
            subject { FactoryBot.create(:easy_contact, firstname: "Pink", lastname: "user") }
            before(:each) do
              allow_any_instance_of(EasyContact)
                  .to receive(:visible?).and_return(true)
            end
          end if Redmine::Plugin.installed?(:easy_contacts)
          it_behaves_like "easy_lookup for", "easy_crm_case", "name" if Redmine::Plugin.installed?(:easy_crm)
          it_behaves_like "easy_lookup for", "project", "name"
          it_behaves_like "easy_lookup for", "user", "name" do
            subject { FactoryBot.create(:user, firstname: "Pink", lastname: "user") }
          end

        end

      end

    end

    describe ".with_deliveries", type: :model do
      let(:user) { FactoryBot.create(:user, mail: "user@dummy.com") }

      it "#perform_later will not send emails" do

        Mailer.with_deliveries(false) do
          Mailer.test_email(user).deliver_later
        end
        expect(ActionMailer::DeliveryJob).not_to have_been_enqueued

      end

    end
  end

  context "News", logged: :admin do
    let(:project) { FactoryBot.build_stubbed(:project) }
    let(:planned_project) { FactoryBot.build_stubbed(:project, status: Project::STATUS_PLANNED) }
    let(:news) { FactoryBot.build_stubbed(:news, project: project) }
    let(:planned_news) { FactoryBot.build_stubbed(:news, project: planned_project) }

    it "deliver" do
      allow_any_instance_of(News).to receive(:notified_users).and_return([User.current])
      news
      expect {
        described_class.deliver_news_added(news)
      }.to have_enqueued_job(ActionMailer::DeliveryJob)
    end

    it "deliver planned" do
      allow_any_instance_of(News).to receive(:notified_users).and_return([User.current])
      planned_news
      expect {
        described_class.deliver_news_added(planned_news)
      }.not_to have_enqueued_job(ActionMailer::DeliveryJob)
    end
  end
end
