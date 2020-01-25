@IsTest
private class CaseCloseWebServiceTest {

    @TestSetup
    static void createCase() {
        Case record = new Case(
            Status = 'New',
            Origin = 'Web'
        );
        insert record;
    }

    @IsTest
    static void testCloseRequest() {
        Case record = [SELECT Id FROM Case LIMIT 1];

        CaseCloseWebService.CloseCaseRequest requestParams = new CaseCloseWebService.CloseCaseRequest();
        requestParams.caseId = record.Id;
        requestParams.reason = 'User clicked the thingy!';

        RestContext.response = new RestResponse();

        Test.startTest();
        CaseCloseWebService.CloseCaseResult result = CaseCloseWebService.doPost(requestParams);
        Test.stopTest();

        System.assertEquals(record.Id, result.caseId, 'The case ID should be the same.');
        System.assertEquals(true, result.success, 'Operation result should be a success.');
        System.assertEquals(null, result.errors, 'The errors list shouldn\'t even exist.');

        record = [SELECT Id, Status FROM Case LIMIT 1];

        System.assertEquals('Closed', record.Status, 'The case should\'ve been closed.');
    }

    @IsTest
    static void testCaseAlreadyClosed() {
        Case record = [SELECT Id FROM Case LIMIT 1];
        record.Status = 'Closed';
        update record;

        CaseCloseWebService.CloseCaseRequest requestParams = new CaseCloseWebService.CloseCaseRequest();
        requestParams.caseId = record.Id;
        requestParams.reason = 'User clicked the thingy!';

        RestContext.response = new RestResponse();

        Test.startTest();
        CaseCloseWebService.CloseCaseResult result = CaseCloseWebService.doPost(requestParams);
        Test.stopTest();

        System.assertEquals(record.Id, result.caseId, 'The case ID should be the same.');
        System.assertEquals(true, result.success, 'Operation result should be a success.');
        System.assertEquals(null, result.errors, 'The errors list shouldn\'t even exist.');

        record = [SELECT Id, Status FROM Case LIMIT 1];

        System.assertEquals('Closed', record.Status, 'The case should\'ve been closed.');
    }
}
