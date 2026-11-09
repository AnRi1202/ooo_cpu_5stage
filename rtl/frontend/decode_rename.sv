module decode_rename
    import ooo_pkg::*;
(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                valid_i,
    input  logic [31:0]         instr_i,
    input  logic                stall_i,
    output logic [4:0]          arf_rs1_o,
    input  logic [31:0]         arf_val1_i,
    output logic [4:0]          arf_rs2_o,
    input  logic [31:0]         arf_val2_i,
    output logic [ROB_BITS-1:0] rob_query_tag1_o,
    input  logic                rob_query_ready1_i,
    input  logic [31:0]         rob_query_val1_i,
    output logic [ROB_BITS-1:0] rob_query_tag2_o,
    input  logic                rob_query_ready2_i,
    input  logic [31:0]         rob_query_val2_i,
    input  logic [ROB_BITS-1:0] rob_tail_i,
    input  logic                cdb_valid_i,
    input  logic [ROB_BITS-1:0] cdb_tag_i,
    input  logic [31:0]         cdb_val_i,
    input  logic                commit_valid_i,
    input  logic [4:0]          commit_rd_i,
    input  logic [ROB_BITS-1:0] commit_tag_i,
    output logic                dispatch_en_o,
    output logic [2:0]          disp_op_o,
    output logic [4:0]          disp_rd_o,
    output logic [31:0]         disp_vj_o,
    output logic                disp_qj_v_o,
    output logic [ROB_BITS-1:0] disp_qj_o,
    output logic [31:0]         disp_vk_o,
    output logic                disp_qk_v_o,
    output logic [ROB_BITS-1:0] disp_qk_o
);
    logic                rat_busy [0:ARCH_REGS-1];
    logic [ROB_BITS-1:0] rat_tag  [0:ARCH_REGS-1];

    wire [6:0]  opcode = instr_i[6:0];
    wire [4:0]  rd     = instr_i[11:7];
    wire [2:0]  funct3 = instr_i[14:12];
    wire [4:0]  rs1    = instr_i[19:15];
    wire [4:0]  rs2    = instr_i[24:20];
    wire [31:0] imm_i  = {{20{instr_i[31]}}, instr_i[31:20]};
    wire        is_imm = (opcode == 7'b0010011);

    assign dispatch_en_o    = valid_i && !stall_i;
    assign disp_op_o        = funct3;
    assign disp_rd_o        = rd;
    assign arf_rs1_o        = rs1;
    assign arf_rs2_o        = rs2;
    assign rob_query_tag1_o = rat_tag[rs1];
    assign rob_query_tag2_o = rat_tag[rs2];

    always_comb begin
        if (rs1 == 5'd0) begin
            disp_vj_o = 32'd0; disp_qj_v_o = 1'b0; disp_qj_o = '0;
        end else if (rat_busy[rs1]) begin
            if (rob_query_ready1_i) begin
                disp_vj_o = rob_query_val1_i; disp_qj_v_o = 1'b0; disp_qj_o = '0;
            end else if (cdb_valid_i && (cdb_tag_i == rat_tag[rs1])) begin
                disp_vj_o = cdb_val_i; disp_qj_v_o = 1'b0; disp_qj_o = '0;
            end else begin
                disp_vj_o = 32'd0; disp_qj_v_o = 1'b1; disp_qj_o = rat_tag[rs1];
            end
        end else begin
            disp_vj_o = arf_val1_i; disp_qj_v_o = 1'b0; disp_qj_o = '0;
        end
    end

    always_comb begin
        if (is_imm) begin
            disp_vk_o = imm_i; disp_qk_v_o = 1'b0; disp_qk_o = '0;
        end else if (rs2 == 5'd0) begin
            disp_vk_o = 32'd0; disp_qk_v_o = 1'b0; disp_qk_o = '0;
        end else if (rat_busy[rs2]) begin
            if (rob_query_ready2_i) begin
                disp_vk_o = rob_query_val2_i; disp_qk_v_o = 1'b0; disp_qk_o = '0;
            end else if (cdb_valid_i && (cdb_tag_i == rat_tag[rs2])) begin
                disp_vk_o = cdb_val_i; disp_qk_v_o = 1'b0; disp_qk_o = '0;
            end else begin
                disp_vk_o = 32'd0; disp_qk_v_o = 1'b1; disp_qk_o = rat_tag[rs2];
            end
        end else begin
            disp_vk_o = arf_val2_i; disp_qk_v_o = 1'b0; disp_qk_o = '0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ARCH_REGS; i++) begin
                rat_busy[i] <= 1'b0;
                rat_tag[i]  <= '0;
            end
        end else begin
            if (commit_valid_i && (commit_rd_i != 5'd0)) begin
                if ((rat_tag[commit_rd_i] == commit_tag_i) && !(dispatch_en_o && (rd == commit_rd_i))) begin
                    rat_busy[commit_rd_i] <= 1'b0;
                end
            end
            if (dispatch_en_o && (rd != 5'd0)) begin
                rat_busy[rd] <= 1'b1;
                rat_tag[rd]  <= rob_tail_i;
            end
        end
    end
endmodule
