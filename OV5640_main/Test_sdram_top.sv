module Test_sdram_top 
#(
    parameter w_digit = 4
 )   
    (
        input clk,
        input rst,
        
    );
    
    rom test_rom
    (
        .clk(),
        .rom_adr(),
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