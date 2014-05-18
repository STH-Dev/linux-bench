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
#
#	Latest development versions are available on the GitHub site:  https://github.com/STH-Dev/STHbench.sh
#
#   If you find bugs, verify you are on the latest version and then post in:
#	http://forums.servethehome.com/index.php?threads/introducing-the-sthbench-sh-benchmark-script.2519/
#
################################################################################################################################

#Current Version
rev='12.11'

version()
{
cat << EOF
##############################################################
#  (c) 2014 ServeTheHome.com and ServeThe.biz
# 
#	STHbench $rev
#	- STH Benchmark Suite 
###############################################################

EOF
}


usage() 
{
cat << EOF

usage: $0 

This is the STH benchmark suite. 

ARGS:
        ARG1 - none required for now
        ARG2 - none required for now
        ARG3 - none required for now

OPTIONAL ARGS:
        ARG -- script_option_1 script_option-2 

OPTIONS:
	-h	help (usage info)
    	-V	Version of STHbench

EOF
}


# Verify if the script is executed with Root Privileges #
rootcheck() 
{
	if [[ $EUID -ne 0 ]]; then
   		echo "This script must be run as root" 
		echo "Ex. "sudo ./STHbench""
		exit 1
	fi
}


#Set Functions
setup()
{
	benchdir=`pwd`
	NEED_PTS=1

	date_str="+%Y_%m%d_%H%M%S"
	full_date=`date $date_str`
	host=$(hostname)
	log="STHbench"$rev"_"$host"_"$full_date.log
	if [ -f /.dockerinit ] ; then
		log=/data/"STHbench"$rev"_"$host"_"$full_date.log
	fi
	#outdir=$host"_"$full_date
	#mkdir $outdir
}


# Update and install required packages (Debian)
Update_Install_Debian()
{
	apt-get -y install build-essential libx11-dev libglu-dev hardinfo sysbench unzip expect php5-curl php5-common php5-cli php5-gd libfpdi-php gfortran
	mkdir -p /usr/tmp/
}


# Update and install required packages (CentOS/RHEL)
Update_Install_RHEL()
{
	rpm -Uhv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	rpm -Uhv http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
	yum -y groupinstall "Development Tools" && yum -y install wget sysbench unzip libX11 perl-Time-HiRes mesa-libGLU hardinfo expect php-common glibc.i686 gfortran
}


# Detects which OS and if it is Linux then it will detect which Linux Distribution.
whichdistro() 
{
	OS=`uname -s`
	REV=`uname -r`
	MACH=`uname -m`

	if [ "${OS}" = "SunOS" ] ; then
		OS=Solaris
		DIST=Solaris
		ARCH=`uname -p`	
		OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
	elif [ "${OS}" = "AIX" ] ; then
		DIST=AIX
		OSSTR="${OS} `oslevel` (`oslevel -r`)"
		
	elif [ "${OS}" = "Linux" ] ; then
		KERNEL=`uname -r`
	
		if [ -f /etc/redhat-release ] ; then
			DIST='RedHat'
			PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
			
		elif [ -f /etc/centos-release ] ; then
			DIST='CentOS'
			PSUEDONAME=`cat /etc/centos-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/centos-release | sed s/.*release\ // | sed s/\ .*//`
			
		elif [ -f /etc/SuSE-release ] ; then
			DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
			REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
			
		elif [ -f /etc/mandrake-release ] ; then
			DIST='Mandrake'
			PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
			
		elif [ -f /etc/debian_version ] ; then
			DIST="Debian"
			PSUEDONAME=`cat /etc/debian_version`
				REV=""

		elif [ -f /etc/UnitedLinux-release ] ; then
			DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
			
		else 
			DIST='Not detected'	
		fi
		
		OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"
	fi
}


