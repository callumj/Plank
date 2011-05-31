class Post < DirtyDocument
  attr_accessor :contents
  attr_accessor :created_at_i

   belongs_to :forum_thread
   belongs_to :user
  
  def initialize
    super()
  end
  
  def created_at=(val)
    self.created_at_i = val.to_i
  end
  
  def created_at
    Time.at(self.created_at_i.to_i)
  end
  
  def to_json(*a)
    {"contents" => @contents, "created_at" => @created_at_i, "user" => user.name, "easy_date" => created_at.strftime("%I:%M%p %d/%m/%Y"), "restore_at" => @restore_time.to_i}.to_json(*a)
  end
  
  def email_users()
    all_emails = self.forum_thread.all_emails
    all_emails.delete(self.user.email) #remove own email
    
    new_email = Mail.new
    
    new_email.body "#{self.user.name} posted a reply\r\n---------------------\r\n#{self.contents}"
    new_email['from'] = self.user.email
    new_email.subject = "Re: #{self.forum_thread.title}"
    all_emails.each do |email|
      puts "Sending email to #{email}"
      new_email[:to] = email
      
      new_email.delivery_method :sendmail
      
      new_email.deliver!
    end
  end
end