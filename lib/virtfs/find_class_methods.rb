module VirtFS
  module FindClassMethods
    #
    # Modified version of Find.find:
    # - Accepts only a single path.
    # - Can be restricted by depth - optimization for glob searches.
    # - Will work with VirtFS, even when it's not active.
    #
    def find(path, max_depth = nil)
      raise SystemCallError.new(path, Errno::ENOENT::Errno) unless VirtFS::VFile.exist?(path)
      block_given? || (return enum_for(__method__, path, max_depth))

      depths = [0]
      paths  = [path.dup]

      while (file = paths.shift)
        depth = depths.shift
        catch(:prune) do
          yield file.dup.taint
          begin
            s = VirtFS::VFile.lstat(file)
          rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
            next
          end
          if s.directory?
            next if depth + 1 > max_depth if max_depth
            begin
              fs = VirtFS::VDir.entries(file)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
              next
            end
            fs.sort!
            fs.reverse_each do |f|
              next if f == "." || f == ".."
              f = VfsRealFile.join(file, f)
              paths.unshift f.untaint
              depths.unshift depth + 1
            end
          end
        end
      end
    end

    def prune
      throw :prune
    end

    GLOB_CHARS = '*?[{'
    def glob_str?(str)
      str.gsub(/\\./, "X").count(GLOB_CHARS) != 0
    end

    def dir_and_glob(glob_pattern)
      glob_path = Pathname.new(glob_pattern)

      if glob_path.absolute?
        search_path    = VfsRealFile::SEPARATOR
        specified_path = VfsRealFile::SEPARATOR
      else
        search_path    = dir_getwd
        specified_path = nil
      end

      components = glob_path.each_filename.to_a
      while (comp = components.shift)
        if glob_str?(comp)
          components.unshift(comp)
          break
        end
        search_path = VfsRealFile.join(search_path, comp)
        if specified_path
          specified_path = VfsRealFile.join(specified_path, comp)
        else
          specified_path = comp
        end
      end
      return normalize_path(search_path), specified_path, VfsRealFile.join(components)
    end

    def glob_depth(glob_pattern)
      path_components = Pathname(glob_pattern).each_filename.to_a
      return nil if path_components.include?('**')
      path_components.length
    end
  end
end
