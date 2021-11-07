public with sharing class SimpleRepository implements ISimpleRepository, IServices.SimpleRepoService {
    Schema.SObjectType objectType;

    QueryStringBuilder query;
    CRUDService crud;

    public SimpleRepository() { }

    public SimpleRepository(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.query = new QueryStringBuilder(objectType);
        this.crud = new CRUDService(objectType);
    }

    public SimpleRepository forObject(Schema.SObjectType objectType) {
        return new SimpleRepository(objectType);
    }

    public Schema.SObjectType getSObjectType() {
        return objectType;
    }

    public SimpleRepository selectField(String fieldName) {
        this.query.selectField(fieldName);
        return this;
    }

    public SimpleRepository selectFields(List<String> fieldNames) {
        this.query.selectFields(fieldNames);
        return this;
    }

    public SimpleRepository selectFields(Set<String> fieldNames) {
        this.query.selectFields(fieldNames);
        return this;
    }

    public SimpleRepository selectFields(Schema.FieldSet fieldSet) {
        this.query.selectFields(fieldSet);
        return this;
    }

    public SimpleRepository whereField(String fieldName, QueryCondition.Operator operator, Object value) {
        this.query.whereField(fieldName, operator, value);
        return this;
    }

    public SimpleRepository whereField(String fieldName, QueryCondition.Operator operator, List<Object> values) {
        this.query.whereField(fieldName, operator, values);
        return this;
    }

    public Schema.SObjectType getObjectType() {
        return this.objectType;
    }

    public String getQueryString() {
        return this.query.getQueryString();
    }

    public List<SObject> getResults() {
        return Database.query(this.query.getQueryString());
    }

    public List<SObject> find(SObject recordToFind) {
        return Database.query(this.query.getFindQueryString(recordToFind));
    }

    public SimpleRepository add(SObject record) {
        this.crud.add(record);
        return this;
    }

    public SimpleRepository remove(SObject record) {
        this.crud.remove(record);
        return this;
    }

    public List<SObject> save() {
        return this.crud.save();
    }

    public List<SObject> insertNew() {
        return this.crud.insertNew();
    }

    public List<SObject> updateExisting() {
        return this.crud.updateExisting();
    }

    public List<SObject> deleteExisting() {
        return this.crud.deleteExisting();
    }
}
