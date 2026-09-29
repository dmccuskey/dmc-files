# dmc-files

Read and write files in a Solar2D (formerly Corona SDK) app in one call each: plain text, a file's lines, JSON, and simple config files with typed values.

dmc-files is [lua-files](https://github.com/dmccuskey/lua-files) packaged like the other DMC Solar2D libraries, plus a `remove()` that takes a file name and a Solar2D folder. The DMC libraries read their `dmc_corona.cfg` in its config format:

```lua
local File = require 'dmc_corona.dmc_files'

local path = system.pathForFile( 'scores.json', system.DocumentsDirectory )
local data = File.readJSONFile( path )     -- a Lua table
File.remove( 'scores.json' )               -- from system.DocumentsDirectory
```

## Features

- Read a whole file as a string, or as an array of its lines
- Write a string to a file
- Read a JSON file into a Lua table, with Solar2D's `json`
- Read a config file of `[SECTIONS]` and `KEY = value` lines, with the value cast by a type in the key (`PORT:INT = 8080`): boolean, number, JSON, module path, string
- Remove a file by name, or everything in a Solar2D folder such as `system.TemporaryDirectory`
- Pure Lua, no plugins needed; MIT licensed

## Quick Start

The following code will get you up and running in about 10 minutes in the Solar2D Simulator on macOS or Windows. It reads a config file shipped with the app, writes a text file and a JSON file to the app's documents folder, reads them back and removes them.

Prerequisites: the [Solar2D](https://solar2d.com/) Simulator and a copy of this repository (`git clone https://github.com/dmccuskey/dmc-files.git`, or download the ZIP from GitHub).

### 1. Copy the Library into Your Project

Copy these from this repository into the root of your project folder:

```text
dmc_corona_boot.lua     loader for the DMC libraries
dmc_corona.cfg          configuration
dmc_corona/             dmc-files and the modules it needs
```

**Going further:** keep the libraries in a subfolder, or combine several DMC libraries ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

### 2. Add a Config File

Create `app.cfg` in the project folder:

```text
-- settings for the app
NAME = 'Space Game'

[SERVER]
HOST = example.com
PORT:INT = 8080
SECURE:BOOL = true
```

### 3. Use It

Create `main.lua` in the project folder:

```lua
local File = require 'dmc_corona.dmc_files'

-- a config file shipped with the app (read-only)
local cfg_path = system.pathForFile( 'app.cfg', system.ResourceDirectory )
local cfg = File.readConfigFile( cfg_path )
print( cfg.default.name, cfg.server.host, cfg.server.port + 1, cfg.server.secure )

-- a text file the app writes
local notes_path = system.pathForFile( 'notes.txt', system.DocumentsDirectory )
File.saveFile( notes_path, "one\ntwo\nthree\n" )
local lines = File.readFileLines( notes_path )
print( #lines, lines[3] )

-- JSON
local scores_path = system.pathForFile( 'scores.json', system.DocumentsDirectory )
File.saveFile( scores_path, '{ "player":"ann", "points":[10,25] }' )
local scores = File.readJSONFile( scores_path )
print( scores.player, scores.points[2] )

-- remove what we wrote
File.remove( 'notes.txt' )
File.remove( 'scores.json' )
print( io.open( notes_path ) == nil, io.open( scores_path ) == nil )

display.newText( cfg.default.name, display.contentCenterX, display.contentCenterY, native.systemFont, 32 )
```

Open the project in the Simulator. The screen shows `Space Game`; the console shows:

```text
Space Game	example.com	8081	true
3	three
ann	25
true	true
```

If the console shows `module 'dmc_corona.dmc_files' not found` instead, `dmc_corona/` is missing from the root of the project folder.

The config file's sections become tables with lowercase names, and keys outside a section go into `default`; `PORT:INT` and `SECURE:BOOL` are cast to a number and a boolean. The read and write functions take a full path, from `system.pathForFile()`; `remove()` takes a file name and looks in `system.DocumentsDirectory` unless told otherwise. The app's own folder (`system.ResourceDirectory`) is read-only on devices: write to `system.DocumentsDirectory` or `system.TemporaryDirectory`.

To update, copy `dmc_corona_boot.lua` and `dmc_corona/` again from the newer version. Keep your own `dmc_corona.cfg` if you have changed it.

## Documentation

`require 'dmc_corona.dmc_files'` returns lua-files' module with two functions replaced, so its documentation applies to the rest as written:

- [Reference](https://github.com/dmccuskey/lua-files#reference): the text, JSON and config file functions, and the config format with its types
- [In Solar2D](https://github.com/dmccuskey/lua-files#in-solar2d): paths from `system.pathForFile()`, and `dmc_corona.cfg`
- [Known Issues](https://github.com/dmccuskey/lua-files#known-issues) of the file functions

### Functions Added for Solar2D

| function | does |
|---|---|
| `remove( items, options )` | Removes files from a Solar2D folder. `items` is a file name (in `options.base_dir`, default `system.DocumentsDirectory`), or a folder constant such as `system.TemporaryDirectory`, which removes every file in it and in its subfolders, and the subfolders themselves unless `options.rm_dir` is `false`. Prints an error, rather than raising one, when a file can't be removed. See Known Issues for folder names and lists. |
| `fileExists( name, options )` | Meant to say whether `name` exists in `options.base_dir` (default `system.DocumentsDirectory`); it raises an error instead (Known Issues). |

They replace lua-files' `remove()` and `fileExists()` in the shared module, so every module that requires `lib.dmc_lua.lua_files` gets them once dmc-files has loaded.

## Examples

`examples/dmc-files-readconfig/` reads the app's `dmc_corona.cfg` with `readConfigFile()` and prints the result to the console (the screen stays empty); see [examples/README.md](examples/README.md).

## Configuration

dmc-files has no settings: `dmc_corona.cfg` needs no section for it, only the `[DMC_CORONA]` section that tells the loader where the libraries are. See [dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md).

## Known Issues

The bugs of the file functions themselves are in lua-files' [Known Issues](https://github.com/dmccuskey/lua-files#known-issues); the ones most likely to be met: `writeJSONFile()` errors (use `saveFile( path, File.convertLuaToJson( data ) )`), and config section and key names with digits (`[SERVER2]`) make `readConfigFile()` raise. In `dmc_files.lua`:

- **`fileExists()` always errors** (`attempt to index global 'LuaFile' (a nil value)`): it calls lua-files' function under a name that doesn't exist. Because it replaces lua-files' own `fileExists()`, which works, loading dmc-files breaks `fileExists()` for every module. Check with `io.open( system.pathForFile( name, dir ) )` instead.
- **`remove()` of a folder name errors**: for a name that is a folder it calls an undefined `rm_dir()`. A list of names does nothing. A file name and a Solar2D folder constant work.
- It sets the global `_extend` (its copy of `Utils.extend()` declares the inner function without `local`).
- Its version (`1.1.0`) isn't available to code.

## Development

Only `dmc_corona/dmc_files.lua` is written in this repository. It loads the DMC boot loader, takes lua-files' module from `lib.dmc_lua.lua_files` and replaces `fileExists()` and `remove()` with the Solar2D versions. Everything else is a generated copy; fix it in its own repository, then rebuild:

| file | owner |
|---|---|
| every file in `dmc_corona/lib/dmc_lua/` | [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library), which copies them from the `lua-*` repositories ([lua-files](https://github.com/dmccuskey/lua-files), [lua-json-shim](https://github.com/dmccuskey/lua-json-shim), ...) |
| `dmc_corona_boot.lua` | [dmc-corona-boot](https://github.com/dmccuskey/dmc-corona-boot) |
| `examples/*/dmc_corona/`, `examples/*/dmc_corona_boot.lua` | copies of the above and of `dmc_corona/dmc_files.lua` |

The copies are made by Snakemake from sibling checkouts of the repositories above (`../DMC-Lua-Library`, `../dmc-corona-boot`, `../DMC-Corona-Library` for the shared rules). From this repository's root folder:

```sh
snakemake --cores 1 build_all
```

dmc-files has no tests of its own; lua-files' are in its `spec/`. The Quick Start and the example are the checks that the package loads in Solar2D.

## License

dmc-files is released under the [MIT License](LICENSE).
