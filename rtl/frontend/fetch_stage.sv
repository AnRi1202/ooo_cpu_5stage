module fetch_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall_i,
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_rdata_i,
    output logic [31:0] if_id_pc_o,
    output logic [31:0] if_id_instr_o,
    output logic        if_id_valid_o
);
    logic [31:0] pc_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_q          <= 32'h0;
            if_id_pc_o    <= 32'h0;
            if_id_instr_o <= 32'h0;
            if_id_valid_o <= 1'b0;
        end else if (!stall_i) begin
            pc_q          <= pc_q + 32'd4;
            if_id_pc_o    <= pc_q;
            if_id_instr_o <= imem_rdata_i;
            if_id_valid_o <= 1'b1;
        end
    end

    assign imem_addr_o = pc_q;
endmodule
