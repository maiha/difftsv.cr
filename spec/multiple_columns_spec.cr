require "./spec_helper"

describe "Support multiple columns" do
  src1 = [["Asia", "Taipei", "8"],
          ["Asia", "Tokyo" , "9"]]

  it "uses [0] for primary key in default" do
    diff = DiffTsv::Diff.new(src1, src1)
    diff.primary_keys.should eq([0])
    diff.value_keys.should eq([1,2])
    expect_raises(DiffTsv::Halt, /Found duplicated key "Asia"/) do
      diff.execute
    end
  end

  it "respects `keys` arg for primary key" do
    diff = DiffTsv::Diff.new(src1, src1, keys: [1])
    diff.primary_keys.should eq([1])
    diff.value_keys.should eq([0,2])
    diff.execute
    diff.similarity_pct?.should eq(100)
  end

  it "accepts multiple columns for primary key" do
    diff = DiffTsv::Diff.new(src1, src1, keys: [0,1])
    diff.primary_keys.should eq([0,1])
    diff.value_keys.should eq([2])
    diff.execute
    diff.similarity_pct?.should eq(100)
  end

  it "works" do
    src1 = [["Asia", "Taipei", "8"],
            ["Asia", "Tokyo" , "9"]]
    src2 = [["Asia", "Taipei", "8"],
            ["Asia", "Tokyo" , "10"]]

    diff = DiffTsv::Diff.new(src1, src2, keys: [0,1])
    diff.execute
    diff.similarity_pct?.should eq(50)
  end
end
