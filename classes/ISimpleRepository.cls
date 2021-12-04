public interface ISimpleRepository {
    ISimpleRepository selectField(String field);
    ISimpleRepository selectFields(List<String> fields);
    ISimpleRepository selectFields(Set<String> fields);
    ISimpleRepository selectFields(Schema.FieldSet fields);
    ISimpleRepository whereField(String fieldName, QueryCondition.Operator operator, Object value);
    ISimpleRepository whereField(String fieldName, QueryCondition.Operator operator, List<Object> values);
    Schema.SObjectType getSObjectType();
    String getQueryString();
    List<SObject> getResults();
    List<SObject> find(SObject recordToFind);
    ISimpleRepository add(SObject record);
    ISimpleRepository remove(SObject record);
    List<SObject> save();
    List<SObject> insertNew();
    List<SObject> updateExisting();
    List<SObject> deleteExisting();
}