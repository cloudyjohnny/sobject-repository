/**
    SObjectRepository allows you to cleanly compose SOQL queries in an OO fashion.
    It also enabled dependency injection for any DMLs.
    @author https://github.com/cloudyjohnny
*/
public with sharing virtual class SObjectRepository implements ISObjectRepository, IServices.RepoService {
    private Schema.SObjectType objectType;

    private QueryStringBuilder query;
    private CRUDService crud;
    private SchemaValidator schemaValidator;

    public SObjectRepository(Schema.SObjectType objectType) {
        this.objectType = objectType;
        this.query = new QueryStringBuilder(this.objectType);
        this.crud = new CRUDService(this.objectType);
        this.schemaValidator = new SchemaValidator(this.objectType);
    }

    public SObjectRepository forObject(Schema.SObjectType objectType) {
        return new SObjectRepository(objectType);
    }

    /*
     * Query Operations
     */

    public SObjectRepository selectField(SObjectField field) {
        this.schemaValidator.validateField(field);
        this.query.selectField(field);
        return this;
    }

    public SObjectRepository selectFields(List<SObjectField> fields) {
        for (SObjectField currField : fields) {
            this.selectField(currField);
        }

        return this;
    }

    public SObjectRepository selectFields(Set<SObjectField> fields) {
        for (SObjectField field : fields) {
            this.selectField(field);
        }

        return this;
    }

    public SObjectRepository selectFields(Schema.FieldSet fieldSet) {
        for(Schema.FieldSetMember currField : fieldSet.getFields()) {
            this.selectField(currField.getSObjectField());
        }

        return this;
    }

    public List<String> getSelectedFields() {
        return this.query.getSelectedFields();
    }

    public SObjectRepository selectChild(String relationshipName, ISObjectRepository childRepo) {
        schemaValidator.validateChildRelationship(relationshipName, childRepo.getSObjectType());
        this.query.selectChild(relationshipName, childRepo);

        return this;
    }    

    private SObjectRepository selectParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        schemaValidator.validateParentRelationship(relationshipField, parentRepo.getSObjectType());
        this.query.selectParent(relationshipField, parentRepo);

        return this;
    }    

    public SObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, Object value) {
        this.schemaValidator.validateField(field);
        this.query.whereField(field, operator, value);
        return this;
    }

    public SObjectRepository whereField(SObjectField field, QueryCondition.Operator operator, List<Object> values) {
        this.schemaValidator.validateField(field);
        this.query.whereField(field, operator, values);
        return this;
    }

    private SObjectRepository whereParent(Schema.SObjectField relationshipField, ISObjectRepository parentRepo) {
        schemaValidator.validateParentRelationship(relationshipField, parentRepo.getSObjectType());
        this.query.whereParent(relationshipField, parentRepo);
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

    public String getQueryString() {
        return this.query.getQueryString();
    }

    public virtual List<SObject> getResults() {
        String queryString = this.query.getQueryString();
        this.query.reset();

        return Database.query(queryString);
    }

    public List<SObject> find(SObject recordToFind) {
        this.schemaValidator.validateSObjectType(recordToFind);
        String queryString = this.query.getFindQueryString(recordToFind);
        this.query.reset();
        return Database.query(queryString);
    }

    /* 
     *  CRUD operations
     */

    public SObjectRepository add(SObject record) {
        this.crud.add(record);
        return this;
    }

    public SObjectRepository remove(SObject record) {
        this.crud.remove(record);
        return this;
    }

    public List<SObject> save() {
        List<SObject> records = this.crud.save();
        this.crud.reset();
        return records;
    }

    public List<SObject> insertNew() {
        List<SObject> records = this.crud.insertNew();
        this.crud.reset();
        return records;
    }

    public List<SObject> updateExisting() {
        List<SObject> records = this.crud.updateExisting();
        this.crud.reset();
        return records;
    }

    public List<SObject> deleteExisting() {
        List<SObject> records = this.crud.deleteExisting();
        this.crud.reset();
        return records;
    }
}