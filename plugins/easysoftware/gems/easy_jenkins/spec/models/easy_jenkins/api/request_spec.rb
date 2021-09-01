require_relative '../../../spec_helper'

RSpec.describe EasyJenkins::Api::Request do
  before(:each) do
    allow_any_instance_of(EasyJenkins::Api::Connection).to receive(:fetch_response).and_return(response)
  end

  describe 'fetch_jobs' do
    let(:response) { EasyJenkins::Api::Connection::ApiResponse.new(200, { 'jobs' => [{ 'name' => 'job_name' }] }) }

    subject { described_class.call(setting: nil).fetch_jobs }

    it 'returns list of job names' do
      expect(subject).to match_array([["job_name", "job_name"]])
    end
  end

  describe 'run_job' do
    let(:pipeline) { FactoryBot.create(:pipeline) }
    let(:issue)    { FactoryBot.create(:issue) }
    let(:response) { EasyJenkins::Api::Connection::ApiResponse.new('', {}) }

    subject { described_class.call(setting: nil).run_job(pipeline, issue) }

    it 'creates a job' do
      expect{subject}.to change{pipeline.jobs.count}.from(0).to(1)
    end
  end

  describe 'connected?' do
    let(:response) { EasyJenkins::Api::Connection::ApiResponse.new(200, {}) }

    subject { described_class.call(setting: nil).connected? }

    it 'returns true if status is not 401' do
      expect(subject).to be true
    end

    context 'status is 401' do
      let(:response) { EasyJenkins::Api::Connection::ApiResponse.new(401, {}) }

      it 'returns true' do
        expect(subject).to be false
      end
    end
  end
end