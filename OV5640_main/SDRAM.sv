module sdram 
#(
    parameter clk_mhz = 100,
    parameter write_mode = 0,
    parameter cas_latency = 3'b010,
    parameter burst_type = 0,
    parameter burst_length = 3'b111 
) 
(
    input           clk,
    input   [15:0]  data_in,                 //from camera
    input           we,
    input   [21:0]  instr,

    output          cke,                     //clock enable
    output          cs,                      //chip select
    output          ras,                     //row adress strobe
    output          cas,                     //Column Address Strobe,
    output          we_sdram,                //write enable
    output          dqm                      //mask for data

    output  [1: 0]  bank_adr,                //bank adress
    output  [11:0]  adr,                     //row and column adress. Row adress [11:0] RA, Column adress [7:0] CA
    output  [15:0]  data_out,                //for VGA

    inout   [15:0]  sdram_data_rw            //data read/write in sdram
);

    localparam delay_rp  = 2;
    localparam delay_rcd = 2;
    localparam delay_dpl = 2;
    localparam delay_nop = 255;

    enum logic [3:0]
    {  
        IDLE        = 4'd0, //Стартовая позиция автомата. Из нее две дороги: 1) Инициализация и 2)Циклы запись/чтение

        // Блок Инициализации ---------------------------------------------------------------------------------------
        PALL        = 4'd1, //
        SET_MODE    = 4'd2, //
        
        // Блок Основные команды в цикле запись/чтение --------------------------------------------------------------
        ACTIVE      = 4'd3,
        READ        = 4'd4,
        WRITE       = 4'd5,
        PRECHARDGE  = 4'd6,

        // Блок команд на задержку -----------------------------------------------------------------------------------
        T_RP        = 4'd7, //
        T_RCD       = 4'd8, //
        T_DPL       = 4'd9, //
        NOP         = 4'd10

    }
    state, next_state, return_state;

    always_ff @( posedge clk ) begin : next_state_reg
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    logic       set_mode_flg = '0;
    logic       mode_adr = {bank_adr, adr};

    logic       cnt_vld;
    logic [7:0] cnt;

    always_ff @( posedge clk ) begin : timer
        if (rst) begin
            cnt <= '0;
        end else if (cnt_vld && state == PALL) begin
            cnt <= 8'(delay_rp);
        end else if (cnt_vld && state == ACTIVE) begin
            cnt <= 8'(delay_rcd);
        end else if (cnt_vld && (state == WRITE || state == READ)) begin
            cnt <= 8'(delay_nop);
        end else if (cnt_vld && state == NOP) begin
            cnt <= 8'(delay_dpl);
        end
    end

    logic [15:0] reg_data_out, reg_data_in;
    always_ff @( posedge clk ) begin : data_in_reg
        if (rst) begin
            reg_data_out <= '0;
        end else if (in_vld) begin
            reg_data_in  <= data_in;
        end
    end

    logic choose_wr_rd = '0;
    always_comb begin
        
        next_state = state;

        case (state)
            IDLE: begin
                if(set_mode_flg)
                    next_state = ACTIVE;
                else
                    next_state = PALL;
            end

            PALL: begin
                ras           = 1'b0;
                cas           = 1'b1;
                we_sdram      = 1'b0;
                adr [10] = 1'b1;
                next_state    = T_RP;
                return_state  = SET_MODE;
                cnt_vld       = '1;
                sdram_data_rw = 'z;
            end

            SET_MODE: begin
                ras           = 1'b0;
                cas           = 1'b0;
                we_sdram      = 1'b0;

                mode_adr [13:10] = '0;
                mode_adr [9] = write_mode;
                mode_adr [8:7] = '0;
                mode_adr [6:4] = cas_latency;
                mode_adr [3] = burst_type;
                mode_adr [2:0] = burst_length;

                next_state = IDLE;
                set_mode_flg = '1;

                sdram_data_rw = 'z;
            end

            ACTIVE: begin
                ras           = 1'b0;
                cas           = 1'b1;
                we_sdram      = 1'b1;

                bank_adr      = 2'b00;
                adr           = 12'd0;

                cnt_vld       = '1;
                next_state    = T_RCD;
                return_state  = (we) ? WRITE : READ;

                sdram_data_rw = 'z;
            end

            WRITE: begin
                ras           = 1'b1;
                cas           = 1'b0;
                we_sdram      = 1'b0;

                bank_adr      = 2'b00;
                adr           = 12'b0000_0000_0000;

                next_state    = NOP;
                return_state  = T_DPL;

                sdram_data_rw = data_in;
                choose_wr_rd  = '1;
            end

            READ: begin
                ras           = 1'b1;
                cas           = 1'b0;
                we_sdram      = 1'b1;

                bank_adr      = 2'b00;
                adr           = 12'b0000_0000_0000;

                next_state    = NOP;
                return_state  = T_DPL;

                sdram_data_rw = data_out;   
                choose_wr_rd  = '0;             
            end

            PRECHARDGE: begin
                ras           = 1'b0;
                cas           = 1'b1;
                we_sdram      = 1'b0;
                
                adr [10]      = 1'b0;
                bank_adr      = 2'b00;

                next_state    = T_RP;
                return_state  = IDLE;
                cnt_vld       = '1;

                sdram_data_rw = 'z;
            end

            T_RP: begin
                next_state = (cnt == 0) ? return_state : T_RP;
                cnt_vld    = '0;

                ras           = 1'b1;
                cas           = 1'b1;
                we_sdram      = 1'b1;
            end

            T_RCD: begin
                next_state = (cnt == 0) ? return_state : T_RCD;
                cnt_vld    = '0;

                ras           = 1'b1;
                cas           = 1'b1;
                we_sdram      = 1'b1;
            end

            T_DPL: begin
                next_state = (cnt == 0) ? PRECHARDGE : T_DPL;
                cnt_vld    = '0;

                ras           = 1'b1;
                cas           = 1'b1;
                we_sdram      = 1'b1;
            end            

            NOP: begin
                next_state = (cnt == 0) ? return_state : NOP;
                cnt_vld    = '0;

                ras           = 1'b1;
                cas           = 1'b1;
                we_sdram      = 1'b1;

                sdram_data_rw = choose_wr_rd ? data_in : data_out;
            end
             
        endcase
    end
    
    assign cke = '1;
    assign cs  = '0;
endmodule