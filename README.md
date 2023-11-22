# OpenGate Manage Users List

<a href="https://githubsfdeploy.herokuapp.com?owner=wmccullough-opengate&repo=ogUserList&ref=master" target="_blank">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

A LWC that is searchable, filterable, and sortable. Supports easy search and login as a user.

Includes a Permission Set 'ogUserList'. Give yourself access to this permission set to begin using the component.
You can add the tab 'Manage Users' to an app or create a shortcut to it.

# Supported Features:

1) Search by name as you type.
2) Add User using minimal modal record edit form.
3) Clear Search button.
4) Filter by Profile.
5) Filter by Active Users.
6) Clear (reset) Filters.
7) Login As row button.
8) Click column headings to sort by that column.
9) Edit table button.
10) Actions column - supports copying the User Id, freezing the user, resetting the password for user, managing user
    permission set assignments, and managing group members.
11) Pagination - shows 10 rows at a time with First/Previous/Next/Last buttons
12) Download button to export currently filtered list of users.
13) Double-Click table to edit any row. Supports editing of Profile, Role, and IsActive.