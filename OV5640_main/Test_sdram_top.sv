module test_sdram_top 
#(
    parameter   w_digit     = 4,
                clk_mhz     = 100, 
                w_key       = 4, 
                w_led       = 4,

                screen_width  = 640,
                screen_height = 480,

                w_red       = 1,
                w_green     = 1,
                w_blue      = 1,

                w_x         = $clog2 ( screen_width  ),
                w_y         = $clog2 ( screen_height )
 )   
    (
        input clk,
        // input clk_sdram,
        input                rst,
        input  [w_key - 1:0] key,
        output [w_led - 1:0] leds,

        // Graphics ----------------------------------
        input                        pixel_clk,
        input        [w_x     - 1:0] x,
        input        [w_y     - 1:0] y,

        output logic [w_red   - 1:0] red,
        output logic [w_green - 1:0] green,
        output logic [w_blue  - 1:0] blue,

        input                        vsync,
        input                        hsync,
        input                        display_on,

        //SDRAM output -------------------------------
        output                       sdram_we,
        output                       sdram_cas,
        output                       sdram_ras,
        output                       sdram_cke,
        output                       sdram_cs,
        output       [          1:0] sdram_dqm,
        output       [         11:0] sdram_address,
        output       [          1:0] sdram_bank,

        output       [         15:0] data_write,
        output       [         15:0] data_read,
        output                       oe,

        inout        [         15:0] sdram_data,

        //seven_segment_display output----------------
        output  [          7:0] abcdefgh,
        output  [w_digit - 1:0] digit
        
    );
    
    localparam period = 10_000_000; // 10нс * 1_000_000 = 0.01с
    localparam w_data = 16;
    localparam w_display_number = w_digit * $clog2(w_data);

    
    logic [w_data - 1:0] data_from_sram;
    logic [         1:0] rom_adr = 2'd0;
    logic [        20:0] test_cnt;
    logic [w_data - 1:0] data_seg;
    logic [        31:0] cnt_seg;
    logic [        11:0] pack_data_write;
    logic [         2:0] pack_data_read;
	logic [        11:0] row_cnt;

    logic               sdram_rdy; 
    logic               sdram_read_vld; 
    logic               rd_enable;
    logic               full, empty;
    logic               pop_enable;
    
	logic               prev_key, prev_key_2, prev_key_3;
    logic               cmd_pulse_key, cmd_pulse_key_2, cmd_pulse_key_3;
    logic [       13:0] key_filtered, key_filtered_2, key_filtered_3;
    logic               start;
    
    wire [w_data - 1:0] fifo_data_out;
    wire [w_data - 1:0] rom_data;
    wire                sdram_locked;
    // wire                push_in_sdram   = (cmd_pulse_key |(|pack_data_write)) && !sdram_locked;
    wire                push_in_sdram   = (cmd_pulse_key || start) && ~sdram_locked;
    wire                pop_from_sdram  = cmd_pulse_key_2;
    wire                push = sdram_read_vld & ~full;
    // wire                push = (cmd_pulse_key || start) & ~full & ~lock;
    wire                pop  = pop_enable && ~empty;
    // wire                pop  = cmd_pulse_key_3 && ~empty;
    wire                 rom_vld;
    logic [w_data - 1:0] test_data;

//---------------------------------------------------------------------------------------------------
    wire  [15:0] pxl_d;
    logic [15:0] data_from_rom;
    wire  [15:0] pixel_data;

    logic go_push;
    logic full_vga, empty_vga, almost_empty, lock_vga;
    logic pixel_clk_front;
    logic pixel_clk_prev;
    logic enable_push_in_vga;
    logic [18:0] cnt_addr_rom;
    logic debug;

