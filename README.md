# VirtFS

[![Build Status](https://travis-ci.org/ManageIQ/virtfs.svg)](https://travis-ci.org/ManageIQ/virtfs)
[![Code Climate](https://codeclimate.com/github/ManageIQ/virtfs/badges/gpa.svg)](https://codeclimate.com/github/ManageIQ/virtfs)

A virtual (pseudo) filesystem facility for Ruby.

Provides an infrastructure where instances of various filesystem **plugins** can be _mounted_ within the filesystem namespace of a Ruby process, and accessed via Ruby `File` and `Dir` classes and objects.

Typically, these **plugins** implement a filesystem access paradigm on top of various storage mechanisms and/or programmatic data generation.

**For example:** a plugin can be implemented that stores and maintains filesystem-like information in a database - say Berkeley DB - we'll call that plugin `BdbFS`, which is also the name of the Ruby class implementing the plugin. Instantiating an instance of this class will return an instance of the `BdbFS` filesystem, which can then be mounted and accessed through the **VirtFS** facility.

## Installation

Add this line to your application's Gemfile:

    gem 'virtfs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install virtfs

## Usage
### Mounting root
By default, **VirtFS** does not mount the native filesystem of the system on which the Ruby process is running. It needs to be done explicitly. This is accomplished through the use of a **plugin** that simply _wraps_ the native filsystem in a class that enables its access through **VirtFS**.

Typically, one of the first things a **VirtFS** client does, is _mount_ the native filesystem:
```ruby
require "virtfs-nativefs-thick"

# Instantiate an instance of the native filesystem.
native_fs = VirtFS::NativeFS::Thick.new

# Mount the native filesystem on root "/"
VirtFS.mount(native_fs, "/")
```
### Access

Once the native filesystem is mounted, **VirtFS** can be accessed explicitly through the `VirtFS` class, or it can be _activated_, enabling access through Ruby's `File` and `Dir` classes.

#### Explicit access
```ruby
require "virtfs-nativefs-thick"

# Instantiate an instance of the native filesystem
native_fs = VirtFS::NativeFS::Thick.new

# Mount the native filesystem on root "/"
VirtFS.mount(native_fs, "/")

VirtFS::VDir.chdir("/etc")
VirtFS::VDir.getwd        # => "/etc"

VirtFS::VDir.foreach(this_dir) do |f|
  puts f
end

# Note: this does not change the state of Ruby's standard filesystem.
Dir.getwd                 # => the original cwd of the ruby process.
```
#### Activation
```ruby
require "virtfs-nativefs-thick"

# Instantiate an instance of the native filesystem.
native_fs = VirtFS::NativeFS::Thick.new

# Mount the native filesystem on root "/"
VirtFS.mount(native_fs, "/")

VirtFS.activate!
VirtFS.activated?          # => true

# Dir and File classes now go through VirtFS.
Dir.chdir("/etc")
Dir.getwd                  # => "/etc"

Dir.foreach(this_dir) do |f|
  puts f
end

VirtFS.deactivate!
VirtFS.activated?          # => false
```
Activation can be confined to a block through the use of the `with` class method:
```ruby
VirtFS.activated?          # => false
VirtFS.with do
  VirtFS.activated?        # => true
end
VirtFS.activated?          # => false
```

### Mounting other filesystems

Let's use the, yet to be implemented, `BdbFS` plugin as an example:
```ruby
require "virtfs-nativefs-thick"
require "virtfs-bdbfs"

# The Berkeley DB file containing the filesystem data.
bdbfs_file = "/usr/me/my_bdbfs_file"

# Where to mount the BdbFS instance under the native filesystem.
bdbfs_mount_point = "/usr/me/bdbfs_root"

#
# Mount the native filesystem.
#
native_fs = VirtFS::NativeFS::Thick.new
VirtFS.mount(native_fs, "/")

#
# Instantiate a BdbFS instance and mount it.
#
bdb_fs = VirtFS::BdbFS.new(bdbfs_file)
VirtFS.mount(bdb_fs, bdbfs_mount_point)

VirtFS.with do
  Dir.chdir(bdbfs_mount_point)
  Dir.getwd                  # => "/usr/me/bdbfs_root"

  # List the files at the root of the BdbFS.
  Dir.foreach(this_dir) do |f|
    puts f
  end
end
```

## Plugins

There are two types of filesystem plugins for **VirtFS**; they are distinguished by the type of interface they present to the **VirtFS** infrastructure - the interface that **VirtFS** uses to call into the plugin.

* **Thin** interface plugins implement the minimum low-level methods required by **VirtFS**. Most of the common filesystem functionality is provided by the **VirtFS** infrastructure itself (like buffered IO and character encoding), making this type of plugin easier to implement.
* **Thick** interface plugins implement most, if not all, of the filesystem functionality within the plugin, overriding the common implementations within **VirtFS**. While these plugins require more work to implement, they do provide a measurable performance improvement.

In reality, most plugins will be of the **thin** type. More often than not, **thick** plugins will be used to interface **VirtFS** to an underlying technology that already implements the full filesystem interface. An obvious example of this is the plugin that interfaces with Ruby's native filesystem interface.

Notice in the examples above, when mounting the native filesystem on root, we used the `VirtFS::NativeFS::Thick` plugin class. This plugin passes most requests directly to the underlying Ruby filesystem implementation, bypassing the common implementations in **VirtFS**.

There is a **thin** version of this plugin: `VirtFS::NativeFS::Thin`. It only calls down into the underlying Ruby filesystem implementation for low-level operations, relying on the common functionality provided by **VirtFS** for everything else. While this plugin is less performant than its **thick** counterpart, it's extremely useful in testing the common filesystem functionality implemented within **VirtFS**. In fact the _spec_ tests for **VirtFS** are run using both **thick** and **thin** interfaces, to ensure the expected results are identical. 

## Contributing 

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
