module board_specific_top
# (
    parameter clk_mhz       = 100,
              pixel_mhz     = 25,

              w_key         = 4,
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

    output [w_digit - 1:0] DIG,
    output [7          :0] SEG,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output                 VGA_R,
    output                 VGA_G,
    output                 VGA_B,

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

    
    // Seven-segment display

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    // Graphics

    wire                 display_on;
    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;
    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    
    // PLL

    wire clk_2;
    wire lock;

    // Pixel clk

    wire pixel_clk;

    //SDRAM wire assigment
    wire         sdram_we;
    wire         sdram_cas;
    wire         sdram_ras;
    wire         sdram_cke;
    wire         sdram_cs;
    wire         clk_sdram;

    wire [1:0]   sdram_dqm;
    wire [11:0]  sdram_address;
    wire [ 1:0]  sdram_bank;
    wire [15:0]  sdram_data;
    wire [15:0]  data_write;
    wire [15:0]  data_read;
    wire         oe;

    assign LED          = ~ lab_led;
    assign SEG          = ~ abcdefgh;
    assign DIG          = ~ digit;

    assign VGA_R        = display_on & ( | red   );
    assign VGA_G        = display_on & ( | green );
    assign VGA_B        = display_on & ( | blue  );

    assign SDRAM_CLK    = clk_sdram;
    assign SDRAM_CKE    = sdram_cke;
    assign SDRAM_CS     = sdram_cs;
    assign SDRAM_RAS    = sdram_ras;
    assign SDRAM_CAS    = sdram_cas;
    assign SDRAM_WE     = sdram_we;
    assign SDRAM_LDQM   = sdram_dqm[0];
    assign SDRAM_UDQM   = sdram_dqm[1];
    assign SDRAM_BS     = sdram_bank;
    assign SDRAM_A      = sdram_address;

    PLL_100mhz pll
    (
        .areset (rst),
        .inclk0 (clk),
        .c0     (clk_2),
        .c1     (clk_sdram), //shift phase
        .locked (lock)
    );

    // buffer_iobuf_bidir_p1p data_sdram_interface
    // (
    //     .datain   (data_write),
    //     .dataio   (sdram_data),
    //     .dataout  (data_read),
    //     .oe       (oe)
    // );

    test_sdram_top  
    #(
        .w_digit        (w_digit        ),
        .clk_mhz        (clk_mhz        ),
        .w_key          (w_key          ),
        .w_led          (w_led          )
    )
    test_1
    (
        .clk            (clk_2          ),
        .rst            (rst            ),
        .key            (~ KEY_SW       ),
        .leds           (lab_led        ),

        .sdram_we       (sdram_we       ),
        .sdram_cas      (sdram_cas      ),
        .sdram_ras      (sdram_ras      ),
        .sdram_cke      (sdram_cke      ),
        .sdram_cs       (sdram_cs       ),
        .sdram_dqm      (sdram_dqm      ),
        .sdram_address  (sdram_address  ),
        .sdram_bank     (sdram_bank),
        .sdram_data     (SDRAM_D),

        .abcdefgh       (abcdefgh       ),
        .digit          (digit          ),

        .x              (x              ),
        .y              (y              ),

        .red            (red            ),
        .green          (green          ),
        .blue           (blue           ),

        .vsync          (VGA_VSYNC),
        .hsync          (VGA_HSYNC),
        .display_on     (display_on),

        .pixel_clk      (pixel_clk      )
    );

    wire [9:0] x10; assign x = x10;
    wire [9:0] y10; assign y = y10;

    vga
    # (
        .CLK_MHZ     ( clk_mhz      ),
        .PIXEL_MHZ   ( pixel_mhz    )
    )
    i_vga
    (
        .clk         ( clk_2        ),
        .rst         ( rst          ),
        .hsync       ( VGA_HSYNC    ),
        .vsync       ( VGA_VSYNC    ),
        .display_on  ( display_on   ),
        .hpos        ( x10          ),
        .vpos        ( y10          ),
        .pixel_clk   ( pixel_clk    )
    );

endmodule