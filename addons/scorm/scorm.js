/*
SCORM 1.2 - Based on https://scorm.com/wp-content/assets/golf_examples/PIFS/RuntimeBasicCalls_SCORM12.zip

LLC is licensed under a Creative Commons Attribution 3.0 United States License
(http://creativecommons.org/licenses/by/3.0/us/)
*/

///////////////////////////////////////////
//Begin ADL-provided API discovery algorithm
///////////////////////////////////////////
var findAPITries = 0;

function findAPI(win) {
  // Check to see if the window (win) contains the API
  // if the window (win) does not contain the API and
  // the window (win) has a parent window and the parent window
  // is not the same as the window (win)
  while (win.API == null && win.parent != null && win.parent != win) {
    // increment the number of findAPITries
    findAPITries++;

    // Note: 7 is an arbitrary number, but should be more than sufficient
    if (findAPITries > 7) {
      alert("Error finding API -- too deeply nested.");
      return null;
    }

    // set the variable that represents the window being
    // being searched to be the parent of the current window
    // then search for the API again
    win = win.parent;
  }
  return win.API;
}

function getAPI() {
  // start by looking for the API in the current window
  var theAPI = findAPI(window);

  // if the API is null (could not be found in the current window)
  // and the current window has an opener window
  if (
    theAPI == null &&
    window.opener != null &&
    typeof window.opener != "undefined"
  ) {
    // try to find the API in the current window�s opener
    theAPI = findAPI(window.opener);
  }
  // if the API has not been found
  if (theAPI == null) {
    // Alert the user that the API Adapter could not be found
    alert("Unable to find an API adapter");
  }
  return theAPI;
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
//and onbeforeunload events, ensure that we only call LMSFinish once.
var finishCalled = false;

//Track whether or not we successfully initialized.
var initialized = false;

var API = null;

function ScormProcessInitialize() {
  let result;

  API = getAPI();

  if (API == null) {
    alert(
      "ERROR - Could not establish a connection with the LMS.\n\nYour results may not be recorded."
    );
    return;
  }

  result = API.LMSInitialize("");

  if (result == SCORM_FALSE) {
    let errorNumber = API.LMSGetLastError();
    let errorString = API.LMSGetErrorString(errorNumber);
    let diagnostic = API.LMSGetDiagnostic(errorNumber);

    let errorDescription =
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
  console.log("Scorm process initialized.");
}

function ScormProcessFinish() {
  // NOTE: alert() not works here.

  let result;

  //Don't terminate if we haven't initialized or if we've already terminated
  if (initialized == false || finishCalled == true) {
    return;
  }

  result = API.LMSFinish("");

  finishCalled = true;

  if (result == SCORM_FALSE) {
    let errorNumber = API.LMSGetLastError();
    let errorString = API.LMSGetErrorString(errorNumber);
    let diagnostic = API.LMSGetDiagnostic(errorNumber);

    let errorDescription =
      "Number: " +
      errorNumber +
      "\nDescription: " +
      errorString +
      "\nDiagnostic: " +
      diagnostic;

    console.log(
      "Error - Could not terminate communication with the LMS.\n\nYour results may not be recorded.\n\n" +
        errorDescription
    );
    return;
  }
  console.log("Scorm process finished.");
}

var scorm = {
  reachedEnd: false,
  commit: function() {
    // console.log("JS-Scorm.commit()");
    let result;
  
    //Don't terminate if we haven't initialized or if we've already terminated
    if (initialized == false || finishCalled == true) {
      return;
    }
  
    result = API.LMSCommit("");
    // console.log("JS-Scorm.commit(): result - " + result);
  
    if (result == SCORM_FALSE) {
      let errorNumber = API.LMSGetLastError();
      let errorString = API.LMSGetErrorString(errorNumber);
      let diagnostic = API.LMSGetDiagnostic(errorNumber);
  
      let errorDescription =
        "Number: " +
        errorNumber +
        "\nDescription: " +
        errorString +
        "\nDiagnostic: " +
        diagnostic;
  
      alert("Error - Could not commit changes.\n\n" + errorDescription);
      return;
    }
  },
  getValue: function(...args) {
    // console.log("JS-Scorm.getValue(): " + args);
    let element = args[0];
    let result;
  
    if (initialized == false || finishCalled == true) {
      return;
    }
  
    result = API.LMSGetValue(element);
    // console.log("JS-Scorm.getValue(): result - " + result);
  
    if (result == "") {
      let errorNumber = API.LMSGetLastError();
      // console.log("JS-Scorm.getValue(): errorNumber - " + errorNumber);
  
      if (errorNumber != SCORM_NO_ERROR) {
        let errorString = API.LMSGetErrorString(errorNumber);
        let diagnostic = API.LMSGetDiagnostic(errorNumber);
  
        let errorDescription =
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
    // console.log("JS-Scorm.getValue(): result-return - " + result);
    return result;
  },
  setValue: function(...args) {
    // console.log("JS-Scorm.setValue(): " + args);
    let element = args[0];
    let value = args[1];
    let result;
  
    if (initialized == false || finishCalled == true) {
      return;
    }
  
    result = API.LMSSetValue(element, value);
    // console.log("JS-Scorm.setValue(): result - " + result);
  
    if (result == SCORM_FALSE) {
      let errorNumber = API.LMSGetLastError();
      let errorString = API.LMSGetErrorString(errorNumber);
      let diagnostic = API.LMSGetDiagnostic(errorNumber);
  
      let errorDescription =
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
  }
};

////////////
var processedUnload = false;
// var reachedEnd = false;
function doStart() {
  // console.log("JS-Scorm.doLoad()");
  //record the time that the learner started the SCO so that we can report the total time
  startTimeStamp = new Date();

  //initialize communication with the LMS
  ScormProcessInitialize();

  //it's a best practice to set the lesson status to incomplete when
  //first launching the course (if the course is not already completed)
  let lessonStatus = scorm.getValue("cmi.core.lesson_status");
  if (lessonStatus == "not attempted") {
    scorm.setValue("cmi.core.lesson_status", "incomplete");
  }
  if (lessonStatus == "completed" || lessonStatus == "passed" || lessonStatus == "failed") {
    scorm.reachedEnd = true
  }

  //see if the user stored a bookmark previously (don't check for errors
  //because cmi.core.lesson_location may not be initialized
  let bookmark = scorm.getValue("cmi.core.lesson_location");

  //if there isn't a stored bookmark, start the user at the first page
  if (bookmark == "") {
    // currentPage = 0;
  } else {
    //if there is a stored bookmark, prompt the user to resume from the previous location
    if (
      confirm("Would you like to resume from where you previously left off?")
    ) {
      //   currentPage = parseInt(bookmark, 10);
    } else {
      //   currentPage = 0;
    }
  }
  console.log("=== score");
  console.log(scorm.getValue("cmi.core.score.raw"));
  console.log("=== lesson_status");
  console.log(scorm.getValue("cmi.core.lesson_status"));
  console.log("=== entry RO");
  console.log(scorm.getValue("cmi.core.entry"));
  //   console.log('exit');   // WO
  //   console.log(scorm.get_value("cmi.core.exit"));
  console.log("=== total_time RO");
  console.log(scorm.getValue("cmi.core.total_time"));
  console.log("=== lesson_location (bookmark)");
  console.log(scorm.getValue("cmi.core.lesson_location"));
  console.log("=== suspend_data");
  console.log(scorm.getValue("cmi.suspend_data"));
  console.log("=== launch_data RO");
  console.log(scorm.getValue("cmi.launch_data"));
  console.log("=== Supported features");
  console.log(scorm.getValue('cmi.core._children'));
}

function doUnload(pressedExit) {
  // console.log("JS-Scorm.doUnload()");
  if (processedUnload == true) {
    return;
  }

  processedUnload = true;

  // Record the session time
  let endTimeStamp = new Date();
  let totalMilliseconds = endTimeStamp.getTime() - startTimeStamp.getTime();
  let scormTime = ConvertMilliSecondsToSCORMTime(totalMilliseconds, false);
  console.log(
    "The task time is:\n" + scormTime + "\n" + totalMilliseconds + "ms"
  );

  scorm.setValue("cmi.core.session_time", scormTime);

  //if the user just closes the browser, we will default to saving
  //their progress data. If the user presses exit, he is prompted.
  //If the user reached the end, the exit normall to submit results.
  if (pressedExit == true || scorm.reachedEnd == true) {
    scorm.setValue("cmi.core.exit", "");
  } else {
    scorm.setValue("cmi.core.exit", "suspend");
  }
  
  // NOTE: We must retrieve the information before closing the connection.
  console.log("=== score");
  console.log(scorm.getValue("cmi.core.score.raw"));
  console.log("=== lesson_status (bookmark)");
  console.log(scorm.getValue("cmi.core.lesson_status"));
  console.log("=== entry RO");
  console.log(scorm.getValue("cmi.core.entry"));
  //   console.log('exit');   // WO
  //   console.log(scorm.get_value("cmi.core.exit"));
  console.log("=== total_time RO");
  console.log(scorm.getValue("cmi.core.total_time"));
  console.log("=== lesson_location");
  console.log(scorm.getValue("cmi.core.lesson_location"));
  console.log("=== suspend_data");
  console.log(scorm.getValue("cmi.suspend_data"));
  console.log("=== launch_data RO");
  console.log(scorm.getValue("cmi.launch_data"));
  console.log("=== scorm.reachedEnd");
  console.log(scorm.reachedEnd);

  ScormProcessFinish();
}

//SCORM requires time to be formatted in a specific way
function ConvertMilliSecondsToSCORMTime(
  intTotalMilliseconds,
  blnIncludeFraction
) {
  let intHours;
  let intintMinutes;
  let intSeconds;
  let intMilliseconds;
  let intHundredths;
  let strCMITimeSpan;

  if (blnIncludeFraction == null || blnIncludeFraction == undefined) {
    blnIncludeFraction = true;
  }

  //extract time parts
  intMilliseconds = intTotalMilliseconds % 1000;

  intSeconds = ((intTotalMilliseconds - intMilliseconds) / 1000) % 60;

  intMinutes =
    ((intTotalMilliseconds - intMilliseconds - intSeconds * 1000) / 60000) % 60;

  intHours =
    (intTotalMilliseconds -
      intMilliseconds -
      intSeconds * 1000 -
      intMinutes * 60000) /
    3600000;

  /*
    deal with exceptional case when content used a huge amount of time and interpreted CMITimstamp 
    to allow a number of intMinutes and seconds greater than 60 i.e. 9999:99:99.99 instead of 9999:60:60:99
    note - this case is permissable under SCORM, but will be exceptionally rare
    */

  if (intHours == 10000) {
    intHours = 9999;

    intMinutes = (intTotalMilliseconds - intHours * 3600000) / 60000;
    if (intMinutes == 100) {
      intMinutes = 99;
    }
    intMinutes = Math.floor(intMinutes);

    intSeconds =
      (intTotalMilliseconds - intHours * 3600000 - intMinutes * 60000) / 1000;
    if (intSeconds == 100) {
      intSeconds = 99;
    }
    intSeconds = Math.floor(intSeconds);

    intMilliseconds =
      intTotalMilliseconds -
      intHours * 3600000 -
      intMinutes * 60000 -
      intSeconds * 1000;
  }

  //drop the extra precision from the milliseconds
  intHundredths = Math.floor(intMilliseconds / 10);

  //put in padding 0's and concatinate to get the proper format
  strCMITimeSpan =
    ZeroPad(intHours, 4) +
    ":" +
    ZeroPad(intMinutes, 2) +
    ":" +
    ZeroPad(intSeconds, 2);

  if (blnIncludeFraction) {
    strCMITimeSpan += "." + intHundredths;
  }

  //check for case where total milliseconds is greater than max supported by strCMITimeSpan
  if (intHours > 9999) {
    strCMITimeSpan = "9999:99:99";

    if (blnIncludeFraction) {
      strCMITimeSpan += ".99";
    }
  }

  return strCMITimeSpan;
}

function ZeroPad(intNum, intNumDigits) {
  let strTemp;
  let intLen;
  let i;

  strTemp = new String(intNum);
  intLen = strTemp.length;

  if (intLen > intNumDigits) {
    strTemp = strTemp.substr(0, intNumDigits);
  } else {
    for (i = intLen; i < intNumDigits; i++) {
      strTemp = "0" + strTemp;
    }
  }

  return strTemp;
}

// TODO: Put timestamp and version in the godot zip by default.
// TODO: Timestamp on logs.
// TODO: Redesign the test scene.
// TODO: Implement some save system.
// TODO: Maybe, implement the time tracking algorithm in the Godot side.
