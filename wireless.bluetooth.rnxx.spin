{
    --------------------------------------------
    Filename: wireless.bluetooth.rnxx.spin
    Description: Driver for RNxx Bluetooth modules
    Author: Jesse Burt
    Copyright (c) 2023
    Started Jan 30, 2023
    Updated Jan 30, 2023
    See end of file for terms of use.
    --------------------------------------------
}

OBJ

    uart:   "com.serial.terminal"
    time:   "time"
    str:    "string"

VAR

    byte _rx_buff[32]

PUB startx(RN42_RX, RN42_TX, RN42_BPS, RESET_PIN): status
' Start the driver using custom I/O settings
'   RN42_RX: RX pin (from RN42 module's perspective)
'   RN42_TX: TX pin (from RN42 module's perspective)
'   RN42_BPS: connection speed to module in bits per second/baud
'   Returns: (cog ID of UART engine + 1) on success, or 0 on failure
    status := uart.init(RN42_TX, RN42_RX, 0, RN42_BPS)

    outa[RESET_PIN] := 0
    dira[RESET_PIN] := 1
    time.msleep(3)
    outa[RESET_PIN] := 1

    time.msleep(600)                            ' need to wait after resetting

PUB defaults()
' Factory default settings
'   NOTE: This affects _all_ settings in the module's flash memory, including settings such as
'       the PIN code, node name, etc
    cmd_set_int("F", 1)

PUB accept_only_bonded_conn(state): s
' Accept connections only from the device stored with store_remote_addr()
'   Valid values: TRUE (non-zero), FALSE (0)
    state := "0" + ((state <> 0) & 1)           ' promote any non-zero value to true, throw out all
                                                '  bits except the LSB, and add to ASCII "0"

    return cmd_set_int("X", "0" + state)

PUB command_mode()
' Enter command mode
    uart.puts(string("$$$"))
    time.msleep(100)

PUB connect_node(ptr_addr): s
' Connect to remote node
'   ptr_addr: pointer to 12-digit Bluetooth MAC address
'   NOTE: Address pointed to _must_ be exactly 12 hexadecimal digits (OUI in memory first)
'   NOTE: There must be no characters between digits
'       e.g., the address 00:11:22:33:44:55 should be stored at ptr_addr as:
'           remote_mac := string("001122334455")
'           bt.connect_node(remote_mac)
'       or e.g.,
'           DAT remote_mac    byte "001122334455", 0
'           PUB main()
'               bt.connect_node(@remote_mac)
    uart.putchar("C")                           ' connect to remote address
    uart.putchar(",")
    uart.puts(ptr_str)                          ' setting value
    uart.putchar(uart.CR)

    { get response }
    uart.getchar()                              ' swallow CR

    bytefill(@_rx_buff, 0, 32)
    uart.gets(@_rx_buff)

    if ( strcomp(@_rx_buff, @_ok) )             ' setting ok
        return 0
    else                                        ' setting error
        return -2

PUB data_enable_7bit(state): s
' Enable 7-bit data mode
'   Valid values: TRUE (non-zero), FALSE (0)
    state := "0" + ((state <> 0) & 1)           ' promote any non-zero value to true, throw out all
                                                '  bits except the LSB, and add to ASCII "0"

    return cmd_set_int("7", "0" + state)

PUB data_mode()
' Enter data mode
    uart.puts(string("---"))
    time.msleep(100)

PUB is_connected(): c
' Flag indicating module is connected
    uart.strln(@"GK")
    return uart.get_dec()

PUB read_settings()
' Read all of the settings
'   NOTE: The module must be in command mode first
    get_setting_str(@_node_addr)
    get_setting_str(@_node_nm)
    _bps := get_setting_dec()
    get_setting_str(@_parity)
    get_setting_str(@_role)
    _auth_en := get_setting_dec()
    _crypt_en := get_setting_dec()
    get_setting_str(@_pin)
    _bonded := get_setting_dec()
    get_setting_str(@_remote_addr)

PUB reset()
' Reset/reboot the device
    cmd("R", 1)
    
PUB role_switch_ena(state): s
' Enable role switch
'   Valid values: TRUE (non-zero), FALSE (0)
    state := "0" + ((state <> 0) & 1)           ' promote any non-zero value to true, throw out all
                                                '  bits except the LSB, and add to ASCII "0"

    return cmd_set_int("?", "0" + state)

