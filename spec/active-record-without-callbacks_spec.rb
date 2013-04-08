require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActiveRecordWithoutCallbacks" do
  it "doesnt fail" do
    #The following code tests disabled callbacks.
    
    #Deal.after_create do
    #  raise "Create WTF!?"
    #end
    
    #Deal.after_save do
    #  raise "Save WTF!?"
    #end
    
    Deal.before_create do
      raise "Before create!"
    end
    
    Deal.after_create do
      raise "After create!"
    end
    
    ActiveRecordWithoutCallbacks.wo_callbacks(Deal) do
      deal = Deal.new(:legacy_id => 999999)
      
      #puts deal.methods.sort
      
      deal.save! :validate => false
      puts "Deal created as expected"
    end
    
    deal = Deal.new(:legacy_id => 999999999)
    
    deal.save! :validate => false
    puts "Second deal creation did not fail."
  end
end
