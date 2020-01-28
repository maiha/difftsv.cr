require "./spec_helper"

describe "Support similarity" do
  describe "#similarity_pct?" do
    src1 = [["a", "1"], ["b", "2"]]
    src2 = [["a", "1"], ["b", "3"]]

    it "returns 100% for the same data" do
      diff = DiffTsv::Diff.new(src1, src1).execute
      diff.similarity_pct?.should eq(100)
      diff.result_code.should eq(0)
    end

    it "returns 50% when half data match" do
      diff = DiffTsv::Diff.new(src1, src2).execute
      diff.similarity_pct?.should eq(50)
      diff.result_code.should eq(1)
    end

    it "returns nil when not executed yet" do
      diff = DiffTsv::Diff.new(src1, src2)
      diff.similarity_pct?.should eq(nil)
      diff.result_code.should eq(2)
    end
  end
end
