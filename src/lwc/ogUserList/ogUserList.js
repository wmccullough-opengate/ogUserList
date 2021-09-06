/**
 * Created by wmccu on 7/20/2021.
 */

import {api, LightningElement, track} from "lwc";
import getUsers from "@salesforce/apex/ogUserListController.getUsers";
import getOGUserListWrapper from "@salesforce/apex/ogUserListController.getOGUserListWrapper";
import saveUsers from "@salesforce/apex/ogUserListController.saveUsers";
import currentUserId from "@salesforce/user/Id";
import {ShowToastEvent} from "lightning/platformShowToastEvent";


export default class OgUserList extends LightningElement {
    @api searchTerm;
    @track users = [];
    @track wrapper = [];
    @track profileOptions = [];
    @track roleOptions = [];
    @track isPartnerEdited = false;
    @track hideSaveCancel = false;
    @track isUserEdited = false;
    @track saveIsDisabled = true;
    @track showAddUser = false;
    @track activeUsersVariant = "neutral";
    @track recordsToDisplay = [];
    @track currentSelectedProfile;
    isLoading = false;
    recordsperpage = "10";
    totalRecords;
    pageNo;
    totalPages;
    startRecord;
    endRecord;
    end = false;
    activeOnly = false;
    selectedProfileId = "";
    recordId;
    currentOrgId;
    loginNonce;
    lookupQueryLimit = 10;
    sfdcBaseURL;
    sfdcBaseURLEncode;
    sortedDirection = "asc";
    sortedColumn;
    error;
    timerId;

    get title() {
        return "Manage Users (Today is: " + this.today + ")";
    }

    get today() {
        return new Date().toLocaleDateString();
    }

    get adminUserId() {
        return currentUserId.substring(0, 14);
    }

    get pageNumberOf() {
        return this.pageNo + " of " + this.totalPages;
    }

    connectedCallback() {
        this.sfdcBaseURL = window.location.origin;
        this.sfdcBaseURLEncode = encodeURI(window.location.origin);
        getOGUserListWrapper().then(result => {
            // console.log(JSON.stringify(result));
            if (result) {
                this.currentOrgId = result[0].currentOrgId;
                this.loginNonce = result[0].loginNonce;
                const profiles = result[0].profiles;
                this.profileOptions = [...this.profileOptions, {value: "", label: ""}];
                for (let i = 0; i < profiles.length; i++) {
                    this.profileOptions = [...this.profileOptions, {value: profiles[i].Id, label: profiles[i].Name}];
                }
                const roles = result[0].roles;
                this.roleOptions = [...this.roleOptions, {value: "", label: ""}];
                for (let i = 0; i < roles.length; i++) {
                    this.roleOptions = [...this.roleOptions, {value: roles[i].Id, label: roles[i].Name}];
                }
            }
        });
        this.getListUsers("");
    }

    renderedCallback() {
        setTimeout(function () {
            this.setFocusSearchField();
        }, 100);
    }

    setFocusSearchField() {
        const fieldToFocus = this.template.querySelector("lightning-input[data-fieldname='search']");
        if (fieldToFocus) {
            fieldToFocus.focus();
        }
    }

    getListUsers(search) {
        getUsers({
            searchTerm: search,
            activeOnly: this.activeOnly,
            selectedProfileId: this.selectedProfileId
        }).then(result => {
            // console.log(JSON.stringify(result));
            let nameURL, roleURL, roleName, profileURL, profileName, loginAs;
            this.users = result.map(row => {
                nameURL = this.sfdcBaseURL + `/lightning/setup/ManageUsers/page?address=%2F${row.Id}%3Fnoredirect%3D1%26isUserEntityOverride%3D1`;
                roleURL = this.sfdcBaseURL + `/lightning/setup/Roles/page?address=%2F${row.UserRoleId}`;
                roleName = row.UserRole !== undefined ? row.UserRole.Name : "";
                profileURL = this.sfdcBaseURL + `/lightning/setup/EnhancedProfiles/page?address=%2F${row.ProfileId}`;
                profileName = row.Profile !== undefined ? row.Profile.Name : "";
                loginAs = `/one/one.app#/alohaRedirect/servlet/servlet.su?oid=${this.currentOrgId}&suorgadminid=${row.Id}&targetURL=%2Fhome%2Fhome.jsp&amp;retURL=%2Flightning%2Fn%2FManage_Users%3FisUserEntityOverride%3D1%26retURL%3D%252Fsetup%252Fhome%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3D${this.sfdcBaseURLEncode}%26sfdcIFrameHost%3Dweb%26nonce%3D${this.loginNonce}%26ltn_app_id%3D06m1t0000000fbwAAA%26clc%3D1&isdtp=p1`;
                return {...row, nameURL, roleURL, roleName, profileURL, profileName, loginAs};
            });
            // console.log("this.users----> ", this.users.length);
            this.totalRecords = this.users.length;
            this.setRecordsToDisplay();
            this.setFocusSearchField();
            this.error = undefined;
        })
            .catch(error => {
                this.error = error;
                this.users = undefined;
                console.error(JSON.stringify(error));
            });
    }

