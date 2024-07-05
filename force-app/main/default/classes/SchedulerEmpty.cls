public class SchedulerEmpty extends Scheduler.AbstractScheduler {
    public SchedulerEmpty() {
        this.setName('SchedulerEmpty');
    }
  public override virtual List<Resource_Assignment__c> callImplementation(List<Work_Order__c> workOrders, List<Resource__c> resources) {
        List<Resource_Assignment__c> assignments = new List<Resource_Assignment__c>();
        return null;
    }
}