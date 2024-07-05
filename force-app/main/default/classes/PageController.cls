public class PageController {
    public List<SelectOption> weeks { get {
        List<SelectOption> result = new List<SelectOption>();
        List<Week__c> weeks = [SELECT Id, Name FROM Week__c];
        for (Week__c week : weeks) {
            result.add(new SelectOption(week.Id, week.Name));
        }
        return result;
    } set; }
    public List<SelectOption> schedulers { get {
        List<SelectOption> result = new List<SelectOption>();
        List<ApexClass> classes = [SELECT Id, Name FROM ApexClass WHERE Name LIKE 'Scheduler%' AND Name != 'Scheduler' AND Name != 'SchedulerAPI'];
        for (ApexClass cls : classes) {
            result.add(new SelectOption(cls.Name, cls.Name));
        }
        return result;
    } set; }
    public Id selectedWeek { get; set; }
    public String selectedScheduler { get; set; }
    
    public PageController() {
        
    }
    public PageReference run() {
        Type t = Type.forName(this.selectedScheduler);
        Scheduler.IScheduler scheduler = (Scheduler.IScheduler) t.newInstance() ;
        scheduler.setWeek(this.selectedWeek);
        system.debug('scheduler::'+scheduler);
        Id scheduleId = scheduler.run();
        return new PageReference('/' + scheduleId);
    }
}