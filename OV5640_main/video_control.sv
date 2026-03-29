module video_control
# (
    parameter  clk_mhz       = 100,

               w_data        = 16,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 1,
               w_green       = 1,
               w_blue        = 1,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                               clk,
    input                         pixel_clk,
    input                               rst,

    // Graphics

    input        [w_x     - 1:0]          x,
    input        [w_y     - 1:0]          y,
    input                             hsync,
    input                             vsync,
    input                        display_on,

    input  logic [w_data   -1:0] pixel_data,
    input  logic                     in_vld,

    output logic [w_red   - 1:0]        red,
    output logic [w_green - 1:0]      green,
    output logic [w_blue  - 1:0]       blue,

    output                            almost_empty,
    output                            lock_vga,
    output                            full_vga,
    output                            empty_vga,

    // Debug signals

    output logic      [w_data   -1:0]  data_seg_debug,
    input                              key,
    output logic                       pop_debug

);

    logic [w_red   - 1:0] red_reg;
    logic [w_green - 1:0] green_reg;
    logic [w_blue  - 1:0] blue_reg;

    logic                  push_fifo;
    logic                  pop_fifo;
    logic [w_data   -1:0]  data_in_fifo, data_from_fifo;
    logic                  empty, full;

    logic lock;
    logic [7  : 0] cnt_h_choose_out;
    logic [10 : 0] cnt_v_choose_out;
    logic h_strobe, v_strobe;
    
	logic go_video;
    logic hsync_front;
    logic hsync_prev;
    logic almost_empty_r;



    // -----------------------------------------------------------------

    // always_ff @( posedge clk or posedge rst ) begin : Hstrobe
    //     if(rst) begin
    //         {hsync_prev,hsync_front} <= '0;
    //     end  else begin
    //         hsync_prev <= hsync;
    //         hsync_front <= ~hsync_prev & hsync;
    //     end 
    // end

    // always_ff @( posedge clk or posedge rst ) begin : row_strobe_choose_fifo
    //     if(rst)
    //         h_strobe <= '0;
    //     else if (hsync_front)
    //         h_strobe <= ~h_strobe;
    // end

    always_ff @( posedge clk or posedge rst ) begin : start_enable
        if(rst)
            go_video <= '0;
        else if(full & vsync)
            go_video <= '1;        
    end

    flip_flop_fifo_with_counter  
    #(
        .width          (w_data         ),
        .depth          (3200           )
    )
    fifo_vga
    (
        .clk            (clk            ),
        .rst            (rst            ),
        .push           (in_vld         ),
        .pop            (pop_fifo       ),
        // .pop            (key            ),
        .write_data     (pixel_data   ),
        .read_data      (data_from_fifo ),
        .empty          (empty          ),
        .locked         (lock           ),
        .almost_empty   (almost_empty   ),
        .full           (full           )
    );

    assign data_seg_debug = data_from_fifo;
    assign pop_debug = display_on;

    assign full_vga     = full;
    assign empty_vga    = empty;
    assign almost_empty = almost_empty;
    assign lock_vga     = lock;
    assign pop_fifo     = display_on & pixel_clk & go_video;

    // --------------------------------------------------------------------------------

    // always_ff @( posedge clk or posedge rst) begin : rgb
    //     if(rst) begin
    //         red_reg   = '0;
    //         green_reg = '0;
    //         blue_reg  = '0;
    //     end else if(pop_fifo) begin
    //         // red_reg   <= pixel_data [15];
    //         // green_reg <= pixel_data [10];
    //         // blue_reg  <= pixel_data [4];

    //         red_reg   = data_from_fifo [15];
    //         green_reg = data_from_fifo [10];
    //         blue_reg  = data_from_fifo [4];
    //     end else begin
    //         red_reg   = '0;
    //         green_reg = '0;
    //         blue_reg  = '0;
    //     end
    // end

    // assign red   = w_red'   ( red_reg   );
    // assign green = w_green' ( green_reg );
    // assign blue  = w_blue'  ( blue_reg  );

    logic [w_red   - 1:0] red_wire;
    logic [w_green - 1:0] green_wire;
    logic [w_blue  - 1:0] blue_wire;
	 
	assign data_seg_debug = data_from_fifo;

    always_comb
    begin
        red_wire   = '0;
        green_wire = '0;
        blue_wire  = '0;
        //pop_fifo   = '0;

        // if ((x < screen_width && y < screen_height))

        if (display_on)
        begin
            red_wire   = data_from_fifo [15];
            green_wire = data_from_fifo [10];
            blue_wire  = data_from_fifo [4];
            
            // red_wire   = pixel_data [15];
            // green_wire = pixel_data [10];
            // blue_wire  = pixel_data [4];
        end
    end

    assign red   = w_red'   ( red_wire   );
    assign green = w_green' ( green_wire );
    assign blue  = w_blue'  ( blue_wire  );


endmodule
