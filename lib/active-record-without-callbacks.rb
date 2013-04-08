#This class can disable all callbacks for a model, run a block and then re-enable all callbacks.
class ActiveRecordWithoutCallbacks
  TRUE_BLOCK = proc{ true }
  
  def self.wo_callbacks(args)
    klass = args[:class]
    @debug = args[:debug]
    
    #Callback-types that we will clear or recompile.
    callbacks = [:create, :find, :initialize, :destroy, :commit, :rollback, :save, :touch, :update, :validate, :validation]
    callback_types = [:before, :after]
    previous_values = []
    
    #List of various possible callbacks.
    takes = [:_create_callbacks, :_find_callbacks, :_initialize_callbacks, :_destroy_callbacks, :_commit_callbacks, :_rollback_callbacks, :_save_callbacks, :_touch_callbacks, :_update_callbacks, :_validate_callbacks, :_validation_callbacks]
    
    #Run inside exclusive, so we are sure no other thread suffers from the horrible hack, that we are about to do.
    Thread.exclusive do
      callbacks.each do |callback|
        puts "Disabling callbacks for '#{callback}'." if @debug
        
        #Method-name for callbacks to reset.
        callbacks_method_name = "_#{callback}_callbacks"
        
        #Store previous value for restoring later.
        previous_values << {
          :callbacks_method_name => callbacks_method_name,
          :value => klass.__send__(callbacks_method_name).clone
        }
        
        #Clear all callbacks.
        puts "Clearing callbacks in '#{callbacks_method_name}'." if @debug
        klass.__send__(callbacks_method_name).clear
        
        #Test that callbacks really was cleared.
        puts "Checking if everything is okay for '#{callback}'." if @debug
        raise "Expected '#{callbacks_method_name}' to be empty but it wasnt: #{klass.__send__(callbacks_method_name)}" unless klass.__send__(callbacks_method_name).empty?
        
        #Trick ActiveRecord to recompile callbacks.
        callback_types.each do |callback_type|
          method_name = "#{callback_type}_#{callback}"
          
          if klass.respond_to?(method_name)
            klass.__send__(method_name, &TRUE_BLOCK)
          end
        end
      end
      
      begin
        #Run the given block, now that all callbacks are disabled.
        puts "Yielding block." if @debug
        return yield
      ensure
        puts "Restoring callbacks." if @debug
        
        #Restore previous callbacks.
        previous_values.each do |previous_value|
          method_name = "#{previous_value[:callbacks_method_name]}="
          klass.__send__(method_name, previous_value[:value])
        end
        
        #Trick ActiveRecord to recompile old callbacks.
        callbacks.each do |callback|
          callback_types.each do |callback_type|
            method_name = "#{callback_type}_#{callback}"
            
            if klass.respond_to?(method_name)
              klass.__send__(method_name, &TRUE_BLOCK)
            end
          end
        end
      end
    end
  end
end