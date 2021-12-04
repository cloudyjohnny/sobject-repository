public class IServices {
    public interface RepoService {
        ISObjectRepository forObject(SObjectType type);
    }

    public interface SimpleRepoService {
        ISimpleRepository forObject(SObjectType type);
    }
}
