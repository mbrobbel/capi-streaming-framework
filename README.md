# capi-streaming-framework

AFU framework for streaming applications with CAPI connected FGPAs.

**Please note the following;**

* **It is recommended to read the [CAPI Users Guide](http://www.nallatech.com/wp-content/uploads/IBM_CAPI_Users_Guide_1-2.pdf) before using this framework.**

* **For now there is very limited instructions and documentation, but this will all be added later. An example project file for the Nallatech P385-A7 card with the Altera Stratix V GX A7 FPGA will also be added later. The current Computing Unit (CU) does not implement any functionality. A more advanced example will also be added later.**

* **This framework runs in dedicated mode and was developed to be used with `Linux`.**

## Overview

This will be added later.

## Organization

* `accelerator`
  * `lib` - VHDL global packages
    * `functions.vhd` - Helper functions
    * `psl.vhd` - PSL constants and interface records
    * `wed.vhd` - WED record and parse procedure
  * `pkg` - VHDL packages
  * `rtl` - VHDL architectures
    * `afu.vhd` - PSL to AFU wrapper
    * `control.vhd` - Framework control
    * `cu.vhd` - Computing Unit - implements the actual AFU functionality
    * `dma.vhd` - Direct Memory Access
    * `fifo.vhd` - First-In-First-Out
    * `frame.vhd` - AFU top level
    * `mmio.vhd` - Memory-Mapped-Input-Output
    * `ram.vhd` - Random-Access-Memory
* `host`
	* `app` - Host application sources
* `sim`
  * `pslse` - [PSL Simulation Engine](https://github.com/ibm-capi/pslse) sources
  * *`pslse.parms`* - PSLSE parameter file
  * *`pslse_server.dat`* - PSLSE server used by the host application to attach
  * *`shim_host.dat`* - Simulation host used by the PSLSE
  * *`vsim.tcl`* - Compilation and simulation script for `vsim`
  * *`wave.do`* - Wave script for `vsim`
* *`Makefile`* - Global makefile

## Details

This will be added later.

### AFU wrapper and Frame

### Control

### Memory-Mapped-Input-Output (MMIO)

### Direct Memory Access (DMA)

### Computing Unit (CU)

## Simulation

The following instructions target ModelSim (`vsim`).

Starting from release 15.0 of Quartus II, the included [ModelSim-Altera Starter Edition](https://www.altera.com/products/design-software/model---simulation/modelsim-altera-software.html) (free) has mixed-language support, which is required for simulation of this framework with the current `PSLSE`.

It is assumed that the 32-bit version of `vsim` is installed in `/opt/altera/15.0/modelsim_ase/` and `/opt/altera/15.0/modelsim_ase/bin` is added to your `PATH`.

Please note that all listed `make` commands should be executed from the root of this project.

### Initial setup

1. Set your `VPI_USER_H_DIR` environment variable to point to the `include` directory of your simulator e.g.:
```bash
export VPI_USER_H_DIR=/opt/altera/15.0/modelsim_ase/include
```

2. Build the [`PSLSE`](https://github.com/ibm-capi/pslse):
```bash
make pslse-build
```
This will build the `PSLSE` with the `DEBUG` flag and the `AFU` driver for a 32-bit simulator.

3. Build the host application for simulation:
```bash
make sim-build
```

### Run simulation

1. Start the simulator:
```bash
make vsim-run
```

This will start `vsim` and execute the `vsim.tcl` script, which will automatically compile the sources.

2. Start simulation

Use the following command in the `vsim` console to start the simulation:
```bash
s
```

2. Open a new terminal and start the `PSLSE`:
```bash
make pslse-run
```

3. Open a new terminal and run your host application. This will run your host application from the `sim` directory:
```bash
make sim-run ARGS="<your-arguments>"
```

4. Switch to the `PSLSE` terminal and kill (`CTRL+C`) the `PSLSE` to inspect the wave.

### Development

During development `vsim` can be kept running.

The `vsim.tcl` script also allows to quickly run the following commands again from the `vsim` console:
* `r` - Recompile the `HDL` source files
* `s` - Start the simulation
* `rs` - Recompile the `HDL` source files and restart the simulation

## FPGA build

This will be added later.
