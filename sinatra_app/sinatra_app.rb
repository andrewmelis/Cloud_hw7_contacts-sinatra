require 'rubygems'
require 'sinatra'
require 'aws-sdk'


get '/' do
  erb :index
end

get '/sns' do
  erb :sns
end


get '/new_contact' do
  erb :new_contact
end