# Update and install required packages
dlDependancies()
{
# Test to see if $DOCKER has been defined. Those building DockerFiles can set DOCKER=TRUE to bypass installing/updates.
	if [ -f /.dockerinit ] ; then
	echo "In a Docker container, no updates run."
	elif [ "${DIST}" = "CentOS" ] ; then
	Update_Install_RHEL
	elif [ "${DIST}" = "RedHat" ] ; then
	Update_Install_RHEL
	elif [ "${DIST}" = "Debian" ] ; then
	Update_Install_Debian
	fi
}


# Display script output and append to log
benchlog()
{
	exec > >(tee --append $log)
	exec 2>&1
	echo ${OSSTR}
}


extract()
{
	if [ -e ./$appbin ] ; then
		echo "$apptgz already installed"
	elif [ -e ./$apptgz ] ; then
		tar $tgzstring $apptgz
	else
		wget $appdlpath
		tar $tgzstring $apptgz
	fi
}


#System information and log capture.
sysinfo()
{
	eval "strings `which lscpu`" | grep -q version ;
	if [ $? = 0 ] ; then
		lscpu
		lscpu -V
		lscpu -e
	else 
		lscpu;
	fi
}


# HardInfo
hardi()
{
	cd $benchdir
	echo "Running HardInfo test"
	hardinfo --generate-report --report-format text 
}

# UnixBench 5.1.3
ubench()
{
	cd $benchdir
	echo "Building UnixBench"
	wget -N https://byte-unixbench.googlecode.com/files/UnixBench5.1.3.tgz 
	wget -N http://forums.servethehome.com/pjk/fix-limitation.patch 
	tar -zxf UnixBench5.1.3.tgz
	
	cd UnixBench 
	mv ../fix-limitation.patch .	
	make 
	patch Run fix-limitation.patch
	echo "Running UnixBench"
	./Run dhry2reg whetstone-double syscall pipe context1 spawn execl shell1 shell8 shell16
	cd ..
	rm -rf UnixBench*
}

# C-Ray 1.1
cray()
{
	cd $benchdir
	
	appbase=c-ray-1.1
	apptgz=c-ray-1.1.tar.gz
	tgzstring=xfz
	appbin=$appbase/c-ray-mt
	appdlpath=http://www.futuretech.blinkenlights.nl/depot/$apptgz
	extract
	
	threads=$(grep "processor" /proc/cpuinfo | wc -l)
	echo "Running C-Ray test"
	cd c-ray-1.1 && make
	echo "c-ray Easy Test"
	cat scene | ./c-ray-mt -t $threads -s 7500x3500 > foo.ppm 
	echo "c-ray Medium Test"
	cat sphfract | ./c-ray-mt -t $threads -s 1920x1200 -r 8 > foo.ppm
	echo "c-ray Hard Test"
	cat sphfract | ./c-ray-mt -t $threads -s 3840x2160 -r 8 > foo.ppm 
	cd ..
	rm -rf c-ray-1.1*
}

# STREAM by Dr. John D. McCalpin
stream()
{
	cd $benchdir
	echo "Building STREAM"

	if [ -e stream.c ] ; then
		echo "Stream downloaded"
	else
		wget -N http://www.cs.virginia.edu/stream/FTP/Code/stream.c
	fi

	gcc stream.c -O3 -march=native -fopenmp -o stream-me

	# Determine number of physical cores (not hyperthread) and set OMP to cores value
	procs=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
	pcores=$(grep "cpu cores" /proc/cpuinfo |sort -u |cut -d":" -f2)
	cores=$((procs*pcores))

	export OMP_NUM_THREADS=$cores
	export GOMP_CPU_AFFINITY=0-$((cores-1))
	echo $GOMP_CPU_AFFINITY

	echo "Running STREAM test"
	./stream-me
}

# OpenSSL
OSSL()
{
	cd $benchdir
	
	appbase=openssl-1.0.1g
	apptgz=openssl-1.0.1g.tar.gz
	tgzstring=xfz
	appbin=$appbase/apps/openssl
	appdlpath=http://www.openssl.org/source/$apptgz
	extract

	cd openssl-1.0.1g/
	echo "Building OpenSSL"
	./config no-zlib 2>&1 >> /dev/null
	make 2>&1 >> /dev/null
	echo "Running OpenSSL test"
   	nproc=`nproc`
	./apps/openssl speed rsa4096 -multi ${nproc}

	rm -rf openssl*
}

