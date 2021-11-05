@IsTest
private class SObjectRepository_UnitTests {
    private static final String FAKE_ACCOUNT_ID = '001P032kiFCfg2qv';

    @IsTest
    private static void it_should_build_a_basic_query() {
        String expectedQuery = 'SELECT Id FROM Account WHERE Id = \'' + FAKE_ACCOUNT_ID + '\'';
        SObjectRepository accountRepo = new SObjectRepository(Account.SObjectType);
        
        String actualQuery = accountRepo
            .selectField(Account.Id)
            .whereField(Account.Id, QueryCondition.Operator.EQUALS, FAKE_ACCOUNT_ID)
            .getQueryString();

        System.assertEquals(expectedQuery, actualQuery, 'Basic query does not match');
    }

    @IsTest
    private static void it_should_build_a_child_query() {
        String expectedQuery = 'SELECT (SELECT Id, StageName FROM Opportunities) FROM Account WHERE Id = \'' + FAKE_ACCOUNT_ID + '\'';
        SObjectRepository accountRepo = new SObjectRepository(Account.SObjectType);
        SObjectRepository oppRepo = new SObjectRepository(Opportunity.SObjectType);
        
        oppRepo.selectField(Opportunity.Id).selectField(Opportunity.StageName);
        
        String actualQuery = accountRepo
            .selectChild('Opportunities', oppRepo)
            .whereField(Account.Id, QueryCondition.Operator.EQUALS, FAKE_ACCOUNT_ID)
            .getQueryString();

        System.assertEquals(expectedQuery, actualQuery, 'Child query does not match');        
    }

    @IsTest
    private static void it_should_build_a_child_query_with_child_filter() {
        String expectedQuery = 'SELECT Id, Name, (SELECT Id, StageName FROM Opportunities WHERE Amount > 0) FROM Account WHERE Id = \'' + FAKE_ACCOUNT_ID + '\'';
        SObjectRepository accountRepo = new SObjectRepository(Account.SObjectType);
        SObjectRepository oppRepo = new SObjectRepository(Opportunity.SObjectType);

        oppRepo
            .selectField(Opportunity.Id)
            .selectField(Opportunity.StageName)
            .whereField(Opportunity.Amount, QueryCondition.Operator.GREATER_THAN, 0);

        String actualQuery = accountRepo
            .selectField(Account.Id)
            .selectField(Account.Name)
            .selectChild('Opportunities', oppRepo)
            .whereField(Account.Id, QueryCondition.Operator.EQUALS, FAKE_ACCOUNT_ID)
            .getQueryString();

        System.assertEquals(expectedQuery, actualQuery, 'Child query with child filter does not match');
    }

    @IsTest
    private static void it_should_build_a_complex_query_string_mith_multiple_joins() {
        String expectedQuery = 'SELECT Id, StageName, (SELECT Id, Name, ProductCode, UnitPrice, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE IsClosed = false AND Owner.LastName = \'Carmona\' AND Account.Rating = \'Hot\'';

        SObjectRepository oppLineItemRepo = new SObjectRepository(OpportunityLineItem.SObjectType)
            .selectField(OpportunityLineItem.Id)
            .selectField(OpportunityLineItem.Name)
            .selectField(OpportunityLineItem.ProductCode)
            .selectField(OpportunityLineItem.UnitPrice)
            .selectField(OpportunityLineItem.Quantity);
        
        SObjectRepository userRepo = new SObjectRepository(User.SObjectType)
            .whereField(User.LastName, QueryCondition.Operator.EQUALS, 'Carmona');
        
        SObjectRepository accountRepo = new SObjectRepository(Account.SObjectType)
            .whereField(Account.Rating, QueryCondition.Operator.EQUALS, 'Hot');
        
        SObjectRepository oppRepo = new SObjectRepository(Opportunity.SObjectType)
            .selectField(Opportunity.Id)
            .selectField(Opportunity.StageName)
            .selectChild('OpportunityLineItems', oppLineItemRepo)
            .whereField(Opportunity.IsClosed, QueryCondition.Operator.EQUALS, false)
            .joinParent(Opportunity.OwnerId, userRepo)
            .joinParent(Opportunity.AccountId, accountRepo);
        
        String actualQuery = oppRepo.getQueryString();

        System.debug(actualQuery);

        System.assertEquals(expectedQuery, actualQuery, 'Queries should match.');
    }
}
