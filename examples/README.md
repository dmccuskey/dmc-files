# Examples

Each folder is a complete Solar2D project with its own copy of the library: open its `main.lua` in the Solar2D Simulator.

**dmc-files-readconfig** reads the app's own `dmc_corona.cfg` with `readConfigFile()`, using `dmc_corona` as the section for keys outside one, and prints the result. It draws nothing: the screen stays empty and the console shows:

```text
dmc_corona --> table: 0x... w 0 items
  lua_path --> table: 0x... w 1 items
    1 = './dmc_corona'
```

The `[DMC_CORONA]` section became the table `dmc_corona`, and `LUA_PATH:JSON` the array `lua_path`. Add a section or a key to `dmc_corona.cfg` to see how it is read.
