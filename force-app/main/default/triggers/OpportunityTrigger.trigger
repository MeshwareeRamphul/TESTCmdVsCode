trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Before Insert events
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityHandler.handleBeforeInsert(Trigger.New);
        //if (PAD.canTrigger('AP17')) {
        //    AP17_EROCreatedFromOpportunity.generateERO(Trigger.New);
        //}
        //if (PAD.canTrigger('AP18')) {
        //    AP18_UpdateEROsOnOpptiesWon.updateEROs(Trigger.New);
        //}
    }

    // Before Update events
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityHandler.handleBeforeUpdate(Trigger.OldMap, Trigger.NewMap);
        //if (PAD.canTrigger('AP17')) {
        //    AP17_EROCreatedFromOpportunity.generateERO(Trigger.New);
        //}
        //if (PAD.canTrigger('AP18')) {
        //   AP18_UpdateEROsOnOpptiesWon.updateEROs(Trigger.New);
        //}
    }

    // After Insert events
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityHandler.handleAfterInsert(Trigger.NewMap);
        // if (PAD.canTrigger('AP09')) {
        //     AP09_ProductEntityLinks.upsertProductEntityLinkOnOptyList(Trigger.OldMap, Trigger.NewMap);
        // }
    }

    // After Update events
    if (Trigger.isAfter && Trigger.isUpdate) {
        //if (PAD.canTrigger('AP01')) {
        OpportunityHandler.handleAfterUpdate(Trigger.OldMap, Trigger.NewMap);
        //}
        // if (PAD.canTrigger('AP09')) {
        //     AP09_ProductEntityLinks.upsertProductEntityLinkOnOptyList(Trigger.OldMap, Trigger.NewMap);
        // }
    }
}