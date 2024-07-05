trigger tr_RA on Resource_Assignment__c (after insert, after update) {
    if (Scheduler.running == false) {
        Set<Id> scheduleIds = new Set<Id>();
        for (Resource_Assignment__c ra : Trigger.new) {
            scheduleIds.add(ra.Schedule__c);
        }
        
        for (Schedule__c sch : [SELECT Id, Week__c FROM Schedule__c WHERE Id IN :scheduleIds]) {
            AssignmentValidationUtility.validateAssignmentForWeek(sch.Week__c, sch.Id);
        }
    }
}