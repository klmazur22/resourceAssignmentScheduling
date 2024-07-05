public class SchedulerAPI extends Scheduler.AbstractScheduler {
    private List<Resource_Assignment__c> assignments;
    public SchedulerAPI() {
        this.setName('SchedulerAPI');
    }
    public void setAssignments(List<Resource_Assignment__c> assignments) {
        this.assignments = assignments;
    }
	public override virtual List<Resource_Assignment__c> callImplementation(List<Work_Order__c> workOrders, List<Resource__c> resources) {
        return this.assignments;
    } 
}