require 'spec_helper'

describe VirtFS, " - context manager class operations (#{$fs_interface} interface)" do
  before(:all) do
    @root = File::SEPARATOR
  end

  before(:each) do
    reset_context
  end

  context "Before any FS operations" do
    describe "context_manager.managers" do
      it "should return a Hash" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash).to be_kind_of(Hash)
      end

      it "should return an empty hash before any operations" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash.empty?).to be true
      end
    end

    describe "context_manager.current!" do
      it "should raise VirtFS::NoContextError when there's no context for the ThreadGroup" do
        expect do
          VirtFS.context_manager.current!
        end.to raise_exception(VirtFS::NoContextError, /No filesystem context defined for thread group:/)
      end
    end

    describe "context!" do
      it "should raise VirtFS::NoContextError when there's no context for the ThreadGroup" do
        expect do
          VirtFS.context!
        end.to raise_exception(VirtFS::NoContextError, /No filesystem context defined for thread group:/)
      end
    end

    describe "context_manager.current" do
      it "should return a ContextManager bound to our ThreadGroup" do
        cmanager = VirtFS.context_manager.current
        expect(cmanager.thread_group).to eq(Thread.current.group)
      end
    end

    describe "context" do
      it "should return a Context bound to our ThreadGroup" do
        context = VirtFS.context
        expect(context).to be_kind_of(VirtFS::Context)
      end
    end

    describe "context_manager.manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return nil when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.manager_for(ThreadGroup.new)).to be nil
      end

      it "should return nil when given our ThreadGroup" do
        expect(VirtFS.context_manager.manager_for(Thread.current.group)).to be nil
      end
    end

    describe "context_manager.new_manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.new_manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return a ContextManager when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.new_manager_for(ThreadGroup.new)).to be_kind_of(VirtFS::ContextManager)
      end

      it "should return a ContextManager when given our ThreadGroup" do
        expect(VirtFS.context_manager.new_manager_for(Thread.current.group)).to be_kind_of(VirtFS::ContextManager)
      end

      it "should return a ContextManager bound to a new ThreadGroup" do
        tgroup   = ThreadGroup.new
        cmanager = VirtFS.context_manager.new_manager_for(tgroup)
        expect(cmanager.thread_group).to eq(tgroup)
      end

      it "should return a ContextManager bound to our ThreadGroup" do
        tgroup   = Thread.current.group
        cmanager = VirtFS.context_manager.new_manager_for(tgroup)
        expect(cmanager.thread_group).to eq(tgroup)
      end

      it "new ContextManager should be retrievable by ThreadGroup" do
        tgroup   = Thread.current.group
        cmanager = VirtFS.context_manager.new_manager_for(tgroup)
        expect(VirtFS.context_manager.manager_for(tgroup)).to eq(cmanager)
      end
    end

    describe "context_manager.remove_manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.remove_manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return nil when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.remove_manager_for(ThreadGroup.new)).to be nil
      end

      it "should return nil when given our ThreadGroup" do
        expect(VirtFS.context_manager.remove_manager_for(Thread.current.group)).to be nil
      end
    end
  end

  context "With root mounted by main thread/thread_group" do
    before(:each) do
      @native_fs = nativefs_class.new
      VirtFS.mount(@native_fs, @root)
    end

    describe "context_manager.managers" do
      it "should return a Hash" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash).to be_kind_of(Hash)
      end

      it "should return a Hash with one entry" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash.length).to eq(1)
      end

      it "should contain a ContextManager" do
        cm = VirtFS.context_manager.managers.values.first
        expect(cm).to be_kind_of(VirtFS::ContextManager)
      end

      it "should contain a ContextManager bound to the current ThreadGroup" do
        cm = VirtFS.context_manager.managers.values.first
        expect(cm.thread_group).to eq(Thread.current.group)
      end
    end

    describe "context_manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return nil when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.manager_for(ThreadGroup.new)).to be nil
      end

      it "should return a ContextManager when given our ThreadGroup" do
        cm = VirtFS.context_manager.manager_for(Thread.current.group)
        expect(cm).to be_kind_of(VirtFS::ContextManager)
        expect(cm.thread_group).to eq(Thread.current.group)
      end
    end
  end

  context "With root mounted by different thread groups" do
    before(:each) do
      @thread_groups = [ThreadGroup.new, ThreadGroup.new, ThreadGroup.new]
      @thread_groups.each_with_index do |tg, i|
        tg.add(Thread.current)
        native_fs = nativefs_class.new
        native_fs.name = "FS-#{i}"
        VirtFS.mount(native_fs, @root)
      end
    end

    after(:each) do
      ThreadGroup::Default.add(Thread.current)
    end

    describe "context_manager.managers" do
      it "should return a Hash" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash).to be_kind_of(Hash)
      end

      it "should return a hash of the expected length" do
        cm_hash = VirtFS.context_manager.managers
        expect(cm_hash.length).to eq(@thread_groups.length)
      end

      it "hash should contain one entry per thread group" do
        cm_hash = VirtFS.context_manager.managers
        @thread_groups.each do |tg|
          cm = cm_hash[tg]
          expect(cm).to be_kind_of(VirtFS::ContextManager)
          expect(cm.thread_group).to eq(tg)
        end
      end
    end

    describe "context_manager.manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return nil when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.manager_for(ThreadGroup.new)).to be nil
      end

      it "should return a ContextManager when given each ThreadGroup" do
        @thread_groups.each do |tg|
          cm = VirtFS.context_manager.manager_for(tg)
          expect(cm).to be_kind_of(VirtFS::ContextManager)
          expect(cm.thread_group).to eq(tg)
        end
      end
    end

    describe "context_manager.remove_manager_for" do
      it "should raise ArgumentError when not passed a ThreadGroup object" do
        expect do
          VirtFS.context_manager.remove_manager_for(nil)
        end.to raise_exception(ArgumentError, "value must be a ThreadGroup object")
      end

      it "should return nil when given an unused ThreadGroup" do
        expect(VirtFS.context_manager.remove_manager_for(ThreadGroup.new)).to be nil
      end

      it "should return nil when given our ThreadGroup" do
        @thread_groups.each do |tg|
          cm = VirtFS.context_manager.manager_for(tg)
          expect(cm).to be_kind_of(VirtFS::ContextManager)
          expect(VirtFS.context_manager.remove_manager_for(tg)).to eq(cm)
          expect(VirtFS.context_manager.manager_for(tg)).to be nil
        end
      end
    end
  end
end
