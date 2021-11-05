/*
 * Validates SObject types, fields, and relationships
 * @author github@cloudyjohnny
 */
public class SchemaValidator {
    private Schema.SObjectType objectType;

    public SchemaValidator(Schema.SObjectType objectType) {
        this.objectType = objectType;
    }

    public void validateField(SObjectField field) {
        this.validateField(field.getDescribe().getName());
    }

    public void validateField(String fieldName) {
        if (!this.objectType.getDescribe().fields.getMap().containsKey(fieldName)) {
            throw new InvalidFieldException (
                String.format(
                    InvalidFieldException.MESSAGE_TEMPLATE, 
                    new List<String> { fieldName, this.objectType.getDescribe().getName() }
                )
            );
        }
    }

    public void validateSObjectType(SObject record) {
        if(record.getSObjectType() != this.objectType) {
            throw new InvalidSObjectTypeException(
                String.format(
                    InvalidSObjectTypeException.MESSAGE_TEMPLATE,
                    new List<String> {
                        this.objectType.getDescribe().getName(),
                        record.getSObjectType().getDescribe().getName()
                    }
                )
            );
        }
    }

    public void validateChildRelationship(String relationshipName, Schema.SObjectType childType) {
        List<Schema.ChildRelationship> childRelationships = this.objectType.getDescribe().getChildRelationships();
        for(Schema.ChildRelationship currRelationship : childRelationships) {
            if (currRelationship.getRelationshipName() == relationshipName && currRelationship.getChildSObject() == childType) {
                return;
            }
        }

        throw new InvalidRelationshipException (
            String.format(
                InvalidChildRelationshipException.MESSAGE_TEMPLATE,
                new List<String> {
                    relationshipName,
                    childType.getDescribe().getName(),
                    this.objectType.getDescribe().getName()
                }
            )
        );
    }

    public void validateParentRelationship(Schema.SObjectField relationshipField, Schema.SObjectType parentType) {
        this.validateField(relationshipField);
        for(Schema.SObjectType currRelationshipType : relationshipField.getDescribe().getReferenceTo()) {
            if(currRelationshipType == parentType) {
                return;
            }
        }

        throw new InvalidChildRelationshipException (
            String.format(
                InvalidChildRelationshipException.MESSAGE_TEMPLATE,
                new List<String> {
                    relationshipField.getDescribe().getName(),
                    parentType.getDescribe().getName(),
                    this.objectType.getDescribe().getName()
                }
            )
        );
    }

    
}
