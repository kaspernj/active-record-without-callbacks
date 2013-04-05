#This class can disable all callbacks for a model, run a block and then re-enable all callbacks.
class ActiveRecordWithoutCallbacks
  TRUE_BLOCK = proc{ true }
  
  def self.wo_callbacks(klass)
    #Callback-types that we will clear or recompile.
    callbacks = [:create, :find, :initialize, :destroy, :commit, :rollback, :save, :touch, :update, :validate, :validation]
    
    #Callback-types.
    callback_types = [:before, :after]
    
    #List of various possible callbacks.
    takes = [:_create_callbacks, :_find_callbacks, :_initialize_callbacks, :_destroy_callbacks, :_commit_callbacks, :_rollback_callbacks, :_save_callbacks, :_touch_callbacks, :_update_callbacks, :_validate_callbacks, :_validation_callbacks, ]
    
    #Array containing previous values.
    saved = []
    
    #Run inside exclusive, so we are sure no other thread suffers from the horrible hack, that we are about to do.
    Thread.exclusive do
      callbacks.each do |callback|
        #Method-name for callbacks to reset.
        callbacks_method_name = "_#{callback}_callbacks"
        
        #Store previous value for restoring later.
        saved << {
          :callbacks_method_name => callbacks_method_name,
          :value => klass.__send__(callbacks_method_name).clone
        }
        
        #Clear all callbacks.
        klass.__send__("#{callbacks_method_name}").clear
        
        #Test that callbacks really was cleared.
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
        return yield
      ensure
        #Restore previous callbacks.
        saved.each do |save|
          klass.__send__("#{save[:callbacks_method_name]}=", save[:value])
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