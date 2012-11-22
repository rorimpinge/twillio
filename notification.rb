class Notification < ActiveRecord::Base
  has_many :notification_contacts
  has_many :contacts, :through => :notification_contacts
  
  has_many :notification_titles
  has_many :titles, :through => :notification_titles
  
  has_many :notification_groups
  has_many :groups, :through => :notification_groups
  
  has_many :notification_companies
  has_many :companies, :through => :notification_companies
  
  has_many :calls
  

  
  validates_presence_of :message, :delivering_at
  
  before_create :contacts_list
  after_create :create_calls

  
  def name 
    return "blank"
  end
  
  def contacts_list
    list_of_contacts = []
    
    contacts.each{|contact| list_of_contacts << contact } unless self.contacts.empty?
    self.companies.each{|company| company.contacts.each{|contact| list_of_contacts << contact }} unless self.companies.empty?
    self.groups.each{|group| group.contacts.each{|contact| list_of_contacts << contact }} unless self.groups.empty?
    self.titles.each{|title| title.contacts.each{|contact| list_of_contacts << contact }} unless self.titles.empty?
    
    return list_of_contacts.empty? ? false : list_of_contacts
    
  end
  
  def create_calls    
    # Create the call
    contacts_list.each do |the_contact|
      
      new_call = Call.new
      # Values
      new_call.notification = self
      new_call.first_name = the_contact.first_name
      new_call.last_name = the_contact.last_name
      new_call.phone_number = the_contact.phone_number
      new_call.email = the_contact.email
      new_call.company_name = the_contact.company.name unless the_contact.company.nil?
      new_call.group_name = the_contact.group.name unless the_contact.group.nil?
      new_call.title_name = the_contact.title.name unless the_contact.title.nil?
      new_call.save
      
      if the_contact.phone_number_secondary && the_contact.phone_number_secondary != ""
        new_second_call = Call.new
        new_second_call = new_call.clone
        new_second_call.phone_number = the_contact.phone_number_secondary
        new_second_call.save
      end
      
    end
    
	end
	
	
  
end
