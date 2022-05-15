/**
 * Created by wmccu on 9/4/2021.
 */

@IsTest
private class ogUserListControllerTest {
    @TestSetup
    static void setupOGUserListControllerTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User standardUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'StandardUser09178', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id,
                TimeZoneSidKey = 'America/New_York', Username = 'standardtestuser' + getRandomNumberString() + '@testorg.com');
        insert standardUser;

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User sysAdminUser = new User(Alias = 'sysadm22', Email = 'sysadminuser22@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'AdminUser', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id,
                TimeZoneSidKey = 'America/New_York', Username = 'sysadminuser' + getRandomNumberString() + '@testorg.com');
        insert sysAdminUser;
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