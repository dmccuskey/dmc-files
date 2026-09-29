--====================================================================--
-- tests/dmc_files_spec.lua
--
-- Unit tests for dmc-files, using Luna Test.
-- Run with tests/run_unit.sh
--====================================================================--


module(..., package.seeall)



--====================================================================--
--== Setup


local File, LuaFiles, lfs
local docs, temp -- folder paths

local function write( path, text )
	local fh = assert( io.open( path, 'w' ) )
	fh:write( text or 'x' )
	fh:close()
end

local function exists( path )
	return lfs.attributes( path, 'mode' ) ~= nil
end

local function count( dir )
	local n = 0
	for name in lfs.dir( dir ) do
		if name ~= '.' and name ~= '..' then n = n + 1 end
	end
	return n
end

-- a folder with a file, and a subfolder with a file
local function makeTree( path )
	lfs.mkdir( path )
	write( path..'/a.txt' )
	lfs.mkdir( path..'/sub' )
	write( path..'/sub/b.txt' )
end

function suite_setup()
	File = require 'dmc_corona.dmc_files'
	LuaFiles = require 'lib.dmc_lua.lua_files'
	lfs = require 'lfs'
	docs = system.pathForFile( '', system.DocumentsDirectory )
	temp = system.pathForFile( '', system.TemporaryDirectory )
end

function setup()
	File.remove( system.DocumentsDirectory )
	File.remove( system.TemporaryDirectory )
end



--====================================================================--
--== Module


function test_version()
	assert_string( File.VERSION )
end

function test_hasLuaFilesFunctions()
	assert_equal( LuaFiles.readConfigFile, File.readConfigFile )
	assert_equal( LuaFiles.saveFile, File.saveFile )
end

function test_sharedModuleUnchanged()
	assert_not_equal( LuaFiles.fileExists, File.fileExists )
	assert_not_equal( LuaFiles.remove, File.remove )
	write( docs..'notes.txt' )
	assert_true( LuaFiles.fileExists( docs..'notes.txt' ), "lua-files' takes a full path" )
end



--====================================================================--
--== fileExists()


function test_fileExists()
	write( docs..'notes.txt' )
	assert_true( File.fileExists( 'notes.txt' ) )
	assert_false( File.fileExists( 'missing.txt' ) )
end

function test_fileExistsSubfolder()
	makeTree( docs..'saves' )
	assert_true( File.fileExists( 'saves/a.txt' ) )
	assert_false( File.fileExists( 'saves' ), "false for a folder" )
end

function test_fileExistsBaseDir()
	write( temp..'cache.txt' )
	assert_false( File.fileExists( 'cache.txt' ) )
	assert_true( File.fileExists( 'cache.txt', { base_dir=system.TemporaryDirectory } ) )
end

function test_fileExistsResource()
	assert_true( File.fileExists( 'dmc_corona.cfg', { base_dir=system.ResourceDirectory } ) )
	assert_false( File.fileExists( 'missing.cfg', { base_dir=system.ResourceDirectory } ) )
end



--====================================================================--
--== remove()


function test_removeFile()
	write( docs..'notes.txt' )
	File.remove( 'notes.txt' )
	assert_false( exists( docs..'notes.txt' ) )
end

function test_removeMissing()
	File.remove( 'missing.txt' )
	File.remove( 'missing.cfg', { base_dir=system.ResourceDirectory } )
end

function test_removeList()
	write( docs..'one.txt' )
	write( docs..'two.txt' )
	write( docs..'three.txt' )
	File.remove( { 'one.txt', 'two.txt' } )
	assert_false( exists( docs..'one.txt' ) )
	assert_false( exists( docs..'two.txt' ) )
	assert_true( exists( docs..'three.txt' ) )
end

function test_removeFolderByName()
	makeTree( docs..'saves' )
	File.remove( 'saves' )
	assert_false( exists( docs..'saves' ) )
end

function test_removeFolderKeepFolders()
	makeTree( docs..'saves' )
	File.remove( 'saves', { rm_dir=false } )
	assert_true( exists( docs..'saves/sub' ) )
	assert_equal( 1, count( docs..'saves' ), "only the emptied subfolder" )
	assert_equal( 0, count( docs..'saves/sub' ) )
end

function test_removeBaseDir()
	write( docs..'cache.txt' )
	write( temp..'cache.txt' )
	File.remove( 'cache.txt', { base_dir=system.TemporaryDirectory } )
	assert_false( exists( temp..'cache.txt' ) )
	assert_true( exists( docs..'cache.txt' ) )
end

function test_removeSolarFolder()
	makeTree( temp..'cache' )
	write( temp..'c.txt' )
	write( docs..'notes.txt' )
	File.remove( system.TemporaryDirectory )
	assert_true( exists( temp ), "the folder itself stays" )
	assert_equal( 0, count( temp ) )
	assert_true( exists( docs..'notes.txt' ) )
end

function test_removeSolarFolderInList()
	write( temp..'c.txt' )
	write( docs..'notes.txt' )
	File.remove( { system.TemporaryDirectory, 'notes.txt' } )
	assert_equal( 0, count( temp ) )
	assert_false( exists( docs..'notes.txt' ) )
end

function test_removeFailureRaises()
	lfs.mkdir( docs..'locked' )
	write( docs..'locked/a.txt' )
	os.execute( "chmod a-w '"..docs.."locked'" )
	local ok, err = pcall( File.remove, 'locked' )
	os.execute( "chmod u+w '"..docs.."locked'" )
	assert_false( ok )
	assert_match( 'Permission denied', err )
	assert_true( exists( docs..'locked/a.txt' ) )
end

function test_removeWrongType()
	local ok, err = pcall( File.remove, 42 )
	assert_false( ok )
	assert_match( 'expected a name', err )
end

function test_optionsUnchanged()
	local options = { rm_dir=false }
	File.remove( 'missing.txt', options )
	assert_nil( options.base_dir )
end
