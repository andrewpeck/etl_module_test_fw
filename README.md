## Table of Contents <span class="tag" data-tag-name="TOC_4"><span class="smallcaps">TOC\_4</span></span>

## Build Instructions

To build the firmware, simply clone the repository and run:

    make init
    make impl

## Directories

    ├── README.org     -- This readme
    ├── Makefile       -- GNU Makefile
    ├── readout_board  -- Readout Board Firmware
    ├── etroc          -- ETROC Firmware
    ├── wrappers       -- Wrappers around IP/Submodules
    ├── xdc            -- XDC Constraints Files
    ├── doc            -- Documentation & Images
    ├── ip             -- Xilinx IP
    ├── lpgbt-fpga     -- Submodule: LPGBT-FPGA Core
    ├── gbt-sc         -- Submodule: CERN GBT-SC Core
    ├── ipbus-firmware -- Submodule: IPBus Firmware
    ├── Top            -- Hog Projects
    └── Hog            -- Hog Build System

## Updating Register Definitions

To update register definitions, you should change the corresponding XML
file and then run

    make reg

## Block Diagram

### DAQ

![](doc/daq.svg)

### Downlink

![](doc/fast_commands.svg)

### Firmware Infrastructure

![](doc/structure/structure.gv.svg)

## Optical Connections

| Function       | Fiber Number  |
| -------------- | ------------- |
| Downlink       | RX (Fiber 7)  |
| DAQ Uplink     | TX1 (Fiber 6) |
| Trigger Uplink | TX2 (Fiber 5) |

## Hardware Setup

Details of the hardware setup and a shopping list can be read at
[shopping](http://etl-rb.web.cern.ch/Setup/test-stand-shopping/).

### XDMA

We are using the Xilinx PCIE XDMA driver for register access to the
KCU105 board. It is configured for 8 GT/s, 1 lane PCIE (we can expand
the number of lanes in the future if needed).

Details of the XDMA setup and installationcan be read at
[XDMA](doc/XDMA.org).

### Ethernet

A gigabit ethernet port may also be used for control.

The ethernet interface on your computer can be configured, e.g. with the
command:

``` bash
sudo /sbin/ifconfig eth0 192.168.0.130 netmask 255.255.255.0 broadcast 192.168.0.255
```

![](doc/kcu105.jpg)

## Changelog

This changelog describes changes made in recommended versions of the
firmware. Versions not described here are intermediate versions which
are either not tested or known to be problematic. Change log is
inclusive of all changes from the previous recommended version; please
only use the versions listed here unless instructed otherwise.

### v3.0.6

  - Features:
      - Switchable FEC mode
      - Add 40MHz clock output on user SMA
  - Fixes:
      - Connect global QINJ generator to ETROCs
  - Cleanup + documentation of code

### v3.0.4

  - Multi-rb support
  - Add header rate counters
  - Reduce archive size
  - Improve timing closure
      - ETROC data inversion is registered
      - ETROC err monitors are registered
      - RXSLIDE goes through an XPM CDC pulse synchronizer
      - FEC flags from lpgbt core have an additional pipeline stage
      - LPGBT ready signals are registered
      - Add a global random QINJ generator

### v2.1.11

  - Add a data frame counter for each ETROC
  - Fix TX FIFO

### v2.1.10

  - Add a synchronized QINJ + L1A command

### v2.1.9

  - Add QINJ and other fast commands

### v2.1.8

  - Fix BC0 Fast Command

### v2.1.7

  - Add 640/1280 Mbps mode

### v2.1.6

  - Fix the TX FIFO

### v2.1.5

  - Fix `noflash` mode for program.tcl
  - Add a work-in-progress tx fifo

### v2.1.4

  - Fix the upper two e-links

### v2.1.3

  - Improve programming script
  - Add a timeout to the ETROC selector

### v2.1.2

  - Compress bitstream
  - Enable SCA debugging ILA
  - Upgrade Hog

### v2.1.1

  - Add a FIFO occupancy signal for more efficient DAQ readout
  - Lost word counter increased to 32 bits for throughput testing
  - Make the system IBERT an optional component and disable by default
  - Fix max data frame counting in the ETROC

### v2.1.0

  - Supercharge the LEDs
  - Major cleanup of the ipbus wrapper firmware, including a switch to
    axi stream fifos for cdc, and clean up of the clocking constraints
    for CDC
  - Move the MGT reset signals into the SYSTEM ipb endpoint; remove the
    mgt ipb endpoint
  - Add flip-flops to the {tx,rx}-ready signals from the mgt to improve
    timing slack

### v2.0.0

  - Add a working dumb daq
  - Add a system slave for global signals
      - L1A generators moved from RB to System block
  - Add metadata into the etroc datastream
  - Remove downlink aligner block
  - Cleanup code mess

### v1.4.1

  - Deprecate software fast commands
  - ILA additions, disable wishbone ILA by default
  - Add enable signal for external SMA trigger
  - FIFO reset will be 8 clocks long automatically, no need to double
    clock in software
  - Added a compile-time mask to disable unconnected elinks
  - Added shallow FIFOs at the output of each ETROC decoder which feed
    into the main DAQ FIFO, in preparation for an event merger

### v1.4.0

  - Fix bitslip / zero\_suppress / raw\_data\_mode bitmask connection
    (previously bit0 was connected to all 28 elinks, now it will be a
    bitmask)
  - Connect the CRC8 to an ILA
  - Increase the depth of the ETROC FIFO from 32768 (\~1 Mb) to 131072
    words (\~8.4 Mb) to decrease overflow probability
  - Remove elink daq
  - Add a RX FIFO lost word counter
  - Add an RX FIFO full flag

### v1.3.5

  - Add auto-inversion logic to the ETROC RX decoder
  - Add an (untested) CRC8 to the ETROC RX decoder

### v1.3.4

  - Fix an issue with the ETROC decoder getting stuck in the locked
    state
  - Add a "raw data mode" to the ETROC decoder which simply writes the
    raw 40 bit frames
  - Separate the bitslip/reset/zero suppress/raw data mode between
    master and slave
  - Add an external trigger output (mirror of the internal L1A signal)
  - Update Hog

### v1.3.2

  - Add a feature to disable automatic bitslipping in the ETROC decoder
    (for debug purposes)
  - Start and end of packet signals should now only be 1bx wide (instead
    of 5)

### v1.3.1

  - Improve timing closure by various tweaks which should not affect
    functionality
  - Purge Si570 clock mirror output (was used during testing)
  - Hopefully improve reliability of UDP transactions w/ more timing
    constraints
  - Update docs
  - Upgrade to vivado 2021.1

### v1.2.10

  - Support for LPGBT version 1
  - Fix lpgbt fifo reset signal which was not connected
  - Increase the number of xpm stages to improve timing
  - Add ETROC error counters
  - ILA improvements
  - Upgrade submodules

### v1.2.7

  - Add received packet counters
  - Add an ETROC rx locked signal
  - Add a packet rate counter
  - Add per-etroc packet decoders and mux their outputs, to have
    counters run in parallel
  - Add device DNA readout
  - Add SFP disable to firmware control
  - Improvements to program.sh