crafty()
{
	cd $benchdir
   	wget -N http://www.craftychess.com/crafty-23.4.zip
   	unzip -o crafty-23.4.zip
   	cd crafty-23.4/
   	export target=LINUX
   	export CFLAGS="-Wall -pipe -O3 -fomit-frame-pointer $CFLAGS"
   	export CXFLAGS="-Wall -pipe -O3 -fomit-frame-pointer"
   	export LDFLAGS="$LDFLAGS -lstdc++"
   	make crafty-make
   	chmod +x crafty
   	./crafty bench end
	rm -rf crafty-23.4*
}



# sysbench CPU test prime
sysb()
{
	cd $benchdir
   	echo "Running sysbench CPU Single Thread"
   	sysbench --test=cpu --cpu-max-prime=30000 run
   	echo "Running sysbench CPU Multi-Threaded"
   	nproc=`nproc`
   	sysbench --num-threads=${nproc} --test=cpu --cpu-max-prime=300000 run
}


# redis Benchmark based on feedback. Next step is to add memchached as seen here: http://oldblog.antirez.com/post/redis-memcached-benchmark.html
red()
{
	cd $benchdir
	echo "Building Redis"

	wget http://download.redis.io/redis-stable.tar.gz
	tar xzf redis-stable.tar.gz && cd redis-stable && make install
	cp utils/redis_init_script /etc/init.d/redis_6379
	mkdir -p /var/redis/6379
	wget http://forums.servethehome.com/pjk/6379.conf
	mkdir -p /etc/redis
	cp ./6379.conf /etc/redis

	service redis_6379 start

   	# Original redis benchmark set/ get test

	echo "Running Redis test"
	redis-benchmark -n 1000000 -t set,get -P 32 -q -c 200

	BIN=redis-benchmark

	payload=32
	iterations=10000
	keyspace=100000

	for clients in 1 5 10 25 50 75 100
	do
		SPEED=0
		for dummy in 0 1 2
			do
				S=$($BIN -n $iterations -r $keyspace -d $payload -c $clients | grep 'per second' | tail -1 | awk '{print $1}')
				VALUE=$(echo $S | awk '{printf "%.0f",$1}')
				if [ $(($VALUE > $SPEED)) != 0 ]
					then
					SPEED=$VALUE
				fi
			done
		echo "$clients $SPEED"
	done

	redis-cli shutdown

	rm -rf /etc/redis
	rm -f /etc/init.d/redis_6379
	rm -rf /var/redis
	rm -f /usr/local/bin/redis-benchmark
	rm -f /usr/local/bin/redis-check-aof
	rm -f /usr/local/bin/redis-check-dump
	rm -f /usr/local/bin/redis-cli
	rm -f /usr/local/bin/redis-server
	rm -f redis-stable.tar.gz
	rm -rf redis-stable
}


# NPB Benchmarks
NPB()
{
	cd $benchdir

	apptgz=NPB3.3.1.tar.gz
	appbin=NPB3.3.1/NPB3.3-OMP
	appdlpath=http://forums.servethehome.com/pjk/$apptgz
	tgzstring=xfz
	extract
	
	cd NPB3.3.1/NPB3.3-OMP/
	echo "Building NPB"

   	# Use the provided makefile definitions
   	cp config/NAS.samples/make.def.gcc_x86 config/make.def

	# Define which tests to build
	echo "ft A" >> config/suite.def
	#echo "mg A" >> config/suite.def
	#echo "sp A" >> config/suite.def
	#echo "lu A" >> config/suite.def
	echo "bt A" >> config/suite.def
	#echo "is A" >> config/suite.def
	#echo "ep A" >> config/suite.def
	#echo "cg A" >> config/suite.def
	#echo "ua A" >> config/suite.def
	#echo "dc A" >> config/suite.def

	make suite

	# Determine number of physical cores (not hyperthread) and set OMP to cores value
	procs=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
	pcores=$(grep "cpu cores" /proc/cpuinfo |sort -u |cut -d":" -f2)
	cores=$((procs*pcores))

	export OMP_NUM_THREADS=$cores

	echo "Running NPB tests"
	bin/bt.A.x
	bin/ft.A.x
	rm -rf NPB3.3.1*
}


