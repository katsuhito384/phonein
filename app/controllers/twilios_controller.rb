class TwiliosController < ApplicationController
  
  skip_before_filter :authenticate_admin! 
  
  BASE_URL = "http://phonein.herokuapp.com/twilios"
  
  def incoming
    # Get client by phone number
    client_phone = params['From'][2..params['From'].size]
    @client = Client.find_by_phone(client_phone)
    
    # Welcom message.
    # "Welcome to #{@client.name}'s residence."
    # Ask agent to identy him/herself.
    # "Please enter your code"
    if @client.nil? 
      render :action => "no_client.xml.builder"
    else
      @post_to = BASE_URL + "/verify?client_id=#{@client.id}"
      render :action => "incoming.xml.builder", :layout => false
    end
  end
  
  def verify
    @client = Client.find(params[:client_id])    
    @agent = Agent.find_by_code(params['Digits'])
    
    if @agent.nil?
      @post_to = BASE_URL + "/verify?client_id=#{@client.id}"
      render :action => "no_agent.xml.builder"
      return
    else
      if @agent.checked_in?(@client.id) 
        @message = "You have already checked in."
      else
        @agent.check_in(@client.id)
        @message = "Now you are checked in."
      end
    end 

    @post_to = BASE_URL + "/direction?agent_id=#{@agent.id}&client_id=#{@client.id}"
    render :action => "direction.xml.builder", :layout => false
  end
        
  def direction    
    @client = Client.find(params[:client_id])
    @agent = Agent.find(params[:agent_id])
    @message = @client.task_list
    @post_to = BASE_URL + "/direction?agent_id=#{@agent.id}&client_id=#{@client.id}"
    
    # 1 to hear the tasks again, 2 to check out, 3 to hang up.
    if params['Digits'] == '1'
      render :action => "direction.xml.builder", :layout => false
    elsif params['Digits'] == '2'
      @agent.check_out(@client.id)
      @goodbye_message = "Thank you for your service today."
      render :action => 'goodbye.xml.builder', :layout => false
    elsif params['Digits'] == '3'
      @message = "Yang is the most awesome guy ever - both personally and professionally. He is pretty sexy, too."
      render :action => 'direction.xml.builder', :layout => false
    elsif params['Digits'] == '4'
      @goodbye_message = "Have a great day."
      render :action => 'goodbye.xml.builder', :layout => false
    end
  end
    
end
