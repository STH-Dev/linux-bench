#!/bin/bash
#
#		(C) 2013-2014 ServeTheHome.com and ServeThe.biz
#		
#
# 	STHbench - A System Benchmark and comparison tool created by the STH community.
#
#	Should include a description of what the script does right here... 
#	All the benchmarks it includes... packages it installs... actions during runtime etc.
#
#	For more information go:
#	http://forums.servethehome.com/processors-motherboards/2519-introducing-sthbench-sh-benchmark-script.html
#
# 	Authors: Patrick Kennedy, nitrobass24, mir, Chuckleb, Patriot 
#
#   If you find bugs, verify you are on the latest version and then post in:
#	http://forums.servethehome.com/index.php?threads/introducing-the-sthbench-sh-benchmark-script.2519/
#
################################################################################################################################

#Current Version
rev='12.08'


revhist()
{
cat << EOF
	* 1.0 Intial release.
	* 2.0 Added: sysbench (CPU test, redis), Removed apt-get spam(1k lines), Added CentOS support
	* 3.0 Fixed: OS detection for Ubuntu including development/ daily builds)
	* 4.0 Fixed: redis-benchmark issue under some OSes and adds a 6379.conf file for the benchmark
	* 5.0 Fixed: Debian install and redis.
	* 6.0 Fixed: Installer.  Now redis-server shuts down after benchmarking is complete.
	* 7.0 Added: root check, removal code for benchmarks. Updated: Debian installation.
	* 8.0 Added: STREAM, OpenSSL, unzip,crafty benchmarks and lscpu logging.  
	      Updated: lowered prime problem size for sysbench.
	* 9.0 Nothing according to diff...
	* 10.0 Added: NAMD benchmark.  Updated: STREAM benchmark (non-PTS) (I don't see it changed)
	* 11.0 Deprecated crafty benchmark, too single threaded.
	* 12.0 Modularized neatened. 
	* 12.01 Fixed: SLES OS detection. Added: revhist, version, modules and a proper header.
	* 12.02 Seperated Benchmark Download from Runtime.
	* 12.03 Fixed: broken link to apoa1.tar.gz
	* 12.04 Added: Menu, flags: hVR.  Which call: help, Version, Revision History.
	* 12.05 Updated: OpenSSL to latest revision free of heartbleed.
	* 12.06 Fixed: redis config in wrong directory. 
	* 12.07 Fixed: Detection of lscpu for Ubuntu. 
		Added: Detect Docker environment to skip updates/installs
	* 12.08 Fixed: Removed PTS from standard run to cover heartbleed bug.   
		Added: OSSL multi threaded support to replace PTS, lscpu also run without flags.
		EOF
#exit 1
#Future ideas/plans/hopes/dreams

#Header needs work... read it and you will see.
#proxy configuration either prompted or just hardcoded per run.
# gui menu, yeah I am dreaming...
# work dir 
# separate downloads from benchmark runs.
# log file as STHBench_hostname_timestamp.log
# Run options 
# proxy variables maybe...
# upload options...
# separate or included results parsing script.
# add error checking on downloads...
# Else options for runtime... currently do nothing
}



usage() 
{
cat << EOF

usage: $0 

This is the STH benchmark suite. 

ARGS:
        ARG1 - none required for now

OPTIONAL ARGS:
        ARG -- script_option_1 script_option-2 

OPTIONS:
	-h	help (usage info)
  -V	Version of STHbench
	-R	Revision history

EOF
