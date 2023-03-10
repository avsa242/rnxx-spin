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

P2/SPIN2:
* ~~p2-spin-standard-library~~ _(not implemented yet)_

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.25-beta) | Bytecode    | OK                    |
| P1	    | SPIN1    | FlexSpin (5.9.25-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.25-beta) | NuCode      | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (5.9.25-beta) | Native code | Not yet implemented   |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Hardware compatibility

* Tested with RN42 (firmware v4.77)

## Limitations

* Very early in development - may malfunction, or outright fail to build

