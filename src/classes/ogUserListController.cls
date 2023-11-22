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
                String nameSearch = '%' + String.escapeSingleQuotes(searchTerm) + '%';
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
    @AuraEnabled(Cacheable=false)
    public static ogUserListGroupWrapper getGroupsForUser(String userId) {
        ogUserListGroupWrapper ogUserListGroupWrapper = new ogUserListGroupWrapper();
        if (String.isEmpty(userId)) {
            return ogUserListGroupWrapper;
        }
        List<GroupMember> groupMembers = new List<GroupMember>();
        groupMembers = [
                SELECT Id, GroupId, Group.Name, UserOrGroupId, SystemModstamp
                FROM GroupMember
                WHERE UserOrGroupId = :userId
                ORDER BY Group.Name
        ];
        List<Group> groups = [
                SELECT Id, Name, DeveloperName
                FROM Group
                WHERE Type IN ('Regular', 'Queue')
                AND Id NOT IN (
                        SELECT GroupId
                        FROM GroupMember
                        WHERE UserOrGroupId = :userId
                )
                ORDER BY Name
                LIMIT 400
        ];
        ogUserListGroupWrapper.currentGroupMembers = groupMembers;
        if (groups != null && groups.size() > 0) {
            ogUserListGroupWrapper.potentialGroups = groups;
        }
        return ogUserListGroupWrapper;
    }
    @AuraEnabled
    public static void saveNewGroupMember(String userId, String groupId) {
        if (String.isEmpty(userId) || String.isEmpty(groupId)) {
            return;
        }
        System.debug(userId);
        System.debug(groupId);
        GroupMember newGroupMember = new GroupMember(
                UserOrGroupId = Id.valueOf(userId),
                GroupId = Id.valueOf(groupId)
        );
        try {
            insert newGroupMember;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    @AuraEnabled
    public static void deleteGroupMember(String recordId) {
        if (String.isEmpty(recordId)) {
            return;
        }
        GroupMember existingGroupMember = new GroupMember(Id = Id.valueOf(recordId));
        delete existingGroupMember;
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
    public class ogUserListGroupWrapper {
        @AuraEnabled
        public List<GroupMember> currentGroupMembers { get; set; }
        @AuraEnabled
        public List<Group> potentialGroups { get; set; }

        public ogUserListGroupWrapper() {
            this.currentGroupMembers = new List<GroupMember>();
            this.potentialGroups = new List<Group>();
        }
    }
}