require "easy_extensions/spec_helper"

RSpec.describe EasyExtensions::Avatar, type: :helper do
  let(:user) { FactoryBot.create :user }
  let(:view_context) { spy }
  let(:entity) { described_class.new(user, view_context) }
  shared_context "avatar enabled" do
    before do
      allow(entity).to receive(:enabled?).and_return true
      allow(user).to receive(:visible?).and_return true
    end
  end

  describe "#initialize" do
    it "default settings" do
      expect(entity.options).to include :size, :style
      expect(entity.options).to include size: /^\d+$/
    end
  end
  context "no avatar" do
    around do |example|
      with_easy_settings avatar_enabled: false do
        example.run
      end
    end

    it "to_html should be empty" do
      expect(entity.to_html).to be_empty
    end
    it "image_path should be nil" do
      expect(entity.image_path).to be_nil
    end
  end

  context "gravatar" do
    include_context "avatar enabled"
    let(:user) { FactoryBot.create :user, mail: "lukas@easy.cz" }
    let(:gravatar_url) { "https://www.gravatar.com/avatar/a0a87172aa37755b8d5fb6f0c2530ddd?rating=PG&size=32&default=wavatar" }
    before do
      allow(Setting).to receive(:gravatar_enabled?).and_return true
    end
    around do |example|
      with_settings gravatar_enabled: true do
        example.run
      end
    end

    describe "#gravatar_url" do
      subject { entity.gravatar_url }
      it "existing email" do
        expect(view_context).to receive(:gravatar_url).with("lukas@easy.cz", kind_of(Hash)).and_return gravatar_url
        is_expected.to start_with "https://www.gravatar.com/avatar/"
      end
    end

    describe "#image_path" do
      subject { entity.image_path }
      it "uri to gravatar" do
        expect(entity).to receive(:gravatar_url).and_return "https://www.gravatar.com/avatar/xxx"
        subject
      end
      it "letter avatar as fallback" do
        expect(entity).to receive(:gravatar_url).and_return nil
        expect(view_context).to receive(:letter_avatar_url_for).and_return "public/images/easy_images/letter_avatars/2/752f86f90ced9adda1572d061426bb5c7ddc8805/32.png"
        subject
      end
    end

    describe "#name" do
      subject { entity.name }
      before do
        expect(entity).to receive(:gravatar_url).and_return gravatar_url
      end
      it "contains default ext" do
        is_expected.to eq "a0a87172aa37755b8d5fb6f0c2530ddd.jpg"
      end
    end
  end

  context "easy avatar" do
    include_context "avatar enabled"
    let(:image_path) { "images/easy_images/easy_avatars/107/original/14024057f372accb83ce14eea268bc22.jpg"}
    let(:easy_avatar) { spy("EasyAvatar", image: double("Image", url: "/#{image_path}?1479284879", exists?: true, path: Rails.public_path.join(image_path) ), present?: true, image_file_name: "14024057f372accb83ce14eea268bc22.jpg") }
    before do
      allow(user).to receive(:easy_avatar).and_return easy_avatar
    end
    describe "#image_path" do
      subject { entity.image_path }

      it do
        is_expected.to start_with "/images/easy_images/easy_avatars/107"
      end
      describe "#generate_base64" do
        let(:entity) { EasyExtensions::Avatar.new(user, view_context, base64: true) }
        it do
          expect(File).to receive(:binread).and_return "xxx"
          is_expected.to include "base64"
        end
      end
    end

    describe "#name" do
      subject { entity.name }
      it { is_expected.to eq "14024057f372accb83ce14eea268bc22.jpg" }
    end

  end

  context "letter avatar" do
    include_context "avatar enabled"
    let(:letter_avatar_url) do
      URI.join("#{Setting.protocol}://#{Setting.host_name}", LetterAvatar.path_to_url(user.letter_avatar_path(32))).to_s
    end
    let(:view_context) { spy("ViewContext", letter_avatar_url_for: letter_avatar_url) }

    describe "#image_path" do
      subject { entity.image_path }

      it "user without avatar should have letter one" do
        is_expected.to include "/letter_avatars/"
      end
      describe "#generate_base64" do
        let(:entity) { described_class.new(user, view_context, base64: true) }
        it "correct letter" do
          expect(File).to receive(:read).and_return "xxx"
          is_expected.to include "base64"
        end

        it "letter avatar with timestamp" do
          letter_avatar = "#{File.absolute_path File.join(__dir__, "../../../fixtures/files", "yoda-tux-256.png")}?15045"
          expect(entity).to receive(:letter_avatar).and_return letter_avatar

          is_expected.to include "base64"
        end

        it "letter avatar without timestamp" do
          letter_avatar = "#{File.absolute_path File.join(__dir__, "../../../fixtures/files", "yoda-tux-256.png")}"
          expect(entity).to receive(:letter_avatar).and_return letter_avatar

          is_expected.to include "base64"
        end
      end
    end

    describe "#name" do
      subject { entity.name }
      it { is_expected.to end_with ".png" }
    end

  end
end