require 'pathname'

VfsRealDir       = ::Dir
VfsRealFile      = ::File
VfsRealIO        = ::IO
VfsRealPathname  = ::Pathname

require_relative 'virtfs/version.rb'
require_relative 'virtfs/exception.rb'
require_relative 'virtfs/context.rb'
require_relative 'virtfs/context_manager.rb'
require_relative 'virtfs/file_modes_and_options.rb'
require_relative 'virtfs/context_switch_class_methods.rb'
require_relative 'virtfs/find_class_methods.rb'
require_relative 'virtfs/activation.rb'
require_relative 'virtfs/delegate_module.rb'
require_relative 'virtfs/stat.rb'
require_relative 'virtfs/thin_dir_delegator.rb'
require_relative 'virtfs/thin_file_delegator.rb'
# require_relative 'virtfs/kernel'
require_relative 'virtfs/v_pathname.rb'

module VirtFS
  @activated = false

  extend Activation
  extend DelegateModule
  extend ContextSwitchClassMethods
  extend FindClassMethods
end

require_relative 'virtfs/dir_instance_delegate.rb'
require_relative 'virtfs/file_instance_delegate.rb'
require_relative 'virtfs/io_instance_delegate.rb'
require_relative 'virtfs/v_io.rb'
require_relative 'virtfs/v_file.rb'
require_relative 'virtfs/v_dir.rb'
