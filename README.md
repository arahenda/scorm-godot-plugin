# Godot SCORM plugin

Offers a channel for communication with the SCORM API and packages the **Web exported** files into a ZIP archive.
The communication can be made with the functions or the signals of the `Scorm` autoload node.
`ScormExport` do the post-export zip packaging.

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

> [!NOTE]
> Take note that changing `ScormExport`'s exported values will require you to restart the engine for the changes to take effect.

The plugin takes care of the init and finish process taking care of the SCORM quirks. The developer should:

- Set a `score` for the current learner's attempt.
- In case the student has reached the end of the exercise, call `set_lesson_status(LessonStatus.COMPLETED)` to signalize 
it for the SCORM runtime. In case the lesson should be considered a test, `set_lesson_status(LessonStatus.PASSED)` can
be used in case the learner surpassed the threshold for approval. Otherwise, `set_lesson_status(LessonStatus.FAILED)`
should be called.
- The first start of the lesson has `cmi.core.lesson_status` as `not attempted`, the plugin
sets it to `incomplete` as suggested by the SCORM reference (see `doStart()`, `doUnload()` at `scorm.js`).
This way, the current attempt progression is retained by the LMS if the user closes the browser
or exits the SCORM lesson abruptly.

### Scorm Data model

#### `cmi.core.score.raw` - score (float RW Persistent*)

Represents the student score in the current SCO attempt.

##### `cmi.core.lesson_status` - current attempt status (String RW - “passed”, “completed”, “failed”,“incomplete”, “browsed”, “not attempted”)

'completed' the attempt, and if he 'passed' or 'failed'.

##### `cmi.core.session_time` - Current attempt running time (CustomTimeType WO)

Managed at the Javascript routines (`scorm.js`).

##### `cmi.core.lesson_location` (String(255 chars) RW Persistent*)

The learner’s current location in the SCO. A free text field for the SCO to record a bookmark.

##### `cmi.suspend_data` (String(4096 chars) RW Persistent*)

Provides space to store and retrieve data between learner sessions.

> [!NOTE]
> Attributes marked as **Persistent** above retain its values between runs in the same attempt (in case the learner chose to
continue a previous run).

More info:

- <https://scorm.com/scorm-explained/technical-scorm/run-time/>
- <https://scorm.com/scorm-explained/technical-scorm/run-time/run-time-reference/#section-2>

## Contributing

To extend the functionality you probably will:

- Adjust the enums/consts (`Attributes`, `ATTRIBUTES_TXT`, ...);
- Create a `TXT2<enum>`, adjust the `_init()`, adjust `_value_ext2type()`;
- Adjust `DME._set_safe()`;
- Create new API functions if necessary.
