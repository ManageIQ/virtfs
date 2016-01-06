shared_examples_for "common_bytes" do
  it "should return an enum" do
    expect(suppress_warnings { @vfile_read_obj.bytes }).to be_kind_of(Enumerator)
  end

  it "should enumerate the same bytes as the standard File#bytes" do
    rbytes = suppress_warnings { @rfile_obj.bytes.to_a }
    vbytes = suppress_warnings { @vfile_read_obj.bytes.to_a }
    expect(vbytes).to match_array(rbytes)
  end
end

shared_examples_for "common_chars" do
  it "should return an enum" do
    expect(suppress_warnings { @vfile_read_test_obj.chars }).to be_kind_of(Enumerator)
  end

  it "should enumerate the same characters as the standard File#chars" do
    rchars = suppress_warnings { @rfile_obj.chars.to_a }
    vchars = suppress_warnings { @vfile_read_test_obj.chars.to_a }
    expect(vchars).to match_array(rchars)
  end
end

shared_examples_for "common_each" do
  it "should return an enum when no block is given" do
    expect(@vfile_read_obj.each).to be_kind_of(Enumerator)
  end

  it "should return the IO object when block is given" do
    expect(@vfile_read_obj.each { true }).to eq(@vfile_read_obj)
  end

  it "should enumerate the same lines as the standard File#each" do
    expect(@vfile_read_test_obj.each.to_a).to match_array(@rfile_obj.each.to_a)
  end
end

shared_examples_for "common_each_byte" do
  it "should return an enum when no block is given" do
    expect(@vfile_read_obj.each_byte).to be_kind_of(Enumerator)
  end

  it "should return the IO object when block is given" do
    expect(@vfile_read_obj.each_byte { true }).to eq(@vfile_read_obj)
  end

  it "should enumerate the same bytes as the standard File#each_byte" do
    expect(@vfile_read_obj.each_byte.to_a).to match_array(@rfile_obj.each_byte.to_a)
  end
end

shared_examples_for "common_each_char" do
  it "should return an enum when no block is given" do
    expect(@vfile_read_test_obj.each_char).to be_kind_of(Enumerator)
  end

  it "should return the IO object when block is given" do
    expect(@vfile_read_test_obj.each_char { true }).to eq(@vfile_read_test_obj)
  end

  it "should enumerate the same lines as the standard File#each_char" do
    expect(@vfile_read_test_obj.each_char.to_a).to match_array(@rfile_obj.each_char.to_a)
  end
end

shared_examples_for "common_each_each_codepoint" do
  it "should return an enum when no block is given" do
    expect(@vfile_read_test_obj.each_codepoint).to be_kind_of(Enumerator)
  end

  it "should return the IO object when block is given" do
    expect(@vfile_read_test_obj.each_codepoint { true }).to eq(@vfile_read_test_obj)
  end

  it "should enumerate the same values as the standard IO#each_codepoint" do
    expect(@vfile_read_test_obj.each_codepoint.to_a).to match_array(@rfile_obj.each_codepoint.to_a)
  end
end

shared_examples_for "common_getbyte" do
  it "should return a Fixnum" do
    expect(@vfile_read_obj.getbyte).to be_kind_of(Fixnum)
  end

  it "should return nil when at EOF" do
    @vfile_read_obj.read
    expect(@vfile_read_obj.getbyte).to be_nil
  end

  it "should read all the bytes in the file" do
    byte_count = 0
    byte_count += 1 until @vfile_read_obj.getbyte.nil?
    expect(byte_count).to eq(@file_size)
  end

  it "should return the same values as the standard IO#getbyte" do
    while (vrv = @vfile_read_obj.getbyte)
      expect(vrv).to eq(@rfile_obj.getbyte)
    end
    expect(@rfile_obj.getbyte).to be_nil
  end
end

