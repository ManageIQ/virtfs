module VirtFS
  class Stat
    include Comparable

    ATTR_ACCESSORS = %w(
      atime
      blksize
      blockdev?
      blocks
      chardev?
      ctime
      dev
      dev_major
      dev_minor
      directory?
      executable?
      executable_real?
      file?
      ftype
      gid
      grpowned?
      ino
      inspect
      mode
      mtime
      nlink
      owned?
      pipe?
      rdev
      rdev_major
      rdev_minor
      readable?
      readable_real?
      setgid?
      setuid?
      size
      size?
      socket?
      sticky?
      symlink?
      uid
      world_readable?
      world_writable?
      writable?
      writable_real?
      zero?
    )

    def self.iv_name(name)
      name = name.chomp('?') if name.end_with?('?')
      "@#{name}"
    end

    ATTR_ACCESSORS.each { |aa| class_eval("def #{aa}; #{iv_name(aa)}; end") }

    def initialize(obj)
      if obj.is_a?(VfsRealFile::Stat)
        stat_init(obj)
      else
        hash_init(obj)
      end
    end

    def <=>(other)
      return -1 if mtime < other.mtime
      return  1 if mtime > other.mtime
      0
    end

    private

    def stat_init(obj)
      ATTR_ACCESSORS.each do |aa|
        next unless obj.respond_to?(aa)
        instance_variable_set(iv_name(aa), obj.send(aa))
      end
    end

    def hash_init(obj)
      ATTR_ACCESSORS.each do |aa|
        next unless aa.key?(aa)
        instance_variable_set(iv_name(aa), obj.send(aa))
      end
    end

    def iv_name(name)
      self.class.iv_name(name)
    end
  end
end
