# Changelog

## 1.2.0 (2026-09-29)

### Changed

- `remove()` now calls lua-files' `remove()`: it raises `os.remove()`'s error when a file can't be removed, instead of printing it and going on, and a symbolic link is removed itself, never followed.
- `fileExists()` returns `false` for a folder (lua-files 0.3.0).
- `require 'dmc_corona.dmc_files'` returns a copy of lua-files' module, so the shared module other code gets from `lib.dmc_lua.lua_files` keeps its path-based `fileExists()` and `remove()`.
- `remove()` no longer adds `base_dir` and `rm_dir` to the options table it's given.
- Rebuilt with dmc-corona-boot 1.6.0 and the current DMC-Lua-Library (lua-files 0.3.0: `writeJSONFile()` works; config names with digits).

### Added

- `VERSION` in the table the module returns.
- Unit tests: `tests/run_unit.sh`, plain Lua 5.1.
