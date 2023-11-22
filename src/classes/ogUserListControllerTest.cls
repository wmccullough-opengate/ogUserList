/**
 * Created by wmccu on 9/4/2021.
 */

@IsTest
private class ogUserListControllerTest {
    @TestSetup
    static void setupOGUserListControllerTestData() {
        Group testGroup = new Group(
                Name = 'Test Group',
                DeveloperName = 'Test_Group',
                Type = 'Regular'
        );
        insert testGroup;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User standardUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'StandardUser09178', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id,
                TimeZoneSidKey = 'America/New_York', Username = 'standardtestuser' + getRandomNumberString() + '@testorg.com');
        insert standardUser;
        PermissionSet permissionSet1 = new PermissionSet(
                Name = 'testPermission1',
                Label = 'testPermission1'
        );
        insert permissionSet1;
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                AssigneeId = standardUser.Id,
                PermissionSetId = permissionSet1.Id
        );
        insert permissionSetAssignment;
        PermissionSet permissionSet2 = new PermissionSet(
                Name = 'testPermission2',
                Label = 'testPermission2'
        );
        insert permissionSet2;
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User sysAdminUser = new User(Alias = 'sysadm22', Email = 'sysadminuser22@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'AdminUser', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id,
                TimeZoneSidKey = 'America/New_York', Username = 'sysadminuser' + getRandomNumberString() + '@testorg.com');
        insert sysAdminUser;
        GroupMember testGroupMember = new GroupMember(
                UserOrGroupId = standardUser.Id,
                GroupId = testGroup.Id
        );
        insert testGroupMember;
    }
    @IsTest
    static void getOGUserListWrapperShouldReturnResults() {
        Test.startTest();
        {
            List<ogUserListController.ogUserListWrapper> ogUserListWrappers = ogUserListController.getOGUserListWrapper();
            System.assert(ogUserListWrappers.size() > 0);
        }
        Test.stopTest();
    }
    @IsTest
    static void emptySearchShouldReturnUsers() {
        String profileId = '';
        String searchTerm = '';
        Test.startTest();
        {
            List<User> users = ogUserListController.getUsers(searchTerm, false, profileId);
            System.assert(users.size() > 0, 'There should be users in the list.');
        }
        Test.stopTest();
    }
    @IsTest
    static void searchTermShouldReturnUsers() {
        String profileId = '';
        String searchTerm = 'StandardUser09178';
        Test.startTest();
        {
            List<User> users = ogUserListController.getUsers(searchTerm, false, profileId);
            System.debug(users);
            System.assert(users.size() == 1, 'There should be 1 user in the list.');
        }
        Test.stopTest();
    }
    @IsTest
    static void profileFilterShouldReturnUsers() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String profileId = String.valueOf(profile.Id);
        String searchTerm = '';
        Test.startTest();
        {
            List<User> users = ogUserListController.getUsers(searchTerm, false, profileId);
            System.debug(users);
            for (User user : users) {
                System.assert(user.ProfileId == profile.Id, 'All users should have the same profile as the "filtered profile"');
            }
        }
    }
    @IsTest
    static void activeFilterShouldReturnUsers() {
        String profileId = '';
        String searchTerm = '';
        Test.startTest();
        {
            List<User> users = ogUserListController.getUsers(searchTerm, true, profileId);
            System.debug(users);
            for (User user : users) {
                System.assert(user.IsActive == true, 'All users should active users');
            }
        }
    }
    @IsTest
    static void savingUsersShouldReturnSuccess() {
        User standardUser = [SELECT Id, Name, FirstName, LastName FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            standardUser.FirstName = 'Test';
            List<User> users = new List<User>{
                    standardUser
            };
            String message = ogUserListController.saveUsers(users);
            System.assert(message.indexOf('Saved') != -1, 'Saved Users should be the message');
        }
        Test.stopTest();
        User verifyUser = [SELECT Id, Name, FirstName FROM User WHERE LastName = 'StandardUser09178'];
        System.debug(verifyUser);
        System.assert(verifyUser.FirstName == 'Test', 'The StandardUser\'s FirstName should be "Test"');
    }
    @IsTest
    static void savingUsersShouldReturnErrorMessage() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            standardUser.FirstName = 'Test0123456789Test0123456789Test0123456789Test0123456789Test0123456789Test0123456789Test0123456789';
            List<User> users = new List<User>{
                    standardUser
            };
            String message = ogUserListController.saveUsers(users);
            System.debug(message);
            System.assert(message.startsWith('Error'));
        }
        Test.stopTest();
    }
    @IsTest
    static void getPermissionSetAssignmentShouldReturn() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            ogUserListController.ogUserListPermissionSetWrapper ogUserListPermissionSetWrapper = ogUserListController.getPermissionSetsForUser(String.valueOf(standardUser.Id));
            System.assert(ogUserListPermissionSetWrapper.currentPermissionSetAssignments.size() > 0);
        }
        Test.stopTest();
    }
    @IsTest
    static void savingNewPermissionSetAssignmentShouldWork() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        PermissionSet testPermission2 = [SELECT Id FROM PermissionSet WHERE Label = 'testPermission2'];
        Test.startTest();
        {
            ogUserListController.saveNewPermissionSetAssignment(String.valueOf(standardUser.Id), String.valueOf(testPermission2.Id));
        }
        Test.stopTest();
    }
    @IsTest
    static void deletingPermissionSetAssignmentShouldWork() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        List<PermissionSetAssignment> permissionSetAssignments = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :standardUser.Id
                AND PermissionSet.Label = 'testPermission1'
                LIMIT 1
        ];
        PermissionSetAssignment permissionSetAssignment = (permissionSetAssignments.size() == 1) ? permissionSetAssignments.get(0) : null;
        Test.startTest();
        {
            ogUserListController.deletePermissionSetAssignment(String.valueOf(permissionSetAssignment.Id));
        }
        Test.stopTest();
    }
    @IsTest
    static void shouldGetGroupWrapper() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            ogUserListController.ogUserListGroupWrapper ogUserListGroupWrapper = ogUserListController.getGroupsForUser(String.valueOf(standardUser.Id));
            Assert.isTrue(ogUserListGroupWrapper.currentGroupMembers.size() == 1);
            Assert.isTrue(ogUserListGroupWrapper.potentialGroups.size() > 0);
        }
        Test.stopTest();
    }
    @IsTest
    static void savingNewGroupMemberShouldWork() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];
        Test.startTest();
        {
            ogUserListController.saveNewGroupMember(String.valueOf(standardUser.Id), String.valueOf(testGroup.Id));
        }
        Test.stopTest();
        List<GroupMember> verifyMembers = [
                SELECT Id, GroupId, UserOrGroupId
                FROM GroupMember
                WHERE UserOrGroupId = :standardUser.Id
        ];
        System.debug(verifyMembers);
    }
    @IsTest
    static void deletingGroupMemberShouldWork() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        List<GroupMember> groupMembers = [
                SELECT Id
                FROM GroupMember
                WHERE UserOrGroupId = :standardUser.Id
                AND Group.Name = 'Test Group'
                LIMIT 1
        ];
        GroupMember currentGroupMember = (groupMembers.size() == 1) ? groupMembers.get(0) : null;
        Test.startTest();
        {
            ogUserListController.deleteGroupMember(String.valueOf(currentGroupMember.Id));
        }
        Test.stopTest();
    }
    @IsTest
    static void shouldReturnEmptyGroupWrapper() {
        Test.startTest();
        {
            ogUserListController.ogUserListGroupWrapper ogUserListGroupWrapper = ogUserListController.getGroupsForUser(String.valueOf(''));
            Assert.isTrue(ogUserListGroupWrapper.currentGroupMembers.size() == 0);
            Assert.isTrue(ogUserListGroupWrapper.potentialGroups.size() == 0);
        }
        Test.stopTest();
    }
    @IsTest
    static void passwordResetShouldReset() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            ogUserListController.resetUserPassword(String.valueOf(standardUser.Id));
        }
        Test.stopTest();
    }
    @IsTest
    static void toggleFreezeShouldToggle() {
        User standardUser = [SELECT Id, Name FROM User WHERE LastName = 'StandardUser09178'];
        Test.startTest();
        {
            ogUserListController.toggleFreezeUser(String.valueOf(standardUser.Id));
        }
        Test.stopTest();
    }
    private static String getRandomNumberString() {
        return String.valueOf(Integer.valueOf((Math.random() * 1000000000)));
    }
}