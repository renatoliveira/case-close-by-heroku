@RestResource(urlMapping='/closeCase/*')
global without sharing class CaseCloseWebService {

    @HttpPost
    global static CloseCaseResult doPost(CloseCaseRequest req) {

        RestResponse res = RestContext.response;
        CloseCaseResult result = new CloseCaseResult();

        if (req.caseId == null) {
            return null;
        }

        Case record = [SELECT Id, Status FROM Case WHERE Id = :req.caseId];

        if (record.Status == 'Closed') {
            res.statusCode = 200;
            result.caseId = record.Id;
            result.success = true;
            result.redirect_url = 'https://google.com/';
            return result;
        }

        record.Status = 'Closed';

        Database.SaveResult sr = Database.update(record);

        result.caseId = req.caseId;

        if (sr.isSuccess()) {
            res.statusCode = 200;
            result.success = true;
            result.redirect_url = 'https://google.com/';
            return result;
        }

        res.statusCode = 500;
        result.errors = new List<String>();
        result.errors.add(sr.getErrors()+'');
        result.success = false;

        return result;
    }

    global class CloseCaseRequest {
        public Id caseId;
        public String reason;
    }

    global class CloseCaseResult {
        public Id caseId;
        public Boolean success;
        public List<String> errors;
        public String redirect_url;
    }
}
