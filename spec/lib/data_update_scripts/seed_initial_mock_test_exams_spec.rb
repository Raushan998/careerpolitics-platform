require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260529100700_seed_initial_mock_test_exams.rb",
)

describe DataUpdateScripts::SeedInitialMockTestExams do
  it "creates the curated, published, global exams" do
    expect { described_class.new.run }.to change(Exam, :count).by(described_class::EXAMS.size)

    exams = Exam.all
    expect(exams).to all(have_attributes(published: true, subforem_id: nil))
  end

  it "is idempotent" do
    described_class.new.run
    expect { described_class.new.run }.not_to change(Exam, :count)
  end

  it "generates slugs from the exam names" do
    described_class.new.run
    expect(Exam.exists?(slug: "upsc-civil-services-prelims", subforem_id: nil)).to be(true)
  end
end
