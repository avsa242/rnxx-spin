{
----------------------------------------------------------------------------------------------------
    Filename:       RNXX-Demo.spin
    Description:    Demo of the RNxx Bluetooth driver
    Author:         Jesse Burt
    Started:        Jan 30, 2023
    Updated:        Sep 25, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    bt:     "wireless.bluetooth.rnxx" | RX_PIN=0, TX_PIN=1, RST=2, SER_BAUD=9600


PUB main() | in_ch, out_ch

    setup()
    bt.command_mode()                           ' start "offline" (in command mode)
    repeat
        repeat until bt.is_connected()
        ser.strln(@"CONNECT")
        bt.data_mode()                          ' go "online" (transmit/receive data)
        repeat
            in_ch := bt.getchar_noblock()
            if ( in_ch > -1 )
                ser.putchar(in_ch)
            out_ch := ser.getchar_noblock()
            if ( out_ch > -1 )
                bt.putchar(out_ch)


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()

    if ( bt.start() )
        ser.strln(@"RNXX driver started")
    else
        ser.strln(@"RNXX driver failed to start - halting")
        repeat


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

