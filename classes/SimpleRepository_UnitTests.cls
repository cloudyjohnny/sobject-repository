@IsTest
private class SimpleRepository_UnitTests {
    @IsTest
    private static void it_should_build_a_complex_query_string_mith_multiple_joins() {
        String expectedQuery = 'SELECT Id, StageName, (SELECT Id, Name, ProductCode, UnitPrice, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE IsClosed = false AND Owner.LastName = \'Carmona\' AND Account.Rating = \'Hot\'';

        String actualQuery = new SimpleRepository(Opportunity.SObjectType)
            .selectField('Id')
            .selectField('StageName')
            .selectField('(SELECT Id, Name, ProductCode, UnitPrice, Quantity FROM OpportunityLineItems)')
            .whereField('IsClosed', QueryCondition.Operator.EQUALS, false)
            .whereField('Owner.LastName', QueryCondition.Operator.EQUALS, 'Carmona')
            .whereField('Account.Rating', QueryCondition.Operator.EQUALS, 'Hot')
            .getQueryString();

        System.assertEquals(expectedQuery, actualQuery, 'Queries should match.');
    }
}
