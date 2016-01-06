require 'spec_helper'
require 'io_bufferio_size_shared_examples'

describe VirtFS::VIO, "(#{$fs_interface} interface)" do
  before(:all) do
    @data_dir        = VfsRealFile.join(__dir__, "data")
    @utf_8_filename  = VfsRealFile.join(@data_dir, "UTF-8-data.txt")
    @utf_16_filename = VfsRealFile.join(@data_dir, "UTF-16LE-data.txt")

    @start_marker = "START OF FILE:\n"
    @end_marker   = ":END OF FILE"
    @data1        = "0123456789"
    @data2        = "abcdefghijklmnopqrstuvwzyz\n"

    @temp_file    = Tempfile.new("VirtFS-IO")
    @temp_file.write(@start_marker)
    (0..9).each do
      @temp_file.write(@data1)
      @temp_file.write(@data2)
    end
    @temp_file.write(@end_marker)
    @temp_file.close

    @full_path  = @temp_file.path
    @file_size  = VfsRealFile.size(@full_path)

    @temp_write = Tempfile.new("VirtFS-IO")
    @temp_write.close
    @write_file_path = @temp_write.path

    @default_encoding = Encoding.default_external
    @binary_encoding  = Encoding.find("ASCII-8BIT")
  end

  before(:each) do
    reset_context

    @root      = File::SEPARATOR
    @native_fs = nativefs_class.new
    VirtFS.mount(@native_fs, @root)

    @vfile_read_obj  = VirtFS::VFile.new(@full_path, "r")
    @vfile_write_obj = VirtFS::VFile.new(@write_file_path, "w")
  end

  after(:each) do
    @vfile_read_obj.close  unless @vfile_read_obj.closed?
    @vfile_write_obj.close unless @vfile_write_obj.closed?
    VirtFS.umount(@root)
  end

  #
  # Run the set of tests for each buffer size.
  #
  buffer_test_sizes.each do |buf_sz|
    describe "#bytes - Buffer size: #{buf_sz}" do # deprecated
      before(:each) do
        @vfile_read_obj.send(:min_read_buf_sz=, buf_sz)
        @rfile_obj = VfsRealFile.new(@full_path, "r")
      end

      after(:each) do
        @rfile_obj.close
      end

      it_should_behave_like "common_bytes"
    end

    describe "#chars - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_chars"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_chars"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_chars"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_chars"
      end
    end

    describe "#each - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_each"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each"
      end
    end

    describe "#each_byte - Buffer size: #{buf_sz}" do
      context "Buffer size: #{buf_sz}" do
        before(:each) do
          @vfile_read_obj.send(:min_read_buf_sz=, buf_sz)
          @rfile_obj = VfsRealFile.new(@full_path, "r")
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_each_byte"
      end
    end

    describe "#each_char - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_each_char"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each_char"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each_char"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each_char"
      end
    end

    describe "#each_codepoint - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_each_each_codepoint"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each_each_codepoint"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_each_each_codepoint"
      end
    end

    describe "#getbyte - Buffer size: #{buf_sz}" do
      context "Buffer size: #{buf_sz}" do
        before(:each) do
          @vfile_read_obj.send(:min_read_buf_sz=, buf_sz)
          @rfile_obj = VfsRealFile.new(@full_path, "r")
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_getbyte"
      end
    end

    describe "#getc - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_getc"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_getc"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_getc"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_getc"
      end
    end

    describe "#gets - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_gets"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_gets"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_gets"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_gets"
      end
    end

    describe "#lines - Buffer size: #{buf_sz}" do  # deprecated
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_lines"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_lines"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_lines"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_lines"
      end
    end

    describe "#read - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_read"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_read"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_read"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_read"
      end
    end

    describe "#readlines - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @expected_full_read_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @rfile_obj = VfsRealFile.new(@full_path, "r")
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @rfile_obj.close
        end

        it_should_behave_like "common_readlines"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_readlines"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @expected_full_read_size = @test_file_size
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_readlines"
      end

      context "Transcode UTF-8 to UTF-16LE (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @expected_full_read_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @rfile_obj = VfsRealFile.new(@utf_8_filename, "r:UTF-8:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        after(:each) do
          @vfile_read_test_obj.close
          @rfile_obj.close
        end

        it_should_behave_like "common_readlines"
      end
    end

    describe "#ungetbyte - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)

          @char = "X"
          @bytes_for_char = @char.dup.force_encoding("ASCII-8BIT")
          @expected_return_char = @char
        end

        it_should_behave_like "common_ungetbyte"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)

          @char = "X".encode("UTF-8")
          @bytes_for_char = @char.dup.force_encoding("ASCII-8BIT")
          @expected_return_char = @char
        end

        it_should_behave_like "common_ungetbyte"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE")
          @expected_returned_encoding = Encoding.find("UTF-16LE")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)

          @char = "X".encode("UTF-16LE")
          @bytes_for_char = @char.dup.force_encoding("ASCII-8BIT")
          @expected_return_char = @char
        end

        it_should_behave_like "common_ungetbyte"
      end
    end

    describe "#ungetc - Buffer size: #{buf_sz}" do
      context "default encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = @file_size
          @vfile_read_test_obj = @vfile_read_obj
          @expected_returned_encoding = Encoding.default_external

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        it_should_behave_like "common_ungetc"
      end

      context "UTF-8 encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_8_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_8_filename, "r:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        it_should_behave_like "common_ungetc"
      end

      context "UTF-16LE encoding (buffer size: #{buf_sz})" do
        before(:each) do
          @test_file_size = VfsRealFile.size(@utf_16_filename)
          @vfile_read_test_obj = VirtFS::VFile.new(@utf_16_filename, "rb:UTF-16LE:UTF-8")
          @expected_returned_encoding = Encoding.find("UTF-8")

          @vfile_read_test_obj.send(:min_read_buf_sz=, buf_sz)
        end

        it_should_behave_like "common_ungetc"
      end
    end
  end
end
