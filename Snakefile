# dmc-files

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-files"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-files",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_files.lua"
		],
		"requires": [
			"dmc-corona-boot",
			"DMC-Lua-Library"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "dmc-files-readconfig",
				"requires": []
			}
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-files", module_config )

