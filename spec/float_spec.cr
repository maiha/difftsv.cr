require "./spec_helper"

describe "Support Float" do
  src1 = [["a", "1.03"]]
  src2 = [["a", "0.97"]]

  it "provides delta=0.001 in default" do
    diff = DiffTsv::Diff.new(src1, src2)
    diff.delta.should eq(0.001)
  end
  
  it "compares float values with delta" do
    diff = DiffTsv::Diff.new(src1, src2)
    diff.execute.similarity_pct.should be < 100

    diff = DiffTsv::Diff.new(src1, src2)
    diff.delta = 0.1
    diff.execute.similarity_pct.should eq(100)
  end
end
