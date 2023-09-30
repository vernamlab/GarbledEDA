# GarbledEDA
 Garbled EDA is a framework built based on the TinyGarble framework and allows IP owners to secure their IPs in end-users hands. GarbledEDA also allows end-users to simulate, synthesize, and implement the IP design without revealing any information about the IP functionality or proprietary inputs. For more information, please refer to [Garbled EDA: Privacy Preserving Electronic Design Automation](https://dl.acm.org/doi/abs/10.1145/3508352.3549455).
# Dependencies:
Install dependencies on Ubuntu:
g++: 
```
 $ sudo apt-get install g++
```
OpenSSL: 
```
  $ sudo apt-get install libssl-dev
```
boost:
```
  $ sudo apt-get install libboost-all-dev
```
cmake:
```
  $ sudo apt-get install software-properties-common
  $ sudo add-apt-repository ppa:george-edison55/cmake-3.x
  $ sudo apt-get update
  $ sudo apt-get upgrade
  $ sudo apt-get install cmake
```
TinyGarble:
```
  $ cd TintGarbe 
  $./configure
  $ cd bin
  $ make
```
ARM2GC:
```
  $ sudo apt install binutils-arm-linux-gnueabi
  $ sudo apt install gcc-arm-linux-gnueabi
```
Cross-compiler:
```
  $ sudo apt-get install apt-file
  $ sudo apt-file update
  $ apt-file search -x 'gcc$' | grep 'gcc-arm-linux-gnueabi'
```
# Install dependencies on Windows: 
1. ARMSIM: ARMSim/Installer.msi
1. QtSpim: QtSpim/QtSpim_9.1.24_Windows.msi
1. v2c: Extract v2c-bin.tar.gz and use cmake.
# SCD generation:
V2SCD_Main: Translating netlist Verilog (.v) file to simple circuit description (.scd) file
```
  -h [ --help ]                         produce help message.
  -i [ --netlist ]
                                        Input netlist (verilog .v) file
                                        address.
  -o [ --scd ]
                                        Output simple circuit description (scd)
                                        file address.
```
# Run:
For circuit synthesize go to this directory:
``` 
$cd TinyGarble/circuit_synthesis
```
Generate p_init.text as follows:  
First, go to your benchmark directory:
```
  $ cd <benchmark_directory>
```
Then compile the source code and write the Assembly instructions to ```p_init```:  
```
  $ GarbledEDA/TinyGarble/bin/garbled_circuit/TinyGarble -a -i GarbledEDA/TinyGarble/bin/scd/netlists/a23_gc_main_64_w_n_cc.scd --p_init a23/<benchmark_directory>/p.txt --init a23/<benchmark_directory>/test/g.txt -c 1000 -t 1 --log2std
```
Last step:  
Provide the ```p_init```, ```e_init```, and ```g_init``` to ```GarbledEDA/ARM_Garbled_Evaluator_Core/ARM_Garbled_Core_gc_main.v``` for ARM or ```GarbledEDA/MIPS_Garbled_Evaluator_Core/Garbled_MIPS_netlist.v for MIPS```.  
Synthesize and run the ```ARM_Garbled_Core_gc_main.v``` for ARM or ```GarbledEDA/MIPS_Garbled_Evaluator_Core/Garbled_MIPS_netlist.v``` for MIPS.
# References:
How to cite this code: 
@inproceedings{hashemi2022garbled,
  title={Garbled EDA: Privacy Preserving Electronic Design Automation},
  author={Hashemi, Mohammad and Roy, Steffi and Ganji, Fatemeh and Forte, Domenic},
  booktitle={Proceedings of the 41st IEEE/ACM International Conference on Computer-Aided Design},
  pages={1--9},
  year={2022}
}
1. Ebrahim M. Songhori, Siam U. Hussain, Ahmad-Reza Sadeghi, Thomas Schneider and Farinaz Koushanfar, "TinyGarble: Highly Compressed and Scalable Sequential Garbled Circuits." Security and Privacy, 2015 IEEE Symposium on May, 2015.
1. Mukherjee, Rajdeep, Michael Tautschnig, and Daniel Kroening. "v2c–A verilog to C translator." Tools and Algorithms for the Construction and Analysis of Systems: 22nd International Conference, TACAS 2016, Held as Part of the European Joint Conferences on Theory and Practice of Software, ETAPS 2016, Eindhoven, The Netherlands, April 2-8, 2016, Proceedings 22. Springer Berlin Heidelberg, 2016.
1. Cao, Junwei. "ARMSim: A modeling and simulation environment for agent-based grid computing." Simulation 80.4-5 (2004): 221-229.