# NAMD Benchmark http://www.ks.uiuc.edu/Research/namd/performance.html
NAMD()
{
	echo "Building NAMD"
	cd $benchdir

	appbase=NAMD_2.9_Linux-x86_64-multicore
	apptgz=NAMD_2.9_Linux-x86_64-multicore.tar.gz
	tgzstring=xfz
	appbin=$appbase/namd2
	appdlpath=http://forums.servethehome.com/pjk/$apptgz
	extract
	
	appbase=apoa1
	apptgz=apoa1.tar.gz
	tgzstring=xfz
	appbin=$appbase/apoa1.pdb
	appdlpath=http://forums.servethehome.com/pjk/$apptgz
	extract

	cores=$(grep "processor" /proc/cpuinfo | wc -l)

	echo "Using" $cores "threads"
	echo "Running NAMD benchmark... (will take a while)"

	cd NAMD_2.9_Linux-x86_64-multicore
	timeperstep=$(./namd2 +p$cores +setcpuaffinity ../apoa1/apoa1.namd | grep "Benchmark time" | tail -1 | cut -d" " -f6)

	echo "Time per step" $timeperstep
	rm -rf NAMD* apoa1*
}
    
# p7zip
p7zip()
{
	cd $benchdir

	appbase=p7zip_9.20.1
	apptgz=p7zip_9.20.1_src_all.tar.bz2
	tgzstring=xfj
	appbin=p7zip_9.20.1/bin/7za
	appdlpath=https://dl.dropboxusercontent.com/u/124184/$apptgz
	extract

	echo "Building p7zip"
	cd $appbase
	make -j 2>&1 >> /dev/null

	echo "Starting 7zip benchmark, this will take a while"
	bin/7za b >> output.txt
	
	compressmips=$(grep Avr output.txt | tr -s ' ' |cut -d" " -f4)
	decompressmips=$(grep Avr output.txt | tr -s ' ' |cut -d" " -f7)
	
	echo "Compress speed (MIPS):" $compressmips
	echo "Decompress speed (MIPS):" $decompressmips
	
	rm -rf p7zip*
}

runBenches()
{	
#Individual modules run below...comment them out to prevent them from running.
#echo ${iterations:=1} passes
#	while [ $iterations -gt 0 ] ; do
		echo "hardinfo"  
		time hardi
		echo "ubench"
		time ubench
		echo "cray"
		time cray
		echo "stream"
		time stream
		echo "OSSL"
		time OSSL  
		echo "sysbench"
		time sysb 
		echo "redis"
		time red
		echo "NPB"
		time NPB
		echo "NAMD" 
		time NAMD
		echo "p7zip"
		time p7zip
#		let iterations-=1
#	done
	
}

#	Runtime  This is where everything is actually run from and called...
#
# 	This is where a menu would go for runtime options...
#

main()
{	
rootcheck

while getopts "hVR" arg; do
  case $arg in
	h)
	usage
	exit 1
	;;
	V)
	version
	exit 1
	;;
	\?)
     	usage
	exit 1
     	;;
  esac
done

	echo "version"
	version
	echo "setup"
	setup
	echo "whichdistro"
	whichdistro
	echo "dlDep"
	dlDependancies
	echo "benchlog"
	benchlog
	echo "derpinfo"
	sysinfo  exiting on sysinfo...
	sysinfo
	echo "run benches"
	runBenches
	echo "Uninstall benches"
	echo "done"
}

# Execute everything in the script
main
