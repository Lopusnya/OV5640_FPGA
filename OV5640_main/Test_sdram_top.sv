module test_sdram_top 
#(
    parameter w_digit = 4, clk_mhz = 100
 )   
    (
        input clk,
        input rst,

        output logic [          7:0] abcdefgh,
        output logic [w_digit - 1:0] digit
        
    );
    
    localparam period = 1000000;
    localparam w_data = 16;
    localparam clk_div_2_max = clk_mhz * 1_000_000,
    localparam w_clk_div_2 = $clog2(clk_div_2_max + 1);

    logic [21:0] instr = 22'b00__0000_0000_0000__0000_0000; // BA - 2bits, RA - 12 bits, CA - 8bits

    wire instr_rdy, data_rdy, rom_vld, wr_e, instr_vld, sdram_read_vld, full, empty;

    wire [w_data - 1:0] rom_data, sdram_data_out, fifo_data_out;
    logic [7:0] rom_adr;

    always_ff @( posedge clk ) 
        if (rst)
            rom_adr <= '0;
        else if (rom_vld)
                rom_adr <= rom_adr + 1'b1;

    always_ff @(posedge clk)
        if(rst)
            wr_e <= '1;
        else if (rom_adr == 8'd255)
            wr_e <= '0;

    rom test_rom
    (
        .clk(clk),
        .rom_adr(rom_adr),
        .data_out(rom_data)
    );


    assign rom_vld = ~instr_rdy && data_rdy;

    sdram ram // #()
    (
        .clk            (           clk),
        .rst            (           rst),
        .wr_e           (          wr_e),
        .in_vld         (       rom_vld),
        .data_rdy       (      data_rdy),
        .data_in        (      rom_data),                 
        .instr_vld      (     instr_vld),
        .instr_rdy      (     instr_rdy), 
        .instr          (         instr),
        .data_read_vld  (sdram_read_vld),
        .data_out       (sdram_data_out)                  
    );

    wire push = sdram_read_vld && ~full;
    wire pop  = pop_enable && ~empty;

    flip_flop_fifo_with_counter fifo 
    #(
        .width(16),
        .depth(256)
    )
    (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .write_data(sdram_data_out),
        .read_data(fifo_data_out),
        .empty(emty),
        .full(full)
    );

    logic [31:0] cnt_seg;

    always_ff @ (posedge clk ) begin : Sinchronizatore
        if (rst)
            cnt_seg <= '0;
        else if (cnt_seg == '0)
            cnt_seg <= period - 1'b1;
        else
            cnt_seg <= cnt_seg - 1'd1;
    end

    logic pop_enable;
    always_ff @( posedge clk ) begin : Pop_signal_source
        if (rst)
            pop_enable <= '0;
        else if (cnt_seg == '0)
            pop_enable <= '1;
        else
            pop_enable <= '0;
    end

    logic [w_data - 1:0] data_seg;
    always_ff @( posedge clk ) begin : reg_data_for_seg
        if (rst)
            data_seg <= '0;
        else if (pop)
            data_seg <= fifo_data_out;
    end

    logic [w_clk_div_2 - 1 : 0] clk_div_2;

    always_ff @( posedge clk or posedge rst) begin : divider_clock_for_seg
        if (rst)
            clk_div_2 <= '0;
        else if (clk_div_2 == clk_mhz)
            clk_div_2 <= 0;
        else
            clk_div_2 <= clk_div_2 + 1;
    end

    wire clk_2 = clk_div_2 == clk_mhz;
    logic w_display_number = w_digit * $clog2(w_data);

    seven_segment_display #(w_digit) i_7segment
    (
        .clk      ( clk_2                              ),
        .rst      ( rst                                ),
        .number   ( w_display_number' (data_seg)       ),
        .dots     ( w_digit' (0)                       ),
        .abcdefgh ( abcdefgh                           ),
        .digit    ( digit                              )
    );
    
endmodule