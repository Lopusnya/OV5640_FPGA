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

    inout  [w_gpio  - 1:0] PSEUDO_GPIO_USING_SDRAM_PINS,

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


    test_sdram_top test_1 
    #(
        .w_digit(w_digit),
        .clk_mhz(clk_mhz)
    )
    (
        .clk(clk_2),
        .rst(rst),
        .abcdefgh(abcdefgh),
        .digit(digit)
    );

endmodule