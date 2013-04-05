class ActiveRecordWithoutCallbacks
  TRUE_BLOCK = proc{ true }
  
  def self.wo_callbacks(klass)
    #List of various possible callbacks.
    takes = [:_create_callbacks, :_find_callbacks, :_initialize_callbacks, :_destroy_callbacks, :_commit_callbacks, :_rollback_callbacks, :_save_callbacks, :_touch_callbacks, :_update_callbacks, :_validate_callbacks, :_validation_callbacks, ]
    
    #Array containing previous values.
    saved = []
    
    Thread.exclusive do
      takes.each do |take|
        #Store previous value for restoring later.
        saved << {
          :take => take,
          :value => klass.__send__(take)
        }
        
        #Clear all callbacks.
        klass.__send__("#{take}=", [])
        
        #Test that callbacks really was cleared.
        raise "Expected '#{take}' to be empty but it wasnt: #{klass.__send__(take)}" unless klass.__send__(take).empty?
      end
      
      klass.after_save(&TRUE_BLOCK)
      
      begin
        return yield
      ensure
        #Restore previous callbacks.
        saved.each do |save|
          klass.__send__("#{save[:take]}=", save[:value])
        end
        
        klass.after_save(&TRUE_BLOCK)
      end
    end
  end
end