module my_sram(
    input wire clk,
    input wire[12:0] adr,
    input wire[31:0] din,
    input wire[3:0] dsel,
    input wire we,
    input wire cs,

    output reg[31:0] dout = 32'b0,
    output reg rdy = 1'b0
);
    wire [7:0]dout_lane[0:4];
    wire sp_we;
    assign sp_we = we & cs;

    reg read_del = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : sram_block
            Gowin_SP byte_ram (
                .clk(clk),
                .ce(cs),
                .wre(sp_we & dsel[i]),
                .ad(adr[12:2]), 
                .din(din[8*i +: 8]),
                .dout(dout_lane[i]),
                .oce(1'b0), .reset(1'b0)
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (cs && !we) begin
            dout <= {dout_lane[3], dout_lane[2], dout_lane[1], dout_lane[0]};
        end

        if(we) begin 
            rdy <= cs;
        end else if(read_del) begin 
            rdy <= cs;
        end else begin
            read_del <= 1'b1;
        end

        if(!cs) begin
            read_del <= 1'b0;
        end
    end

endmodule