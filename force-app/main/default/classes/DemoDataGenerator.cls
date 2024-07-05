public class DemoDataGenerator {
    public static Integer rand(Integer l){
        Integer res = Math.round(Math.random()*l);
        return res;
    }
    public static void deleteWeek(String name) {
        delete [select id from Work_Order__c WHERE Week__r.Name = :name];
        delete [select id from Resource__c WHERE Week__r.Name = :name];
        delete [select id from Week__c WHERE Name = :name];
    }
    public static void generateDemoData1(String week_name, Integer wo_amount, Integer resource_amount){ 
        //get names set
        List<StaticResource> sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'Names'];
        String names = '';
        if (sr.size() > 0) {
            names = sr.get(0).Body.toString();
        }
        List<String> names_rows = names.split('\n');
        DateTime start_date = DateTime.newInstance(Date.today().toStartOfWeek(), Time.newInstance(0,0,0,0));
        DateTime end_date = start_date.addDays(7);
        
        
        Week__c w = new Week__c();
        w.Name = week_name;
        w.Week_End__c = end_date.addDays(1);
        w.Fine_per_unfinished_WO__c = 2000;
        insert w;
        //Generate resources
        List<Resource__c> resources_to_insert = new List<Resource__c>();
        
        for(Integer i = 0; i < resource_amount; i++) {
            Resource__c r = new Resource__c();  
            r.Week__c = w.Id;
            integer start_hour = 4 + rand(8);
            Integer end_hour = 16 + rand(4);
            r.Start_Regular_Working_Time__c = (start_hour < 10 ? '0':'') + String.valueOf(start_hour) + ':00';
            r.End_Regular_Working_Time__c = (end_hour < 10 ? '0':'') +String.valueOf(end_hour) + ':00';
            Integer name1 = rand(80);
            Integer name2 = rand(80);
            r.Name = names_rows.get(name1).split(',').get(0) + ' ' + names_rows.get(name2).split(',').get(1);
            r.Performance__c = 1 + rand(5)/2;
            if (Math.mod(rand(5),2) == 1) {
                
                r.Overtime_Capable__c = true;
                
            }
            r.Regular_Rate__c = rand(100);
            r.Overtime_Rate__c = Math.max(r.Regular_Rate__c + 10, 50 + rand(100));
            resources_to_insert.add(r);
        }
        insert resources_to_insert;
        List<Work_Order__c> wos_to_insert = new List<Work_Order__c>();

        
        Integer hours = 7 * 24;
        for(Integer i = 0; i < wo_amount; i++) {
            Integer d_dat = rand(7);
            Integer h_start = 5  + rand(7);
            Integer h_end = h_start + 3 + rand(8);
            
            Work_Order__c wo  = new Work_Order__c();
            wo.Week__C = w.Id;
            wo.Amount_of_Work__c = 1 + (h_end - h_start)/2 + rand(5);
            wo.Start_Time__c = start_date.addDays(d_dat).addHours(h_start);
            wo.End_Time__c = start_date.addDays(d_dat).addHours(h_end);
            wo.Fine_per_hour_delay__c = 30 + rand(120);
            wos_to_insert.add(wo);
        }
        insert wos_to_insert;
    }
    
    public static void generateDemoData2(String week_name, Integer wo_amount, Integer resource_amount){ 
        //get names set
        List<StaticResource> sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'Names'];
        String names = '';
        if (sr.size() > 0) {
            names = sr.get(0).Body.toString();
        }
        List<String> names_rows = names.split('\n');
        
        DateTime start_date = DateTime.newInstance(Date.today().toStartOfWeek(), Time.newInstance(0,0,0,0));
        DateTime end_date = start_date.addDays(7);
        
        
        Week__c w = new Week__c();
        w.Name = week_name;
        w.Week_End__c = end_date.addDays(1);
        w.Fine_per_unfinished_WO__c = 500;
        insert w;
        //Generate resources
        List<Resource__c> resources_to_insert = new List<Resource__c>();
        
        for(Integer i = 0; i < resource_amount; i++) {
            Resource__c r = new Resource__c();  
            r.Week__c = w.Id;
            integer start_hour = 4 + rand(5);
            Integer end_hour = 16 + rand(2);
            r.Start_Regular_Working_Time__c = (start_hour < 10 ? '0':'') + String.valueOf(start_hour) + ':00';
            r.End_Regular_Working_Time__c = (end_hour < 10 ? '0':'') +String.valueOf(end_hour) + ':00';
            Integer name1 = rand(80);
            Integer name2 = rand(80);
            r.Name = names_rows.get(name1).split(',').get(0) + ' ' + names_rows.get(name2).split(',').get(1);
            r.Performance__c = 1 + rand(5)/2.0;
            if (Math.mod(rand(5),2) == 1) {
                r.Overtime_Capable__c = true;
            }
            r.Regular_Rate__c = 10 + rand(40);
            r.Overtime_Rate__c = r.Regular_Rate__c + 10 + rand(100);
            resources_to_insert.add(r);
        }
        insert resources_to_insert;
        List<Work_Order__c> wos_to_insert = new List<Work_Order__c>();
        
        Integer hours = 7 * 24;
        for(Integer i = 0; i < wo_amount; i++) {
            Integer d_dat = rand(7);
            Integer h_start = 5  + rand(7);
            Integer h_end = h_start + 3 + rand(8);
            
            Work_Order__c wo  = new Work_Order__c();
            wo.Week__C = w.Id;
            wo.Amount_of_Work__c = 1 + (h_end - h_start)/2 + rand(5);
            wo.Start_Time__c = start_date.addDays(d_dat).addHours(h_start);
            wo.End_Time__c = start_date.addDays(d_dat).addHours(h_end);
            wo.Fine_per_hour_delay__c = 15 + rand(120);
            wos_to_insert.add(wo);
        }
        insert wos_to_insert;
    }
}