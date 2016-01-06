require 'spec_helper'

describe VirtFS, " - context manager instance operations (#{$fs_interface} interface)" do
  before(:all) do
    @root = File::SEPARATOR
  end

  before(:each) do
    reset_context
    @my_context_manager = VirtFS.context_manager.current
  end

  describe "#[]" do
    it "should return nil given an non-existent key" do
      expect(@my_context_manager[:not_a_key]).to be nil
    end

    it "should have a default context" do
      expect(@my_context_manager[:default]).to be_kind_of(VirtFS::Context)
    end
  end

  describe "#[]=" do
    it "should raise an ArgumentError when not passed a VirtFS::Context object" do
      expect do
        @my_context_manager[:new_key] = "not a context object"
      end.to raise_exception(ArgumentError, "Context must be a VirtFS::Context object")
    end

    it "should raise an ArgumentError when attempting to change the default context" do
      expect do
        @my_context_manager[:default] = VirtFS::Context.new
      end.to raise_exception(ArgumentError, "Cannot change the default context")
    end

    it "should return the assigned context on success" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
    end

    it "should raise an RuntimeError when attempting to change existing value" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
      expect do
        @my_context_manager[:new_key] = VirtFS::Context.new
      end.to raise_exception(RuntimeError, "Context for given key already exists")
    end

    it "should raise an RuntimeError when attempting assign context to more than one key" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key1] = new_context).to eq(new_context)
      expect do
        @my_context_manager[:new_key2] = new_context
      end.to raise_exception(RuntimeError, /Context already assigned to key:/)
    end

    it "should delete a context by assigning nil" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
      expect(@my_context_manager[:new_key] = nil).to be nil
      expect(@my_context_manager[:new_key]).to be nil
    end

    it "should permit re-assignment of deleted entry" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
      expect do
        @my_context_manager[:new_key] = VirtFS::Context.new
      end.to raise_exception(RuntimeError, "Context for given key already exists")
      expect(@my_context_manager[:new_key] = nil).to be nil
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
    end

    it "should permit assignment to new key after deletion from old key" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key1] = new_context).to eq(new_context)
      expect do
        @my_context_manager[:new_key2] = new_context
      end.to raise_exception(RuntimeError, /Context already assigned to key:/)
      expect(@my_context_manager[:new_key1] = nil).to be nil
      expect(@my_context_manager[:new_key2] = new_context).to eq(new_context)
    end
  end

  describe "#current_context and #current_context=" do
    it "should return the default context by default" do
      expect(@my_context_manager.current_context).to eq(@my_context_manager[:default])
    end

    it "should raise RuntimeError when key doesn't exist" do
      expect do
        @my_context_manager.current_context = :new_key
      end.to raise_exception(RuntimeError, "Context for given key doesn't exist")
    end

    it "should set the current_context to a new value" do
      new_context = VirtFS::Context.new
      expect(@my_context_manager[:new_key] = new_context).to eq(new_context)
      expect(@my_context_manager.current_context).to eq(@my_context_manager[:default])
      @my_context_manager.current_context = :new_key
      expect(@my_context_manager.current_context).to eq(@my_context_manager[:new_key])
    end
  end

  describe "#activated?" do
    after(:each) do
      @my_context_manager.deactivate! if @my_context_manager.activated?
    end

    it "should return false by default" do
      expect(@my_context_manager.activated?).to be false
    end

    it "should return true when activated" do
      @my_context_manager.activate!(:default)
      expect(@my_context_manager.activated?).to be true
    end
  end

  describe "#activate!" do
    after(:each) do
      @my_context_manager.deactivate! if @my_context_manager.activated?
    end

    it "should raise RuntimeError when key doesn't exist" do
      expect do
        @my_context_manager.activate!(:new_key)
      end.to raise_exception(RuntimeError, "Context for given key doesn't exist")
    end

    it "should raise RuntimeError when already activated" do
      @my_context_manager.activate!(:default)
      expect do
        @my_context_manager.activate!(:default)
      end.to raise_exception(RuntimeError, "Context already activated")
    end

    it "should cause activated? to return true" do
      expect(@my_context_manager.activated?).to be false
      @my_context_manager.activate!(:default)
      expect(@my_context_manager.activated?).to be true
    end

    it "should return the pre-activation context" do
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      prev_context = @my_context_manager.current_context
      expect(new_context).not_to eq(prev_context)
      expect(@my_context_manager.activate!(:new_key)).to eq(prev_context)
    end

    it "should change the current context" do
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      expect(@my_context_manager[:default]).not_to eq(new_context)
      expect(@my_context_manager.current_context).to eq(@my_context_manager[:default])
      @my_context_manager.activate!(:new_key)
      expect(@my_context_manager.current_context).to eq(new_context)
    end
  end

  describe "#deactivate!" do
    it "should raise RuntimeError when not activated" do
      expect do
        @my_context_manager.deactivate!
      end.to raise_exception(RuntimeError, "Context not activated")
    end

    it "should cause activated? to return false" do
      expect(@my_context_manager.activated?).to be false
      @my_context_manager.activate!(:default)
      expect(@my_context_manager.activated?).to be true
      @my_context_manager.deactivate!
      expect(@my_context_manager.activated?).to be false
    end

    it "should return the pre-deactivated context" do
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      @my_context_manager.activate!(:new_key)
      expect(@my_context_manager.deactivate!).to eq(new_context)
    end

    it "should restore original context" do
      context0 = @my_context_manager.current_context
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      @my_context_manager.activate!(:new_key)
      expect(@my_context_manager.current_context).not_to eq(context0)
      @my_context_manager.deactivate!
      expect(@my_context_manager.current_context).to eq(context0)
    end
  end

  describe "#with" do
    it "should raise RuntimeError when key doesn't exist" do
      expect do
        @my_context_manager.with(:new_key) {}
      end.to raise_exception(RuntimeError, "Context for given key doesn't exist")
    end

    it "should raise RuntimeError when already activated" do
      @my_context_manager.activate!(:default)
      expect do
        @my_context_manager.with(:default) {}
      end.to raise_exception(RuntimeError, "Context already activated")
    end

    it "should cause activated? to return true within the block" do
      expect(@my_context_manager.activated?).to be false
      @my_context_manager.with(:default) do
        expect(@my_context_manager.activated?).to be true
      end
      expect(@my_context_manager.activated?).to be false
    end

    it "should save and restore original context" do
      context0 = @my_context_manager.current_context
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      @my_context_manager.with(:new_key) do
        expect(@my_context_manager.current_context).not_to eq(context0)
        expect(@my_context_manager.current_context).to eq(new_context)
      end
      expect(@my_context_manager.current_context).to eq(context0)
    end
  end

  describe "#without" do
    it "should not change the current context when not activated" do
      context0 = @my_context_manager.current_context
      @my_context_manager.without do
        expect(@my_context_manager.current_context).to eq(context0)
      end
      expect(@my_context_manager.current_context).to eq(context0)
    end

    it "should deactivate the context for the duration of the block" do
      context0 = @my_context_manager.current_context
      new_context = VirtFS::Context.new
      @my_context_manager[:new_key] = new_context
      @my_context_manager.with(:new_key) do
        expect(@my_context_manager.current_context).not_to eq(context0)
        expect(@my_context_manager.current_context).to eq(new_context)

        @my_context_manager.without do
          expect(@my_context_manager.current_context).to eq(context0)
        end

        expect(@my_context_manager.current_context).to eq(new_context)
      end
      expect(@my_context_manager.current_context).to eq(context0)
    end
  end
end
