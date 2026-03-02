module rom (
    input              clk,
    input  [7:0]   rom_adr,
    output [15:0] data_out
);

always_ff @( posedge clk ) begin

    case (rom_adr)
        0 : data_out <= 16'h00_00;
        1 : data_out <= 16'h00_01;
        2 : data_out <= 16'h00_02;
        3 : data_out <= 16'h00_03;
        4 : data_out <= 16'h00_04;
        5 : data_out <= 16'h00_05;
        6 : data_out <= 16'h00_06;
        7 : data_out <= 16'h00_07;
        8 : data_out <= 16'h00_08;
        9 : data_out <= 16'h00_09;
        10: data_out <= 16'h00_0a;
        11: data_out <= 16'h00_0b;
        12: data_out <= 16'h00_0c;
        13: data_out <= 16'h00_0d;
        14: data_out <= 16'h00_0e;
        15: data_out <= 16'h00_0f;
        16: data_out <= 16'h00_10;
        17: data_out <= 16'h00_11;
        18: data_out <= 16'h00_12;
        19: data_out <= 16'h00_13;
        20: data_out <= 16'h00_14;
        21: data_out <= 16'h00_15;
        22: data_out <= 16'h00_16;
        23: data_out <= 16'h00_17;
        24: data_out <= 16'h00_18;
        25: data_out <= 16'h00_19;
        26: data_out <= 16'h00_1a;
        27: data_out <= 16'h00_1b;
        28: data_out <= 16'h00_1c;
        29: data_out <= 16'h00_1d;
        30: data_out <= 16'h00_1e;
        31: data_out <= 16'h00_1f;
        32: data_out <= 16'h00_20;
        33: data_out <= 16'h00_21;
        34: data_out <= 16'h00_22;
        35: data_out <= 16'h00_23;
        default: data_out <= 16'hff_ff;
    endcase
    
end
    
endmodule