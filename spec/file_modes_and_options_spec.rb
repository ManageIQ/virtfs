require 'spec_helper'

#
# *args --> mode="r" <,permission> <,options>
#           mode       --> String or Integer
#           permission --> Integer
#           options    --> Hash
#
# 1 arg:  <mode | options>
# 2 args: mode, <permissions | options>
# 3 args: mode, permissions, options
#
# mode string --> file-mode[:external-encoding[:internal-encoding]]
#
# file-mode mapped to binary:
#     "r"  --> File::RDONLY
#     "r+" --> File::RDWR
#     "w"  --> File::WRONLY | File::TRUNC  | File::CREAT
#     "w+" --> File::RDWR   | File::TRUNC  | File::CREAT
#     "a"  --> File::WRONLY | File::APPEND | File::CREAT
#     "a+" --> File::RDWR   | File::APPEND | File::CREAT
#
# Options:
#     :autoclose          => If false, the underlying file will not be closed
#                            when this I/O object is finalized.
#
#     :binmode            => Opens the IO object in binary mode if true (same as mode: "b").
#
#     :encoding           => Specifies both external and internal encodings
#                            as "external:internal" (same format used in mode parameter).
#
#     :external_encoding  => Specifies the external encoding.
#
#     :internal_encoding  => Specifies the internal encoding.
#
#     :mode               => Specifies what would have been the mode parameter.
#
#     :textmode           => Open the file in text mode (the default).
#
describe VirtFS::FileModesAndOptions, "(#{$fs_interface} interface)" do
  before(:each) do
    reset_context
  end

  context "modes" do
    context "default" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new
      end

      describe "mode_bits" do
        it "should return File::RDONLY" do
          expect(@fmo.mode_bits).to eq(File::RDONLY)
        end
      end

      describe "external_encoding" do
        it "should return Encoding.default_external" do
          expect(@fmo.external_encoding).to eq(Encoding.default_external)
        end
      end

      describe "internal_encoding" do
        it "should return Encoding.default_internal" do
          expect(@fmo.internal_encoding).to eq(Encoding.default_internal)
        end
      end

      describe "permissions" do
        it "should return nil" do
          expect(@fmo.permissions).to eq(nil)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return true" do
          expect(@fmo.rdonly?).to be true
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "default + binmode = 'b'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("b")
      end

      describe "mode_bits" do
        it "should return File::RDONLY" do
          expect(@fmo.mode_bits).to eq(File::RDONLY)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return true" do
          expect(@fmo.binmode?).to be true
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return true" do
          expect(@fmo.rdonly?).to be true
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "read only = 'r'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("r")
      end

      describe "mode_bits" do
        it "should return File::RDONLY" do
          expect(@fmo.mode_bits).to eq(File::RDONLY)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return true" do
          expect(@fmo.rdonly?).to be true
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "read only + binmode = 'rb'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("rb")
      end

      describe "mode_bits" do
        it "should return File::RDONLY" do
          expect(@fmo.mode_bits).to eq(File::RDONLY)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return true" do
          expect(@fmo.binmode?).to be true
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return true" do
          expect(@fmo.rdonly?).to be true
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "read write = 'r+'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("r+")
      end

      describe "mode_bits" do
        it "should return File::RDWR" do
          expect(@fmo.mode_bits).to eq(File::RDWR)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "read write + binmode = 'r+b'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("r+b")
      end

      describe "mode_bits" do
        it "should return File::RDWR" do
          expect(@fmo.mode_bits).to eq(File::RDWR)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return true" do
          expect(@fmo.binmode?).to be true
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "write only, truncate, create = 'w'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("w")
      end

      describe "mode_bits" do
        it "should return (File::WRONLY | File::TRUNC  | File::CREAT)" do
          expect(@fmo.mode_bits).to eq(File::WRONLY | File::TRUNC  | File::CREAT)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return true" do
          expect(@fmo.create?).to be true
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return true" do
          expect(@fmo.trunc?).to be true
        end
      end

      describe "wronly?" do
        it "should return true" do
          expect(@fmo.wronly?).to be true
        end
      end
    end

    context "read write, truncate, create = 'w+'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("w+")
      end

      describe "mode_bits" do
        it "should return (File::RDWR   | File::TRUNC  | File::CREAT)" do
          expect(@fmo.mode_bits).to eq(File::RDWR   | File::TRUNC  | File::CREAT)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return true" do
          expect(@fmo.create?).to be true
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return true" do
          expect(@fmo.trunc?).to be true
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "write only, append, create = 'a'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("a")
      end

      describe "mode_bits" do
        it "should return (File::WRONLY | File::APPEND | File::CREAT)" do
          expect(@fmo.mode_bits).to eq(File::WRONLY | File::APPEND | File::CREAT)
        end
      end

      describe "append?" do
        it "should return true" do
          expect(@fmo.append?).to be true
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return true" do
          expect(@fmo.create?).to be true
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return false" do
          expect(@fmo.rdwr?).to be false
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return true" do
          expect(@fmo.wronly?).to be true
        end
      end
    end

    context "read write, append, create = 'a+'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("a+")
      end

      describe "mode_bits" do
        it "should return (File::RDWR   | File::APPEND | File::CREAT)" do
          expect(@fmo.mode_bits).to eq(File::RDWR   | File::APPEND | File::CREAT)
        end
      end

      describe "append?" do
        it "should return true" do
          expect(@fmo.append?).to be true
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return true" do
          expect(@fmo.create?).to be true
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end

    context "with encoding" do
      context "external encoding" do
        before(:each) do
          @fmo = VirtFS::FileModesAndOptions.new("r+:ascii-8bit")
        end

        it "should set the external encoding to a value other than the default" do
          new_encoding = Encoding.find("ascii-8bit")
          expect(new_encoding).not_to eq(Encoding.default_external)
          expect(@fmo.external_encoding).to eq(new_encoding)
        end

        describe "mode_bits" do
          it "should return File::RDWR" do
            expect(@fmo.mode_bits).to eq(File::RDWR)
          end
        end

        describe "append?" do
          it "should return false" do
            expect(@fmo.append?).to be false
          end
        end

        describe "binmode?" do
          it "should return false" do
            expect(@fmo.binmode?).to be false
          end
        end

        describe "create?" do
          it "should return false" do
            expect(@fmo.create?).to be false
          end
        end

        describe "excl?" do
          it "should return false" do
            expect(@fmo.excl?).to be false
          end
        end

        describe "noctty?" do
          it "should return false" do
            expect(@fmo.noctty?).to be false
          end
        end

        describe "nonblock?" do
          it "should return false" do
            expect(@fmo.nonblock?).to be false
          end
        end

        describe "rdonly?" do
          it "should return false" do
            expect(@fmo.rdonly?).to be false
          end
        end

        describe "rdwr?" do
          it "should return true" do
            expect(@fmo.rdwr?).to be true
          end
        end

        describe "trunc?" do
          it "should return false" do
            expect(@fmo.trunc?).to be false
          end
        end

        describe "wronly?" do
          it "should return false" do
            expect(@fmo.wronly?).to be false
          end
        end
      end

      context "internal encoding" do
        before(:each) do
          @fmo = VirtFS::FileModesAndOptions.new("r+::utf-8")
        end

        it "should set the internal encoding to a value other than the default" do
          new_encoding = Encoding.find("utf-8")
          expect(new_encoding).not_to eq(Encoding.default_internal)
          expect(@fmo.internal_encoding).to eq(new_encoding)
        end

        describe "mode_bits" do
          it "should return File::RDWR" do
            expect(@fmo.mode_bits).to eq(File::RDWR)
          end
        end

        describe "append?" do
          it "should return false" do
            expect(@fmo.append?).to be false
          end
        end

        describe "binmode?" do
          it "should return false" do
            expect(@fmo.binmode?).to be false
          end
        end

        describe "create?" do
          it "should return false" do
            expect(@fmo.create?).to be false
          end
        end

        describe "excl?" do
          it "should return false" do
            expect(@fmo.excl?).to be false
          end
        end

        describe "noctty?" do
          it "should return false" do
            expect(@fmo.noctty?).to be false
          end
        end

        describe "nonblock?" do
          it "should return false" do
            expect(@fmo.nonblock?).to be false
          end
        end

        describe "rdonly?" do
          it "should return false" do
            expect(@fmo.rdonly?).to be false
          end
        end

        describe "rdwr?" do
          it "should return true" do
            expect(@fmo.rdwr?).to be true
          end
        end

        describe "trunc?" do
          it "should return false" do
            expect(@fmo.trunc?).to be false
          end
        end

        describe "wronly?" do
          it "should return false" do
            expect(@fmo.wronly?).to be false
          end
        end
      end

      context "external and internal encoding" do
        before(:each) do
          @fmo = VirtFS::FileModesAndOptions.new("r+:ascii-8bit:utf-8")
        end

        it "should set the external and internal encodings to a values other than the default" do
          new_external_encoding = Encoding.find("ascii-8bit")
          expect(new_external_encoding).not_to eq(Encoding.default_external)
          new_internal_encoding = Encoding.find("utf-8")
          expect(new_internal_encoding).not_to eq(Encoding.default_internal)
          expect(@fmo.external_encoding).to eq(new_external_encoding)
          expect(@fmo.internal_encoding).to eq(new_internal_encoding)
        end

        describe "mode_bits" do
          it "should return File::RDWR" do
            expect(@fmo.mode_bits).to eq(File::RDWR)
          end
        end

        describe "append?" do
          it "should return false" do
            expect(@fmo.append?).to be false
          end
        end

        describe "binmode?" do
          it "should return false" do
            expect(@fmo.binmode?).to be false
          end
        end

        describe "create?" do
          it "should return false" do
            expect(@fmo.create?).to be false
          end
        end

        describe "excl?" do
          it "should return false" do
            expect(@fmo.excl?).to be false
          end
        end

        describe "noctty?" do
          it "should return false" do
            expect(@fmo.noctty?).to be false
          end
        end

        describe "nonblock?" do
          it "should return false" do
            expect(@fmo.nonblock?).to be false
          end
        end

        describe "rdonly?" do
          it "should return false" do
            expect(@fmo.rdonly?).to be false
          end
        end

        describe "rdwr?" do
          it "should return true" do
            expect(@fmo.rdwr?).to be true
          end
        end

        describe "trunc?" do
          it "should return false" do
            expect(@fmo.trunc?).to be false
          end
        end

        describe "wronly?" do
          it "should return false" do
            expect(@fmo.wronly?).to be false
          end
        end
      end
    end
  end

  context "options" do
    context "modes" do
      context "read write + binmode = :mode => 'r+b'" do
        before(:each) do
          @fmo = VirtFS::FileModesAndOptions.new(:mode => "r+b")
        end

        describe "mode_bits" do
          it "should return File::RDWR" do
            expect(@fmo.mode_bits).to eq(File::RDWR)
          end
        end

        describe "append?" do
          it "should return false" do
            expect(@fmo.append?).to be false
          end
        end

        describe "binmode?" do
          it "should return true" do
            expect(@fmo.binmode?).to be true
          end
        end

        describe "create?" do
          it "should return false" do
            expect(@fmo.create?).to be false
          end
        end

        describe "excl?" do
          it "should return false" do
            expect(@fmo.excl?).to be false
          end
        end

        describe "noctty?" do
          it "should return false" do
            expect(@fmo.noctty?).to be false
          end
        end

        describe "nonblock?" do
          it "should return false" do
            expect(@fmo.nonblock?).to be false
          end
        end

        describe "rdonly?" do
          it "should return false" do
            expect(@fmo.rdonly?).to be false
          end
        end

        describe "rdwr?" do
          it "should return true" do
            expect(@fmo.rdwr?).to be true
          end
        end

        describe "trunc?" do
          it "should return false" do
            expect(@fmo.trunc?).to be false
          end
        end

        describe "wronly?" do
          it "should return false" do
            expect(@fmo.wronly?).to be false
          end
        end
      end
    end

    context "binmode" do
      context "read write + binmode = :binmode => true, :mode => 'r+'" do
        before(:each) do
          @fmo = VirtFS::FileModesAndOptions.new(:binmode => true, :mode => "r+")
        end

        describe "mode_bits" do
          it "should return File::RDWR" do
            expect(@fmo.mode_bits).to eq(File::RDWR)
          end
        end

        describe "append?" do
          it "should return false" do
            expect(@fmo.append?).to be false
          end
        end

        describe "binmode?" do
          it "should return true" do
            expect(@fmo.binmode?).to be true
          end
        end

        describe "create?" do
          it "should return false" do
            expect(@fmo.create?).to be false
          end
        end

        describe "excl?" do
          it "should return false" do
            expect(@fmo.excl?).to be false
          end
        end

        describe "noctty?" do
          it "should return false" do
            expect(@fmo.noctty?).to be false
          end
        end

        describe "nonblock?" do
          it "should return false" do
            expect(@fmo.nonblock?).to be false
          end
        end

        describe "rdonly?" do
          it "should return false" do
            expect(@fmo.rdonly?).to be false
          end
        end

        describe "rdwr?" do
          it "should return true" do
            expect(@fmo.rdwr?).to be true
          end
        end

        describe "trunc?" do
          it "should return false" do
            expect(@fmo.trunc?).to be false
          end
        end

        describe "wronly?" do
          it "should return false" do
            expect(@fmo.wronly?).to be false
          end
        end
      end
    end

    context "external_encoding" do
      it "should set the external encoding to a value other than the default" do
        new_encoding = Encoding.find("ascii-8bit")
        expect(new_encoding).not_to eq(Encoding.default_external)
        fmo = VirtFS::FileModesAndOptions.new(:external_encoding => "ascii-8bit", :mode => "r+")
        expect(fmo.external_encoding).to eq(new_encoding)
      end
    end

    context "internal_encoding" do
      it "should set the internal encoding to a value other than the default" do
        new_encoding = Encoding.find("utf-8")
        expect(new_encoding).not_to eq(Encoding.default_internal)
        fmo = VirtFS::FileModesAndOptions.new(:internal_encoding => "utf-8", :mode => "r+")
        expect(fmo.internal_encoding).to eq(new_encoding)
      end
    end

    context "encoding" do
      it "should set the external encoding to a value other than the default" do
        new_encoding = Encoding.find("ascii-8bit")
        expect(new_encoding).not_to eq(Encoding.default_external)
        fmo = VirtFS::FileModesAndOptions.new(:encoding => "ascii-8bit", :mode => "r+")
        expect(fmo.external_encoding).to eq(new_encoding)
        expect(fmo.internal_encoding).to eq(Encoding.default_internal)
      end

      it "should set the internal encoding to a value other than the default" do
        new_encoding = Encoding.find("utf-8")
        expect(new_encoding).not_to eq(Encoding.default_internal)
        fmo = VirtFS::FileModesAndOptions.new(:encoding => ":utf-8", :mode => "r+")
        expect(fmo.internal_encoding).to eq(new_encoding)
        expect(fmo.external_encoding).to eq(Encoding.default_external)
      end

      it "should set the external and internal encodings to a values other than the default" do
        new_external_encoding = Encoding.find("ascii-8bit")
        expect(new_external_encoding).not_to eq(Encoding.default_external)
        new_internal_encoding = Encoding.find("utf-8")
        expect(new_internal_encoding).not_to eq(Encoding.default_internal)
        fmo = VirtFS::FileModesAndOptions.new(:encoding => "ascii-8bit:utf-8", :mode => "r+")
        expect(fmo.external_encoding).to eq(new_external_encoding)
        expect(fmo.internal_encoding).to eq(new_internal_encoding)
      end
    end

    context "textmode" do
    end
  end

  context "permissions" do
    it "should set permissions when specified after mode" do
      permissions = 0755
      fmo = VirtFS::FileModesAndOptions.new("r", permissions)
      expect(fmo.permissions).to eq(permissions)
    end

    it "should set permissions when specified after mode and before options" do
      permissions = 0755
      fmo = VirtFS::FileModesAndOptions.new("r", permissions, :binmode => true)
      expect(fmo.permissions).to eq(permissions)
    end
  end

  #
  # Test arg combinations.
  #

  context "mode, permissions" do
    context "read write = 'r+' with permissions = 0755" do
      before(:each) do
        @permissions = 0755
        @fmo = VirtFS::FileModesAndOptions.new("r+", @permissions)
      end

      it "should set permissions accordingly" do
        expect(@fmo.permissions).to eq(@permissions)
      end

      describe "mode_bits" do
        it "should return File::RDWR" do
          expect(@fmo.mode_bits).to eq(File::RDWR)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end
  end

  context "mode, options" do
    context "read write = 'r+' with options: :encoding => 'ascii-8bit:utf-8'" do
      before(:each) do
        @fmo = VirtFS::FileModesAndOptions.new("r+", :encoding => "ascii-8bit:utf-8")
      end

      it "should set the external and internal encodings to a values other than the default" do
        new_external_encoding = Encoding.find("ascii-8bit")
        expect(new_external_encoding).not_to eq(Encoding.default_external)
        new_internal_encoding = Encoding.find("utf-8")
        expect(new_internal_encoding).not_to eq(Encoding.default_internal)
        expect(@fmo.external_encoding).to eq(new_external_encoding)
        expect(@fmo.internal_encoding).to eq(new_internal_encoding)
      end

      describe "mode_bits" do
        it "should return File::RDWR" do
          expect(@fmo.mode_bits).to eq(File::RDWR)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end
  end

  context "mode, permissions, options" do
    context "read write = 'r+' with permissions = 0755 and ,options = :encoding => 'ascii-8bit:utf-8'" do
      before(:each) do
        @permissions = 0755
        @fmo = VirtFS::FileModesAndOptions.new("r+", @permissions, :encoding => "ascii-8bit:utf-8")
      end

      it "should set permissions accordingly" do
        expect(@fmo.permissions).to eq(@permissions)
      end

      it "should set the external and internal encodings to a values other than the default" do
        new_external_encoding = Encoding.find("ascii-8bit")
        expect(new_external_encoding).not_to eq(Encoding.default_external)
        new_internal_encoding = Encoding.find("utf-8")
        expect(new_internal_encoding).not_to eq(Encoding.default_internal)
        expect(@fmo.external_encoding).to eq(new_external_encoding)
        expect(@fmo.internal_encoding).to eq(new_internal_encoding)
      end

      describe "mode_bits" do
        it "should return File::RDWR" do
          expect(@fmo.mode_bits).to eq(File::RDWR)
        end
      end

      describe "append?" do
        it "should return false" do
          expect(@fmo.append?).to be false
        end
      end

      describe "binmode?" do
        it "should return false" do
          expect(@fmo.binmode?).to be false
        end
      end

      describe "create?" do
        it "should return false" do
          expect(@fmo.create?).to be false
        end
      end

      describe "excl?" do
        it "should return false" do
          expect(@fmo.excl?).to be false
        end
      end

      describe "noctty?" do
        it "should return false" do
          expect(@fmo.noctty?).to be false
        end
      end

      describe "nonblock?" do
        it "should return false" do
          expect(@fmo.nonblock?).to be false
        end
      end

      describe "rdonly?" do
        it "should return false" do
          expect(@fmo.rdonly?).to be false
        end
      end

      describe "rdwr?" do
        it "should return true" do
          expect(@fmo.rdwr?).to be true
        end
      end

      describe "trunc?" do
        it "should return false" do
          expect(@fmo.trunc?).to be false
        end
      end

      describe "wronly?" do
        it "should return false" do
          expect(@fmo.wronly?).to be false
        end
      end
    end
  end

  #
  # Error handling.
  #

  context "errors" do
    it "should raise ArgumentError when third arg is not a hash" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("r+", 0755, true)
      end.to raise_error(
        ArgumentError, "wrong number of arguments (4 for 1..3)"
      )
    end

    it "should raise ArgumentError when external encoding specified twice" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("r+:ascii-8bit", 0755, :external_encoding => "ascii-8bit")
      end.to raise_error(
        ArgumentError, "encoding specified twice"
      )
    end

    it "should raise ArgumentError when internal encoding specified twice" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("r+::ascii-8bit", 0755, :internal_encoding => "ascii-8bit")
      end.to raise_error(
        ArgumentError, "encoding specified twice"
      )
    end

    it "should raise ArgumentError when given invalid access mode" do
      mode_str = "z+"
      expect do
        @fmo = VirtFS::FileModesAndOptions.new(mode_str)
      end.to raise_error(
        ArgumentError, "invalid access mode #{mode_str}"
      )
    end

    it "should raise ArgumentError when binmode specified twice" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("rb", :binmode => true)
      end.to raise_error(
        ArgumentError, "binmode specified twice"
      )
    end

    it "should raise ArgumentError when mode specified twice" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("rb", :mode => "rb")
      end.to raise_error(
        ArgumentError, "mode specified twice"
      )
    end

    it "should raise ArgumentError when both binmode and textmode are specified" do
      expect do
        @fmo = VirtFS::FileModesAndOptions.new("rb", :textmode => true)
      end.to raise_error(
        ArgumentError, "binmode and textmode are mutually exclusive"
      )
    end
  end
end
