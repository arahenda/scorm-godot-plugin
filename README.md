# Godot SCORM plugin

Offers a channel for communication with the SCORM API and packages the **Web exported** files into a ZIP archive. The communication can be made with the functions or the signals of the `Scorm` autoload node. `ScormExport` do the post-export zip packaging.

Follows the _SCORM 1.2_ specification.

## Installation

- Install the `Scorm` plugin.
- Activate the `Scorm` plugin (`Project > Plugins > Scorm`).
- Export your project for Web.
- The plugin will detect the export process and do his thing.

## Usage

`ScormExport` has some configurable options:

- `auto_zip`: If the plugin should generate a .zip of the built files or not.
- `default_zip_filename`: The name given to the .zip file.

> Take note that changing `ScormExport`'s exported values will require you to restart the engine for the changes to take effect.

The plugin takes care of the init and finish process taking care of the SCORM quirks. The user should:

- Set a 'score' for the current learner's attempt.
- In case the user reached the end of the exercise, call 'lesson_completed' to signalize it for
the SCORM runtime. In case the lesson should be considered a test, 'lesson_passed' can be used
in case the learner surpassed the threshould for approvation. Otherwise, 'lesson_failed' should
be called.
- The first start of the lesson has 'cmi.core.lesson_status' as 'not attempted', the plugin
sets it to 'incomplete' as suggested by the SCORM reference (see 'doStart()', 'doUnload()').
This way, the attempt progression is retained by the LMS case the user closes the browser
or exits the SCORM lesson.

### Scorm Data model

#### cmi.core.score.raw - score (float RW Persistent*)

Represents the student score in the current SCO attempt.

##### cmi.core.lesson_status - current attempt status (String RW - “passed”, “completed”, “failed”,“incomplete”, “browsed”, “not attempted”, RW)

'completed' the attempt, and if he 'passed' or 'failed'.

##### cmi.core.session_time - Current attempt running time (CustomTimeType WO)

Managed at the Javascript routines (scorm.js).

##### cmi.core.lesson_location (String(255 chars) RW Persistent*)

The learner’s current location in the SCO. A free text field for the SCO to record a bookmark.

##### cmi.suspend_data (String(4096 chars) RW Persistent*)

Provides space to store and retrieve data between learner sessions.

> [!NOTE]
> Attributes that are **persistent** betweens runs in the same attempt (in case the learner chose to
continue a previous run).

More info:

- <https://scorm.com/scorm-explained/technical-scorm/run-time/>
- <https://scorm.com/scorm-explained/technical-scorm/run-time/run-time-reference/#section-2>

## Contributing

To extend the functionality you problably will:

- Adjust the enums/consts (`Attributes`, `ATTRIBUTES_TXT`, ...);
- Create a `TXT2<enum>`, adjust the `_init()`, adjust `_value_ext2type()`;
- Adjust `DME._set_safe()`;
- Create new API functions if necessary.