    startSearchTimer(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this.timerId);
        this.timerId = setTimeout(this.handleSearch().bind(this), 500);
    }

    clearSearch() {
        this.searchTerm = undefined;
        this.getListUsers(this.searchTerm);
    }

    clearFilters() {
        this.selectedProfileId = undefined;
        this.currentSelectedProfile = undefined;
        this.activeUsersVariant = "neutral";
        this.activeOnly = false;
        this.getListUsers(this.searchTerm);
    }

    handleSearch() {
        if (!this.searchTerm) {
            this.errorMsg = "Please enter user name to search.";
            this.users = undefined;
            return;
        }
        this.getListUsers(this.searchTerm);
    }

    handleSavingUsers() {
        console.log("handleSavingUsers");
        // console.log(this.users);
        saveUsers({users: this.users})
            .then(result => {
                console.log(result);
                const message = result;
                const messageVariant = message.includes('Saved') ? "success" : "error";
                this.showToastMessage(messageVariant.toUpperCase(), message, messageVariant);
                this.getListUsers("");
                this.cancelEditUsers();
            })
            .catch(error => {
                this.error = error;
                console.log("Error in Save call back:", this.error);
            });
    }

    handleProfileSelection(event) {
        this.selectedProfileId = event.target.value;
        this.currentSelectedProfile = event.target.value;
        this.getListUsers(this.searchTerm);
    }

    handleSelection(event) {
        console.log("handleSelection");
        event.stopPropagation();
        //unique-key passed in input is coming as key here
        //By passing ApiName of the field, we can make this function
        //dynamic for multiple lookups on a single screen
        let fieldName = event.detail.data.key;
        // console.log(fieldName);
        //selected id passed by lookup component
        let selectedId = event.detail.data.selectedId;
        // this.objectInfo[fieldName] = selectedId;
        // const fieldSelector = "lightning-input-field[data-id=" + fieldName + "]";
        // this.template.querySelector(fieldSelector).value = selectedId;
        // console.log(this.template.querySelector(fieldSelector));
    }

    handleComboBoxChange(event) {
        console.log("handleComboBoxChange");
        const fieldName = event.target.dataset.fieldname;
        console.log(fieldName);
        const rowId = event.target.dataset.rowid;
        console.log(rowId);
        const newValue = event.detail.value;
        console.log(newValue);
        let element = this.users.find(ele => ele.Id === rowId);
        element[fieldName] = newValue;
        console.log(JSON.stringify(element));
        this.users = [...this.users];
        // console.log(JSON.stringify(this.users));
    }

    handleCheckboxChange(event) {
        console.log("handleCheckboxChange");
        const fieldName = event.target.dataset.fieldname;
        console.log(fieldName);
        const rowId = event.target.dataset.rowid;
        console.log(rowId);
        const newValue = event.detail.checked;
        console.log(newValue);
        let element = this.users.find(ele => ele.Id === rowId);
        element[fieldName] = newValue;
        console.log(JSON.stringify(element));
        this.users = [...this.users];
        // console.log(JSON.stringify(this.users));

    }

    showActiveUsersOnly() {
        if (this.activeUsersVariant === "neutral") {
            this.activeUsersVariant = "brand";
            this.activeOnly = true;
        } else {
            this.activeUsersVariant = "neutral";
            this.activeOnly = false;
        }
        this.getListUsers(this.searchTerm);
    }

    addUser() {
        console.log("addUser");
        this.showAddUser = true;
    }

    closeAddUser() {
        this.showAddUser = false;
    }

    cancelEditUsers() {
        this.isUserEdited = false;
        this.saveIsDisabled = true;
    }

    onDoubleClickEdit() {
        this.isUserEdited = true;
        this.saveIsDisabled = false;
    }

    freezeUser() {

    }

    handleAddUserSubmit(event) {
        // console.log("onsubmit: " + JSON.stringify(event.detail.fields));
        // this.showSpinner = true;
        this.template.querySelector("lightning-record-edit-form").submit();
    }

    handleAddUserSuccess(event) {
        console.log("handleAddUserSuccess");
        const message = "Record ID: " + event.detail.Id;
        this.showToastMessage("User Created", message, "success");
        this.showAddUser = false;
        this.handleReset(event);
    }

    sort(event) {
        if (this.sortedColumn === event.currentTarget.dataset.id) {
            this.sortedDirection = this.sortedDirection === "asc" ? "desc" : "asc";
        } else {
            this.sortedDirection = "asc";
        }
        let reverse = this.sortedDirection === "asc" ? 1 : -1;
        let table = JSON.parse(JSON.stringify(this.users));
        table.sort((a, b) => {
            return a[event.currentTarget.dataset.id] > b[event.currentTarget.dataset.id] ? 1 * reverse : -1 * reverse;
        });
        this.sortedColumn = event.currentTarget.dataset.id;
        this.users = table;
    }

    showToastMessage(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
            "lightning-input-field"
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    copyUserId(event) {
        const userId = event.currentTarget.dataset.userid;
        // console.log(userId);
        this.copyTextToClipboard(userId);
    }

    //**** Pagination
    setRecordsToDisplay() {
        console.log('setRecordsToDisplay');
        this.pageNo = 1;
        this.totalPages = Math.ceil(this.totalRecords / this.recordsperpage);
        this.preparePaginationList();
        this.isLoading = false;
    }

    handleClick(event) {
        let label = event.target.label;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleNext() {
        this.pageNo += 1;
        this.preparePaginationList();
    }

    handlePrevious() {
        this.pageNo -= 1;
        this.preparePaginationList();
    }

    handleFirst() {
        this.pageNo = 1;
        this.preparePaginationList();
    }

    handleLast() {
        this.pageNo = this.totalPages;
        this.preparePaginationList();
    }

    handlePage(button) {
        this.pageNo = button.target.label;
        this.preparePaginationList();
    }

    preparePaginationList() {
        this.isLoading = true;
        if (this.users.length >= this.recordsperpage) {
            let begin = (this.pageNo - 1) * parseInt(this.recordsperpage);
            let end = begin + parseInt(this.recordsperpage);
            this.recordsToDisplay = this.users.slice(begin, end);
            console.log("preparePaginationList");
            // console.log(JSON.stringify(this.recordsToDisplay));
            this.startRecord = begin + parseInt(1);
            this.endRecord = end > this.totalRecords ? this.totalRecords : end;
            this.end = end > this.totalRecords;
        } else {
            this.recordsToDisplay = [...this.users];
        }
        this.isLoading = false;
    }

    //**** Page Level Functions
    //https://www.salesforcecodecrack.com/2019/05/export-data-as-csv-file-with-javascript.html
    downloadCSVFile() {
        let rowEnd = "\n";
        let csvString = "";
        const includeTheseColumns = new Set(['Id', 'Name', 'Email', 'profileName', 'roleName',
            'LastLoginDate', 'IsActive']);
        // this set eliminates the duplicates if have any duplicate keys
        let rowData = new Set();
        // console.log(JSON.stringify(this.users));
        // getting keys from data
        this.users.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                if (includeTheseColumns.has(key)) {
                    rowData.add(key);
                }
            });
        });
        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);
        // console.log(rowData);
        // splitting using ','
        csvString += rowData.join(",");
        csvString += rowEnd;
        // main for loop to get the data based on key value
        for (let i = 0; i < this.users.length; i++) {
            // console.log(JSON.stringify(this.users[i]));
            let colValue = 0;
            // validating keys in data
            for (let key in rowData) {
                if (rowData.hasOwnProperty(key)) {
                    // Key value
                    // Ex: Id, Name
                    let rowKey = rowData[key];
                    // add , after every value except the first.
                    if (colValue > 0) {
                        csvString += ",";
                    }
                    // If the column is undefined, set as blank in the CSV file.
                    let value = this.users[i][rowKey] === undefined ? "" : this.users[i][rowKey];
                    csvString += "\"" + value + "\"";
                    colValue++;
                }
            }
            csvString += rowEnd;
        }
        // Creating anchor element to download
        let downloadElement = document.createElement("a");
        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = "data:text/csv;charset=utf-8," + encodeURI(csvString);
        downloadElement.target = "_self";
        // CSV File Name
        let today = new Date();
        const dd = String(today.getDate()).padStart(2, "0");
        const mm = String(today.getMonth() + 1).padStart(2, "0"); //January is 0!
        const yyyy = today.getFullYear();
        const hh = today.getHours();
        const min = today.getMinutes();
        const ss = today.getSeconds();
        today = yyyy + mm + dd + "_" + hh + min + ss;
        downloadElement.download = "UserData_" + today + ".csv";
        // this statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }

    copyTextToClipboard(content) {
        // Create an input field with the minimum size and place in a not visible part of the screen
        let tempTextAreaField = document.createElement("textarea");
        tempTextAreaField.style = "position:fixed;top:-5rem;height:1px;width:10px;";
        // Assign the content we want to copy to the clipboard to the temporary text area field
        tempTextAreaField.value = content;
        // Append it to the body of the page
        document.body.appendChild(tempTextAreaField);
        // Select the content of the temporary markup field
        tempTextAreaField.select();
        // Run the copy function to put the content to the clipboard
        document.execCommand("copy");
        // Remove the temporary element from the DOM as it is no longer needed
        tempTextAreaField.remove();
    }
}