[![Build Status](https://travis-ci.org/esonghori/TinyGarble.svg?branch=develop)](https://travis-ci.org/esonghori/TinyGarble)

TinyGarble
=======
TinyGarble is a full implementation of 
[Yao's Garbled Circuit (GC) protocol](https://en.wikipedia.org/wiki/Garbled_Circuit) for
two-party Secure Function Evaluation (SFE) in which the parties are able to
execute any function on their private inputs and learn the output without
leaking any information about their inputs.
This repository consists of two main parts: (1) circuit synthesis (output examples 
of this is stored in `scd/netlist/v.tar.bz` and will be unzipped and translated in 
`bin/scd/netlist/` after `make`) and (2) secure function evaluation.
Circuit synthesis is partially described in TinyGarble paper in IEEE S&P'15 (see
References). It is based on upon hardware synthesis and sequential circuit
concept and outputs a netlist Verilog (`.v`) file (not included in this repository). 
The other part of TinyGarble, hereafter called "TinyGarble", is a GC framework 
implemented based on [JustGarble](http://cseweb.ucsd.edu/groups/justgarble/)
project. Beside Free-XOR, Row-reduction, OT extension, and
Fixed-key block cipher, TinyGarble includes Half Gates which is the most recent
optimization on GC protocol and reduces the communication by 33%.
TinyGarble also includes communication and Oblivious Transfer (OT) which were
missing in JustGarble. Note that OT is a crucial part for the security of the GC 
protocol.

TinyGarble general flow:
1. Write a Verilog file (`.v`) describing the function.
2. Synthesis the Verilog file using TinyGarble's [*circuit synthesis*](circuit_synthesis/README.md) to generate
a netlist Verilog file (`.v`).
3. Translate the netlist file (`.v`) to a simple circuit description file
([SCD](scd/README.md)) using TinyGarble's `V2SCD_Main` and then provide both parties with the
file. (We have done steps 1-3 for a number of functions, and you can find their scd files after compiling in `bin/scd/netlists/`.)
4. Execute `TinyGarble` using `--alice` flag on one party and `--bob` flag
on the other plus other appropriate arguments.

# Circuit Synthesis

## Dependencies
Netlist generation requires Synopsys Design Compiler or Yosys-ABC synthesis
tools.

## Manual for Synopsys Design Compiler
### Compile library
[This part is mentioned only for documentation and it is already done, please skip.]

Go to `circuit_synthesis/lib/dff_full` and compile the library:
```
	$ cd circuit_synthesis/lib/dff_full
	$ ./compile
```
_Advanced detailed_: Let's suppose that our\_lib.lib is located in
/path/to/our\_lib.

- Go inside /path/to/our\_lib and run:
```
	$ lc_shell
	lc_shell> set search_path [concat /path/to/our_lib/]
	lc_shell> read_lib our_lib.lib
	lc_shell> write_lib our_lib -format db
	lc_shell> exit
```
[Note: commands starting with "lc_shell>" should be called inside `lc_shell`.
Please ignore "lc_shell>" for them].

### Compile a benchmark
Go inside `circuit_synthesis/benchmark`, where benchmark is the name of the function
and compile the benchmark to generate the netlist:
```
	$ cd benchmark
	$ ./compile
```
You can edit `benchmark.dcsh` file to change synthesis parameters.

_Advanced detailed_: Let's suppose that `our_lib.db` is compiled and located
in `/path/to/our_lib` and benchmark.v is located in `/path/to/benchmark/`.

- Go to `/path/to/benchmark/` and run:
```
	$ design_vision
	design_vision> elaborate benchmark -architecture verilog -library DEFAULT -update
	design_vision> set_max_area -ignore_tns 0
	design_vision> set_flatten false -design *
	design_vision> set_structure -design * false
	design_vision> set_resource_allocation area_only
	design_vision> report_compile_options
	design_vision> compile -ungroup_all -boundary_optimization  -map_effort high -area_effort high -no_design_rule
	design_vision> write -hierarchy -format verilog -output benchmark_syn.v
	design_vision> exit
```
It creates `benchmark_syn.v` in the current directory. [Note: commands
starting with "design\_vision>" should be called inside `design_vision`.
Please ignore "design\_vision>" for them.]

### Counting number of gates
You can use `script/count.sh` to count the number of gates in
the generated netlist file. For counting gates in
`/path/to/benchmark/benchmark_syn.v`, simply run:
```
	$ script/count.sh /path/to/benchmark/benchmark_syn.v
```
## Manual for Yosys

Here is how to compile a verilog file named "benchmark.v" using the custom
library "asic\_cell.lib". We assume that the files are inside a folder named
"Synthesis\_yosys-abc" inside the "yosys" directory. The final output will be
written in "benchmark\_syn.v"
```
	$ cd ~/yosys
	$ ./yosys
	yosys> read_verilog Synthesis_yosys-abc/benchmark.v
	yosys> hierarchy -check -top benchmark
	yosys> proc; opt; memory; opt; fsm; opt; techmap; opt;
	yosys> abc -liberty Synthesis_yosys-abc/asic_cell_extended.lib
	yosys> opt
	yosys> write_verilog Synthesis_yosys-abc/benchmark_syn.v
	yosys> exit
```	
[Note: commands starting with "yosys>" should be called inside design_vision.
Please ignore "yosys>" for them.]

gates."](http://eprint.iacr.org/2014/756)
In <i>Eurocrypt, 2015</i>.
- G. Asharov, Y. Lindell, T. Schneider and M. Zohner: More Efficient Oblivious
Transfer and Extensions for Faster Secure Computation In <i>CCS'13</i>.
