/**
* @author Kyrylo Mazur
* @date 2024
*
* @group Schedule Visualization
* @group-content 
*
* @description Test class for ScheduleComparisonController
*/

@IsTest
private with sharing class ScheduleComparisonControllerTest {

    /* 
    * @description Create data needed to perform tests
    */
    @TestSetup
    private static void testDataSetup() {
        DemoDataGenerator.generateDemoData1('Test Week', 5, 3);
        Week__c week = [SELECT Id FROM Week__c LIMIT 1];
        runScheduler(new SchedulerOne(), week.Id, 1);
        runScheduler(new SchedulerTwo(), week.Id, 2);
        runScheduler(new SchedulerThree(), week.Id, 3);
    }

    /* 
     * @description Test that controller works properly with valid week ID
     */
    @IsTest
    private static void testGetSchedulesByWeekSuccess() {
        Week__c week = [SELECT Id FROM Week__c LIMIT 1];

        Test.startTest();
        List<Schedule__c> scheduleList = ScheduleComparisonController.getSchedulesByWeek(week.Id);
        Test.stopTest();

        Assert.areEqual(3, scheduleList.size(), 'Unexpected number of schedules retrieved');
    }

    /* 
     * @description Set name and week for scheduler and run it
     */
    private static void runScheduler(Scheduler.AbstractScheduler scheduler, Id weekId, Integer schedulerNumber){
        scheduler.setWeek(weekId);
        scheduler.setName('Scheduler' + schedulerNumber);
        scheduler.run();
    }
}