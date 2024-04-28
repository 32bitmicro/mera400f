parameter CPU_NUMBER = 1;
parameter AWP_PRESENT = 1'b1;


parameter INOU_USER_ILLEGAL = 1'b1;
parameter STOP_ON_NOMEM = 1'b1;
parameter LOW_MEM_WRITE_DENY = 1'b0;

parameter CLK_UART_HZ = 1_000_000;
parameter UART_BAUD = 9600;

parameter MODULE_ADDR_WIDTH  = 2;
parameter FRAME_ADDR_WIDTH = 3;

parameter CLK_EXT_HZ = 12_000_000;
parameter INOU_USER_ILLEGAL = 1'b1;

// a: 6-1 : 2 ms = 500 Hz = 24_000 cycles @ 12MHz
// a: 6-2 : 4 ms = 250 Hz = 48_000 cycles @ 12MHz
// a: 6-3 : 8 ms = 125 Hz = 96_000 cycles @ 12MHz
// a: 6-4 : 10 ms = 100 Hz = 120_000 cycles @ 12MHz
// a: 6-5 : 20 ms = 50 Hz = 240_000 cycles @ 12MHz

parameter TIMER_CYCLE_MS = 10;
parameter CLK_SYS_HZ = 100;

parameter ALARM_DLY_TICKS = 5000;
parameter ALARM_TICKS = 5000;

// UART
parameter clk_speed = 12_000_000;
parameter baud = 9600;
parameter width = 8'd8;
parameter period = 8'd104; // 104μs