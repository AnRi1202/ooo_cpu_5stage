module issue_rs
    import ooo_pkg::*;
(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                dispatch_en_i,
    input  logic [2:0]          disp_op_i,
    input  logic [ROB_BITS-1:0] disp_dst_tag_i,
    input  logic [31:0]         disp_vj_i,
    input  logic                disp_qj_v_i,
    input  logic [ROB_BITS-1:0] disp_qj_i,
    input  logic [31:0]         disp_vk_i,
    input  logic                disp_qk_v_i,
    input  logic [ROB_BITS-1:0] disp_qk_i,
    output logic                rs_full_o,
    input  logic                cdb_valid_i,
    input  logic [ROB_BITS-1:0] cdb_tag_i,
    input  logic [31:0]         cdb_val_i,
    output logic                ex_valid_o,
    output logic [2:0]          ex_op_o,
    output logic [31:0]         ex_opr1_o,
    output logic [31:0]         ex_opr2_o,
    output logic [ROB_BITS-1:0] ex_rob_tag_o
);
    logic                rs_busy  [0:RS_ENTRIES-1];
    logic [2:0]          rs_op    [0:RS_ENTRIES-1];
    logic [31:0]         rs_vj    [0:RS_ENTRIES-1];
    logic [31:0]         rs_vk    [0:RS_ENTRIES-1];
    logic                rs_qj_v  [0:RS_ENTRIES-1];
    logic [ROB_BITS-1:0] rs_qj    [0:RS_ENTRIES-1];
    logic                rs_qk_v  [0:RS_ENTRIES-1];
    logic [ROB_BITS-1:0] rs_qk    [0:RS_ENTRIES-1];
    logic [ROB_BITS-1:0] rs_dst   [0:RS_ENTRIES-1];
    logic                rs_ready [0:RS_ENTRIES-1];

    logic [RS_BITS-1:0] free_idx, issue_idx;
    logic               has_free, issue_valid;

    always_comb begin
        has_free    = 1'b0;
        free_idx    = '0;
        issue_valid = 1'b0;
        issue_idx   = '0;
        for (int i = 0; i < RS_ENTRIES; i++) begin
            rs_ready[i] = rs_busy[i] && !rs_qj_v[i] && !rs_qk_v[i];
            if (!rs_busy[i] && !has_free) begin
                has_free = 1'b1;
                free_idx = i[RS_BITS-1:0];
            end
            if (rs_ready[i] && !issue_valid) begin
                issue_valid = 1'b1;
                issue_idx   = i[RS_BITS-1:0];
            end
        end
    end

    assign rs_full_o = !has_free;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_valid_o   <= 1'b0;
            ex_op_o      <= 3'd0;
            ex_opr1_o    <= 32'd0;
            ex_opr2_o    <= 32'd0;
            ex_rob_tag_o <= '0;
            for (int i = 0; i < RS_ENTRIES; i++) begin
                rs_busy[i] <= 1'b0;
                rs_qj_v[i] <= 1'b0;
                rs_qk_v[i] <= 1'b0;
            end
        end else begin
            if (cdb_valid_i) begin
                for (int i = 0; i < RS_ENTRIES; i++) begin
                    if (rs_busy[i]) begin
                        if (rs_qj_v[i] && (rs_qj[i] == cdb_tag_i)) begin
                            rs_vj[i]   <= cdb_val_i;
                            rs_qj_v[i] <= 1'b0;
                        end
                        if (rs_qk_v[i] && (rs_qk[i] == cdb_tag_i)) begin
                            rs_vk[i]   <= cdb_val_i;
                            rs_qk_v[i] <= 1'b0;
                        end
                    end
                end
            end
            ex_valid_o <= issue_valid;
            if (issue_valid) begin
                rs_busy[issue_idx] <= 1'b0;
                ex_op_o            <= rs_op[issue_idx];
                ex_opr1_o          <= rs_vj[issue_idx];
                ex_opr2_o          <= rs_vk[issue_idx];
                ex_rob_tag_o       <= rs_dst[issue_idx];
            end
            if (dispatch_en_i) begin
                rs_busy[free_idx] <= 1'b1;
                rs_op[free_idx]   <= disp_op_i;
                rs_dst[free_idx]  <= disp_dst_tag_i;
                rs_vj[free_idx]   <= disp_vj_i;
                rs_qj_v[free_idx] <= disp_qj_v_i;
                rs_qj[free_idx]   <= disp_qj_i;
                rs_vk[free_idx]   <= disp_vk_i;
                rs_qk_v[free_idx] <= disp_qk_v_i;
                rs_qk[free_idx]   <= disp_qk_i;
            end
        end
    end
endmodule
