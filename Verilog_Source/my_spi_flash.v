module my_spi_flash(
    input wire clk,
    
    output reg f_mosi = 1'b0, 
    output wire f_sck, 
    output wire f_cs,
    input wire f_miso,

    input wire cs,
    input wire [23:0] adr,
    output reg [31:0] dout = 32'b0,
    output reg rdy = 1'b0
);

localparam 
    INIT_STAGE  = 2'b00,
    WRITE_STAGE = 2'b01,
    READ_STAGE  = 2'b10,
    FINISH_STAGE = 2'b11;

reg [1:0]current_stage = 2'b00;

reg pwr_up_done = 1'b0;
reg [13:0]pwr_up_counter = 14'b0;

reg [31:0] rdata = 32'hFFFFFFFF, wdata = 32'b0;

reg [4:0] data_counter = 5'b0;

localparam read_command = 8'h03;

reg f_cs_local = 1'b1;

assign f_sck = f_cs_local ? 1'b0 : clk;

assign f_cs = ~(cs & ~rdy);

always @(posedge clk) begin
    if(pwr_up_done) begin
    if(cs) begin
        if(current_stage == INIT_STAGE) begin
            wdata <= {read_command, adr};
            data_counter <= 5'b0;
            f_cs_local <= 1'b0;
            current_stage <= WRITE_STAGE;
        end else if(current_stage == WRITE_STAGE) begin
            if(data_counter == 5'b11110) begin 
                current_stage <= READ_STAGE;
            end
        end else if(current_stage == READ_STAGE) begin
            if(data_counter == 5'b11110) begin
                current_stage <= FINISH_STAGE;
                f_cs_local <= 1'b1;
            end
        end else begin 
            dout <= {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
            rdy <= 1'b1;
        end
    end else begin
        current_stage <= INIT_STAGE;
        rdy <= 1'b0;
    end

    if(!f_cs_local) begin
        if(current_stage == WRITE_STAGE) begin
            wdata <= {wdata[30:0], 1'b0};
        end else if(current_stage == READ_STAGE) begin
            rdata <= {rdata[30:0], f_miso};
        end
        data_counter <= data_counter+1;
    end

    end else begin
        if(&pwr_up_counter) begin
            pwr_up_done <= 1'b1;
        end else begin
            pwr_up_counter <= pwr_up_counter + 1;
        end
    end
end

always @(negedge clk) begin
    if(!f_cs) begin
        f_mosi <= wdata[30];
    end
end

endmodule