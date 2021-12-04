public with sharing class QueryStringBuilder {
    private Schema.SObjectType objectType;
    private List<String> selectedFields;
    private List<String> selectedChildQueries;
    private Set<QueryCondition> whereConditions;
    private List<String> parentWhereConditions;

    private final String QUERY_STRING_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2}';
    private final String FROM_OBJECT_TEMPLATE = 'FROM {0}';
    private final String SEPARATOR = ' AND ';

    public QueryStringBuilder(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.reset();
    }

    public void reset() {
        this.selectedFields = new List<String>();
        this.selectedChildQueries = new List<String>();
        this.whereConditions = new Set<QueryCondition>();
        this.parentWhereConditions = new List<String>();
    }

    public QueryStringBuilder selectField(String fieldName) {
        selectedFields.add(fieldName);        
        return this;
    }

    public QueryStringBuilder selectField(SObjectField field) {
        return this.selectField(field.getDescribe().getName());
    }

    public QueryStringBuilder selectFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.selectField(fieldName);
        }

        return this;
    }

    public QueryStringBuilder selectFields(List<SObjectField> fields) {
        for (SObjectField currField : fields) {
            this.selectField(currField);
        }

        return this;
    }

    public QueryStringBuilder selectFields(Set<String> fields) {
        return this.selectFields(new List<String>(fields));
    }

    public QueryStringBuilder selectFields(Set<SObjectField> fields) {
        for (SObjectField field : fields) {
            this.selectField(field);
        }

        return this;
    }

    public QueryStringBuilder selectFields(Schema.FieldSet fieldSet) {
        for(Schema.FieldSetMember currField : fieldSet.getFields()) {
            this.selectField(currField.getFieldPath());
        }

        return this;
    }

    public List<String> getSelectedFields() {
        return this.selectedFields;
    }

    public QueryStringBuilder selectChild(String relationshipName, ISObjectRepository childRepo) {
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

    public QueryStringBuilder selectParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        String relationshipName = relationshipField.getDescribe().getRelationshipName();
        for (String currParentField : parentRepo.getSelectedFields()) {
            this.selectedFields.add(relationshipName + '.' + currParentField);
        }

        return this;
    }    

    public QueryStringBuilder whereField(String fieldName, QueryCondition.Operator operator, Object value) {
        this.whereConditions.add(new QueryCondition(fieldName, operator, value));
        return this;
    }

    public QueryStringBuilder whereField(SObjectField field, QueryCondition.Operator operator, Object value) {
        this.whereConditions.add(new QueryCondition(field, operator, value));
        return this;
    }

    public QueryStringBuilder whereField(String fieldName, QueryCondition.Operator operator, List<Object> values) {
        this.whereConditions.add(new QueryCondition(fieldName, operator, values));
        return this;
    }

    public QueryStringBuilder whereField(SObjectField field, QueryCondition.Operator operator, List<Object> values) {
        this.whereConditions.add(new QueryCondition(field, operator, values));
        return this;
    }

    public QueryStringBuilder whereParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        String relationshipName = relationshipField.getDescribe().getRelationshipName();
        String parentQueryString = parentRepo.getQueryString();
        List<String> parentWhereConditions = parentQueryString.substringAfter('WHERE').split(SEPARATOR);
        for (String currParentCondition : parentWhereConditions) {
            String condition = currParentCondition.trim();
            if (String.isBlank(condition)) {
                continue;
            }
            this.parentWhereConditions.add(relationshipName + '.' + condition);
        }

        return this;
    }

    public QueryStringBuilder joinParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        this.selectParent(relationshipField, parentRepo);
        this.whereParent(relationshipField, parentRepo);
        return this;
    }

    public Schema.SObjectType getSObjectType() {
        return this.objectType;
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

    public String getFindQueryString(SObject recordToFind) {
        Map<String, Object> objectMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(recordToFind));
        objectMap.remove('attributes'); // this is always in the map, but it's not a field
        for (String currFieldName : objectMap.keySet()) {
            this.whereField(currFieldName, QueryCondition.Operator.Equals, objectMap.get(currFieldName));
        }

        return this.getQueryString();
    }
}