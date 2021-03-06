# sobject-repository

Contains SObject Repository for Salesforce Apex. It can handle child queries and nested filters. The approach for complex relationship queries is create a repo instance per object and compose them.
The primary motivation behind this is be able build SOQL queries in a clean, OO fashion.

## Here is a simple insert and query example:

```
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
````

## Here is an example with a complex query across multiple relationships

```
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
```
You'll notice that these queries can grow quite big vertically very quickly. If you prefer to have long queries on a single line, you may find this approach to be burdensome.

## Simple Repository

Alternatively I have included a Simple Repository that does no validation and simple builds the query based on the exact string input. Here is the same complex query from the preceding example using simple repository.

```
new SimpleRepository(Opportunity.SObjectType)
    .selectField('Id')
    .selectField('StageName')
    .selectField('(SELECT Id, Name, ProductCode, UnitPrice, Quantity FROM OpportunityLineItems)')
    .whereField('IsClosed', QueryCondition.Operator.EQUALS, false)
    .whereField('Owner.LastName', QueryCondition.Operator.EQUALS, 'Carmona')
    .whereField('Account.Rating', QueryCondition.Operator.EQUALS, 'Hot')
    .getQueryString();
```

## Some other things
- I've included some interfaces and a sudo-depency injector. There is MockRepository for mocking DMLs in unit tests.
- There's a fairly rebust SchemaValidator for validating SObject fields and relationships, however it doesn't handled nested relationship validation.
- A query string builder that can be used to build query strings without any of the Repository code. Its only depedency ins QueryCondition.cls
- A basic CRUD Service class. I kept it as minimal as possible, but this could be fleshed out.


## Still TODO
- Complex queries using find()
- Filtering by child query