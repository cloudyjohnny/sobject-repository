/*
 * Copied and slightly modified from https://www.jamessimone.net/blog/joys-of-apex/repository-pattern/
 */
public with sharing class QueryCondition implements Comparable {
    public enum Operator {
        EQUALS,
        NOT_EQUALS,
        LESS_THAN,
        LESS_THAN_OR_EQUAL,
        GREATER_THAN,
        GREATER_THAN_OR_EQUAL
    }

    private final SObjectField field;
    private final Operator operator;
    private final List<Object> values;

    private static Boolean isSet = false;

    public QueryCondition(SObjectField field, Operator operator, Object value) {
        this(field, operator, new List<Object>{ value });
    }

    public QueryCondition(SObjectField field, Operator operator, List<Object> values) {
        this.field = field;
        this.operator = operator;
        this.values = values;
    }

    public override String toString() {
        String fieldName = this.field.getDescribe().getName();
        String valueString = this.convertToString(this.values);
        return fieldName + ' ' + this.getOperator() + ' ' + valueString;
    }

    private String convertToString(Object value) {
        if (value == null) {
            return 'null';
        } else if (value instanceof Datetime) {
            return this.formatDatetime(value);
        } else if (value instanceof List<Object>) {
            return this.formatList(value);
        } else if (value instanceof String) {
            String input = (String) value;
            return '\'' + String.escapeSingleQuotes(input) + '\'';
        }

        String valueString = String.valueOf(value);

        //checking for set since instance of Set is not supported
        if (valueString.startsWith('{') && valueString.endsWith('}')) {
            return this.formatSet(valueString);
        }

        return valueString;
    }

    private String formatDatetime(Object value) {
        Datetime dt = (Datetime) value;
        return dt.format(
            'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'',
            'Greenwich Mean Time'
        );
    }

    private String formatList(Object value) {
        List<Object> values = (List<Object>) value;
        List<String> innerStrings = new List<String>();

        for (Object innerPred : values) {
            // recurse for string value
            String innerString = this.convertToString(innerPred);
            innerStrings.add(innerString);
        }

        String start = innerStrings.size() > 1 ? '(' : '';
        String ending = innerStrings.size() > 1 ? ')' : '';
        
        return start + String.join(innerStrings, ',') + ending;
    }

    private String formatSet(String valueString) {
        List<String> setInner = valueString.substring(
            1,
            valueString.length() - 1
        )
        .split(',');
        isSet = setInner.size() > 1;
        return this.convertToString(setInner);
    }

    private String getOperator() {
        Boolean isList = this.values.size() > 1;
        switch on this.operator {
            when EQUALS {
                return isList || isSet ? 'in' : '=';
            }
            when NOT_EQUALS {
                return isList || isSet ? 'not in' : '!=';
            }
            when LESS_THAN {
                return '<';
            }
            when LESS_THAN_OR_EQUAL {
                return '<=';
            }
            when GREATER_THAN {
                return '>';
            }
            when GREATER_THAN_OR_EQUAL {
                return '>=';
            }
            when else {
                return null;
            }
        }
    }

    public Boolean equals(Object thatObject) {
        if (thatObject instanceof QueryCondition) {
            QueryCondition that = (QueryCondition) thatObject;
            return this.toString() == that.toString();
        }

        return false;
    }

    public Integer compareTo(Object thatObject) {
        QueryCondition that = (QueryCondition) thatObject;
        return this.toString().compareTo(that.toString());
    }

    public Integer hashCode() {
        return this.toString().hashCode();
    }
}
