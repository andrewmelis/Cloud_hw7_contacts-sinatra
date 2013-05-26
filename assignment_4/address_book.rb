#Andrew Melis
#Cloud Computing, Spring 2013
#Assignment 1b

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'securerandom'

#a few indents for visual purposes
puts "\n\n\n\n\n\n\n\n\n\n"
puts "WELCOME TO ANDREW'S AMAZING SDB CONTACTS MANAGER\n\n\n"

puts "Please view the readme if you haven't yet done so.\n"

# get an instance of the SimpleDB interface using the environment variables
AWS.config(:access_key_id => ENV['AWS_ACCESS_KEY'], :secret_access_key => ENV['AWS_SECRET_KEY'])
$sdb = AWS::SimpleDB.new()
$s3 = AWS::S3.new()
$sns = AWS::SNS.new(:region => 'us-west-2')
$url_base = "https://s3.amazonaws.com/melis_assignment_7/"

def mainUI(domain)
  puts "\nwhat would you like to do next?"
  puts "-if you'd like to see a list of all the contacts in #{domain.name}, enter 1"
  puts "-if you'd like to delete a contact in #{domain.name}, enter 2"
  puts "-if you'd like create a new contact, enter 3" 
  puts "-if you'd like to edit a contact, enter 4"
  puts "-if you'd like to change domains, enter 5"
  puts "-if you'd like to exit, enter 6\n"
end


#option 1
#method to list all contents of a domain
def listContents(domain)
  if !domain.empty?
    puts "fetching contents of domain called #{domain.name}"


    #use select function
    domain_items = domain.items	  #returns itemCollection
    domain_items.select('*').each do |item_data|
      item = item_data.item	#returns actual item
      puts "first: #{item.attributes[:first].values[0]}, last: #{item.attributes[:last].values[0]}"
    end

  else
    puts "domain called #{domain.name} contains no contacts!"
  end
end

#option 2
def deleteContact(domain, action)
  name_array = gets.chomp!.split
  name_array.insert(0,'temp_uuid')
  puts name_array

  deleteSimpleDBContact(domain, name_array)

  bucket = changeBucket("melis_#{domain.name}")
  deleteS3Contact(bucket, name_array)

  if action=="delete"
    publish(name_array, action)
  end
end

def deleteSimpleDBContact(domain, name_array)
  uuid = domain.items.select('name').where("first = '#{name_array[1]}' and last => '#{name_array[2]}'")

  domain.items['uuid'].delete
end
  


def deleteS3Contact(bucket, name_array)
  obj = bucket.objects["#{name_array[1]}_#{name_array[2]}.html"]

  if obj.exists?
    return true
  else 
    puts "that contact doesn't exist in #{bucket.name}!"
    return false
  end
end


#option 3
#create new contact, generate html page, store it in the domain
def newContact(domain, action)
  arr = getInput
  arr.insert(0,SecureRandom.uuid)

  generateSimpleDBContact(arr, domain)

  generateFile(arr)


  bucket = changeBucket("melis_#{domain.name}")
  #bucket = changeBucket($s3.buckets["melis_#{domain.name}"])
  sendFile(arr,bucket)

  publish(arr, action)
end

def publish(arr, action)
    arn = "arn:aws:sns:us-west-2:405483072970:51083-updated"   
    
    if action=="new"
      $sns.topics[arn].publish(
	"The contact\'s name is #{arr[1]} #{arr[2]}.
	You can see their contact page at #{$url_base+arr[1]+'_'+arr[2]+'.html'}",
	:subject => "New contact created in 51083")

    elsif action=="edit"
      $sns.topics[arn].publish(
	"The contact\'s name is #{arr[1]} #{arr[2]}.
	You can see their edited contact page at #{$url_base+arr[1]+'_'+arr[2]+'.html'}",
	:subject => "Contact edited in 51083")
    elsif action=="delete"
      $sns.topics[arn].publish(
	"The contact\'s name was #{arr[1]} #{arr[2]}.
	You can no longer see their contact page.",
	:subject => "Contact deleted from 51083")
    else
      puts "error"
    end

  end

#helper function for newContact
#get input for new contact
#returns array of strings
def getInput
  puts "enter the new information for your contact as follows, with a single space separating each item:"
  puts "<first name> <last name>"
  #some kind of error checking?
  return gets.chomp!.split
end


