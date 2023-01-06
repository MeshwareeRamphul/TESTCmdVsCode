public with sharing class AP22_FormatEmailSend {
/*  
----------------------------------------------------------------------
-- - Name          : AP22_FormatEmailSend 
-- - Author        : Spoon Consulting
-- - Description   : class to manage email message to be sent from batch
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 17-MAY-2017  MRA    1.0      Intitial version
----------------------------------------------------------------------

*/	
	
	public integer numberOfsuccess;
	public integer numberOfLines;
	public integer numberOfError;
	public String subject;
	public String Body;
	private list<String> emailDestination;

	public boolean displayDateOnSubject;
	public boolean isHTML;
	public boolean useOrgWideAddress;
	public boolean hasAttachments;
	//
	public Blob csvBody;
	//
	private Messaging.SingleEmailMessage email;
	private list<Messaging.EmailFileAttachment> attachments;

	public AP22_FormatEmailSend(){
		System.debug('## AP00_FormatEmailSend');

		numberOfsuccess = 0;
		numberOfLines = 0;
		numberOfError = 0;

		useOrgWideAddress = true;
		displayDateOnSubject = true;		
		isHTML = false;	
		hasAttachments = false;	

		emailDestination = new list<String>();
		email = new Messaging.SingleEmailMessage();
		attachments = new list<Messaging.EmailFileAttachment>();

	}
	public void setDestination(String s){
		emailDestination = s.split(',');
	}
	public void generateAttachment(String filename,blob body, String fileFormat){
		System.debug('## generateAttachment');

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.setFileName(fileName);
		attachment.setBody(body);
		attachment.setContentType(fileFormat);
		attachment.setInline(false);
		hasAttachments = true;
		attachments.add(attachment);		
	}
	public void sendFormattedEmail(){
		System.debug('## sendFormattedEmail');

		email.setToAddresses(emailDestination); // destination		
		//use wide-org address ?
		/* no owd yet - to confirm if should be configured
		if(useOrgWideAddress){
			OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:system.label.GLO_OrgWideAdresse]; 
			email.setOrgWideEmailAddressId(owea.get(0).Id);
		} */
		//check if to generate date and time in mail subject
		if(displayDateOnSubject) subject += ' ' + DateTime.Now();

		email.setSubject(subject);
		//user plain or HTML version ?
		if(!isHTML) email.setPlainTextBody(body);
		else email.setHtmlBody(body);
		//check to see if attachment present
		if(hasAttachments) email.setFileAttachments(attachments);

		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});	
		}
		catch(exception ex){
			system.debug('## error on sending email :' + ex.getMessage());
		}
		
	}

}