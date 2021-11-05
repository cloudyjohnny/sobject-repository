public class SObjectRepositoryInjector {
    /*
     * Using base SObjectRepository for simplicity
     * Currently does nothing useful but in the future will handle custom
     * metadata driven instantiation to properly decouple the
     * ISObjectRepository implementation from the dependent class
     */
    public static ISObjectRepository instantiate(Schema.SObjectType objectType) {
        return new SObjectRepository(objectType);
    }
}
