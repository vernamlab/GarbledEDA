# GarbledEDA
Garbled EDA is a framework built based on the TinyGarble framework and allows IP owners to secure their IPs in end-users hands.
GarbledEDA also allows end-users to simulate, synthesize, and implement the IP design without revealing any information about the IP functionality or proprietary inputs.
Dependencies:
Install dependencies on Ubuntu:
1. g++: $ sudo apt-get install g++
2. OpenSSL: $ sudo apt-get install libssl-dev
3. boost: $ sudo apt-get install libboost-all-dev
4. cmake: $ sudo apt-get install software-properties-common
  	  $ sudo add-apt-repository ppa:george-edison55/cmake-3.x
  	  $ sudo apt-get update
  	  $ sudo apt-get upgrade
  	  $ sudo apt-get install cmake
5. TinyGarble: $ cd TintGarbe 
	       $./configure
  	       $ cd bin
  	       $ make
6. ARM2GC: $ sudo apt install binutils-arm-linux-gnueabi
	   $ sudo apt install gcc-arm-linux-gnueabi
Cross-compiler: $ sudo apt-get install apt-file
		$ sudo apt-file update
		$ apt-file search -x 'gcc$' | grep 'gcc-arm-linux-gnueabi'
Install dependencies on Windows: 
1. ARMSIM: ARMSim/Installer.msi
2. QtSpim: QtSpim/QtSpim_9.1.24_Windows.msi
3. v2c: use v2c-bin.tar.gz
SCD generation:
V2SCD_Main: Translating netlist Verilog (.v) file to simple circuit description (.scd) file
  -h [ --help ]                         produce help message.
  -i [ --netlist ]
                                        Input netlist (verilog .v) file
                                        address.
  -o [ --scd ]
                                        Output simple circuit description (scd)
                                        file address.
Run:
Generate p_init.text as follows:
$ cd <benchmark_directory>
$ GarbledEDA/TinyGarble/bin/garbled_circuit/TinyGarble -a -i GarbledEDA/TinyGarble/bin/scd/netlists/a23_gc_main_64_w_n_cc.scd --p_init a23/<benchmark_directory>/p.txt --init a23/<benchmark_directory>/test/g.txt -c 1000 -t 1 --log2std
Provide the p_init.text, e_init.text, and g_init.text to GarbledEDA/ARM_Garbled_Evaluator_Core/ARM_Garbled_Core_gc_main.v for ARM or GarbledEDA/MIPS_Garbled_Evaluator_Core/Garbled_MIPS_netlist.v for MIPS.
Syntesize and run the ARM_Garbled_Core_gc_main.v for ARM or GarbledEDA/MIPS_Garbled_Evaluator_Core/Garbled_MIPS_netlist.v for MIPS.
References:
Ebrahim M. Songhori, Siam U. Hussain, Ahmad-Reza Sadeghi, Thomas Schneider and Farinaz Koushanfar, "TinyGarble: Highly Compressed and Scalable Sequential Garbled Circuits." Security and Privacy, 2015 IEEE Symposium on May, 2015.
http://www.cprover.org/hardware/v2c/
https://webhome.cs.uvic.ca/~nigelh/ARMSim-V2.1/index.html
