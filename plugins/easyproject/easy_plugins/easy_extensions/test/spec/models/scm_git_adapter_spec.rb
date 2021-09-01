require "easy_extensions/spec_helper"

RSpec.describe Redmine::Scm::Adapters::GitAdapter do
  let(:repository) { Repository::Git.new(url: "git@easy.com/repo.git") }
  subject { described_class.new("git@easy.com/repo.git") }
  let(:repository_path) { Rails.root.join("tmp/git_adapter_spec") }
  around(:each) do |example|
    unless described_class.client_available # clears $?
      skip "git is not installed"
    end
    with_easy_settings({ git_repository_path: repository_path.to_s }) do
      example.run
    end
  end

  after(:each) do
    FileUtils.rm_r(repository_path) if repository_path.exist?
  end
  describe "#ensure!" do

    it "call git clone" do
      expect(subject).to receive(:git_clone).with("git@easy.com/repo.git", "xyz")
      subject.ensure!("git@easy.com/repo.git", "xyz")
    end
    
    it "call git clone with suffix" do
      expect(subject).to receive(:git_clone).with("git@easy.com/repo.git", "xyz.git")
      subject.ensure!("git@easy.com/repo.git", "xyz.git")
    end

    it "resolve name conflict" do
      FileUtils.mkdir_p repository_path.join("dummy.git")
      expect(subject).to receive(:git_clone).with("git@easy.com/dummy.git", /\w+_dummy\.git\z/)
      subject.ensure!("git@easy.com/dummy.git", "dummy.git")
    end

    it "guess name" do
      expect(subject).to receive(:git_clone).with("git@easy.com/repo.git", "repo.git")
      subject.ensure!("git@easy.com/repo.git")
    end

    it "impossible name" do
      expect { subject.ensure!("corrupted arg") }.to raise_exception Redmine::Scm::Adapters::AbstractAdapter::ScmCommandAborted
    end

  end
end