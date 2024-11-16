# Godot SCORM plugin

Offers a channel for communication with the SCORM API and packages the Web exported files into a ZIP archive. The communication can be made with the functions or the signals of the `Scorm` autoload node. `ScormExport` do the post-export zip packaging.

Follows the _SCORM 2004 4th Edition_ specification.

## Usage

- Installs the `Scorm` plugin.
- Activates the `Scorm` plugin (`Project > Plugins > Scorm`).
- Export your project for Web.
- The plugin will detect the export process and do his thing.

`ScormExport` has some configurable options:
  - `auto_zip`: If the plugin should generate a .zip of the built files or not.
  - `default_zip_filename`: The name given to the .zip file.

> Take note that changing `ScormExport`'s exported values will require you to restart the engine for the changes to take effect.