PUB send_break(len): s
' Send break signal
'   len: length of break signal, in milliseconds
'   Valid values: 37, 19 (18.5), 12, 9, 7, 6
    len := lookdown(len: 37, 19, 12, 9, 7, 6)   ' map input len to 1..6, or 0 for bad values
    if ( len )
        return cmd_set_int("A", "0" + len)
    else
        return -2

CON

    { authentication modes }
    AUTH_MODE_OPEN          = 0
    AUTH_MODE_SSP_KEYIO     = 1
    AUTH_MODE_SSP_JUSTWORKS = 2
    AUTH_MODE_PIN           = 4

PUB set_auth_mode(mode): s
' Set authentication mode
'   Valid values:
'       AUTH_MODE_OPEN (0): open mode
'       AUTH_MODE_SSP_KEYIO (1): SSP keyboard I/O mode (default)
'       AUTH_MODE_SSP_JUSTWORKS (2): SSP "just works" mode
'       AUTH_MODE_PIN (4): pin code
    if ( lookdown(mode: 0, 1, 2, 4) )
        return cmd_set_int("A", "0" + mode)
    else
        return -2

PUB set_class_of_device(cod): s
' Set class of device
    cod &= $ffff
    return cmd_set_str("C", str.hexs(cod, 4))

PUB set_dev_unconnectable(): s
' Set device unconnectable
    return cmd_set_int("J", str.hexs(0, 4))

PUB set_dev_undiscoverable(): s
' Set device undiscoverable
    return cmd_set_int("I", str.hexs(0, 4))

