public with sharing class VFC06_Attachments {
     
	private final Product__c mProduct;
    public String fileName { get; set; }
    public Blob fileBody { get; set; }
    public String deliverable { get; set; }
    public String attachmentName { get; set; }


    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public VFC06_Attachments(ApexPages.StandardController stdController) {
        this.mProduct = (Product__c) stdController.getRecord();
    }


    // creates a new Contact_Attachment__c record
    @TestVisible 
    private Database.SaveResult saveCustomAttachment() {
        Product_Attachment__c vAttach = new Product_Attachment__c();
        vAttach.Product__c = mProduct.Id; 
        vAttach.Name = attachmentName;
        vAttach.Deliverable__c = deliverable;

        // fill out cust obj fields
        return Database.insert(vAttach);
    }

    // create an actual Attachment record with the Contact_Attachment__c as parent
    @TestVisible 
    private Database.SaveResult saveStandardAttachment(Id pParentId) {
        Database.SaveResult vResult;
        
        Attachment vAttachment = new Attachment();
        vAttachment.body = this.fileBody;
        vAttachment.name = this.fileName;
        vAttachment.parentId = pParentId;
        // insert the attachment
        vResult = Database.insert(vAttachment);
        // reset the file for the view state
        fileBody = Blob.valueOf(' ');

        return vResult;
    }


    /**
    * Upload process is:
    *  1. Insert new Contact_Attachment__c record
    *  2. Insert new Attachment with the new Contact_Attachment__c record as parent
    *  3. Update the Contact_Attachment__c record with the ID of the new Attachment
    **/
    public PageReference processUpload() {
        try {
            if (String.isBlank(deliverable)) {
                // reset the file for the view state
                fileBody = Blob.valueOf(' ');
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Attachment_Err_NameRequired));
                return null;
            }

            // Check if name is filled if other is selecterd
            if (System.Label.ProductAttach_Other == deliverable) {
                if (String.isBlank(attachmentName)) {
                    // reset the file for the view state
                    fileBody = Blob.valueOf(' ');
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Attachment_Err_NameRequired));
                    return null;
                }
            } else {
                // Set deliverable as name of the attachment
                attachmentName = deliverable;
            }


            // Insert custom attachment
            Database.SaveResult vCustomAttachmentResult = saveCustomAttachment();

            if (vCustomAttachmentResult == null || !vCustomAttachmentResult.isSuccess()) {
                attachmentName = '';
                // reset the file for the view state
                fileBody = Blob.valueOf(' ');
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Attachment_Err_Save));

                return null;
            }

            // Insert standard attachment
            Database.SaveResult vAttachmentResult = saveStandardAttachment(vCustomAttachmentResult.getId());

            if (vAttachmentResult == null || !vAttachmentResult.isSuccess()) {
                attachmentName = '';
                // reset the file for the view state
                fileBody = Blob.valueOf(' ');
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Attachment_Err_Save));      
                      
                return null;
            } else {
                // update the custom attachment record with some attachment info
                Product_Attachment__c vProductAttachment = [select id from Product_Attachment__c where id = :vCustomAttachmentResult.getId() LIMIT 1];
                vProductAttachment.Attachment_Id__c = vAttachmentResult.getId();
                
                update vProductAttachment;
            }

        } catch (Exception e) {
            ApexPages.AddMessages(e);
            return null;
        }

        return new PageReference('/' + mProduct.Id);
    }

    /**
    * Go back to product page
    */
    public PageReference back() {
        return new PageReference('/' + mProduct.Id);
    }

    /**
    * Construct picklist from the real one
    */
    public List<SelectOption> getDeliverables() {
        Schema.DescribeFieldResult vFieldResult = Product_Attachment__c.Deliverable__c.getDescribe();
        List<Schema.PicklistEntry> vPicklistValues = vFieldResult.getPicklistValues();
        List<SelectOption> vOptions = new List<SelectOption>();
        
        List<Schema.PicklistEntry> vPickEntries = vFieldResult.getPicklistValues();

        vOptions.add(new SelectOption('', ''));
        for (Schema.PicklistEntry vPickEntry : vPickEntries) {
            vOptions.add(new SelectOption(vPickEntry.getLabel(), vPickEntry.getValue()));
        }       

        return vOptions;
    }


}