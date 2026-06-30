package uart_pkg;
    typedef enum logic [1:0] {IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11} state_type;
    typedef enum logic [1:0] {RESET = 2'b00, COUNT = 2'b01, TICK = 2'b10} baud_state;
endpackage
