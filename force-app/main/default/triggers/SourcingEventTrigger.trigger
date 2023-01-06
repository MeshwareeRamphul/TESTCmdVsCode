/**
 * @description       : 
 * @author            : SCHSO
 * @group             : 
 * @last modified on  : 12-20-2021
 * @last modified by  : SCHSO
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   12-20-2021   SCHSO   Initial Version
**/

trigger SourcingEventTrigger on Sourcing_Event__c (before insert, after insert, before update, after update) {
if (Trigger.isBefore && Trigger.isInsert) {
        SourcingEventTriggerHandler.BeforeInsertHandler(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        SourcingEventTriggerHandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        SourcingEventTriggerHandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        SourcingEventTriggerHandler.afterUpdateHandler(Trigger.oldMap, Trigger.newMap, Trigger.new);
    }
}