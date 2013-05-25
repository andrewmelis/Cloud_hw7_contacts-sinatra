#Andrew Melis
#Cloud Computing, Spring 2013
#Assignment 1b

#require File.expand_path(File.dirname(__FILE__) + '/config')
require 'rubygems'
require 'yaml'
require 'aws-sdk'

#a few indents for visual purposes
puts "\n\n\n\n\n\n\n\n\n\n"
puts "WELCOME TO ANDREW'S AMAZING S3 CONTACTS MANAGER\n\n\n"

puts "Please view the readme if you haven't yet done so.\n"

# get an instance of the S3 interface using the environment variables
AWS.config(:access_key_id => ENV['AWS_ACCESS_KEY'], :secret_access_key => ENV['AWS_SECRET_KEY'])
s3 = AWS::S3.new

def mainUI(bucket)
  puts "\nwhat would you like to do next?"
  puts "-if you'd like to see a list of all the contacts in #{bucket.name}, enter 1"
  puts "-if you'd like to delete a contact in #{bucket.name}, enter 2"
  puts "-if you'd like create a new contact, enter 3" 
  puts "-if you'd like to edit a contact, enter 4"
  puts "-if you'd like to change buckets, enter 5"
  puts "-if you'd like to exit, enter 6\n"
end


#option 1
#method to list all contents of a bucket
def listContents(bucket)
  if !bucket.empty?
    puts "fetching contents of bucket called #{bucket.name}"

    #display all bucket objects
    bucket.objects.each do |obj|
      puts obj.key
    end

  else
    puts "bucket called #{bucket.name} contains no objects!"
  end
end

#option 2
def deleteContact(bucket)
  obj_name = gets.chomp!
  obj = bucket.objects[obj_name]
  if obj.exists?
    obj.delete
    return true
  else 
    puts "that contact doesn't exist in #{bucket.name}!"
    return false
  end
end

#option 3
#create new contact, generate html page, store it in the bucket
def newContact(bucket)
  arr = getInput

  generateFile(arr)

  sendFile(arr,bucket)
end

#helper function for newContact
#get input for new contact
#returns array of strings
def getInput
  puts "enter the new information for your contact as follows, with a single space separating each item:"
  puts "<first name> <last name> <phone number>"
  #some kind of error checking?
  return gets.chomp!.split
end

#helper function for newContact
#takes in array with first name, last name, and phone number
#creates a new html file named using that array
#returns a the file for use in sending file up to amazon
def generateFile(arr)
  require 'fileutils'		    #load fileutils module to enable copying behavior

  #copy template_contacts and rename using array
  FileUtils.cp 'template_contact.html', "./contacts/#{arr[0].downcase}_#{arr[1].downcase}_#{arr[2].downcase}.html"

  #append the following lines representing the next row of html table
  f = open("./contacts/#{arr[0].downcase}_#{arr[1].downcase}_#{arr[2]}.html", "a") do |f|
    f << "<td>#{arr[0].capitalize}<td/>\n"
    f << "<td>#{arr[1].capitalize}<td/>\n"
    f << "<td>#{arr[2]}<td/>\n"
    f << "</tr>\n</table>"
  end
end

#helper function for newContact
def sendFile(arr,bucket)
  f = open("./contacts/#{arr[0].downcase}_#{arr[1].downcase}_#{arr[2]}.html", 'r')
  bucket.objects["#{arr[0].downcase}_#{arr[1].downcase}_#{arr[2]}.html"].write(f)
end

#option 4
#basically hotwiring delete and create functions to make edit function
def editContact(bucket)
  puts "please enter the exact filename of the contact you'd like to edit"
  if deleteContact(bucket)
    newContact(bucket)
  end
end

#option 5 
#also called at beginning to set initial bucket
def changeBucket(s3)
  
  puts "\nenter a bucket name. if it doesn't exist yet, i'll make it for you"
  bucket_name = gets.chomp!   #chomp cuts last character off IFF it's a newline character

  bucket = s3.buckets[bucket_name]

  #check if bucket exists
  if bucket.exists?
    puts "bucket called #{bucket.name} exists!"

    #check if have access
    if !testBucketAccess(bucket)
      puts "you don't have access to #{bucket.name}"
      puts "please input a bucket to which you have access or a valid new bucket name"
      bucket = changeBucket(s3)
    end
  else
    puts "creating new bucket"	#called #{bucket.name}"
    bucket = s3.buckets.create(bucket.name)
  end
  return bucket
end

#test if have access to bucket
def testBucketAccess(bucket)
  begin
    listContents(bucket)    #any method that would raise a permission error
    return true
  rescue 
    return false
  end
end

#main UI method
def userInterface(bucket, s3)
  cmd = 0
  local_bucket = bucket
  while cmd !=7
    mainUI(local_bucket)
    cmd = gets.chomp!.to_i

    if cmd == 1
      listContents(local_bucket)
    elsif cmd == 2
      puts "\nfor your convenience, will display all contacts in current bucket"
      listContents(local_bucket)
      puts "\nenter the exact filename of the contact you'd like to delete" #placed here to enable reuse of create/delete functions
      deleteContact(local_bucket)
    elsif cmd == 3 
      newContact(local_bucket)
    elsif cmd == 4 
      puts "\nfor your convenience, will display all contacts in current bucket"
      listContents(local_bucket)
      editContact(local_bucket)
    elsif cmd == 5
      local_bucket = changeBucket(s3)
    elsif cmd == 6 
      puts "\nGoodbye!\n"
      break
    end

  end
end

bucket = changeBucket(s3)
userInterface(bucket, s3)

