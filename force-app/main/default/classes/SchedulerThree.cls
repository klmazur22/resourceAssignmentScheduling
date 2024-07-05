public class SchedulerThree extends Scheduler.AbstractScheduler {
    private List<Resource__c> resources = new List<Resource__c>();
    private Map<Id, DateTime> nextAvailableDate = new Map<Id, DateTime>();
    public SchedulerThree() {
        this.setName('SchedulerThree');
    }
 
    private static Integer calculateWoPriorityForWo(Work_Order__c wo, Integer average_resource_price) {
        //average_resource_price 50 ?
        return Integer.valueOf(wo.Fine_per_hour_delay__c * (24 - wo.End_Time__c.hour())
              + average_resource_price * (12 - wo.Amount_of_Work__c));
             
    }
 
    private static Decimal calculatePriorityForResource(Resource__c r) {
        return (r.Regular_Rate__c) / r.Performance__c;
    }
 
 
    private class WOWrapper implements Comparable{
        public Work_Order__c WorkOrder;
 
        public WOWrapper(Work_Order__c wo) {
            WorkOrder = wo;
        }
 
        public Integer compareTo(Object second_wrapper) {
            return 1 * (
                             calculateWoPriorityForWo(this.WorkOrder,80)
                           - calculateWoPriorityForWo(((WOWrapper)second_wrapper).WorkOrder, 80)
                        );
        }
    }
 
    private class ResourceWrapper implements Comparable{
        public Resource__c Resource;
        public Set<Integer> UsedHours;
        public Week__C Week;
 
        public ResourceWrapper(Resource__c res, Week__c w) {
            Resource = res;
            UsedHours = new Set<Integer>();
            for(Integer i = 0; i < 24; i++) {
                UsedHours.add(i);
            }
            Week  = w;
        }
 
        public Integer compareTo(Object second_wrapper) {
            return  1 * Integer.valueOf((calculatePriorityForResource(Resource) - calculatePriorityForResource(((ResourceWrapper)second_wrapper).Resource)));
        }
 
        public List<Integer> canResourceDoWO(Work_Order__c wo) {
            Integer amount_of_hours_needed = Integer.valueOf(Math.ceil((0.0 + wo.Amount_of_Work__c) / resource.Performance__c));
             
            if (amount_of_hours_needed * Resource.Regular_Rate__c >= Integer.valueOf(wo.Fine_per_hour_delay__c * (24 - wo.End_Time__c.hour()))) {
                //nothing to do here
                return null;
            }
            Integer start_hour = Math.max(Integer.valueOf(Resource.Start_Regular_Working_Time__c.substring(0,2)), wo.Start_Time__c.hour());
            Integer end_hour = Integer.valueOf(Resource.End_Regular_Working_Time__c.substring(0,2));
            for(Integer i = start_hour; i < end_hour - amount_of_hours_needed ; i++) {
                List<Integer> subset = new List<Integer>();
                for(Integer j = i; j < i + amount_of_hours_needed; j++) {
                    subset.add(j);
                }
                if (UsedHours.containsAll(subset)) {
                    UsedHours.removeAll(subset);
                    return subset;
                }
            }
            if (Resource.Overtime_Capable__c) {
                start_hour = wo.Start_Time__c.hour();
                for(Integer i = start_hour; i < 24 - amount_of_hours_needed; i++) {
                    List<Integer> subset = new List<Integer>();
                    for(Integer j = i; j < i + amount_of_hours_needed; j++) {
                        subset.add(j);
                    }
                    if (UsedHours.containsAll(subset)) {
                    //
                    //big fine
                        if (subset.get(subset.size()-1) > wo.End_Time__c.hour()) {
                            Integer fee_time = subset.get(subset.size()-1) - wo.End_Time__c.hour();
                            //overtime here - check how big is the fee
                            if (amount_of_hours_needed * Resource.Regular_Rate__c + fee_time*wo.Fine_per_hour_delay__c
                                 >= Integer.valueOf(week.Fine_per_unfinished_WO__c)) {
                                //nothing to do here
                                return null;
                            }
                        }
 
                        UsedHours.removeAll(subset);
                        return subset;
                    }
                }
            }
            return null;
        }
    }
 
 
    public override virtual List<Resource_Assignment__c> callImplementation(List<Work_Order__c> workOrders, List<Resource__c> resources) {
        Map<Date, List<WOWrapper> > work_orders_by_dates = new Map<Date, List<WOWrapper>>();
 
        for(Work_Order__c wo : workOrders) {
            Date d = wo.Start_Time__c.date();
            if (!work_orders_by_dates.containsKey(d)) {
                work_orders_by_dates.put(d, new List<WOWrapper>());
            }
            work_orders_by_dates.get(d).add(new WOWrapper(wo));
        }
        List<Resource_Assignment__c> assignments = new List<Resource_Assignment__c>();
        for (Date d : work_orders_by_dates.keySet()) {
            //get best resources for every day
            List<ResourceWrapper> resources_by_priority = new List<ResourceWrapper>();
            for(Resource__c r : resources) {
                resources_by_priority.add(new ResourceWrapper(r, week));
            }
            resources_by_priority.sort();
 
            List<WOWrapper> workorders_for_today = work_orders_by_dates.get(d);
            workorders_for_today.sort();
            for(WOWrapper wo : workorders_for_today) {
                for(Integer i = 0; i < resources_by_priority.size(); i++) {
                    List<Integer> res = (resources_by_priority.get(i)).canResourceDoWO(wo.WorkOrder);
                    if (res != null) {
                        //system.debug(LoggingLevel.Error, 'RETURNED' + res);
                        //System.debug(LoggingLevel.Error, 'LEFT' + resources_by_priority.get(i).UsedHours);
 
                        Resource_Assignment__c ra = new Resource_Assignment__c();
                        ra.Work_Order__c  = wo.WorkOrder.Id;
                        ra.Resource__c = resources_by_priority.get(i).Resource.Id;
                         
                        if(res.size() == 0) {
                            ra.Start_Time__c = wo.WorkOrder.Start_Time__c;
                            ra.End_Time__c = ra.Start_Time__c;//0 hours -- amazing
                        } else {
                        ra.Start_Time__c = DateTime.newInstance(d, Time.newInstance(res.get(0),0,0,0));
                        ra.End_Time__c = ra.Start_Time__c.addMinutes(Integer.valueOf(
                                                                        Math.floor(60*(0.0 +  wo.WorkOrder.Amount_of_Work__c)
                                                                            / resources_by_priority.get(i).Resource.Performance__c
                                                                            )
                                                                                     )
                                                                     );
                        }
                        assignments.add(ra);
                        break;
                    }
                }
            }
        }
 
        return assignments;
    }
 
}