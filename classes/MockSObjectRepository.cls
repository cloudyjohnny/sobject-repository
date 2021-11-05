/**
    MockRepository for unit testing.
    @author https://github.com/cloudyjohnny
*/
public with sharing class MockSObjectRepository implements ISObjectRepository {
    private List<SObject> recordsToCreate;
    private List<SObject> recordsToUpdate;
    private List<SObject> recordsToDelete;
    private List<SObject> queryResults;
    private String queryString;

    private Schema.SObjectType objectType;
    public List<SObject> savedRecords = new List<SObject>();

    public MockSObjectRepository(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.recordsToCreate = new List<SObject>();
        this.recordsToUpdate = new List<SObject>();
        this.recordsToDelete = new List<SObject>();
        this.queryResults = new List<SObject>();
    }

    public MockSObjectRepository with(List<SObject> mockResults) {
        this.queryResults = mockResults;
        return this;
    }

    public MockSObjectRepository with(String mockQueryString) {
        this.queryString = mockQueryString;
        return this;
    }

    public MockSObjectRepository selectField(String field) { return this; }
    public MockSObjectRepository selectField(SObjectField field) { return this; }
    public MockSObjectRepository selectFields(List<String> fields) { return this; }
    public MockSObjectRepository selectFields(List<SObjectField> fields) { return this; }
    public MockSObjectRepository selectFields(Set<String> fields) { return this; }
    public MockSObjectRepository selectFields(Set<SObjectField> fields) { return this; }
    public MockSObjectRepository selectFields(Schema.FieldSet fields) { return this; }
    public MockSObjectRepository selectChild(String relationshipName, ISObjectRepository childRepo) { return this; }
    public MockSObjectRepository selectParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) { return this; }
    public List<String> getSelectedFields() { return new List<String>(); }
    public MockSObjectRepository whereField(String fieldName, QueryCondition.Operator operator, Object value) { return this; }
    public MockSObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, Object value)  { return this; }
    public MockSObjectRepository whereField(String fieldName, QueryCondition.Operator operator, List<Object> values) { return this; }
    public MockSObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, List<Object> values) { return this; }
    public MockSObjectRepository whereParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) { return this; }
    public MockSObjectRepository joinParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) { return this; }
    public String getQueryString() { return this.queryString; }
    public Schema.SObjectType getSObjectType() { return this.objectType; }
    public List<SObject> getResults() { return this.queryResults; }
    public List<SObject> find(SObject recordToFind) { return this.queryResults; }

    public MockSObjectRepository add(SObject record) {
        if (record.Id == null) {
            this.recordsToCreate.add(record);
        }
        else {
            this.recordsToUpdate.add(record);
        }
        return this;
    }

    public MockSObjectRepository remove(SObject record) {
        this.recordsToDelete.add(record);
        return this;
    }

    public List<SObject> save() {

        savedRecords.addAll(this.recordsToCreate);
        savedRecords.addAll(this.recordsToUpdate);
        savedRecords.addAll(this.recordsToDelete);
        
        return savedRecords;
    }

    public List<SObject> insertNew() { return this.recordsToCreate; }
    public List<SObject> updateExisting() { return this.recordsToUpdate; }
    public List<SObject> deleteExisting() { return this.recordsToDelete; }
}
