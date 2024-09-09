/*
    Source code created by Rustici Software, LLC is licensed under a
    Creative Commons Attribution 3.0 United States License
    (http://creativecommons.org/licenses/by/3.0/us/)
	
    Want to make SCORM easy? See our solutions at http://www.scorm.com.
	
    This example demonstrates the use of more advanced runtime calls in a multi-page SCO. It
    includes a demonstration of reporting interactions (question results), and progress
    towards specific learning objective. It also demonstrates using the manifest to specify
    a passing score rather than hard coding the passing score within the content.
*/

//Include the standard ADL-supplied API discovery algorithm

///////////////////////////////////////////
//Begin ADL-provided API discovery algorithm
///////////////////////////////////////////

var nFindAPITries = 0;
var API = null;
var maxTries = 500;
// The ScanForAPI() function searches for an object named API_1484_11
// in the window that is passed into the function.  If the object is
// found a reference to the object is returned to the calling function.
// If the instance is found the SCO now has a handle to the LMS
// provided API Instance.  The function searches a maximum number
// of parents of the current window.  If no object is found the
// function returns a null reference.  This function also reassigns a
// value to the win parameter passed in, based on the number of
// parents.  At the end of the function call, the win variable will be
// set to the upper most parent in the chain of parents.
function ScanForAPI(win) {
    while (win.API_1484_11 == null && win.parent != null && win.parent != win) {
        nFindAPITries++;
        if (nFindAPITries > maxTries) {
            return null;
        }
        win = win.parent;
    }
    return win.API_1484_11;
}

// The GetAPI() function begins the process of searching for the LMS
// provided API Instance.  The function takes in a parameter that
// represents the current window.  The function is built to search in a
// specific order and stop when the LMS provided API Instance is found.
// The function begins by searching the current window�s parent, if the
// current window has a parent.  If the API Instance is not found, the
// function then checks to see if there are any opener windows.  If
// the window has an opener, the function begins to look for the
// API Instance in the opener window.
function GetAPI(win) {
    if (win.parent != null && win.parent != win) {
        API = ScanForAPI(win.parent);
    }
    if (API == null && win.opener != null) {
        API = ScanForAPI(win.opener);
    }
}

///////////////////////////////////////////
//End ADL-provided API discovery algorithm
///////////////////////////////////////////

//Create function handlers for the loading and unloading of the page

//Constants
var SCORM_TRUE = "true";
var SCORM_FALSE = "false";
var SCORM_NO_ERROR = "0";

//Since the Unload handler will be called twice, from both the onunload
//and onbeforeunload events, ensure that we only call Terminate once.
var terminateCalled = false;

//Track whether or not we successfully initialized.
var initialized = false;

function ScormProcessInitialize() {
    var result;

    GetAPI(window);

    if (API == null) {
        alert(
            "ERROR - Could not establish a connection with the LMS.\n\nYour results may not be recorded."
        );
        return;
    }

    result = API.Initialize("");

    if (result == SCORM_FALSE) {
        var errorNumber = API.GetLastError();
        var errorString = API.GetErrorString(errorNumber);
        var diagnostic = API.GetDiagnostic(errorNumber);

        var errorDescription =
            "Number: " +
            errorNumber +
            "\nDescription: " +
            errorString +
            "\nDiagnostic: " +
            diagnostic;

        alert(
            "Error - Could not initialize communication with the LMS.\n\nYour results may not be recorded.\n\n" +
            errorDescription
        );
        return;
    }

    initialized = true;
}

function ScormProcessTerminate() {
    var result;

    //Don't terminate if we haven't initialized or if we've already terminated
    if (initialized == false || terminateCalled == true) {
        return;
    }

    result = API.Terminate("");

    terminateCalled = true;

    if (result == SCORM_FALSE) {
        var errorNumber = API.GetLastError();
        var errorString = API.GetErrorString(errorNumber);
        var diagnostic = API.GetDiagnostic(errorNumber);

        var errorDescription =
            "Number: " +
            errorNumber +
            "\nDescription: " +
            errorString +
            "\nDiagnostic: " +
            diagnostic;

        alert(
            "Error - Could not terminate communication with the LMS.\n\nYour results may not be recorded.\n\n" +
            errorDescription
        );
        return;
    }
}

/*
    The onload and onunload event handlers are assigned in launchpage.html because more processing needs to
    occur at these times in this example.
*/
//window.onload = ScormProcessInitialize;
//window.onunload = ScormProcessTerminate;
//window.onbeforeunload = ScormProcessTerminate;

//There are situations where a GetValue call is expected to have an error
//and should not alert the user.
function ScormProcessGetValue(element, checkError) {
    var result;

    if (initialized == false || terminateCalled == true) {
        return;
    }

    result = API.GetValue(element);

    if (checkError == true && result == "") {
        var errorNumber = API.GetLastError();

        if (errorNumber != SCORM_NO_ERROR) {
            var errorString = API.GetErrorString(errorNumber);
            var diagnostic = API.GetDiagnostic(errorNumber);

            var errorDescription =
                "Number: " +
                errorNumber +
                "\nDescription: " +
                errorString +
                "\nDiagnostic: " +
                diagnostic;

            alert(
                "Error - Could not retrieve a value from the LMS.\n\n" +
                errorDescription
            );
            return "";
        }
    }

    return result;
}

