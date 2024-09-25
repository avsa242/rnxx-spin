# rnxx-spin
-----------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Microchip (nee Roving Networks) RNxx Bluetooth modules

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* UART connection at up to 230.4kbps


## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM-based UART engine
* com.serial.terminal.ansi.spin, com.serial.spin (provided by the spin-standard-library)


P2/SPIN2:
* p2-spin-standard-library
* com.serial.terminal.ansi.spin2, com.serial.spin2 (provided by the p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | Untested              |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | Untested              |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware compatibility

* Tested with RN42 (firmware v4.77)

## Limitations

* Very early in development - may malfunction, or outright fail to build

