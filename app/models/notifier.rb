class Notifier < ActionMailer::Base
def signup_thanks(user,from,subject,host)
  # Email header info MUST be added here
  @recipients = user.email
  @from = from
  @subject = subject

  # Email body substitutions go here
  @body["website"] = host
  @body["login"] = user.login
  @body["password"] = user.password
  @body["activation_code"] = user.activation_code
end
end