function ScormProcessSetValue(element, value) {
    var result;

    if (initialized == false || terminateCalled == true) {
        return;
    }

    result = API.SetValue(element, value);

    if (result == SCORM_FALSE) {
        var errorNumber = API.GetLastError();
        var errorString = API.GetErrorString(errorNumber);
        var diagnostic = API.GetDiagnostic(errorNumber);

        var errorDescription =
            "Number: " +
            errorNumber +
            "\nDescription: " +
            errorString +
            "\nDiagnostic: " +
            diagnostic;

        alert(
            "Error - Could not store a value in the LMS.\n\nYour results may not be recorded.\n\n" +
            errorDescription
        );
        return;
    }

    return result;
}

///////////////////////////////////////////
// Begin Godot Scorm plugin code
// Licensed under the MIT license (see LICENSE)
///////////////////////////////////////////
var startTimeStamp = new Date();
var processedUnload = false;

function doStart() {
    //initialize communication with the LMS
    ScormProcessInitialize();

    //it's a best practice to set the completion status to incomplete when
    //first launching the course (if the course is not already completed)
    var completionStatus = ScormProcessGetValue("cmi.completion_status", true);
    if (completionStatus == "unknown") {
        ScormProcessSetValue("cmi.completion_status", "incomplete");
    }
}

function doUnload(pressedExit) {
    //don't call this function twice
    if (processedUnload == true) {
        return;
    }

    processedUnload = true;

    //record the session time
    var endTimeStamp = new Date();
    var totalMilliseconds = endTimeStamp.getTime() - startTimeStamp.getTime();
    var scormTime = ConvertMilliSecondsIntoSCORM2004Time(totalMilliseconds);

    ScormProcessSetValue("cmi.session_time", scormTime);
    //if the user just closes the browser, we will default to saving
    //their progress data. If the user presses exit, he is prompted.
    //If the user reached the end, the exit normall to submit results.
    // var reachedEnd = ScormProcessGetValue("...", true);
    // if (pressedExit == false && reachedEnd == false) {
    //     ScormProcessSetValue("cmi.exit", "suspend");
    // }

    ScormProcessTerminate();
}

//SCORM requires time to be formatted in a specific way
function ConvertMilliSecondsIntoSCORM2004Time(intTotalMilliseconds) {
    var ScormTime = "";

    var HundredthsOfASecond; //decrementing counter - work at the hundreths of a second level because that is all the precision that is required

    var Seconds; // 100 hundreths of a seconds
    var Minutes; // 60 seconds
    var Hours; // 60 minutes
    var Days; // 24 hours
    var Months; // assumed to be an "average" month (figures a leap year every 4 years) = ((365*4) + 1) / 48 days - 30.4375 days per month
    var Years; // assumed to be 12 "average" months

    var HUNDREDTHS_PER_SECOND = 100;
    var HUNDREDTHS_PER_MINUTE = HUNDREDTHS_PER_SECOND * 60;
    var HUNDREDTHS_PER_HOUR = HUNDREDTHS_PER_MINUTE * 60;
    var HUNDREDTHS_PER_DAY = HUNDREDTHS_PER_HOUR * 24;
    var HUNDREDTHS_PER_MONTH = HUNDREDTHS_PER_DAY * ((365 * 4 + 1) / 48);
    var HUNDREDTHS_PER_YEAR = HUNDREDTHS_PER_MONTH * 12;

    HundredthsOfASecond = Math.floor(intTotalMilliseconds / 10);

    Years = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_YEAR);
    HundredthsOfASecond -= Years * HUNDREDTHS_PER_YEAR;

    Months = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_MONTH);
    HundredthsOfASecond -= Months * HUNDREDTHS_PER_MONTH;

    Days = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_DAY);
    HundredthsOfASecond -= Days * HUNDREDTHS_PER_DAY;

    Hours = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_HOUR);
    HundredthsOfASecond -= Hours * HUNDREDTHS_PER_HOUR;

    Minutes = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_MINUTE);
    HundredthsOfASecond -= Minutes * HUNDREDTHS_PER_MINUTE;

    Seconds = Math.floor(HundredthsOfASecond / HUNDREDTHS_PER_SECOND);
    HundredthsOfASecond -= Seconds * HUNDREDTHS_PER_SECOND;

    if (Years > 0) {
        ScormTime += Years + "Y";
    }
    if (Months > 0) {
        ScormTime += Months + "M";
    }
    if (Days > 0) {
        ScormTime += Days + "D";
    }

    //check to see if we have any time before adding the "T"
    if (HundredthsOfASecond + Seconds + Minutes + Hours > 0) {
        ScormTime += "T";

        if (Hours > 0) {
            ScormTime += Hours + "H";
        }

        if (Minutes > 0) {
            ScormTime += Minutes + "M";
        }

        if (HundredthsOfASecond + Seconds > 0) {
            ScormTime += Seconds;

            if (HundredthsOfASecond > 0) {
                ScormTime += "." + HundredthsOfASecond;
            }

            ScormTime += "S";
        }
    }

    if (ScormTime == "") {
        ScormTime = "0S";
    }

    ScormTime = "P" + ScormTime;

    return ScormTime;
}

///////////////////////////////////////////
// End Godot Scorm plugin code
///////////////////////////////////////////