#create simple_db entry
def generateSimpleDBContact(contact_array, domain)
  domain.items["#{contact_array[0]}"].attributes['first'].add contact_array[1].downcase
  domain.items["#{contact_array[0]}"].attributes['last'].add contact_array[2].downcase
  #domain.items["#{contact_array[0]}"].attributes['phone'].add contact_array[3]
end


#helper function for newContact
#takes in array with first name, last name, and phone number
#creates a new html file named using that array
#returns a the file for use in sending file up to amazon
def generateFile(arr)
  require 'fileutils'		    #load fileutils module to enable copying behavior

  #copy template_contacts and rename using array
  #FileUtils.cp 'template_contact.html', "./contacts/#{arr[1].downcase}_#{arr[2].downcase}_#{arr[3].downcase}.html"
  FileUtils.cp 'template_contact.html', "./contacts/#{arr[1].downcase}_#{arr[2].downcase}.html"

  #append the following lines representing the next row of html table
  #f = open("./contacts/#{arr[1].downcase}_#{arr[2].downcase}_#{arr[3]}.html", "a") do |f|
  f = open("./contacts/#{arr[1].downcase}_#{arr[2].downcase}.html", "a") do |f|
    f << "<td>#{arr[0]}<td/>\n"
    f << "<td>#{arr[1].capitalize}<td/>\n"
    f << "<td>#{arr[2].capitalize}<td/>\n"
#    f << "<td>#{arr[3]}<td/>\n"
    f << "</tr>\n</table>"
  end
end

#helper function for newContact
def sendFile(arr,bucket)
  f = open("./contacts/#{arr[1].downcase}_#{arr[2].downcase}.html", 'r')
  bucket.objects["#{arr[1].downcase}_#{arr[2].downcase}.html"].write(f, :acl => :public_read)
end

#option 4
#basically hotwiring delete and create functions to make edit function
def editContact(domain)
  puts "please enter the first and last name of the contact you'd like to edit, in this format:"
  puts "<first> <last>"
  if deleteContact(domain,"edit")
    newContact(domain, "edit")
  end
end

#helper to change bucket
def changeBucket(bucket_name)
  
  bucket = $s3.buckets[bucket_name]
  
  #check if bucket exists
  if bucket.exists?
    puts "bucket called #{bucket.name} exists!"
  else
    puts "creating new bucket"	#called #{bucket.name}"
    bucket = $s3.buckets.create(bucket.name)
  end
  return bucket
end

#option 5 
#also called at beginning to set initial domain
def changeDomain()
  
  puts "\nenter a domain name. if it doesn't exist yet, i'll make it for you"
  domain_name = gets.chomp!   #chomp cuts last character off IFF it's a newline character

  domain = $sdb.domains[domain_name]

  #check if domain exists
  if domain.exists?
    puts "domain called #{domain.name} exists!"

    #check if have access
    #if !testDomainAccess(domain)
    #  puts "you don't have access to #{domain.name}"
    #  puts "please input a domain to which you have access or a valid new domain name"
    #  domain = changeDomain($sdb)
    #end
  else
    puts "creating new domain"	#called #{domain.name}"
    domain = $sdb.domains.create(domain.name)
  end
  return domain
end

#test if have access to domain
def testDomainAccess(domain)
  begin
    listContents(domain)    #any method that would raise a permission error
    return true
  rescue 
    return false
  end
end


#main UI method
def userInterface(domain)
  cmd = 0
  local_domain = domain
  while cmd !=7
    mainUI(local_domain)
    cmd = gets.chomp!.to_i

    if cmd == 1
      puts "inside option 1, domain: #{local_domain}"
      listContents(local_domain)
    elsif cmd == 2
      puts "\nfor your convenience, will display all contacts in current domain"
      listContents(local_domain)
      puts "\nenter the name of the contact you'd like to delete" #placed here to enable reuse of create/delete functions
      deleteContact(local_domain, "delete")
    elsif cmd == 3 
      newContact(local_domain, "new")
    elsif cmd == 4 
      puts "\nfor your convenience, will display all contacts in current domain"
      listContents(local_domain)
      editContact(local_domain)
    elsif cmd == 5
      local_domain = changeDomain()
    elsif cmd == 6 
      puts "\nGoodbye!\n"
      break
    end

  end
end

domain = changeDomain()
userInterface(domain)

