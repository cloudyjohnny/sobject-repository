@IsTest
private class SObjectRepository_Tests {
    @IsTest
    private static void it_should_return_created_lead() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'fake@email.com'
        );
        
        SObjectRepository testLeadRepo = new SObjectRepository(Lead.SObjectType);
        testLeadRepo
            .add(testLead)
            .save();
    
        Test.startTest();

        List<Lead> findTest = (List<Lead>) testLeadRepo
            .selectField(Lead.Id)
            .find(new Lead(
                LastName = testLead.LastName,
                Email = testLead.Email
            ));

        List<Lead> whereTest = (List<Lead>) testLeadRepo
            .selectField(Lead.Id)
            .whereField(Lead.Id, QueryCondition.Operator.EQUALS, testLead.Id)
            .getResults();

        Test.stopTest();

        System.assertEquals(1, findTest.size(), 'Incorrect number of leads found.');
        System.assertEquals(1, whereTest.size(), 'Incorrect number of leads return in query results.');

        System.assertEquals(testLead.Id, findTest.get(0).Id, 'Incorrect lead found.');
        System.assertEquals(testLead.Id, whereTest.get(0).Id, 'Incorrect lead returned in query.');
    }
}
