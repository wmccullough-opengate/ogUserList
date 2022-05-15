# OpenGate Manage Users List

<a href="https://githubsfdeploy.herokuapp.com?owner=wmccullough-opengate&repo=ogUserList&ref=master" target="_blank">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

A LWC that is searchable, filterable, and sortable. Supports easy search and login as a user.

Includes a Lightning Tab called 'Manage Users'. Give yourself access to this tab to begin using the component.  You can add the tab to an app or create a shortcut to it.

# Supported Features:
1) Search by name as you type.
2) Add User using minimal modal record edit form.
3) Clear Search button.
4) Filter by Profile.
5) Filter by Active Users.
6) Clear (reset) Filters.
7) Login As row button.
8) Click column headings to sort by that column.
9) Actions column - supports copying the User Id, freezing the user, and resetting the password for user.
10) Pagination - shows 10 rows at a time with First/Previous/Next/Last buttons
11) Download button to export currently filtered list of users.
12) Double-Click table to edit any row. Supports editing of Profile, Role, and IsActive.