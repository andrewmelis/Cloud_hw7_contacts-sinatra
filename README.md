Assignment 7: More SNS; Pulling some pieces together


Updated contact features: Bringing some pieces together
Due Saturday, May 25 by 11pm CST. Submit via Chalk email.

Pay attention to region as you work on this assignment. 
If you don't explicitly specify a region, your code may coincidentally work for a while, and then mysteriously stop working....

Set up an instance on which you will deploy a web application and a console application.
Configure the appropriate security group(s) to allow access to the web app.

Role credentials (Note: You may need to iterate through the assignment and experiment with later steps to complete this step correctly.)
Create a role that allows only the necessary permissions to complete the assignment.
Assign that role to the instance on which you run the assignment programs. Remember that you must assign the role BEFORE you launch the instance.
Use the role as the mechanism of obtaining AWS credentials on that instance.

Create notification topics
Create four SNS notification topics named 51083-updated, 51083-A, 51083-B and 51083-C

Modify your assignment 4, in which you generated HTML contact-info files from data in SimpleDB.
Expose the S3 files on the Internet by using S3 to serve them as static content.
Change the script to use the role credentials.
Update the console app so that whenever a new HTML file is stored in S3, a notification is sent to all subscribers to the 51083-updated topic. 
The subject should identify whether a contact was created, deleted or modified, and the message body should identify the contact by name, and provide a link to the S3 page.

Write a simple web application with the following features:
Displays an index page that lists the each contact name and provides the link to the appropriate S3 HTML page. This page should always show up-to-date information.
Reads the SNS topics and presents a form for a user to select a topic and submit a URL or email address.
Subscribes that URL or email to the topic.
Allows creation of new contacts
Provide a form with 2 fields, first name and last name. 
Validate the inputs for each field: 1-16 characters, letters only, no spaces or punctuation. 
(This is not necessarily a reasonable constraint on names in the real world, but it’s a quick way to ensure more or less sanitized inputs for our purposes.)
Create a contact item in SimpleDB using the inputs, using the same structure/domain as your console app.
Create the static HTML page in S3 and send the appropriate notification to 51083-updated, as in item 4 above.