//----------------------------------------------------------------------------------------------------



	  
	always_ff @( posedge clk or posedge rst ) begin : strobe
        if(rst) begin
            prev_key <= 1'b0;
            key_filtered <= '0;
            cmd_pulse_key <= 1'b0;
        end else begin
            key_filtered <= {key_filtered[12:0], key[0]};
            prev_key      <= &key_filtered;
            cmd_pulse_key <=  ~prev_key &  (&key_filtered);
		end
    end

    always_ff @( posedge clk or posedge rst ) begin : strobe_2
        if(rst) begin
            prev_key_2 <= 1'b0;
				key_filtered_2  <= '0;
				cmd_pulse_key_2 <= 1'b0;
        end else begin
				key_filtered_2  <= {key_filtered_2[12:0], key[1]};
                prev_key_2      <= &key_filtered_2;
				cmd_pulse_key_2 <=  ~prev_key_2 & (&key_filtered_2);
		end
        
    end

    always_ff @( posedge clk or posedge rst ) begin : strobe_3
        if(rst) begin
                prev_key_3 <= 1'b0;
				key_filtered_3  <= '0;
				cmd_pulse_key_3 <= 1'b0;
        end else begin
				key_filtered_3  <= {key_filtered_3[12:0], key[3]};
                prev_key_3      <= &key_filtered_3;
				cmd_pulse_key_3 <=  ~prev_key_3 & (&key_filtered_3);
		end
        
    end

    // always_ff @( posedge clk or posedge rst ) begin : package_data_write
    //     if(rst)
    //         pack_data_write <= '0;
    //     else if((pack_data_write > 0))
    //         pack_data_write <= pack_data_write - 1'b1;
    //     // else if(cmd_pulse_key || ((row_cnt > 12'h0 && row_cnt < 12'h3) && !sdram_locked))
    //     else if(cmd_pulse_key)        
    //         pack_data_write <= 12'hFF;
    //     else
    //         pack_data_write <= '0;
    // end

    // always_ff @( posedge clk or posedge rst ) begin : data
    //     if(rst) begin
	// 			test_data = 16'hA000;
    //     end else if(push_in_sdram) begin
	// 			test_data <= test_data + 1'b1;
	// 	end
    // end

    logic [11:0]addr_cnt;
    always_ff @( posedge clk or posedge rst ) begin : addr_cnt_data
        if(rst)
            addr_cnt <= '0;
    else if((push_in_sdram) && addr_cnt [11:8] < 4'h2)
            addr_cnt <= addr_cnt + 1'b1;
    // else if(addr_cnt[7:0] > 8'h1)
    //         addr_cnt <= addr_cnt + 1'b1;
    else
            addr_cnt [7:0] <= 8'h0;
    end


    always_ff @( posedge clk or posedge rst ) begin : strt
        if( rst)
            start <= '0;
        else if(((|addr_cnt) | cmd_pulse_key) && (addr_cnt [11:8] < 4'h2))
            start <= '1;
        else
            start <= '0;
    end

    // wire start_w;
    // assign start_w = start && ~full;

    // always_ff @( posedge clk or posedge rst ) begin : rwcnt
    //     if(rst)
    //         row_cnt <= '0;
    //     else if(|addr_cnt)
    //             if(addr_cnt[7:0] == 8'h0)
    //                 row_cnt <= row_cnt + 1'b1;
    // end

    // logic lock;
    // always_ff @( posedge clk or posedge rst ) begin : lck
    //     if(rst)
    //         lock <= '0;
    //     else if(full)
    //         lock <= '1;
    //     else if(empty)
    //         lock <= '0;
    //     else
    //         lock <= lock;
    // end

    rom rom_comb
    (
        .addr(addr_cnt[7:0]),
        .data(data_from_rom)
    );

    sdram ram // #()
    (
        //debug signals ----------------------
        .burst                  (           burst),
        .next_state_strobe      ( cmd_pulse_key_3),
        // -----------------------------------        

        .clk                    (             clk),
        .rst                    (             rst),
        .read_from_sdram        (  pop_from_sdram), // pop from sdram
        .write_in_sdram         (   push_in_sdram), // push in sdram
        .read_strobe            (  sdram_read_vld), // push for FIFO, when read sdram
        // .write_in_sdram_data    (  test_data     ), // input data in sdram
        .write_in_sdram_data    (  data_from_rom     ), // input data in sdram
        .data_from_sram         (  data_from_sram), // output data from sdram
        .sdram_locked           (    sdram_locked),


        .cke                    (       sdram_cke),
        .cs                     (        sdram_cs),
        .ras                    (       sdram_ras),
        .cas                    (       sdram_cas),
        .we_sdram               (        sdram_we),
        .dqm                    (       sdram_dqm),
        .bank_adr               (      sdram_bank),
        .adr                    (   sdram_address),

        .sdram_data_inout       (      sdram_data) // physical pin data inout in-from sdram
                  
    );

    flip_flop_fifo_with_counter  
    #(
        .width      (w_data         ),
        .depth      (512            )
    )
    fifo
    (
        .clk        (clk            ),
        .rst        (rst            ),
        .push       (push           ),
        // .push       (debug          ),
        .pop        (pop            ),
        .write_data (data_from_sram ),
        // .write_data (pxl_d ),
        .read_data  (fifo_data_out  ),
        .empty      (empty          ),
        .locked     (),
        .full       (full           )
    );

    always_ff @ (posedge clk or posedge rst) begin : Sinchronizatore
        if (rst)
            cnt_seg <= '0;
        else if (cnt_seg == '0)
            cnt_seg <= period - 1'b1;
        else
            cnt_seg <= cnt_seg - 1'd1;
    end

    always_ff @ (posedge clk or posedge rst) begin : Pop_signal_source
        if (rst)
            pop_enable <= '0;
        else if (cnt_seg == '0)
            pop_enable <= '1;
        else
            pop_enable <= '0;
    end

    always_ff @ (posedge clk or posedge rst) begin : reg_data_for_seg
        if (rst)
            data_seg <= '0;
        else if (pop)
            data_seg <= fifo_data_out;
    end

    seven_segment_display   
    #(
        .w_digit(w_digit),
        .update_hz(240)
    )
    i_7segment
    (
        .clk      ( clk                                ),
        .rst      ( rst                                ),
        .number   ( w_display_number' (data_seg)   ),
        .dots     ( w_digit' (0)                       ),
        .abcdefgh ( abcdefgh                           ),
        .digit    ( digit                              )
    );

    always_ff @( posedge clk or posedge rst) begin : front_detect_pixel_clk
        if(rst) begin
            {pixel_clk_prev, pixel_clk_front} <= '0;
        end else begin
            pixel_clk_prev <= pixel_clk;
            pixel_clk_front <= ~pixel_clk_prev & pixel_clk;
        end
    end

    always_ff @( posedge clk or posedge rst ) begin : block_push_enable
        if(rst) begin
            go_push <= '0;
        end else if((lock_vga & almost_empty) || empty_vga) begin
            go_push <= 1'b1;
        end else if (full_vga) begin
            go_push <= 1'b0;
        end
    end

    always_ff @( posedge clk or posedge rst) begin : cnt_addr
        if(rst)
            cnt_addr_rom <= '0;
        else 
        // if(display_on & pixel_clk) begin
        if(go_push) begin
                if(cnt_addr_rom < 19'd639)
                    cnt_addr_rom <= cnt_addr_rom + 1'b1;
                else if(cnt_addr_rom == 19'd639)
                    cnt_addr_rom <= 19'd0;
        end
    end

    rom_screen test_screen
    (
        .address(cnt_addr_rom),
        .rgb_out(pixel_data)
    );

    video_control 
    #(
        .clk_mhz    (clk_mhz        )
    )
    video
    (
        .clk        (clk            ),
        .rst        (rst            ),

        .x          (x              ),
        .y          (y              ),

        .vsync      (vsync          ),
        .hsync      (hsync          ),
        .display_on (display_on     ),

        .red        (red            ),
        .green      (green          ),
        .blue       (blue           ),

        .in_vld     (go_push        ),
        .pixel_data (pixel_data     ),
        .pixel_clk  (pixel_clk      ),

        .full_vga     (full_vga       ),
        .empty_vga    (empty_vga      ),
        .almost_empty (almost_empty   ),
        .lock_vga     (lock_vga       ),

        .pop_debug      (debug            ),
        .key            (cmd_pulse_key_3  ),
        .data_seg_debug (pxl_d)

    );





    //debug ----------------------------------------------------------------------------------  
    // logic [w_led - 1:0] signal_state;
    // always_ff @ (posedge clk or posedge rst) begin
    //     if(rst)
    //         signal_state <= '0;
    //     else begin
    //         if(go_push)
    //             signal_state [0] <= 1'b1;
    //         if(full_vga)
    //             signal_state [1] <= 1'b1;
    //         if(almost_empty)
    //             signal_state [2] <= 1'b1;
    //         if (debug)  
    //             signal_state[3] <= 1'b1;          
    //     end
	//  end
    // logic [27:0] cnt_clk;
    // logic [ 3:0] burst;
    // always_ff @( posedge clk or posedge rst ) begin : clk_div
    //     if(rst)
    //         cnt_clk <= '0;
    //     else
    //         cnt_clk <= cnt_clk + 1'b1;
    // end
    // assign leds = signal_state;
    assign leds [0] = push_in_sdram;
    assign leds [1] = empty_vga;
    assign leds [2] = debug;
    assign leds [3] = go_push;
    // assign leds = burst;

    
endmodule