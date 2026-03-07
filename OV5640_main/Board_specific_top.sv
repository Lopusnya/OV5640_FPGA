module board_specific_top
# (
    parameter clk_mhz       = 100,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 4,
              w_led         = 4,
              w_digit       = 4,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 1,
              w_green       = 1,
              w_blue        = 1,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  CLK,
    input                  RESET,

    input  [w_key   - 1:0] KEY_SW,
    output [w_led   - 1:0] LED,

    output [          7:0] SEG,
    output [w_digit - 1:0] DIG,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output                 VGA_R,
    output                 VGA_G,
    output                 VGA_B,

    // inout  [w_gpio  - 1:0] PSEUDO_GPIO_USING_SDRAM_PINS
    output [        11: 0] SDRAM_A,
    output [         1: 0] SDRAM_BS,
    
    output                 SDRAM_LDQM,
    output                 SDRAM_UDQM,
    output                 SDRAM_CLK,
    output                 SDRAM_CKE,
    output                 SDRAM_CS,
    output                 SDRAM_RAS,
    output                 SDRAM_CAS,
    output                 SDRAM_WE,

    inout  [        15: 0]  SDRAM_D

);

    wire clk =   CLK;
    wire rst = ~ RESET;

    wire [w_led   - 1:0] lab_led;

    assign LED       = ~ lab_led;
    // Seven-segment display

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    assign SEG       = ~ abcdefgh;
    assign DIG       = ~ digit;

    // Graphics

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    assign VGA_R = display_on & ( | red   );
    assign VGA_G = display_on & ( | green );
    assign VGA_B = display_on & ( | blue  );

    wire clk_2;
    

    PLL_100clk_mhz pll
    (
        .areset (rst),
        .inclk0 (clk),
        .c0     (clk_2),
        .locked ()
    );

    //SDRAM wire assigment
    wire         sdram_we;
    wire         sdram_cas;
    wire         sdram_ras;
    wire         sdram_cke;
    wire         sdram_cs;
    wire         sdram_ldqm;
    wire         sdram_udqm;

    wire [11:0]  sdram_address;
    wire [ 1:0]  sdram_bank;
    wire [15:0]  sdram_data;

    assign SDRAM_CLK  = clk_2;
    assign SDRAM_CKE  = sdram_cke;
    assign SDRAM_CS   = sdram_cs;
    assign SDRAM_RAS  = sdram_ras;
    assign SDRAM_CAS  = sdram_cas;
    assign SDRAM_WE   = sdram_we;
    assign SDRAM_LDQM = sdram_ldqm;
    assign SDRAM_UDQM = sdram_udqm;
    assign SDRAM_BS   = sdram_bank;
    assign SDRAM_A    = sdram_address;
    assign SDRAM_D    = sdram_data;

    test_sdram_top  
    #(
        .w_digit(w_digit),
        .clk_mhz(clk_mhz),
        .w_key(w_key),
        .w_led(w_led)
    )
    test_1
    (
        .clk(clk_2),
        .rst(rst),
        .key (~ KEY_SW),
        .leds(lab_led),

        .sdram_we(sdram_we),
        .sdram_cas(sdram_cas),
        .sdram_ras(sdram_ras),
        .sdram_cke(sdram_cke),
        .sdram_cs(sdram_cs),
        .sdram_ldqm(sdram_ldqm),
        .sdram_udqm(sdram_udqm),
        .sdram_address(sdram_address),
        .sdram_bank(sdram_bank),
        .sdram_data(sdram_data),

        .abcdefgh(abcdefgh),
        .digit(digit)
    );

endmodule