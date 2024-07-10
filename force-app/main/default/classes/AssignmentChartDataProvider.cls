public with sharing class AssignmentChartDataProvider {

    @AuraEnabled
    public static List<Schedule__c> getSchedulesByWeek(Id weekId){
        try {
            return [SELECT Name, Number_of_Assignments__c, Number_of_Work_Orders_in_Week__c, Total_Cost__c, Total_Fine__c, Total_Fine_Unfinished_Work_Orders__c, Total_Hours_spent_in_Overtime_Hours__c, Total_Hours_spent_in_Regular_Time__c, Total_Labour_Cost__c
                    FROM Schedule__c WHERE Week__c =: weekId ORDER BY Name LIMIT 3];
        } catch (Exception e) {
            throw new AuraHandledException('Data not fetched for schedule with id ' + weekId + '. Please share this error message with your Salesforce Administrator: ' + e.getMessage());
        }
    }
}