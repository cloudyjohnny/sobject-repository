# sobject-repository

Contains SObject Repository for Salesforce Apex. It can handle child queries and nested filters. The approach for complex relationship queries is create a repo instance per object and compose them.

## Here is a simple insert and query example:

`
    Lead demoLead = new Lead(
        FirstName = 'Test',
        LastName = 'Lead',
        Email = 'fake@email.com'
    );
    
    SObjectRepository leadRepo = new SObjectRepository(Lead.SObjectType);
    leadRepo
        .add(testLead)
        .save();

    List<Lead> foundLead = (List<Lead>) testLeadRepo
        .selectField(Lead.Id)
        .find(new Lead(
            LastName = testLead.LastName,
            Email = testLead.Email
        ));

    List<Lead> queryResult = (List<Lead>) testLeadRepo
        .selectField(Lead.Id)
        .whereField(Lead.Id, QueryCondition.Operator.EQUALS, testLead.Id)
        .getResults();
`

## Here is an example with a complex query across multiple relationships

`
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

    //Query String = SELECT Id, StageName, (SELECT Id, Name, ProductCode, UnitPrice, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE IsClosed = false AND Owner.LastName = 'Carmona' AND Account.Rating = 'Hot'
    String queryString = oppRepo.getQueryString();

`

## Still TODO
- Complex queries using find()
- Filtering by child query