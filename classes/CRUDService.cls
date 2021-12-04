public with sharing class CRUDService {
    private List<SObject> recordsToCreate;
    private List<SObject> recordsToUpdate;
    private List<SObject> recordsToDelete;
    private SchemaValidator schemaValidator;

    public CRUDService(SObjectType sObjectType) {
        schemaValidator = new SchemaValidator(sObjectType);
        this.reset();
    }

    public void reset() {
        this.recordsToCreate = new List<SObject>();
        this.recordsToUpdate = new List<SObject>();
        this.recordsToDelete = new List<SObject>();
    }

    public void add(SObject record) {
        schemaValidator.validateSObjectType(record);
        if (record.Id == null) {
            this.recordsToCreate.add(record);
        }
        else {
            this.recordsToUpdate.add(record);
        }
    }

    public void remove(SObject record) {
        schemaValidator.validateSObjectType(record);
        this.recordsToDelete.add(record);
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