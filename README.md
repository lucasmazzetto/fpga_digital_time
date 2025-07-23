# FPGA Digital Clock

This repository contains a VHDL-based digital clock system designed specifically for the **Altera Cyclone IV Board V3.0**, featuring the **Cyclone IV FPGA EP4CE6E22C8**. The project implements time display on a 4-digit common-cathode 7-segment display, with time configuration controlled via the board's onboard push-buttons. It includes hardware debounce logic to ensure stable and glitch-free button input. 

If you use a different development board or FPGA, some modifications and adjustments may be necessary to adapt the design to your hardware.

## Tools Used

- **Quartus Prime 20.1** – for synthesis, fitting, timing analysis, and programming the FPGA.
- **ModelSim** – for VHDL simulation and waveform analysis.

## Board Overview

The [Altera Cyclone IV Board V3.0](https://github.com/lucasmazzetto/Altera-Cyclone-IV-board-V3.0) includes:

- Cyclone IV EP4CE6E22C8 FPGA
- Four push-buttons (active-low) connected to FPGA pins  
- Four 7-segment common-cathode displays with digit enable signals  
- Multiple LEDs for status indication  

## Features

This digital clock system displays the current time in hours and minutes on a 4-digit common-cathode 7-segment display, with the digits multiplexed via four digit enable signals. The four onboard LEDs serve as a rotating seconds indicator, visually showing the passage of each second in a cyclical pattern around the LEDs.

Time adjustment is controlled via four push-buttons on the board, each corresponding to a specific increment: +10 hours, +1 hour, +10 minutes, and +1 minute. Button inputs are debounced in hardware to ensure stable, glitch-free operation.

The system uses the onboard 50 MHz clock as its timing reference. The display refresh rate is configurable to prevent flicker and maintain stable digit presentation.

### Pin Assignments

| Signal          | Direction | Board Pin |
|-----------------|-----------|-----------|
| btn_n(3)        | Input     | PIN_91    |
| btn_n(2)        | Input     | PIN_90    |
| btn_n(1)        | Input     | PIN_89    |
| btn_n(0)        | Input     | PIN_88    |
| clk             | Input     | PIN_23    |
| dig_enable_n(3) | Output    | PIN_137   |
| dig_enable_n(2) | Output    | PIN_136   |
| dig_enable_n(1) | Output    | PIN_135   |
| dig_enable_n(0) | Output    | PIN_133   |
| led_n(3)        | Output    | PIN_84    |
| led_n(2)        | Output    | PIN_85    |
| led_n(1)        | Output    | PIN_86    |
| led_n(0)        | Output    | PIN_87    |
| seg_n(6)        | Output    | PIN_124   |
| seg_n(5)        | Output    | PIN_126   |
| seg_n(4)        | Output    | PIN_132   |
| seg_n(3)        | Output    | PIN_129   |
| seg_n(2)        | Output    | PIN_125   |
| seg_n(1)        | Output    | PIN_121   |
| seg_n(0)        | Output    | PIN_128   |

### Button Functions

| Button | Function    | Board Pin |
|--------|-------------|-----------|
| BTN0   | +10 hours   | PIN_88    |
| BTN1   | +1 hour     | PIN_89    |
| BTN2   | +10 minutes | PIN_90    |
| BTN3   | +1 minute   | PIN_91    |