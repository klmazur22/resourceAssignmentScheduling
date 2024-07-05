public class SchedulerTwo extends Scheduler.AbstractScheduler {
   
  private Map<ID, ResourceDateTimeTuple> resourcesAvailableTime = new Map<ID, ResourceDateTimeTuple>();
    
    public SchedulerTwo() {
        this.setName('SchedulerTwo');
    }
     
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
     
    public class ResourceDateTimeTuple {
        public Resource__c resource;
        public DateTime resourceTime;
         
        public ResourceDateTimeTuple(Resource__c r, DateTime t) {
            this.resource = r;
            this.resourceTime = t;
        }
    }
     
    public override virtual List<Resource_Assignment__c> callImplementation(List<Work_Order__c> workOrders, List<Resource__c> resources) {
        // Sorting
        List<WOWrapper> woWrapperList = new List<WOWrapper>();
        for (Work_Order__c wo : workOrders) {
            woWrapperList.add(new WOWrapper(wo));
        }
        woWrapperList.sort();
         
        //Set the resource available time
        DateTime startTime = woWrapperList[0].wo.Start_Time__c;
        for (Resource__c r : resources) {
            Integer startRegularTime = Integer.valueOf(r.Start_Regular_Working_Time__c.substring(0,2));
//          System.debug(loggingLevel.INFO ,'startTime: ' + startTime + ', startTimeHours ' + startTime.hour() + ' WTF???, startRegularTime: ' + startRegularTime + ', overtimeCapable: ' + r.Overtime_Capable__c);
            if (startRegularTime <= (startTime.hour() - 2) || r.Overtime_Capable__c == true) {
                this.resourcesAvailableTime.put(r.Id, new ResourceDateTimeTuple(r, startTime));
            } else {
                DateTime d = DateTime.newInstance(
                    startTime.year(), startTime.month(), startTime.day(),
                    startRegularTime + 2, 0, 0);
//              System.debug(loggingLevel.INFO, '' + d);
                this.resourcesAvailableTime.put(r.Id, new ResourceDateTimeTuple(r, d));
            }
        }
        //Foreach order, take the resource that cost less, assign it to the order update the class field
        List<Resource_Assignment__c> result = new List<Resource_Assignment__c>();
        for (WOWrapper wow : woWrapperList) {
            ID rId = getCostLessResource(wow.wo);
            //System.debug(loggingLevel.INFO, 'resourceId: ' + rId);
            if (rId != null) {
                DateTime endTime = this.getEndTime(wow.wo.Amount_of_Work__c, this.resourcesAvailableTime.get(rId).resource.Performance__c, this.resourcesAvailableTime.get(rId).resourceTime);
                result.add(new Resource_Assignment__c(Work_Order__c = wow.wo.Id, Resource__c = rId, Start_Time__c = this.resourcesAvailableTime.get(rId).resourceTime, End_Time__c = endTime));
                Resource__c r = this.resourcesAvailableTime.get(rId).resource;
                if (endTime.minute() > 0 || endTime.second() > 0)
                    this.resourcesAvailableTime.put(rId, new ResourceDateTimeTuple(r, DateTime.newInstance(endTime.year(), endTime.month(), endTime.day(), endTime.hour() + 1, 0, 0)));
                else
                    this.resourcesAvailableTime.put(rId, new ResourceDateTimeTuple(r, DateTime.newInstance(endTime.year(), endTime.month(), endTime.day(), endTime.hour(), 0, 0)));
            }
        }
        //Return the list of assignment
        return result;
  }
   
  private ID getCostLessResource(Work_Order__c wo) {
    ID result = null;
        Integer cost = 100000000;
    for (ID rId : this.resourcesAvailableTime.keySet()) {
      //check if the time of the resource is right for the work
      Resource__c r = this.resourcesAvailableTime.get(rId).resource;
            DateTime availableTime = this.resourcesAvailableTime.get(rId).resourceTime;
            if (availableTime <= wo.Start_Time__c) {
                availableTime = wo.Start_Time__c;
                this.resourcesAvailableTime.put(rId, new ResourceDateTimeTuple(r, availableTime));
            }
            DateTime endWorkTime = this.getEndTime(wo.Amount_of_Work__c, r.Performance__c, availableTime);
            if ( availableTime.isSameDay(endWorkTime) && (r.Overtime_Capable__c == true ||
                (availableTime.hour() >= Integer.valueOf(r.Start_Regular_Working_Time__c.substring(0,2)) &&
                 endWorkTime.hour() <= Integer.valueOf(r.End_Regular_Working_Time__c.substring(0,2))))) {
          Integer resourceCost = this.calculateCost(r, availableTime, endWorkTime);
                    //System.debug(loggingLevel.INFO, rId + ' can handle it with a cost of: ' + resourceCost);
                    if (resourceCost < cost) {
                        result = rId;
                        cost = resourceCost;
                    }
                 }
    }
    return result;
  }
   
  private Integer calculateCost(Resource__c r, DateTime startTime, DateTime endTime) {
        Integer startRegularWorkingTime = Integer.valueOf(r.Start_Regular_Working_Time__c.substring(0,2));
        Integer endRegularWorkingTime = Integer.valueOf(r.End_Regular_Working_Time__c.substring(0,2));
    Integer leftMargin = startTime.hour() - startRegularWorkingTime;
    Integer rightMargin = endTime.hour() - endRegularWorkingTime;
    if (leftMargin >= 0 && rightMargin <= 0) //Inside work hours
      return (endTime.hour() - startTime.hour()) * ((Integer) r.Regular_Rate__c);
    else if (leftMargin < 0 && rightMargin > 0) // Include the working hours + overtime
      return (
      (endTime.hour() - startTime.hour()) -
      (endRegularWorkingTime - startRegularWorkingTime )) * ((Integer) r.Overtime_Rate__c) +
      (endRegularWorkingTime - startRegularWorkingTime ) * ((Integer) r.Regular_Rate__c)
      ;
    else if (leftMargin < 0 && rightMargin <= 0) //out from the left
      if (endTime.hour() < startRegularWorkingTime)
        return (endTime.hour() - startTime.hour()) * ((Integer) r.Overtime_Rate__c);
      else
        return (Math.abs(leftMargin) * ((Integer) r.Overtime_Rate__c)) + ((endTime.hour() - startRegularWorkingTime) * ((Integer) r.Regular_Rate__c));
    else if (leftMargin >= 0 && rightMargin > 0) //out from the right
      if (startTime.hour() > endRegularWorkingTime)
        return (endTime.hour() - startTime.hour()) * ((Integer) r.Overtime_Rate__c);
      else
        return (rightMargin * ((Integer) r.Overtime_Rate__c)) + ((endRegularWorkingTime - startTime.hour()) * ((Integer) r.Regular_Rate__c) );
        else
          return 1000000000;
  }
   
  private DateTime getEndTime(Decimal amountOfWork, Decimal resourcePerformance, DateTime start) {
        return start.addMinutes((Integer) Math.ceil(this.getNumberOfHoursNeeded(amountOfWork, resourcePerformance) * 60));
    }
    private Decimal getNumberOfHoursNeeded(Decimal amountOfWork, Decimal resourcePerformance) {
//        System.debug(LoggingLevel.ERROR, 'Amount of hours needed: ' + amountOfWork + ' / ' + resourcePerformance + ' = ' + (AmountOfWork / resourcePerformance));
        return amountOfWork / resourcePerformance;
    }
}