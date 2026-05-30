require "rails_helper"

RSpec.describe Exam, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:subforem).optional }
    it { is_expected.to have_many(:mock_test_sessions).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:exam) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:subforem_id) }
    it { is_expected.to validate_inclusion_of(:difficulty).in_array(described_class::DIFFICULTIES).allow_nil }
  end

  describe "slug generation" do
    it "generates a slug from the name on create" do
      exam = create(:exam, name: "SSC CGL Tier I", slug: nil)
      expect(exam.slug).to eq("ssc-cgl-tier-i")
    end

    it "does not overwrite an explicitly provided slug" do
      exam = create(:exam, slug: "custom-slug")
      expect(exam.slug).to eq("custom-slug")
    end

    it "appends a counter when the slug collides within the same subforem scope" do
      create(:exam, name: "UPSC Prelims", slug: nil, subforem_id: nil)
      duplicate = create(:exam, name: "UPSC Prelims", slug: nil, subforem_id: nil)
      expect(duplicate.slug).to eq("upsc-prelims-1")
    end

    it "allows the same slug across different subforems" do
      subforem = create(:subforem)
      create(:exam, name: "UPSC Prelims", slug: nil, subforem_id: nil)
      scoped = create(:exam, name: "UPSC Prelims", slug: nil, subforem_id: subforem.id)
      expect(scoped.slug).to eq("upsc-prelims")
    end
  end

  describe "scopes" do
    describe ".published" do
      it "returns only published exams" do
        published = create(:exam, published: true)
        create(:exam, :unpublished)
        expect(described_class.published).to contain_exactly(published)
      end
    end

    describe ".ordered" do
      it "orders by position then name" do
        second = create(:exam, position: 2, name: "Beta")
        first = create(:exam, position: 1, name: "Alpha")
        expect(described_class.ordered.to_a).to eq([first, second])
      end
    end

    describe ".from_subforem" do
      it "includes exams for the given subforem and global exams" do
        subforem = create(:subforem)
        global = create(:exam, subforem_id: nil)
        scoped = create(:exam, subforem_id: subforem.id)
        create(:exam, subforem_id: create(:subforem).id)

        expect(described_class.from_subforem(subforem.id)).to contain_exactly(global, scoped)
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      exam = build(:exam, slug: "my-exam")
      expect(exam.to_param).to eq("my-exam")
    end
  end
end
