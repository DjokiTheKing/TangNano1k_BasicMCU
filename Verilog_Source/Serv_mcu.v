module Serv_mcu(
    input wire xtal_clk,

    output wire f_mosi, f_sck, f_cs,
    input wire f_miso,

    inout wire[19:0] gpio
);
    // Main PLL clock init
    wire main_clk;

    Gowin_rPLL fast_pll(
        .clkout(main_clk),
        .clkin(xtal_clk)
    );
    
    // CPU Timer irq
    wire serv_timer_irq;
    
    // CPU Instruction bus
    wire [31:0] ibus_adr;
    wire        ibus_cyc;
    wire [31:0] ibus_rdt;
    wire 	    ibus_ack;
    
    // CPU Data bus
    wire [31:0] dbus_adr;
    wire [31:0] dbus_dat;
    wire [3:0]  dbus_sel;
    wire 	    dbus_we;
    wire        dbus_cyc;
    wire [31:0] dbus_rdt;
    wire 	    dbus_ack;
    
    // CPU Unused
    wire [31:0] ext_rs1, ext_rs2;
    wire [2:0] ext_funct3;
    wire mdu_valid;
	
    // CPU Reset
    reg serv_rst = 1'b1;

    always @(posedge main_clk) begin
        if(serv_rst) serv_rst <= 1'b0;
    end

    // CPU Init
    serv_rf_top #(
        .RESET_PC(32'h01000000)
    )serv_cpu(
        .clk(main_clk),
        .i_rst(serv_rst),
        .i_timer_irq(serv_timer_irq),

        .o_ibus_adr(ibus_adr),
        .o_ibus_cyc(ibus_cyc),
        .i_ibus_rdt(ibus_rdt),
        .i_ibus_ack(ibus_ack),

        .o_dbus_adr(dbus_adr),
        .o_dbus_dat(dbus_dat),
        .o_dbus_sel(dbus_sel),
        .o_dbus_we(dbus_we),
        .o_dbus_cyc(dbus_cyc),
        .i_dbus_rdt(dbus_rdt),
        .i_dbus_ack(dbus_ack),

        .o_ext_rs1(ext_rs1),
        .o_ext_rs2(ext_rs2),
        .o_ext_funct3(ext_funct3),
        .i_ext_rd(32'b0),
        .i_ext_ready(1'b0),

        .o_mdu_valid(mdu_valid)
    );

    // BUS MUX
    wire mux_busy;
    wire mux_ack;
    reg  mux_done = 1'b0;

	assign mux_ack = mux_done & (ibus_cyc | dbus_cyc);

    wire [31:0] mux_adr;
    reg [31:0]  mux_rdt;
    wire mux_we;
	 
	assign mux_busy = ibus_cyc | dbus_cyc;
	assign mux_adr =  ibus_cyc ? ibus_adr : dbus_adr;
	assign mux_we =   ibus_cyc ? 1'b0 : dbus_we;
	
	assign dbus_rdt = mux_rdt;
	assign ibus_rdt = mux_rdt;
	
	assign dbus_ack = mux_ack & !ibus_cyc;
	assign ibus_ack = mux_ack &  ibus_cyc;

    // RAM
    wire [31:0]ram_out;
    wire       ram_rdy;
    reg ram_cs = 1'b0;

    my_sram ram_data(
        .clk(main_clk),
        .dout(ram_out),
        .rdy(ram_rdy), 
        .cs(ram_cs),
        .we(mux_we),
        .adr(mux_adr[12:0]),
        .din(dbus_dat),
        .dsel(dbus_sel)   
    );

    // UART TX ONLY
    reg uart_on = 1'b0;
    reg [7:0]uart_clk_div = 8'b0;

    reg uart_cs = 1'b0;
    reg uart_done = 1'b0;

    reg uart_tx = 1'b1;
    reg [7:0]uart_tx_data = 8'b0;
    reg [3:0]uart_tx_counter = 4'b0;

    always @(posedge main_clk) begin
        if(uart_on) begin
            if(uart_cs & !uart_done) begin
                if(uart_clk_div == 167) begin
                    uart_clk_div <= 8'b0;
                    case(uart_tx_counter)
                        4'b0000: begin
                            uart_tx <= 1'b0;
                            uart_tx_data <= dbus_dat[7:0];
                        end
                        4'b1001: begin
                            uart_tx <= 1'b1;
                        end
                        4'b1010: begin
                            uart_done <= 1'b1;
                        end
                        default: begin
                            uart_tx <= uart_tx_data[0];
                            uart_tx_data <= {1'b0, uart_tx_data[7:1]};
                        end
                    endcase
                    uart_tx_counter <= uart_tx_counter + 1;
                end else begin
                    uart_clk_div <= uart_clk_div+1;
                end
            end else begin
                uart_tx_counter <= 4'b0;
                uart_done <= 1'b0;
                uart_clk_div <= 8'b0;
            end
        end else begin
            if(uart_cs) begin
                uart_done <= 1'b1;
            end else begin
                uart_done <= 1'b0;
                uart_tx_counter <= 4'b0;
            end
        end
    end

    // GPIO
    reg [19:0]gpio_dir = 20'b0;
    reg [19:0]gpio_out = 20'b0;

    assign gpio[0] = uart_on ? uart_tx : (gpio_dir[0] ? gpio_out[0] : 1'bz);

    genvar i;
    generate
        for (i = 1; i < 20; i = i + 1) begin : gpio_block
            assign gpio[i] = gpio_dir[i] ? gpio_out[i] : 1'bz;
        end
    endgenerate

    // TIMER
    reg [31:0]timer_counter = 32'b0;
    reg [31:0]timer_comparator = 32'b0;
    reg timer_irq = 1'b0, timer_irq_en = 1'b0;
    
    assign serv_timer_irq = timer_irq;
        
    reg [15:0] timer_div_counter = 16'b0;
    
    always @(posedge main_clk) begin
        if(timer_div_counter == 41999) begin
            timer_counter <= timer_counter+1;
            timer_div_counter <= 16'b0;
        end else begin
            timer_div_counter <= timer_div_counter+1;
		end

        if(timer_irq_en) begin
            if(timer_counter == timer_comparator) begin
                timer_irq <= 1'b1;
            end else begin 
                timer_irq <= 1'b0;
            end
        end else begin
            timer_irq <= 1'b0;
		end
    end

    // SPI Flash
    wire [31:0]flash_out;
    wire flash_rdy;
    
    reg flash_cs = 1'b0;

    my_spi_flash ro_data(
        .clk(main_clk),
        .dout(flash_out),
        .rdy(flash_rdy),
        .cs(flash_cs),
        .adr(mux_adr[23:0]),
        
        .f_miso(f_miso),
        .f_mosi(f_mosi),
        .f_sck(f_sck),
        .f_cs(f_cs)
    );

    // MAIN BUS CONTROLLER
    always @(posedge main_clk) begin
        if(mux_done) begin
            if(!mux_busy) begin
                mux_done <= 1'b0;
            end
        end else if(mux_busy) begin
            if(mux_adr == 32'h04000000) begin          					// addr 0x04000000 - GPIO OUT
                if(mux_we) begin
                    gpio_out <= dbus_dat[19:0];
                end else begin
                    mux_rdt <= {12'b0, gpio_out};
			    end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000004) begin 					// addr 0x04000004 - GPIO IN
                if(!mux_we) begin
					mux_rdt <= {12'b0, gpio};
				end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000008) begin 					// addr 0x04000004 - GPIO DIRECTION
                if(mux_we) begin
                    gpio_dir <= dbus_dat[19:0];
				end else begin
					mux_rdt <= {12'b0, gpio_dir};
				end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000010) begin 					// addr 0x04000010 - TIMER COUNTER READ ONLY
                if(!mux_we) begin 
					mux_rdt <= timer_counter;
				end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000014) begin 					// addr 0x04000014 - TIMER COMPARATOR
                if(mux_we) begin
					timer_comparator <= dbus_dat;
				end else begin
					mux_rdt <= timer_comparator;
				end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000018) begin 					// addr 0x04000018 - TIMER INTERRUPT
                if(mux_we) begin
                    timer_irq_en <= dbus_dat[0];
                end else begin 
                    mux_rdt <= {31'b0, timer_irq_en};
                end
                mux_done <= 1'b1;
            end else if(mux_adr == 32'h04000020) begin 					// addr 0x04000020 - UART TX
                if(mux_we) begin
                    if(uart_on) begin
                        if(uart_cs) begin
                            if(uart_done) begin
                                uart_cs <= 1'b0;
                                mux_done <= 1'b1;
                            end
                        end else begin
                            uart_cs <= 1'b1;
                        end
                    end else begin
                        mux_done <= 1'b1;
                    end
                end else begin
                    mux_done <= 1'b1;
                end
            end else if(mux_adr == 32'h04000024) begin 					// addr 0x04000024 - UART CONTROL
                if(mux_we) begin
                    uart_on <= dbus_dat[0];
                end
                mux_done <= 1'b1;
            end else if(mux_adr[31:24] == 8'h02) begin 					// addr 0x0200**** - SRAM
                if(ram_cs) begin
                    if(ram_rdy) begin
                        mux_rdt <= ram_out;
                        ram_cs <= 1'b0;
                        mux_done <= 1'b1;
                    end
                end else begin
					ram_cs <= 1'b1;
				end
            end else if((mux_adr[31:24] == 8'h01) && (!mux_we)) begin 	    // addr 0x01****** - FLASH READ ONLY
                if(flash_cs) begin
                    if(flash_rdy) begin
                        mux_rdt <= flash_out;
                        flash_cs <= 1'b0;
                        mux_done <= 1'b1;
                    end
                end else begin
					flash_cs <= 1'b1;
				end
            end else begin // addr other
                mux_rdt <= 32'h00000000;
                mux_done <= 1'b1;
            end
        end
    end
endmodule
