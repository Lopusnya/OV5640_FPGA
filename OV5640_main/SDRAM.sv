module sdram 
#(
    parameter clk_mhz = 100,
    parameter write_mode = 1'b0,
    parameter cas_latency = 3'b010,
    parameter burst_type = 1'b0,
    parameter burst_length = 3'b111 
) 
(
    input                     clk, //
    input                     rst, // 
    input                  in_vld, // Валидность входных данных
    input logic   [15:0]  data_in, // входные данные
    input                    wr_e, // Если он в 1, то значит пишем в SDRAM
    input               instr_vld, //
    input         [21:0]    instr, //

    output                    rdy,

    output                    cke, //clock enable
    output                     cs, //chip select
    output logic              ras, //row adress strobe
    output logic              cas, //Column Address Strobe,
    output logic         we_sdram, //write enable
    output                    dqm, //mask for data

    output logic [1: 0]  bank_adr, //bank adress
    output logic [11:0]       adr, //row and column adress. Row adress [11:0] RA, Column adress [7:0] CA
    output logic [15:0]  data_out, //for VGA

    inout   [15:0]  sdram_data_rw  //data read/write in sdram
);

    localparam       delay_rp  = 2;
    localparam       delay_rcd = 2;
    localparam       delay_dpl = 2;
    localparam delay_full_page = 255;

    logic            output_enable;
    logic              read_enable;
    logic             set_mode_flg = '0;
    logic                  cnt_vld;
    logic         choose_wr_rd_reg;

    logic [ 3: 0] return_state_reg;
    logic [ 1: 0]     bank_adr_reg; // instr [21:20];
    logic [11: 0]      row_adr_reg; // instr [19: 8];
    logic [ 7: 0]   column_adr_reg; // instr [ 7: 0];
    logic [13: 0]         mode_adr = {4'b0000, write_mode, 2'b00, cas_latency, burst_type, burst_length};
    logic [ 8: 0]              cnt;
    logic [ 1: 0]          latency;
    logic [15: 0]    reg_data_read, 
                    reg_data_write;
    

    enum logic [3:0]
    {  
        IDLE        = 4'd0, //Стартовая позиция автомата. Из нее две дороги: 1) Инициализация и 2)Циклы запись/чтение

        // Блок Инициализации ---------------------------------------------------------------------------------------
        PALL        = 4'd1, //
        SET_MODE    = 4'd2, //
        
        // Блок Основные команды в цикле запись/чтение --------------------------------------------------------------
        // ACTIVE      = 4'd3,
        READ        = 4'd4,
        WRITE       = 4'd5,
        PRECHARDGE  = 4'd6,

        // Блок команд на задержку -----------------------------------------------------------------------------------
        NOP        = 4'd7 

    }
    state, next_state, return_state;

    always_ff @( posedge clk ) begin : next_state_reg
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @( posedge clk ) begin : flag_initialization_ready
        if (rst)
            set_mode_flg <= '0;
        else if (state == SET_MODE)
            set_mode_flg <= '1;
    end

    always_ff @( posedge clk ) begin : timer_delay_NOP
        if (rst) begin
            cnt <= '0;
        end else if (cnt_vld && state == PALL) begin
            cnt <= 9'(delay_rp);
        end else if (cnt_vld && state == IDLE && instr_vld) begin
            cnt <= 9'(delay_rcd);
        end else if (cnt_vld && (state == WRITE || state == READ)) begin
            cnt <= 9'(delay_full_page + delay_dpl);
        end else if( cnt > 0) begin
            cnt <= cnt - 1'b1;
        end
    end

    always_ff @( posedge clk ) begin : inout_data
        if (rst) 
            reg_data_read <= '0;
        else
            reg_data_read <= sdram_data_rw;
    end

    always_ff @( posedge clk ) begin : data_in_reg
        if (rst) begin
            reg_data_write <= '0;
        end else if (in_vld) begin
            reg_data_write  <= data_in;
        end
    end

    always_ff @( posedge clk ) begin : write_in_sdram_mode
        if (rst)
            choose_wr_rd_reg <= '0;
        else if (state == WRITE)
            choose_wr_rd_reg <= '1;
        else if (state != NOP)
            choose_wr_rd_reg <= '0;
    end

    always_ff @( posedge clk ) begin : bank_adress
        if(rst)
            bank_adr_reg <= '0;
        else
            bank_adr_reg <= instr [21: 20];
    end

    always_ff @( posedge clk ) begin : row_adress
        if(rst)
            row_adr_reg <= '0;
        else
            row_adr_reg <= instr [19: 8];
    end

    always_ff @( posedge clk ) begin : column_adress
        if(rst)
            column_adr_reg <= '0;
        else
            column_adr_reg <= instr [7:0];
    end

    always_ff @( posedge clk ) begin : return_state_logic
        if(rst)
            return_state_reg <= '0;
        else if (state == PALL || state == ACTIVE || state == WRITE || state == READ || state == PRECHARDGE)
            return_state_reg <= return_state;
    end
    always_comb begin
        
        next_state      = state;
        return_state    = '0;
        ras             = 1'b1;
        cas             = 1'b1;
        we_sdram        = 1'b1;
        adr             = '0;
        bank_adr        = '0;
        output_enable   = '0;
        read_enable     = '0;

        case (state)
            IDLE: begin
                if(set_mode_flg) begin
                    if (instr_vld) begin
                        ras           = 1'b0;
                        cas           = 1'b1;
                        we_sdram      = 1'b1;

                        bank_adr      = bank_adr_reg;
                        adr           = row_adr_reg;

                        cnt_vld       = '1;
                        next_state    = NOP;
                        return_state  = (wr_e) ? WRITE : READ;

                    end
                end else
                    next_state = PALL;
            end

            PALL: begin
                ras           = 1'b0;
                cas           = 1'b1;
                we_sdram      = 1'b0;

                adr [10]      = 1'b1;

                next_state    = NOP;
                return_state  = SET_MODE;

                cnt_vld       = '1;
            end

            SET_MODE: begin
                ras           = 1'b0;
                cas           = 1'b0;
                we_sdram      = 1'b0;

                {bank_adr, adr} = mode_adr;

                next_state = IDLE;
            end

            WRITE: begin
                ras           = 1'b1;
                cas           = 1'b0;
                we_sdram      = 1'b0;

                bank_adr      = bank_adr_reg;
                adr           = column_adr_reg;

                next_state    = NOP;
                return_state  = PRECHARDGE;

                output_enable = '1;
            end

            READ: begin
                ras           = 1'b1;
                cas           = 1'b0;
                we_sdram      = 1'b1;

                bank_adr      = bank_adr_reg;
                adr           = column_adr_reg;

                next_state    = NOP;
                return_state  = PRECHARDGE;             
            end

            PRECHARDGE: begin
                ras           = 1'b0;
                cas           = 1'b1;
                we_sdram      = 1'b0;
                
                adr [10]      = 1'b0;
                bank_adr      = 2'b00;

                next_state    = NOP;
                return_state  = IDLE;
                cnt_vld       = '1;
            end

            NOP: begin
                next_state = (cnt == 0) ? return_state_reg : NOP;
                cnt_vld    = '0;

                ras           = 1'b1;
                cas           = 1'b1;
                we_sdram      = 1'b1;

                if(choose_wr_rd_reg)
                    output_enable = '1;

                if(cnt < 9'(delay_full_page + delay_dpl) - 9'(cas_latency))
                    read_enable = '1;

            end         

        endcase
    end

    assign sdram_data_rw = output_enable ? reg_data_write : 'z; 
    assign data_out = reg_data_read;
    assign cke = '1;
    assign cs  = '0;
endmodule