package ooo_pkg;
    parameter int ROB_ENTRIES = 8;
    parameter int ROB_BITS    = 3;
    parameter int RS_ENTRIES  = 4;
    parameter int RS_BITS     = 2;
    parameter int ARCH_REGS   = 32;

    typedef enum logic [2:0] {
        ALU_ADD = 3'd0,
        ALU_SUB = 3'd1,
        ALU_AND = 3'd2,
        ALU_OR  = 3'd3,
        ALU_XOR = 3'd4
    } alu_op_e;
endpackage
