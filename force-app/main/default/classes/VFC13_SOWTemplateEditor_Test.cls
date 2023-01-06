@isTest
private class VFC13_SOWTemplateEditor_Test {
	
	@isTest static void test_SaveSowTemplate() {
		SOW_Template__c mySOWTemplate = new SOW_Template__c();
		Test.startTest();
			VFC13_SOWTemplateEditor controller = new VFC13_SOWTemplateEditor(new ApexPages.StandardController(mySOWTemplate));
			controller.saveSOWTemplate();
		Test.stopTest();
	}
	
}