PUB set_inq_scan_win(win): s
' Set inquiry scan window (discoverability time)
'   Valid values: 18..2048 (default $0100; clamped to range)
    return cmd_set_int("I", str.hexs( (18 #> win <# 2048), 4))

PUB set_lowpower_conn_period(off_per, on_per): s
' Set low-power connect mode on and off periods, in seconds
'   Valid values: 0..32 (default: 0, always active)
    off_per := (0 #> off_per <# 32) << 8
    on_per := (0 #> on_per <# 32)
    return cmd_set_str("|", str.hexs(off_per | on_per, 4))

PUB set_lowpower_interval(t): s
' Set low-power mode wakeup interval, in microseconds
'   The radio will wake at this interval and sleep in very low power mode the rest of the time
'   Valid values: 0 (disable/active mode, 625..20_479_375)
'   NOTE: This setting only applies to active connections.
'   NOTE: When a connection is made, both nodes must support sniff mode and agree to the
'       set wakeup interval; otherwise, the radio remains in full active mode.
    return cmd_set_str("W", str.hexs( (0 #> (t / 625) <# 32767), 4) )

PUB set_node_name(ptr_str): s
' Set this module's name
'   ptr_str: pointer to (up to) 20-alphanumeric character string
    return cmd_set_str("N", str.left(ptr_str, strsize(ptr_str) <# 20))

PUB set_node_name_mac(ptr_str): s
' Set this module's name, with a suffix of the last 2 MAC address bytes automatically appended
'   ptr_str: pointer to (up to) 15-alphanumeric character string
'   e.g., if the module's MAC address is 00:11:22:33:44:55,
'       PUB main()
'           bt.set_node_name_mac(@"MyDevice")
'   would set the node name to 'MyDevice-4455'
    return cmd_set_str("-", str.left(ptr_str, strsize(ptr_str) <# 15))

CON

    { module operating modes }
    OPMODE_SLAVE    = 0
    OPMODE_MASTER   = 1
    OPMODE_TRIG     = 2
    OPMODE_AUTO_MAST= 3
    OPMODE_AUTO_DTR = 4
    OPMODE_AUTO_ANY = 5
    OPMODE_PAIR     = 6

PUB set_opmode(mode): s
' Set operating mode
'   Valid values:
'       OPMODE_SLAVE (0): slave mode
'       OPMODE_MASTER (1): master mode
'       OPMODE_TRIG (2): trigger mode
'       OPMODE_AUTO_MAST (3): auto-connect master mode
'       OPMODE_AUTO_DTR (4): auto-connect DTR mode (default)
'       OPMODE_AUTO_ANY (5): auto-connect any mode
'       OPMODE_PAIR (6): pairing mode
    mode := lookdown(mode: 0..6)    'XXX no- fix
    if ( mode )
        return cmd_set_int("M", str.dec(mode))
    else
        return -2

PUB set_page_scan_win(win): s
' Set page scan window (connectability time)
'   Valid values: 18..2048 (default $0100; clamped to range)
    return cmd_set_int("J", str.hexs( (18 #> win <# 2048), 4))

PUB set_pin_code(ptr_str): s
' Set security PIN code
'   ptr_str: pointer to (up to) 20-alphanumeric character string
    return cmd_set_str("P", str.left(ptr_str, strsize(ptr_str) <# 20))

PUB set_profile(p): s
' Set Bluetooth profile
'   Valid values:
'       PROF_SPP (0): no modem control (default)
'       PROF_DUN_DCE (1): slave/gateway
'       PROF_DUN_DTE (2): master/client
'       PROF_MDM_SPP (3): with modem control signals
'       PROF_SPP_DUN_DCE (4): multi-profile
'       PROF_APL (5): Apple (iAP) profile
'       PROF_HID (6): HID profile
    return cmd_set_int("~", str.dec(0 #> p <# 6))

PUB set_remote_cfg_timer(t): s
' Set time window from powerup to allow remote configuration (slave mode only)
'   Valid values:
'       0: no remote configuration and no local configuration when connected
'       1..252: time window in seconds (default: 60)
'       253: continuous configuration, local only
'       254: continuous configuration, remote only
'       255: continuous configuration, local and remote
    return cmd_set_str("T", str.dec(0 #> t <# 255))

PUB set_service_class(sc): s   'XXX verify this
' Set service class field in the class of device (COD)
    sc &= $7ff                                  ' field is 11 bits long
    return cmd_set_str("C", str.hexs(sc, 4))

PUB set_service_name(ptr_str): s
' Set service name
'   ptr_str: pointer to string (1..20 alphanumeric characters)
    return cmd_set_str("S", str.left(ptr_str, strsize(ptr_str) <# 20))

CON

    { special configuration settings }
    SCFG_DEF                = 0
    SCFG_NO_GPIO36_PWRUP    = 4
    SCFG_DISC_DIS           = 8
    SCFG_LOW_LATENCY        = 16
    SCFG_REBT_AFTER_DISC    = 128
    SCFG_SER_2BIT_STOP      = 256

PUB set_special_cfg(mask): s
' Set special configuration setting(s)
'   Valid values:
'       SCFG_DEF (0): default; no special configuration
'       SCFG_NO_GPIO36_PWRUP (4): don't read GPIO3 or 6 on powerup
'       SCFG_DISC_DIS (8): disable discoverability on startup
'       SCFG_LOW_LATENCY (16): config module to optimize for low latency at the cost of
'           lower throughput
'       SCFG_REBT_AFTER_DISC (128): reboot after disconnect
'       SCFG_SER_2BIT_STOP (256): set 2-stop bit mode over UART connection
    if ( lookdown(mask: 0, 4, 8, 16, 128, 256) )
        return cmd_set_str("Q", str.dec(mask))
    else
        return -2

PUB set_uart_baud(bps): s
' Set UART baud/bitrate
'   Valid values: 1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600, 115200, 230400, 460800,
'                   921600
    if ( lookdown(bps: 1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600, 115200, 230400, {
}                     460800, 921600) )
        { the module only needs the first two digits of the bitrate, so extract them }
        return cmd_set_str("U", str.left(str.dec(bps), 2))

PUB set_uart_parity(p): s
' Set parity over UART connection
'   Valid values:
'       "E" ($45): Even parity
'       "N" ($4e): No partiy (default)
'       "O" ($4f): Odd parity
'   Example: set_uart_parity("E") - set UART even parity
    if ( lookdown(p: "E", "N", "O") )
        return cmd_set_int("L", p)
    else
        return -2

PUB set_uuid(ptr_uuid): s
' Set the module's UUID
'   ptr_uuid: pointer to a (up to) 16 character (128-bit) UUID string
'   NOTE: Changes effect the UUID starting at the left-most byte
'       e.g., if the existing UUID is 35111C0000110100001000800000805F9B34FB,
'       a partial change of set_uuid(@"ABCD") would change the UUID to
'       ABCD1C0000110100001000800000805F9B34FB
    return cmd_set_str("E", ptr_uuid)

PUB store_remote_addr(ptr_addr): s
' Store a remote address
'   ptr_addr: pointer to 12-digit Bluetooth MAC address
'   NOTE: Address pointed to _must_ be exactly 12 hexadecimal digits (OUI in memory first)
'   NOTE: There must be no characters between digits
'       e.g., the address 00:11:22:33:44:55 should be stored at ptr_addr as:
'           mac_addr := string("001122334455")
'           bt.store_remote_addr(mac_addr)
'       or e.g.,
'           DAT mac_addr    byte "001122334455", 0
'           PUB main()
'               bt.store_remote_addr(@mac_addr)
    cmd_set_str("R", ptr_addr)

PUB rx_check(): ch

    return uart.rx_check()

PUB rx = getchar
PUB charin = getchar
PUB getchar(): ch

    return uart.getchar()

PUB tx = putchar    'XXX remove these and #include the serial object inline instead
PUB char = putchar
PUB putchar(ch)

    uart.putchar(ch)

PUB puts(ptr_str)

    uart.puts(ptr_str)

PUB tx_pwr(pwr): s
' Set transmit power, in dBm
'   Valid values: -12, -8, -4, 0, 4, 8, 12, 16 (August 2012 and later modules)
'   Valid values: -20, -10, -5, 0, 2, 6, 12 (Pre-August 2012 modules)
#ifdef RN42_PRE_AUG2012
    if ( lookdown(pwr: -20, -10, -5, 0, 2, 6, 12) )
        case pwr
            -20: pwr := $ffe8
            -10: pwr := $fff0
            -5: pwr := $fff4
            0: pwr := $fff8
            2: pwr := $fffc
            6: pwr := $0000
            12: pwr := $0004
#else
    if ( lookdown(pwr: -12, -8, -4, 0, 4, 8, 12, 16) )
#endif
        cmd_set_str("Y", str.hexs(pwr, 4))
    else
        return -2

PRI cmd(type, val): status
' Issue a command
    uart.putchar(type)                          ' command/action
    uart.putchar(",")
    uart.putchar(value)                         ' setting value
    uart.putchar(uart.CR)

    return get_resp()

PRI cmd_set_int(setting, value): status
' Issue set command (single-digit integer input)
'   setting: setting to change
'   value: value to update setting to (single-digit integer)
    { send set command }
    uart.putchar(SET_CMD)                       ' "S"
    uart.putchar(setting)                       ' setting command
    uart.putchar(",")
    uart.putchar(value)                         ' setting value
    uart.putchar(uart.CR)

    return get_resp()

PRI cmd_set_str(setting, ptr_str): status
' Issue set command (string input)
'   setting: setting to change
'   ptr_str: string to use as setting value
    { send set command }
    uart.putchar(SET_CMD)                       ' "S"
    uart.putchar(setting)                       ' setting command
    uart.putchar(",")
    uart.puts(ptr_str)                          ' setting value
    uart.putchar(uart.CR)

    { get response }
    uart.getchar()                              ' swallow CR

    bytefill(@_rx_buff, 0, 32)
    uart.gets(@_rx_buff)

    if ( strcomp(@_rx_buff, @_ok) )             ' setting ok
        return 0
    else                                        ' setting error
        return -2

PRI get_resp()

    { get response }
    uart.getchar()                              ' swallow CR

    bytefill(@_rx_buff, 0, 32)
    uart.gets(@_rx_buff)

    if ( strcomp(@_rx_buff, @_ok) )             ' setting ok
        return 0
    else                                        ' setting error
        return -2


PRI get_setting_str(ptr_str): rxcnt
' Extract setting value from configuration, as a string
    skip_config_name()
    rxcnt := uart.gets(ptr_str)
    uart.getchar()

PRI get_setting_dec(): d | rxcnt
' Extract setting value from configuration, as an integer
    skip_config_name()
    d := uart.get_dec()
    uart.getchar()

PRI skip_config_name() | tmp
' Skip configuration item name in settings list
    repeat
        tmp := uart.getchar()
    until (tmp == "=")

var

    byte _node_addr[12+1]
    byte _node_nm[20+1]
    long _bps
    byte _parity[4+1]
    byte _role
    byte _auth_en
    byte _crypt_en
    byte _pin[20+1]
    byte _bonded
    byte _remote_addr[12+1]
    byte _version[5]

CON

    SET_CMD     = "S"

DAT

    _cmd_mode   byte "$$$", 0
    _data_mode  byte "---", 0

    { responses }
    _sett_hdr   byte "***Settings***", 0
    _cmd_resp   byte "CMD", 0
    _ok         byte "AOK", 0
    _err        byte "ERR", 0
    _unknown    byte "?", 0

DAT
{
Copyright 2023 Jesse Burt

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

