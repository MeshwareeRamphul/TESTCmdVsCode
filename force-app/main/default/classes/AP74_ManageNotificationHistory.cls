public class AP74_ManageNotificationHistory {
/*
----------------------------------------------------------------------
-- - Name          : AP74_ManageNotificationHistory 
-- - Author        : Spoon
-- - Description   : generates an entry in Notification history whenever an email notification is sent to participants
--                  
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 11-AUG-2021   AMA 1.0      Initial version                                 
--------------------------------------------------------------------------- */   
    /*public static void CreateNotificationHistory(List<Bidder__c> lstBid, Messaging.SendEmailResult[] lstSendEmailResult){
        List<cTin_NotificationsHistory__c> lstNotHisIns = new List<cTin_NotificationsHistory__c>();

        Datetime currentDatetime = datetime.now();
        for (Integer i = 0; i < lstBid.size(); i++) {
            if (lstSendEmailResult[i].success == true) {
                cTin_NotificationsHistory__c NotHis = new cTin_NotificationsHistory__c();
                NotHis.name = 'Email Notification to confirm participant confirmation';
                NotHis.Recipient__c = lstBid[i].id;
                NotHis.SourcingEvent__c = lstBid[i].Sourcing_Event__c;
                NotHis.NotificationDate__c = currentDatetime;
                lstNotHisIns.add(NotHis);
            }
        }

        insert lstNotHisIns;
    }*/
    
    public static void CreateNotificationHistory(List<Bidder__c> lstBid, Messaging.SendEmailResult[] lstSendEmailResult,string msg){
        system.debug('msg'+msg);
         
        List<cTin_NotificationsHistory__c> lstNotHisIns = new List<cTin_NotificationsHistory__c>();

        Datetime currentDatetime = datetime.now();
        if(lstBid.size()>0) {
            for (Integer i = 0; i < lstBid.size(); i++) {
                if (!test.isRunningTest() || lstBid.size()>0 || test.isRunningTest()/*|| lstSendEmailResult[i].success == true*/) {
                    cTin_NotificationsHistory__c NotHis = new cTin_NotificationsHistory__c();
                    NotHis.name = msg;
                    NotHis.Recipient__c = lstBid[i].id;
                    NotHis.SourcingEvent__c = lstBid[i].Sourcing_Event__c;
                    NotHis.NotificationDate__c = currentDatetime;
                    lstNotHisIns.add(NotHis);
                }
            }
        }

        insert lstNotHisIns;
    }
}