shared_examples_for "common_getc" do
  it "should return a character of the expected encoding" do
    expect(@vfile_read_test_obj.getc.encoding).to eq(@expected_returned_encoding)
  end

  it "should return nil when at EOF" do
    @vfile_read_test_obj.read
    expect(@vfile_read_test_obj.getc).to be_nil
  end

  it "should read all the characters in the file" do
    byte_count = 0
    while (vrv = @vfile_read_test_obj.getc)
      byte_count += vrv.bytesize
    end
    expect(byte_count).to eq(@expected_full_read_size)
  end

  it "should return the same values as the standard IO#getc" do
    while (vrv = @vfile_read_test_obj.getc)
      expect(vrv).to eq(@rfile_obj.getc)
    end
    expect(@rfile_obj.getc).to be_nil
  end
end

shared_examples_for "common_gets" do
  it "should read an entire line by default" do
    rv = @vfile_read_test_obj.gets
    expect(rv[-1]).to eq($/.encode(rv.encoding))
  end

  it "should read the entire file - given a nil separator" do
    rv = @vfile_read_test_obj.gets(nil)
    expect(rv.bytesize).to eq(@expected_full_read_size)
  end

  it "should return nil when at EOF" do
    @vfile_read_test_obj.gets(nil)
    rv = @vfile_read_test_obj.gets
    expect(rv).to be_nil
  end

  it "should read the same lines as the standard File#gets" do
    while (vrv = @vfile_read_test_obj.gets)
      expect(vrv).to eq(@rfile_obj.gets)
    end
    expect(@rfile_obj.gets).to be_nil
  end
end

shared_examples_for "common_lines" do
  it "should return an enum" do
    expect(suppress_warnings { @vfile_read_test_obj.lines }).to be_kind_of(Enumerator)
  end

  it "should enumerate the same lines as the standard File#lines" do
    rlines = suppress_warnings { @rfile_obj.lines.to_a }
    vlines = suppress_warnings { @vfile_read_test_obj.lines.to_a }
    expect(vlines).to match_array(rlines)
  end
end

shared_examples_for "common_read" do
  it "should read the number of bytes requested - when EOF not reached" do
    read_size = @file_size / 2
    rv = @vfile_read_test_obj.read(read_size)
    expect(rv.bytesize).to eq(read_size)
  end

  it "should read data into buffer, when supplied" do
    read_size = @file_size / 2
    rbuf = ""
    rv = @vfile_read_test_obj.read(read_size, rbuf)
    expect(rv).to eq(rbuf)
  end

  it "should read the whole file by default" do
    rv = @vfile_read_test_obj.read
    expect(rv.bytesize).to eq(@expected_full_read_size)
  end

  it "should read at most, the size of the file" do
    rv = @vfile_read_test_obj.read(@test_file_size + 100)
    expect(rv.bytesize).to eq(@test_file_size) # given length, not transcoded
  end

  it "should return nil when attempting to read length at EOF" do
    @vfile_read_test_obj.read(@test_file_size)
    expect(@vfile_read_test_obj.read(@test_file_size)).to be_nil
  end

  it "should return empty string when attempting to read to EOF at EOF" do
    @vfile_read_test_obj.read(@test_file_size)
    expect(@vfile_read_test_obj.read).to eq("")
  end

  it "should read the same data as the standard File#read" do
    read_size = 20
    loop do
      rv1 = @vfile_read_test_obj.read(read_size)
      rv2 = @rfile_obj.read(read_size)
      expect(rv1).to eq(rv2)
      break if rv1.nil? || rv1.empty?
    end
  end

  it "should return a string of expected encoding when reading whole file" do
    rv = @vfile_read_test_obj.read
    expect(rv.encoding).to eq(@expected_returned_encoding)
  end

  it "should return a string of 'binary_encoding' when reading partial file" do
    rv = @vfile_read_test_obj.read(10)
    expect(rv.encoding).to eq(@binary_encoding)
  end
end

