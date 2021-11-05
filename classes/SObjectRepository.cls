/**
    SObjectRepository allows you to cleanly compose SOQL queries in an OO fashion.
    It also enabled dependency injection for any DMLs.
    @author https://github.com/cloudyjohnny
*/
public with sharing virtual class SObjectRepository implements ISObjectRepository {
    private Schema.SObjectType objectType;
    private List<String> selectedFields;
    private List<String> selectedChildQueries;
    private Set<QueryCondition> whereConditions;
    private List<String> parentWhereConditions;

    private List<SObject> recordsToCreate;
    private List<SObject> recordsToUpdate;
    private List<SObject> recordsToDelete;

    private SchemaValidator schemaValidator;

    private final String QUERY_STRING_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2}';
    private final String FROM_OBJECT_TEMPLATE = 'FROM {0}';
    private final String SEPARATOR = ' AND ';

    public SObjectRepository(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.resetQueryVariables();
        this.resetSaveVariables();
        this.schemaValidator = new SchemaValidator(this.objectType);
    }

    private void resetQueryVariables() {
        this.selectedFields = new List<String>();
        this.selectedChildQueries = new List<String>();
        this.whereConditions = new Set<QueryCondition>();
        this.parentWhereConditions = new List<String>();
    }

    private void resetSaveVariables() {
        this.recordsToCreate = new List<SObject>();
        this.recordsToUpdate = new List<SObject>();
        this.recordsToDelete = new List<SObject>();
    }

    /*
     * Query Operations
     */

    public SObjectRepository selectField(String fieldName) {
        schemaValidator.validateField(fieldName);
        selectedFields.add(fieldName);        
        return this;
    }

    public SObjectRepository selectField(SObjectField field) {
        return this.selectField(field.getDescribe().getName());
    }

    public SObjectRepository selectFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.selectField(fieldName);
        }

        return this;
    }

    public SObjectRepository selectFields(List<SObjectField> fields) {
        for (SObjectField currField : fields) {
            this.selectField(currField);
        }

        return this;
    }

    public SObjectRepository selectFields(Set<String> fields) {
        return this.selectFields(new List<String>(fields));
    }

    public SObjectRepository selectFields(Set<SObjectField> fields) {
        for (SObjectField field : fields) {
            this.selectField(field);
        }

        return this;
    }

    public SObjectRepository selectFields(Schema.FieldSet fieldSet) {
        for(Schema.FieldSetMember currField : fieldSet.getFields()) {
            this.selectField(currField.getFieldPath());
        }

        return this;
    }

    public List<String> getSelectedFields() {
        return this.selectedFields;
    }

    public SObjectRepository selectChild(String relationshipName, ISObjectRepository childRepo) {
        schemaValidator.validateChildRelationship(relationshipName, childRepo.getSObjectType());
        String childQueryString = childRepo.getQueryString();
        String originalFromClause = String.format(
            FROM_OBJECT_TEMPLATE,
            new List<String> {
                childRepo
                    .getSObjectType()
                    .getDescribe()
                    .getName()
            }
        );
        String newFromClause = String.format(FROM_OBJECT_TEMPLATE, new List<String> { relationshipName });
        String newChildQueryString = childQueryString.replace(originalFromClause, newFromClause);

        if(String.isBlank(newChildQueryString.substringAfter('WHERE'))) {
            newChildQueryString = newChildQueryString.substringBefore(' WHERE');
        }

        this.selectedChildQueries.add(newChildQueryString);

        return this;
    }    

    public SObjectRepository selectParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        schemaValidator.validateParentRelationship(relationshipField, parentRepo.getSObjectType());
        String relationshipName = relationshipField.getDescribe().getRelationshipName();
        for (String currParentField : parentRepo.getSelectedFields()) {
            this.selectedFields.add(relationshipName + '.' + currParentField);
        }

        return this;
    }    

    public SObjectRepository whereField(String fieldName, QueryCondition.Operator operator, Object value) {
        schemaValidator.validateField(fieldName);
        SObjectField field = this.objectType.getDescribe().fields.getMap().get(fieldName);
        this.whereConditions.add(new QueryCondition(field, operator, value));
        return this;
    }

    public SObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, Object value) {
        this.whereConditions.add(new QueryCondition(field, operator, value));
        return this;
    }

    public SObjectRepository whereField(String fieldName, QueryCondition.Operator operator, List<Object> values) {
        schemaValidator.validateField(fieldName);
        SObjectField field = this.objectType.getDescribe().fields.getMap().get(fieldName);
        this.whereConditions.add(new QueryCondition(field, operator, values));
        return this;
    }

    public SObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, List<Object> values) {
        this.whereConditions.add(new QueryCondition(field, operator, values));
        return this;
    }

    public SObjectRepository whereParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        schemaValidator.validateParentRelationship(relationshipField, parentRepo.getSObjectType());
        String relationshipName = relationshipField.getDescribe().getRelationshipName();
        String parentQueryString = parentRepo.getQueryString();
        List<String> parentWhereConditions = parentQueryString.substringAfter('WHERE').split(SEPARATOR);
        for (String currParentCondition : parentWhereConditions) {
            this.parentWhereConditions.add(relationshipName + '.' + currParentCondition.trim());
        }

        return this;
    }

    public SObjectRepository joinParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        this.selectParent(relationshipField, parentRepo);
        this.whereParent(relationshipField, parentRepo);
        return this;
    }

    public Schema.SObjectType getSObjectType() {
        return this.objectType;
    }

    public virtual List<SObject> getResults() {
        String queryString = this.getQueryString();
        System.debug(queryString);
        this.resetQueryVariables();

        return Database.query(queryString);
    }

    public String getQueryString() {
        List<String> conditionList = new List<String>();
        for (QueryCondition currCondition : this.whereConditions) {
            conditionList.add(currCondition.toString());
        }

        String selectClause = String.join(this.selectedFields, ', ');

        if (!this.selectedChildQueries.isEmpty()) {
            if (!this.selectedFields.isEmpty()) {
                selectClause += ', ';
            }
            selectClause += '(' + String.join(this.selectedChildQueries, '),(') + ')';
        }

        String whereClause = String.join(conditionList, SEPARATOR);

        if (!this.parentWhereConditions.isEmpty()) {
            if(!conditionList.isEmpty()) {
                whereClause += SEPARATOR;
            }

            whereClause += String.join(this.parentWhereConditions, SEPARATOR);
        }

        String queryString = String.format(
            QUERY_STRING_TEMPLATE,
            new List<String> {
                selectClause,
                this.objectType.getDescribe().getName(),
                whereClause
            }
        );

        return queryString;
    }

    public List<SObject> find(SObject recordToFind) {
        Map<String, Object> mappedProperties = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(recordToFind));
        mappedProperties.remove('attributes');
        System.debug(mappedProperties.keySet());
        for (String currFieldName : mappedProperties.keySet()) {
            System.debug(currFieldName);
            this.whereField(currFieldName, QueryCondition.Operator.Equals, mappedProperties.get(currFieldName));
        }

        return this.getResults();
    }

    /* 
     *  CRUD operations
     */

    public SObjectRepository add(SObject record) {
        schemaValidator.validateSObjectType(record);
        if (record.Id == null) {
            this.recordsToCreate.add(record);
        }
        else {
            this.recordsToUpdate.add(record);
        }
        return this;
    }

    public SObjectRepository remove(SObject record) {
        schemaValidator.validateSObjectType(record);
        this.recordsToDelete.add(record);
        return this;
    }

    public List<SObject> save() {
        List<SObject> savedRecords = new List<SObject>();
        if (!this.recordsToCreate.isEmpty()) {
            savedRecords.addAll(this.insertNew());
        }
        if (!this.recordsToUpdate.isEmpty()) {
            savedRecords.addAll(this.updateExisting());
        }
        if (!this.recordsToDelete.isEmpty()) {
            savedRecords.addAll(this.deleteExisting());
        }

        this.resetSaveVariables();

        return savedRecords;
    }

    public List<SObject> insertNew() {
        insert this.recordsToCreate;
        return this.recordsToCreate;
    }

    public List<SObject> updateExisting() {
        update this.recordsToUpdate;
        return this.recordsToUpdate;
    }

    public List<SObject> deleteExisting() {
        delete this.recordsToDelete;
        return this.recordsToDelete;
    }
}