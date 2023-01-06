public with sharing class VFC06_AttachmentsEdit {

	public Product_Attachment__c mAttachment { get; set; }
    public Attachment mStdAttachment { get; set; }
    public String fileName { get; set; }
    public Blob fileBody { get; set; }
    
    public VFC06_AttachmentsEdit(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {            
            stdController.addFields(new List<String>{'Attachment_Id__c'});
        }
        this.mAttachment = (Product_Attachment__c) stdController.getRecord();
        this.mStdAttachment = [SELECT Id, Name FROM Attachment Where Id=:mAttachment.Attachment_Id__c LIMIT 1];
        this.fileName = mStdAttachment.Name;
    }


    // create an actual Attachment record with the Contact_Attachment__c as parent
    private Database.SaveResult updateStandardAttachment() {
        Database.SaveResult vResult;

        mStdAttachment.body = this.fileBody;
        mStdAttachment.name = this.fileName;
        
        // update the attachment
        vResult = Database.update(mStdAttachment);
        // reset the file for the view state
        fileBody = Blob.valueOf(' ');

        return vResult;
    }

    /*
    * Process to upload
    */
    public PageReference processUpload() {
        try {
            
            // Update standard attachment
            if (this.fileBody != null) {
                Database.SaveResult vAttachmentResult = updateStandardAttachment();

                if (vAttachmentResult == null || !vAttachmentResult.isSuccess()) {
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Attachment_Err_Save));            
                    return null;
                } 
            }

        } catch (Exception e) {
            ApexPages.AddMessages(e);
            return null;
        }

        return new PageReference('/' + mAttachment.Product__c);
    }

    /**
    * Go back to product page
    */
    public PageReference back() {
        return new PageReference('/' + mAttachment.Product__c);
    }

}