shared_examples_for "common_readlines" do
  it "should return an Array" do
    expect(@vfile_read_obj.readlines).to be_kind_of(Array)
  end

  it "should enumerate the same lines as the standard File#readlines" do
    expect(@vfile_read_test_obj.readlines).to match_array(@rfile_obj.readlines)
  end
end

shared_examples_for "common_ungetbyte" do
  it "should return nil" do
    expect(@vfile_read_test_obj.ungetbyte(@bytes_for_char)).to be_nil
  end

  it "should return a string in the expected encoding" do
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)
    expect(@vfile_read_test_obj.getc.encoding).to eq(@expected_returned_encoding)
  end

  it "should work at the beginning of the file - with getc" do
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)
    rv = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(rv).to eql(@char.encode(@default_encoding))
  end

  it "should work at the beginning of the file - with gets" do
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)
    rv = @vfile_read_test_obj.gets[0].encode(@default_encoding)
    expect(rv).to eq(@char.encode(@default_encoding))
  end

  it "should work at EOF" do
    @vfile_read_test_obj.read
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)
    rv = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(rv.index(@char.encode(@default_encoding))).to eq(0)
  end

  it "should return the character in next getc" do
    char0 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char0).to_not eq(@char)

    @vfile_read_test_obj.rewind
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)

    char1 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char1).to eq(@char.encode(@default_encoding))
    char1 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char1).to eq(char0)
  end

  it "should return the character in next gets" do
    char0 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char0).to_not eq(@char)

    @vfile_read_test_obj.rewind
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)

    str = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(str[0]).to eq(@char.encode(@default_encoding))
    expect(str[1]).to eq(char0)
  end

  it "should work within the body of the file" do
    offset = @test_file_size
    @vfile_read_test_obj.pos = offset
    @vfile_read_test_obj.ungetbyte(@bytes_for_char)
    rv = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(rv.index(@char.encode(@default_encoding))).to eq(0)
  end
end

shared_examples_for "common_ungetc" do
  it "should return nil" do
    expect(@vfile_read_test_obj.ungetc("X")).to be_nil
  end

  it "should return a string in the expected encoding" do
    char = "X"
    @vfile_read_test_obj.ungetc(char)
    expect(@vfile_read_test_obj.getc.encoding).to eq(@expected_returned_encoding)
  end

  it "should work at the beginning of the file - with getc" do
    char = "X"
    @vfile_read_test_obj.ungetc(char)
    rv = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(rv).to eql(char)
  end

  it "should work at the beginning of the file - with gets" do
    char = "X"
    @vfile_read_test_obj.ungetc(char)
    rv = @vfile_read_test_obj.gets[0].encode(@default_encoding)
    expect(rv).to eq(char)
  end

  it "should work with a string at the beginning of the file - with gets" do
    char = "HELLO"
    @vfile_read_test_obj.ungetc(char)
    rv = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(rv.index(char)).to eq(0)
  end

  it "should work at EOF" do
    @vfile_read_test_obj.read
    char = "HELLO"
    @vfile_read_test_obj.ungetc(char)
    rv = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(rv.index(char)).to eq(0)
  end

  it "should return the character in next getc" do
    char = "X"
    char0 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char0).to_not eq(char)

    @vfile_read_test_obj.rewind
    @vfile_read_test_obj.ungetc(char)

    char1 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char1).to eq(char)
    char1 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char1).to eq(char0)
  end

  it "should return the character in next gets" do
    char = "X"
    char0 = @vfile_read_test_obj.getc.encode(@default_encoding)
    expect(char0).to_not eq(char)

    @vfile_read_test_obj.rewind
    @vfile_read_test_obj.ungetc(char)

    str = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(str[0]).to eq(char)
    expect(str[1]).to eq(char0)
  end

  it "should work within the body of the file" do
    offset = @test_file_size
    @vfile_read_test_obj.pos = offset
    char = "HELLO"
    @vfile_read_test_obj.ungetc(char)
    rv = @vfile_read_test_obj.gets.encode(@default_encoding)
    expect(rv.index(char)).to eq(0)
  end
end
