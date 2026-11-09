module exec_alu
    import ooo_pkg::*;
(
    input  logic                ex_valid_i,
    input  logic [2:0]          ex_op_i,
    input  logic [31:0]         ex_opr1_i,
    input  logic [31:0]         ex_opr2_i,
    input  logic [ROB_BITS-1:0] ex_rob_tag_i,
    output logic                cdb_valid_o,
    output logic [ROB_BITS-1:0] cdb_tag_o,
    output logic [31:0]         cdb_val_o
);
    always_comb begin
        cdb_valid_o = ex_valid_i;
        cdb_tag_o   = ex_rob_tag_i;
        case (ex_op_i)
            ALU_ADD: cdb_val_o = ex_opr1_i + ex_opr2_i;
            ALU_SUB: cdb_val_o = ex_opr1_i - ex_opr2_i;
            ALU_AND: cdb_val_o = ex_opr1_i & ex_opr2_i;
            ALU_OR:  cdb_val_o = ex_opr1_i | ex_opr2_i;
            default: cdb_val_o = ex_opr1_i ^ ex_opr2_i;
        endcase
    end
endmodule
