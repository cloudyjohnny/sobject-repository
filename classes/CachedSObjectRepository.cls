public with sharing class CachedSObjectRepository extends SObjectRepository implements IServices.RepoService, ISObjectRepository {
    private static Map<Id, SObject> recordCache;
    private static Map<String, List<SObject>> queryCache;
    private SObjectField idField;

    public CachedSObjectRepository() {
        super();
        this.initCaches();
    }

    public CachedSObjectRepository(Schema.SObjectType objectType) {
        super(objectType);
        
        this.initCaches();
        this.idField = objectType
            .getDescribe()
            .fields
            .getMap()
            .get('Id');
    }

    public void initCaches() {
        if(recordCache == null) {
            recordCache = new Map<Id, SObject>();
        }
        if(queryCache == null) {
            queryCache = new Map<String, List<SObject>>();
        }
    }

    public static void bustCaches() {
        recordCache = new Map<Id, SObject>();
        queryCache = new Map<String, List<SObject>>();
    }

    public override SObjectRepository forObject(Schema.SObjectType objectType){
        return new CachedSObjectRepository(objectType);
    }

    public override List<SObject> getResults() {
        if(this.isQueryById()) {
            return this.getResultsFromIdCache();
        }

        return this.getResultsFromQueryCache();
    }
    
    private Boolean isQueryById() {
        if(this.query.getWhereConditions().size() > 1 || !this.query.getParentWhereConditions().isEmpty()) {
            return false;
        }

        for(QueryCondition condition : this.query.getWhereConditions()) {
            if(condition.getFieldName().equals('Id') && condition.getOperator() == QueryCondition.Operator.EQUALS) {
                return true;
            }
        }

        return false;
    }

    private List<SObject> getResultsFromIdCache() {
        Set<Id> uniqueIds = new Set<Id>();

        for(QueryCondition condition : this.query.getWhereConditions()) {
            for(Object currValue : condition.getValues()) {
                if(currValue instanceof List<Id>) {
                    uniqueIds.addAll((List<Id>)currValue);
                } else if(currValue instanceof Set<Id>) {
                    uniqueIds.addAll((Set<Id>)currValue);
                } else {
                    uniqueIds.add((Id)currValue);
                }
            }
        }

        if(!recordCache.keySet().containsAll(uniqueIds)){
            this.addIdsToRecordCache(uniqueIds);
        }
        
        List<SObject> results = new List<SObject>();
        for(Id currId : uniqueIds){
            results.add(recordCache.get(currId));
        }

        return results;
    }

    private void addIdsToRecordCache(Set<Id> ids) {
        this.addIdFieldToQuery();
        this.whereField(this.idField, QueryCondition.Operator.EQUALS, ids);
        this.addRecordsToIdCache(super.getResults());
    }

    private void addIdFieldToQuery() {
        if(!this.getQueryString().substringBefore('FROM').contains('Id')) {
            this.selectField(this.idField);
        }
    }

    private void addRecordsToIdCache(List<SObject> records) {
        for(SObject record: records) {
            recordCache.put(record.Id, record);
        }
    }

    private List<SObject> getResultsFromQueryCache() {
        String queryString = this.getQueryString();
        if(!queryCache.containsKey(queryString)){
            this.addIdFieldToQuery();
            List<SObject> records = super.getResults();
            queryCache.put(queryString, records);
        }
        return queryCache.get(queryString);
    }
}