public with sharing class Injector {
    //Using a static map to start, but this can easily be more dynamic in the future
    private static final Map<Type, Type> INTERFACE_TO_IMPLEMENTATION_MAP = new Map<Type, Type> {
        IServices.RepoService.class => SObjectRepository.class
    };

    public static Object init(Type interfaceType) {
        Type implementation = INTERFACE_TO_IMPLEMENTATION_MAP.get(interfaceType);
        return implementation.newInstance();
    }
}
