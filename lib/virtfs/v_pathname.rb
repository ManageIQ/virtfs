module VirtFS
  class VPathname < VfsRealPathname
    def self.getwd
      new(::Dir.getwd)
    end

    def self.pwd
      getwd
    end

    def self.glob(*args)
      return ::Dir.glob(args).collect { |p| new(p) } unless block_given?
      ::Dir.glob(*args).each { |p| yield(new(p)) }
    end

    # absolute?
    # ascend

    def atime
      ::File.atime(to_path)
    end

    # basename

    def binread(*args)
      ::File.binread(to_path, *args)
    end

    # binwrite
    # birthtime
    # blockdev?
    # chardev?
    # children
    # chmod
    # chown
    # cleanpath
    # ctime
    # delete
    # descend
    # directory?
    # dirname
    # each_child
    # each_entry
    # each_filename
    # each_line
    # empty?
    # entries
    # eql?
    # executable?
    # executable_real?
    # exist?

    def expand_path(dirstring = nil)
      return self if absolute?
      self.class.new(::File.expand_path(to_path, dirstring))
    end

    # extname

    def file?
      ::File.file?(to_path)
    end

    # find
    # fnmatch
    # fnmatch?
    # freeze
    # ftype
    # grpowned?
    # join
    # lchmod
    # lchown
    # lstat
    # make_link
    # make_symlink
    # mkdir
    # mkpath
    # mountpoint?
    # mtime
    # open
    # opendir
    # owned?
    # parent
    # pipe?

    def read(*args)
      ::File.open(to_path, "r") { |f| return f.read(*args) }
    end

    # readable?
    # readable_real?
    # readlines
    # readlink
    # realdirpath
    # realpath
    # relative?
    # relative_path_from
    # rename
    # rmdir
    # rmtree
    # root?
    # setgid?
    # setuid?
    # size
    # size?
    # socket?
    # split
    # stat
    # sticky?
    # sub
    # sub_ext
    # symlink?
    # sysopen
    # taint
    # to_path
    # to_s
    # truncate
    # unlink
    # untaint
    # utime
    # world_readable?
    # world_writable?
    # writable?
    # writable_real?
    # write
    # zero?
  end
end
