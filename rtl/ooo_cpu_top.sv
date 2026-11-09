module ooo_cpu_top
    import ooo_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we
);
    logic [31:0]         if_id_pc, if_id_instr;
    logic                if_id_valid;
    logic                stall_front, rs_full, rob_full;
    logic [4:0]          arf_rs1, arf_rs2;
    logic [31:0]         arf_val1, arf_val2;
    logic [ROB_BITS-1:0] rob_qtag1, rob_qtag2, rob_tail;
    logic                rob_qready1, rob_qready2;
    logic [31:0]         rob_qval1, rob_qval2;
    logic                dispatch_en;
    logic [2:0]          disp_op;
    logic [4:0]          disp_rd;
    logic [31:0]         disp_vj, disp_vk;
    logic                disp_qj_v, disp_qk_v;
    logic [ROB_BITS-1:0] disp_qj, disp_qk;
    logic                ex_valid;
    logic [2:0]          ex_op;
    logic [31:0]         ex_opr1, ex_opr2;
    logic [ROB_BITS-1:0] ex_rob_tag;
    logic                cdb_valid;
    logic [ROB_BITS-1:0] cdb_tag;
    logic [31:0]         cdb_val;
    logic                commit_valid;
    logic [4:0]          commit_rd;
    logic [ROB_BITS-1:0] commit_tag;

    assign stall_front = rs_full || rob_full;

    fetch_stage u_fetch (
        .clk(clk), .rst_n(rst_n), .stall_i(stall_front),
        .imem_addr_o(imem_addr), .imem_rdata_i(imem_rdata),
        .if_id_pc_o(if_id_pc), .if_id_instr_o(if_id_instr), .if_id_valid_o(if_id_valid)
    );

    decode_rename u_decode_rename (
        .clk(clk), .rst_n(rst_n), .valid_i(if_id_valid), .instr_i(if_id_instr), .stall_i(stall_front),
        .arf_rs1_o(arf_rs1), .arf_val1_i(arf_val1), .arf_rs2_o(arf_rs2), .arf_val2_i(arf_val2),
        .rob_query_tag1_o(rob_qtag1), .rob_query_ready1_i(rob_qready1), .rob_query_val1_i(rob_qval1),
        .rob_query_tag2_o(rob_qtag2), .rob_query_ready2_i(rob_qready2), .rob_query_val2_i(rob_qval2),
        .rob_tail_i(rob_tail), .cdb_valid_i(cdb_valid), .cdb_tag_i(cdb_tag), .cdb_val_i(cdb_val),
        .commit_valid_i(commit_valid), .commit_rd_i(commit_rd), .commit_tag_i(commit_tag),
        .dispatch_en_o(dispatch_en), .disp_op_o(disp_op), .disp_rd_o(disp_rd),
        .disp_vj_o(disp_vj), .disp_qj_v_o(disp_qj_v), .disp_qj_o(disp_qj),
        .disp_vk_o(disp_vk), .disp_qk_v_o(disp_qk_v), .disp_qk_o(disp_qk)
    );

    issue_rs u_issue_rs (
        .clk(clk), .rst_n(rst_n), .dispatch_en_i(dispatch_en), .disp_op_i(disp_op), .disp_dst_tag_i(rob_tail),
        .disp_vj_i(disp_vj), .disp_qj_v_i(disp_qj_v), .disp_qj_i(disp_qj),
        .disp_vk_i(disp_vk), .disp_qk_v_i(disp_qk_v), .disp_qk_i(disp_qk), .rs_full_o(rs_full),
        .cdb_valid_i(cdb_valid), .cdb_tag_i(cdb_tag), .cdb_val_i(cdb_val),
        .ex_valid_o(ex_valid), .ex_op_o(ex_op), .ex_opr1_o(ex_opr1), .ex_opr2_o(ex_opr2), .ex_rob_tag_o(ex_rob_tag)
    );

    exec_alu u_exec_alu (
        .ex_valid_i(ex_valid), .ex_op_i(ex_op), .ex_opr1_i(ex_opr1), .ex_opr2_i(ex_opr2), .ex_rob_tag_i(ex_rob_tag),
        .cdb_valid_o(cdb_valid), .cdb_tag_o(cdb_tag), .cdb_val_o(cdb_val)
    );

    rob_commit u_rob_commit (
        .clk(clk), .rst_n(rst_n), .dispatch_en_i(dispatch_en), .disp_rd_i(disp_rd),
        .rob_tail_o(rob_tail), .rob_full_o(rob_full),
        .query_tag1_i(rob_qtag1), .query_ready1_o(rob_qready1), .query_val1_o(rob_qval1),
        .query_tag2_i(rob_qtag2), .query_ready2_o(rob_qready2), .query_val2_o(rob_qval2),
        .arf_rs1_i(arf_rs1), .arf_val1_o(arf_val1), .arf_rs2_i(arf_rs2), .arf_val2_o(arf_val2),
        .cdb_valid_i(cdb_valid), .cdb_tag_i(cdb_tag), .cdb_val_i(cdb_val),
        .commit_valid_o(commit_valid), .commit_rd_o(commit_rd), .commit_tag_o(commit_tag)
    );

    assign dmem_addr  = cdb_val;
    assign dmem_wdata = ex_opr2;
    assign dmem_we    = 1'b0;
endmodule
