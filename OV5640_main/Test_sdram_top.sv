module Test_sdram_top 
#(
    parameter w_digit = 4
 )   
    (
        input clk,
        input rst,
        
    );
    
    logic [21:0] instr = 22'b00__0000_0000_0000__0000_0000; // BA - 2bits, RA - 12 bits, CA - 8bits

    wire [15:0] rom_data;
    logic [7:0] rom_adr;
    always_ff @( posedge clk ) 
        if (rst)
            rom_adr <= '0;
        else if (wr_e)
                rom_adr <= rom_adr + 1'b1;

    logic wr_e;
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

    sdram ram // #()
    (
        .clk(clk),
        .data_in(rom_data),                 
        .we(),
        .instr(),                 
        .data_out()                  
    );

    logic w_display_number = w_digit * 4;
    seven_segment_display #(w_digit) i_7segment
    (
        .clk      ( clk                                ),
        .rst      ( rst                                ),
        .number   ( w_display_number' (sdram_data_out) ),
        .dots     ( w_digit' (0)                       ),
        .abcdefgh ( abcdefgh                           ),
        .digit    ( digit                              )
    );
    
endmodule