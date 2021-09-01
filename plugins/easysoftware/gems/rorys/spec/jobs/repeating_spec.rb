RSpec.describe Rorys::Task, type: :jobs do

  let(:sidekiq_crons) { Struct.new(:count).new(0) }

  class MyJob < Rorys.task

    def perform
    end

  end

  def enqueued_to_rake?
    Rorys::EnqueuedTask.count > 0
  end

  def enqueued_to_sidekiq?
    sidekiq_crons.count > 0
  end

  def prepare(environment:, sidekiq:)
    allow(Rorys).to receive(:queuing_environment?).and_return(environment)
    allow(Rorys).to receive(:sidekiq_available?).and_return(sidekiq)
    allow(Rorys).to receive(:use_for_rake_task?).and_return(true)

    Rorys::EnqueuedTask.delete_all

    sidekiq_crons.count = 0

    allow(Sidekiq::Cron::Job).to receive(:create) do |*|
      sidekiq_crons.count += 1
    end
  end

  it 'out of schdule environment' do
    prepare(environment: false, sidekiq: true)

    MyJob.repeat('every 1m').perform_later

    expect(enqueued_to_rake?).to be_falsey
    expect(enqueued_to_sidekiq?).to be_falsey


    prepare(environment: false, sidekiq: false)

    MyJob.repeat('every 1m').perform_later

    expect(enqueued_to_rake?).to be_falsey
    expect(enqueued_to_sidekiq?).to be_falsey
  end

  it 'with rake task' do
    prepare(environment: true, sidekiq: false)

    MyJob.repeat('every 1m').perform_later

    expect(enqueued_to_rake?).to be_truthy
    expect(enqueued_to_sidekiq?).to be_falsey
  end

  it 'with sidekiq' do
    prepare(environment: true, sidekiq: true)

    MyJob.repeat('every 1m').perform_later

    expect(enqueued_to_rake?).to be_falsey
    expect(enqueued_to_sidekiq?).to be_truthy
  end

end
