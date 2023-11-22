/**
 * Created by wmccu on 7/20/2021.
 */

public with sharing class ogUserListController {
    @AuraEnabled(Cacheable=true)
    public static List<ogUserListWrapper> getOGUserListWrapper() {
        List<ogUserListWrapper> ogUserListWrappers = new List<ogUserListWrapper>();
        ogUserListWrapper wrapper = new ogUserListWrapper();
        wrapper.currentOrgId = getCurrentOrgId();
        wrapper.loginNonce = generateRandomString(64);
        wrapper.profiles = getProfiles();
        wrapper.roles = getRoles();
        wrapper.permissionSets = getPermissionSets();
        ogUserListWrappers.add(wrapper);
        return ogUserListWrappers;
    }
    @AuraEnabled(Cacheable=true)
    public static List<User> getUsers(String searchTerm, Boolean activeOnly, String selectedProfileId) {
        String numberRecords = '100';
        List<User> userList = new List<User>();
        String query = getBaseUserQuery();
        String whereClause = '';
        if (String.isNotEmpty(searchTerm) || activeOnly || String.isNotEmpty(selectedProfileId)) {
            if (String.isNotEmpty(searchTerm)) {
                whereClause += ' Name LIKE :nameSearch';
            }
            if (activeOnly) {
                whereClause += String.isEmpty(whereClause) ? ' IsActive = TRUE' : ' AND IsActive = TRUE';
            }
            if (String.isNotEmpty(selectedProfileId)) {
                whereClause += String.isEmpty(whereClause) ? ' ProfileId = :selectedProfileId' : ' AND ProfileId = :selectedProfileId';
            }
        }
        query += String.isEmpty(whereClause) ? ' WHERE Profile.Name != NULL' : ' WHERE' + whereClause + ' AND Profile.Name != NULL';
        query += ' ORDER BY Name ASC';
        query += ' LIMIT ' + numberRecords;
        System.debug(query);
        userList = Database.query(query);
        return userList;
    }
    @AuraEnabled(Cacheable=false)
    public static String saveUsers(List<User> users) {
        String message = 'Saved Users';
        try {
            update users;
        } catch (Exception e) {
            message = 'Error: ' + e.getMessage();
        }
        return message;
    }
    @AuraEnabled(Cacheable=false)
    public static ogUserListPermissionSetWrapper getPermissionSetsForUser(String userId) {
        ogUserListPermissionSetWrapper ogUserListPermissionSets = new ogUserListPermissionSetWrapper();
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        if (String.isEmpty(userId)) {
            return ogUserListPermissionSets;
        }
        permissionSetAssignments = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name, SystemModstamp, PermissionSet.Label
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND (NOT PermissionSet.Name LIKE 'X%')
                ORDER BY PermissionSet.Label
        ];
        List<PermissionSet> permissionSets = [
                SELECT Id, Label
                FROM PermissionSet
                WHERE (NOT Label LIKE '00%')
                AND Id NOT IN (
                        SELECT PermissionSetId
                        FROM PermissionSetAssignment
                        WHERE AssigneeId = :userId
                )
                ORDER BY Label
                LIMIT 400
        ];
        ogUserListPermissionSets.currentPermissionSetAssignments = permissionSetAssignments;
        if (permissionSets != null && permissionSets.size() > 0) {
            ogUserListPermissionSets.potentialPermissionSets = permissionSets;
        }
        return ogUserListPermissionSets;
    }

    @AuraEnabled
    public static void saveNewPermissionSetAssignment(String userId, String permissionSetId) {
        if (String.isEmpty(userId) || String.isEmpty(permissionSetId)) {
            return;
        }
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                AssigneeId = Id.valueOf(userId),
                PermissionSetId = Id.valueOf(permissionSetId)
        );
        try {
            insert permissionSetAssignment;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    @AuraEnabled
    public static void deletePermissionSetAssignment(String recordId) {
        if (String.isEmpty(recordId)) {
            return;
        }
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(Id = Id.valueOf(recordId));
        delete permissionSetAssignment;
    }
    @AuraEnabled
    public static void resetUserPassword(String userId) {
        if (String.isEmpty(userId)) {
            return;
        }
        Id id = Id.valueOf(userId);
        System.resetPassword(id, true);
    }
    @AuraEnabled
    public static void toggleFreezeUser(String userId) {
        if (String.isEmpty(userId)) {
            return;
        }
        Id id = Id.valueOf(userId);
        UserLogin userLogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :id];
        userLogin.IsFrozen = !userLogin.IsFrozen;
        update userLogin;
    }
    private static String getCurrentOrgId() {
        return String.valueOf(UserInfo.getOrganizationId()).substring(0, 15);
    }
    private static String getBaseUserQuery() {
        return 'SELECT Id, Name, Email, IsActive, LastLoginDate, UserRoleId, ' +
                'UserRole.Name, ProfileId, Profile.Name, Username ' +
                'FROM User';
    }
    private static List<Profile> getProfiles() {
        return [SELECT Id, Name FROM Profile ORDER BY Name];
    }
    private static List<UserRole> getRoles() {
        return [SELECT Id, Name FROM UserRole ORDER BY Name];
    }
    private static List<PermissionSet> getPermissionSets() {
        return [
                SELECT Id, Label
                FROM PermissionSet
                WHERE (NOT Label LIKE '00%')
                ORDER BY Label
                LIMIT 400
        ];
    }
    private static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
    public class ogUserListWrapper {
        @AuraEnabled
        public String currentOrgId { get; set; }
        @AuraEnabled
        public String loginNonce { get; set; }
        @AuraEnabled
        public List<Profile> profiles { get; set; }
        @AuraEnabled
        public List<UserRole> roles { get; set; }
        @AuraEnabled
        public List<PermissionSet> permissionSets { get; set; }
    }
    public class ogUserListPermissionSetWrapper {
        @AuraEnabled
        public List<PermissionSetAssignment> currentPermissionSetAssignments { get; set; }
        @AuraEnabled
        public List<PermissionSet> potentialPermissionSets { get; set; }

        public ogUserListPermissionSetWrapper() {
            this.currentPermissionSetAssignments = new List<PermissionSetAssignment>();
            this.potentialPermissionSets = new List<PermissionSet>();
        }
    }
}