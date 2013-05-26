require 'sinatra'
require 'sinatra/reloader' if development?
require 'aws-sdk'

AWS.config(:access_key_id => ENV['AWS_ACCESS_KEY'], :secret_access_key => ENV['AWS_SECRET_KEY'])
$s3 = AWS::S3.new()
$sdb = AWS::SimpleDB.new()



$url_base = "https://s3.amazonaws.com/melis_assignment_7/"
$domain = $sdb.domains['assignment_7']

get '/' do
  @contact_links = $s3.buckets['melis_assignment_7'].objects
  @title = "Index"
  @url_base = $url_base
  @contacts = $domain.items.select('*')
  #erb :sns
  erb :index
end

get '/sns' do
  @title = "SNS"
  erb :sns
end


get '/new_contact' do
  @title = "New Contact"
  erb :new_contact
end


helpers do

  #from http://ididitmyway.herokuapp.com/past/2010/4/25/sinatra_helpers/
  def link_to(url,text=url,opts={})
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end

end



