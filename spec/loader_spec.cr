require "./spec_helper"

private def path
  File.join(__DIR__, "../tmp/loader.tsv")
end

class DiffTsv::Loader
  describe "DiffTsv::Loader#load" do
    context "(CsvStrategy)" do
      it "parses when simple data" do
        Pretty::File.write(path, %Q(a\t1))
        loader = Loader.new(path, "csv")
        loader.load.should eq([["a", "1"]])
      end

      it "raises when double quoted data" do
        expect_raises(Exception, /Expecting comma/) do
          Pretty::File.write(path, %Q("a"xxx\t1))
          loader = Loader.new(path, "csv")
          loader.load.should eq([["a", "1"]])
        end
      end
    end
    
    context "(DonkeyStrategy)" do
      it "parses when simple data" do
        Pretty::File.write(path, %Q(a\t1))
        loader = Loader.new(path, "donkey")
        loader.load.should eq([["a", "1"]])
      end

      it "parses when double quoted data" do
        Pretty::File.write(path, %Q("a"xxx\t1))
        loader = Loader.new(path, "donkey")
        loader.load.should eq([[%Q("a"xxx), "1"]])
      end
    end
  end
end
