public interface ISObjectRepository {
    ISObjectRepository selectField(String field);
    ISObjectRepository selectField(SObjectField field);
    ISObjectRepository selectFields(List<String> fields);
    ISObjectRepository selectFields(List<SObjectField> fields);
    ISObjectRepository selectFields(Set<String> fields);
    ISObjectRepository selectFields(Set<SObjectField> fields);
    ISObjectRepository selectFields(Schema.FieldSet fields);
    ISObjectRepository selectChild(String relationshipName, ISObjectRepository childRepo);
    ISObjectRepository selectParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo);
    ISObjectRepository whereField(String fieldName, QueryCondition.Operator operator, Object value);
    ISObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, Object value) ;
    ISObjectRepository whereField(String fieldName, QueryCondition.Operator operator, List<Object> values);
    ISObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, List<Object> values);
    ISObjectRepository whereParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo);
    ISObjectRepository joinParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo);
    List<String> getSelectedFields();
    String getQueryString();
    Schema.SObjectType getSObjectType();
    List<SObject> getResults();
    List<SObject> find(SObject recordToFind);
    ISObjectRepository add(SObject record);
    ISObjectRepository remove(SObject record);
    List<SObject> save();
    List<SObject> insertNew();
    List<SObject> updateExisting();
    List<SObject> deleteExisting();
}
