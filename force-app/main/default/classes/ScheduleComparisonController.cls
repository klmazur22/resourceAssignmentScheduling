/**
* @author Kyrylo Mazur
* @date 2024
*
* @group Schedule Visualization
* @group-content 
*
* @description Controller class for scheduleComparison LWC.
*/
public with sharing class ScheduleComparisonController {

    /**
    * @description Get data about schedules related to given week
    * @param weekId Id of the week record
    * @return list of schedules related to given week
    */
    @AuraEnabled
    public static List<Schedule__c> getSchedulesByWeek(Id weekId){
        return [SELECT Name, Number_of_Assignments__c, Number_of_Work_Orders_in_Week__c, Total_Cost__c, Total_Fine__c, Total_Fine_Unfinished_Work_Orders__c, Total_Hours_spent_in_Overtime_Hours__c, Total_Hours_spent_in_Regular_Time__c, Total_Labour_Cost__c
                FROM Schedule__c WHERE Week__c =: weekId WITH SECURITY_ENFORCED ORDER BY Name];
    }
}