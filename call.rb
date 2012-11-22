class Call < ActiveRecord::Base
  belongs_to :notification
  
  after_create :call_out
  
  # moving this to a delayed_job
  # after_find :check_call_status
  
  def full_name
    "#{last_name}, #{first_name}"
  end
  
  def call_out    
   
    # Configuration variables on config/initializers/twilio_settings.rb
    # APP_HOST variable on environments/development & environments/prodiction.rb
    begin
      @call = TWILIO_CLIENT.account.calls.create(
        :from => EnsSolution::Application.config.twilio_from_number,
        :to => phone_number,
        :url => "#{EnsSolution::Application.config.app_host}/caller/call/#{self.notification.id}"
      )
      
	  

      self.update_attributes(:phone_number_sid => @call.sid)
      self.check_call_status
      
    rescue StandardError => bang
      self.update_attributes(:status => bang.to_s)
      return
    end
    
  end
  handle_asynchronously :call_out, :queue => "calls", :run_at => Proc.new {|p| p.notification.delivering_at } 

  
  def check_call_status
    unless (status == "completed" || status == "failed" || phone_number_sid.nil?)
      begin
        p "Updating Status"
        @calls = TWILIO_CLIENT.accounts.get(EnsSolution::Application.config.twilio_account_sid).calls    
        self.update_attributes(:status => @calls.get(phone_number_sid).status)
      rescue
        #
      end
    else
      self.check_call_status
    end
    
  end
  handle_asynchronously :check_call_status, :queue => "status_updates", :run_at => Proc.new { 30.seconds.from_now }
  
end
