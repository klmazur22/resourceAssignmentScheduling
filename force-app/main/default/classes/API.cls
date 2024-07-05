@RestResource(urlMapping='/*')
global without sharing class API {
    /* Classes and vars */
    public class APIException extends Exception {}
    global class APIResponse {
        public Boolean success { get {
            if (success == null) { return true; }
            return success;
        } set; }
        public List<APIError> errors { get; set; }
        public Object data { get; set; }

        public Blob getResult()  {
            return Blob.valueOf(JSON.serializePretty(this));
        }
    }
    global class APIError {
        String text;
        String code;
        private Integer httpCode;
    }
    
    @HttpGet
    global static void getRequest() {
        Object response = null;
        try {
            ParsedRequest pr = parseRequest();
            if (pr.method == 'weeks' && pr.targetId == null) {
                response = getWeeks();
            } else if (pr.method == 'work_orders' && pr.targetId != null) {
                response = getWorkOrders(pr.targetId);
            } else if (pr.method == 'resources' && pr.targetId != null) {
                response = getResources(pr.targetId);
            } else {
            	throw new APIException('Unknown route: GET \'' + pr.method + '\'');
            }
        } catch (APIException e) {
            prepareResponse(null,generateAPIErrors(e.getMessage().split('@@@@')));
            return;
        }
        prepareResponse(response);
        return;
    }
    
    @HttpPost
    global static void postRequest() {
        Object response = null;
        try {
            ParsedRequest pr = parseRequest();
            if (pr.method == 'schedule') {
                response = postSchedule();
            } else {
                throw new APIException('Unknown route: POST \'' + pr.method + '\'');
            }
        } catch (APIException e) {
            prepareResponse(null,generateAPIErrors(e.getMessage().split('@@@@')));
            return;
        }
        prepareResponse(response);
        return;
    }
    
    public class ScheduleInput {
        Id weekId;
        List<Resource_Assignment__c> assignments;
    }
    
    private static List<Week__c> getWeeks() {
        return [SELECT Id, Name, Fine_per_unfinished_WO__c, Number_of_Work_Orders__c FROM Week__c];
    }
    private static List<Work_Order__c> getWorkOrders(Id weekId) {
        return [SELECT Id, Name, Amount_of_Work__c, End_Time__c, Fine_per_hour_delay__c, Start_Time__c, Week__c FROM Work_Order__c WHERE Week__c = :weekId];
    }
    private static List<Resource__c> getResources(Id weekId) {
        return [SELECT Id, Name, End_Regular_Working_Time__c, Overtime_Capable__c, Overtime_Rate__c, Performance__c, Regular_Rate__c, Start_Regular_Working_Time__c, Week__c FROM Resource__c WHERE Week__c = :weekId];
    }
    private static Id postSchedule() {
        RestRequest req = RestContext.request;
        System.SavePoint sp = Database.setSavepoint();
        try {
        	ScheduleInput input = (ScheduleInput) JSON.deserialize(req.requestBody.toString(), ScheduleInput.Class);
            if (input.weekId == null) {
                throw new APIException('NO_WEEK_ID');
            }
            List<Week__c> weeks = [SELECT Name FROM Week__c WHERE Id = :input.weekId];
            if (weeks.size() == 0) {
                throw new APIException('INVALID_WEEK_ID');
            }
            if (input.assignments == null || input.assignments.size() == 0) {
                throw new APIException('NO_ASSIGNMENTS');
            }
            SchedulerAPI sch = new SchedulerAPI();
            sch.setWeek(input.weekId);
            sch.setAssignments(input.assignments);
            try {
                return sch.run();
            } catch (Exception e) {
                throw new APIException('Error running scheduler: ' + e.getMessage()  + e.getStackTraceString());
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new APIException(e.getMessage());
        }
        return null;
    }

	/* Internal, private, methods */
    private static void prepareResponse(Object data) {
        prepareResponse(data, null);
    }
    private static void prepareResponse(Object data, List<APIError> errors) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        APIResponse response = new APIResponse();
        response.data = data;
        if (errors != null) {
            response.errors = errors;
            response.success = false;
            Boolean found404 = false;
            Boolean found500 = false;
            for (APIError e: errors) {
                if (e.httpCode == 404) found404 = true;
                if (e.httpCode == 500) found500 = true;
            }
            if (found500 == true) {
                res.statusCode = 500;
            } else if (found404 == true) {
                res.statusCode = 404;
            } else {
                res.statusCode = 400;
            }
        }
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = response.getResult();
    }
    public class ParsedRequest {
        public ParsedRequest(String method, Id targetId, String uuid) {
            this.method = method;
            this.targetId = targetId;
            this.uuid = uuid;
        }
        public String method;
        public Id targetId;
        public String uuid;
    }
    private static ParsedRequest parseRequest() {
        RestRequest req = RestContext.request;
        List<String> errors = new List<String>();
        if (req.headers.get('Username') == null) {
            errors.add('MISSING_USERNAME');
        }
        if (req.headers.get('Password') == null) {
            errors.add('MISSING_PASSWORD');
        }
        if (errors.size() == 0) {
            String username = req.headers.get('Username');
            String password = req.headers.get('Password');
            if (username == 'api' && password == 'developer') {
                
            } else {
            	errors.add('NO_SUCH_ACCOUNT');
            }
        }
        if (errors.size() > 0) {
            throw new APIException(String.join(errors, '@@@@'));
        }
        String requestURI = req.requestURI.substring(1);
        if (requestURI.right(1) == '/') {
            requestURI = requestURI.substring(0, requestURI.length()-1);
        }        
        List<String> urlParts = requestURI.split('/');
        List<String> methodParts = new List<String>();
        Id targetId = null;
        String uuid = null;
        for (String s : urlParts) {
            Id parsedId = null;
            if (s.length() == 15 || s.length() == 18) {
                try {
                    Id tmp = Id.valueOf(s);
                    if (tmp != null) {
                        parsedId = tmp;
                    }
                } catch (Exception e) {
                    // No point
                }
            }
            if (s.length() == 36) {
                uuid = s;
            } else if (parsedId == null) {
                methodParts.add(s);
            } else {
                targetId = parsedId;
            }
        }
        return new ParsedRequest(String.join(methodParts, '/'), targetId, uuid);
    }
    private static Boolean isNullOrEmpty(Object o) {
        if (o == null) {
            return true;
        }
        if (String.valueOf(o) == '') {
            return true;
        }
        return false;
    }
    private static APIError generateError(String code) {
        APIError error = new APIError();
        error.code = code;

        error.httpCode = 400;

        if (code == 'NO_WEEK_ID') {
            error.text = 'No weekId passed';
            error.httpCode = 400;
        } else if (code == 'INVALID_WEEK_ID') {
            error.text = 'Invalid weekId passed';
            error.httpCode = 400;
        } if (code == 'NO_WEEK_ID') {
            error.text = 'No weekId passed';
            error.httpCode = 400;
        } else if (code == 'NO_ASSIGNMENTS') {
            error.text = 'No assignments were passed';
            error.httpCode = 400;
        } else if (code.contains('Unknown route')) {
            error.text = code;
            error.code = 'UNKNOWN_ROUTE';
        } else if (code == 'INVALID_JSON') {
          	error.text = 'Invalide JSON-bericht';
        } else if (code.contains('No content to map to Object')) {
            error.text = 'No body was passed while a body was expected';
            error.code = 'MISSING_BODY';
        } else {
            error.code = 'INTERNAL_ERROR';
            error.text = 'Internal error: ' + code;
            error.httpCode = 500;
        }
        return error;
    }
    private static List<APIError> generateAPIErrors(List<String> errors) {
        List<APIError> result = new List<APIError>();
        for (String s : errors) {
            result.add(generateError(s));
        }
        if (result.size() > 0) {
            return result;
        } else {
            return null;
        }
    }
}