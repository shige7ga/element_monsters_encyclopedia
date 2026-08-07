require "rails_helper"

RSpec.describe "Solid Queue", type: :model do
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue

    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  it "primary DBを使用する" do
    expect(SolidQueue::Record.connection_db_config.name).to eq("primary")
  end

  it "ActiveStorage::AnalyzeJobをenqueueできる" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image"),
      filename: "analysis.png",
      content_type: "image/png"
    )

    expect { blob.analyze_later }
      .to change { SolidQueue::Job.where(class_name: "ActiveStorage::AnalyzeJob").count }
      .by(1)
  end
end
