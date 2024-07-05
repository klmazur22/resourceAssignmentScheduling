public class AssignmentValidationUtility {

    public static void validateAssignmentForWeek(String week_name, String schedule_name) {
       // String week_name = 'Week 1';
        Boolean is_error = false;
        String error = '';
        Map<Id,Work_Order__c> child_work_orders  = 
                new Map<Id, Work_Order__c>(
                            [SELECT Id, Name
                            FROM Work_Order__c 
                            WHERE Week__r.Name = :week_name OR Week__c = :week_name]
                            );

        List<Resource_Assignment__c> ras = 
            [SELECT Id,Work_Order__c, Work_Order__r.Name, Resource__c, Start_Time__c, 
                    Start_Hour__c, End_Hour__c
             FROM Resource_Assignment__c
             WHERE Work_Order__c in :child_work_orders.keySet()
               AND (Schedule__c = :schedule_name OR Schedule__r.Name = :schedule_name)
        ];

        //Match all work orders
        Set<Id> resource_ids = new Set<Id>();
        Map<Id, Integer> ras_per_wo = new Map<Id, Integer>();
        Map<Id, List<Resource_Assignment__c>> ras_per_resources = new Map<Id, List<Resource_Assignment__c>>();
        for(Resource_Assignment__c r : ras) {
            resource_ids.add(r.Resource__c);
            if (!ras_per_wo.containsKey(r.Work_Order__c)) {
                ras_per_wo.put(r.Work_Order__c, 0);
            }

            ras_per_wo.put(r.Work_Order__c, ras_per_wo.get(r.Work_Order__c)+1);

            //
            if (!ras_per_resources.containsKey(r.Resource__c)) {
                ras_per_resources.put(r.Resource__c, new List<Resource_Assignment__c>());
            }
            ras_per_resources.get(r.Resource__c).add(r);
        }

        for(Work_Order__c wo : child_work_orders.values()) {
            if (ras_per_wo.get(wo.Id) > 1) {
                is_error = true;
                String error_line = '### RESULT: INVALID ASSIGNMENT: ' 
                    			+ wo.Name + '(' + wo.Id + ') -- ' 
                    			+ ras_per_wo.get(wo.Id) + ' assignments';
                error += error_line;
                System.debug(error_line);
            }
        } 


        // Validate that resource works only for 1 WO per every moment of time
        Map<Id, Resource__c> resources  = 
                new Map<Id, Resource__c>(
                            [SELECT Id, Name
                            FROM Resource__c 
                            WHERE Id in :resource_ids
                            ]);
        for(Resource__c res : resources.values()) {
            List<Resource_Assignment__c> child_ra_for_resource = ras_per_resources.get(res.Id);
            Map<Date, Map<Integer, Integer>> used_hours = new Map<Date, Map<Integer, Integer>>();
            Map<Integer, Integer> sample_used_hours = new Map<Integer, Integer>();
            for(Integer i = 0; i < 24; i++) {
                sample_used_hours.put(i, 0);
            }

            for(Resource_Assignment__c r : child_ra_for_resource) {
                if (!used_hours.containsKey(r.Start_Time__c.date())) {
                    used_hours.put(r.Start_Time__c.date(), sample_used_hours.clone());
                }
                Integer start_h = Integer.valueOf(r.Start_Hour__c);
                Integer end_h = Integer.valueOf(r.End_Hour__c);

                for(Integer i = start_h; i < end_h; i++) {
                    used_hours.get(r.Start_Time__c.date()).put(i, used_hours.get(r.Start_Time__c.date()).get(i) + 1);
                }
            }

            for(Date d : used_hours.keySet()) {
                for(Integer i = 0; i < 24; i++) {
                    if (used_hours.get(d).get(i) > 1) {
                        is_error = true;
                        String error_line = '### RESULT: OVERLAP RESOURCES: ' 
                                        + res.Name + '(' + res.Id + ') -- for date: ' + d +', for hour: ' 
                                        + i
                                        + ' : ' 
                                        + used_hours.get(d).get(i) + ' work orders scheduled!';
                        error += error_line;
                        System.debug(error_line);
                    }
                }
            }

        }

        if (is_error) {
            throw new InvalidaDataException(error);
        }
    }

    public class InvalidaDataException extends Exception {}

}