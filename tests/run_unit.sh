#!/bin/sh
#
# Run the lunatest unit specs with plain Lua 5.1.
#
# usage: tests/run_unit.sh
#   override the interpreter with LUA=

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
LUA=${LUA:-$ROOT/../tools/lua51/bin/lua}

cd "$ROOT"
LUA_PATH="$ROOT/?.lua;$HERE/?.lua;$($LUA -e 'io.write(package.path)')"
LUA_CPATH="$($LUA -e 'io.write(package.cpath)')"
export LUA_PATH LUA_CPATH

# the specs make and remove files in a folder of their own
DMC_FILES_TEST_DIR=$(mktemp -d)
export DMC_FILES_TEST_DIR
trap 'chmod -R u+w "${DMC_FILES_TEST_DIR:?}"; rm -rf "${DMC_FILES_TEST_DIR:?}"' EXIT

# stand-ins for the Solar2D globals the library touches: dmc_corona_boot
# needs json and system.pathForFile; dmc-files needs the folder constants,
# which are userdata in Solar2D, and pathForFile() for them. Documents and
# Temporary are subfolders of the test folder; Resource is the repository,
# where pathForFile() gives nil for a missing file, as Solar2D does
"$LUA" -e "
package.preload.json = package.preload.json or function() return require 'dkjson' end
local lfs = require 'lfs'
local test_dir = os.getenv( 'DMC_FILES_TEST_DIR' )
system = {
	DocumentsDirectory=newproxy(), TemporaryDirectory=newproxy(),
	ResourceDirectory=newproxy(),
}
local dirs = {
	[system.DocumentsDirectory]=test_dir..'/Documents',
	[system.TemporaryDirectory]=test_dir..'/Temporary',
	[system.ResourceDirectory]='.',
}
lfs.mkdir( dirs[system.DocumentsDirectory] )
lfs.mkdir( dirs[system.TemporaryDirectory] )
function system.pathForFile( name, base_dir )
	local dir = dirs[ base_dir or system.ResourceDirectory ]
	if name == nil or name == '' then return dir..'/' end
	local path = dir..'/'..name
	if base_dir == system.ResourceDirectory and not lfs.attributes( path ) then
		return nil
	end
	return path
end
local lunatest = require 'lunatest'
lunatest.suite( 'dmc_files_spec' )
lunatest.run()
"
