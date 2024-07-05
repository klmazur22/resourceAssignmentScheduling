public class SchedulerOne extends Scheduler.AbstractScheduler {
    private List<Resource__c> resources = new List<Resource__c>();
    private Map<Id, DateTime> nextAvailableDate = new Map<Id, DateTime>();
    // Wrapper for sorting
    public class WOWrapper implements Comparable {
        public Work_Order__c wo;
        public WOWrapper(Work_Order__c wo) {
            this.wo = wo;
        }
        public Integer compareTo(Object compareTo) {
            WOWrapper compareToWo = (WOWrapper) compareTo;
            Integer returnValue = 0;
            if (wo.Start_Time__c > compareToWo.wo.Start_Time__c) {
                returnValue = 1;
            } else if (wo.Start_Time__c < compareToWo.wo.Start_Time__c) {
                returnValue = -1;
            }
            return returnValue;      
        }
    }
    public SchedulerOne() {
        this.setName('SchedulerOne');
    }
  public override virtual List<Resource_Assignment__c> callImplementation(List<Work_Order__c> workOrders, List<Resource__c> resources) {
        // Sorting
        List<WOWrapper> woWrapperList = new List<WOWrapper>();
        for (Work_Order__c wo : workOrders) {
            woWrapperList.add(new WOWrapper(wo));
        }
        woWrapperList.sort();
         
        List<Resource_Assignment__c> assignments = new List<Resource_Assignment__c>();
        this.resources = resources;
        this.fillEarliestAvailableDates(workOrders);
        for (WOWrapper wrapper : woWrapperList) {
            Resource_Assignment__c ra = this.getResourceAssignmentForWorkOrder(wrapper.wo);
            if (ra != null) {
                assignments.add(ra);
            }
        }
        Map<Id, List<Resource_Assignment__c>> assignmentsByResource = new Map<Id, List<Resource_Assignment__c>>();
        for (Resource_Assignment__c ra : assignments) {
            List<Resource_Assignment__c> ras = assignmentsByResource.get(ra.Resource__c);
            if (ras == null) {
                ras = new List<Resource_Assignment__c>();
            }
            ras.add(ra);
            assignmentsByResource.put(ra.Resource__c, ras);
        }
        //throw new Scheduler.SchedulerException('Assignments: ' + JSON.serializePretty(assignmentsByResource));
        return assignments;
    }
    private Resource_Assignment__c getResourceAssignmentForWorkOrder(Work_Order__c wo) {
         // Assign a random resource
        for (Resource__c r : this.resources) {
            DateTime earliestDate = this.nextAvailableDate.get(r.Id);
            if (earliestDate <= wo.Start_Time__c) {
                Boolean assign = false;
                if (Integer.valueOf(r.Start_Regular_Working_Time__c.substring(0,2)) > wo.Start_Time__c.hour() && Integer.valueOf(r.End_Regular_Working_Time__c.substring(0,2)) < wo.End_Time__c.hour()) {
                    assign = true;
                } else {
                    if (r.Overtime_Capable__c == true) {
                        assign = true;
                    }
                }
                if (assign == true) {
                    Resource_Assignment__c ra = new Resource_Assignment__c(Work_Order__c = wo.Id, Resource__c = r.Id, 
                                                                           Start_Time__c = wo.Start_Time__c, 
                                                                           End_Time__c = this.getEndTime(wo, r, wo.Start_Time__c));
                    if (ra.End_Time__c < this.week.Week_End__c) {
                        this.nextAvailableDate.put(r.id, ra.End_Time__c);
                        return ra;
                    }
                }
            }
        }
        return null;
    }
    private void fillEarliestAvailableDates(List<Work_Order__c> workOrders) {
        DateTime earliest = this.getEarliestDateTime(workOrders);
        for (Resource__c r : this.resources) {
            // As we don't respect overtime we are always available
            this.nextAvailableDate.put(r.Id, earliest);
        }
    }
    private DateTime getEarliestDateTime(List<Work_Order__c> woList) {
        DateTime earliestFound = DateTime.newInstance(2100, 1, 1, 1, 1, 1);
        for (Work_Order__c wo : woList) {
            if (wo.Start_Time__c < earliestFound) {
                earliestFound = wo.Start_Time__c;
            }
        }
        return earliestFound;
    }
    private DateTime getEndTime(Work_Order__c wo, Resource__c r, DateTime start) {
        return start.addMinutes((Integer) Math.ceil(this.getNumberOfHoursNeeded(wo, r) * 60));
    }
    private Decimal getNumberOfHoursNeeded(Work_Order__c wo, Resource__c r) {
        System.debug(LoggingLevel.ERROR, 'Amount of hours needed: ' + wo.Amount_of_Work__c + ' / ' + r.Performance__c + ' = ' + (wo.Amount_of_Work__c / r.Performance__c));
        return wo.Amount_of_Work__c / r.Performance__c;
    }
}