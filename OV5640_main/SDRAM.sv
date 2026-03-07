module sdram 
#(
    parameter clk_mhz = 100,
    parameter write_mode = 1'b0,
    parameter cas_latency = 3'b010,
    parameter burst_type = 1'b0,
    parameter burst_length = 3'b111,
    parameter w_led = 4 
) 
(
    input                       clk, //
    input                       rst, // 
    output logic   [w_led -1:0]leds,
    
    input  logic   [15:0]   data_in, // входные данные
    input                      wr_e, // Если он в 1, то значит пишем в SDRAM
    input                 instr_vld, // 
    input          [21:0]     instr, // Инструкция, состоит из адреса банка, строки и колонки

    output logic          instr_rdy, // Сигнал готовности принять инструкцию
    output            data_read_vld, // 
    output logic       data_rdy_out, // Сигнал готовности принять данные
    output logic   [15:0]  data_out, // Вывод данных наружу

    // Сигналы для SDRAM ----------------------------------------------------------------------------------
    output                      cke, //clock enable
    output                       cs, //chip select
    output logic                ras, //row adress strobe
    output logic                cas, //Column Address Strobe,
    output logic           we_sdram, //write enable
    output                     ldqm, //mask for data
    output                     udqm, //mask for data
    output logic   [1: 0]  bank_adr, //bank adress
    output logic   [11:0]       adr, //row and column adress. Row adress [11:0] RA, Column adress [7:0] CA

    inout   [15:0]  sdram_data_rw  //data read/write in sdram
);

    localparam       delay_rp     = w_cnt' (2);
    localparam       delay_start  = w_cnt' (2 ** (w_cnt));
    localparam       delay_rcd    = w_cnt' (2);
    localparam       delay_dpl    = w_cnt' (2);
    localparam delay_full_page    = w_cnt' (254);
    localparam           w_cnt    = 16;

    logic            output_enable;
    logic              read_enable;

    logic                 data_rdy;
    logic             set_mode_flg;
    logic                 mode_flg;
    logic                  cnt_vld;
    logic         choose_wr_rd_reg;
    logic             data_rdy_reg;


    logic [ 1: 0]     bank_adr_reg; // instr [21:20];
    logic [11: 0]      row_adr_reg; // instr [19: 8];
    logic [ 7: 0]   column_adr_reg; // instr [ 7: 0];
    logic [13: 0]         mode_adr = {4'b0000, write_mode, 2'b00, cas_latency, burst_type, burst_length};
    logic [w_cnt-1: 0]         cnt;
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
        READ        = 4'd3,
        WRITE       = 4'd4,
        PRECHARDGE  = 4'd5,

        // Блок команд на задержку -----------------------------------------------------------------------------------
        NOP        = 4'd6 

    }
    state, next_state, return_state, return_state_reg;

    always_ff @ (posedge clk or posedge rst) begin : next_state_reg
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @ (posedge clk or posedge rst) begin : flag_initialization_ready
        if (rst)
            set_mode_flg <= '0;
        else if (mode_flg)
            set_mode_flg <= '1;
    end

    always_ff @ (posedge clk or posedge rst) begin : timer_delay_NOP
        if (rst) begin
            cnt <= '0;
        end else begin 
            if (cnt_vld && state == PALL)
                cnt <= w_cnt'(delay_rp);
            
            if (cnt_vld && state == IDLE && ~set_mode_flg)
                cnt <= w_cnt'(delay_start);
            
            if (cnt_vld && state == IDLE && instr_vld)
                cnt <= w_cnt'(delay_rcd);
            
            if (cnt_vld && (state == WRITE))
                cnt <= w_cnt'(delay_full_page + delay_dpl);
            
            if (cnt_vld && (state == READ))
                cnt <= w_cnt'(delay_full_page + delay_dpl + cas_latency);
                
            if (cnt > '0)
                cnt <= cnt - 1'b1;
        end 
    end

    always_ff @ (posedge clk or posedge rst) begin : inout_data
        if (rst) 
            reg_data_read <= '0;
        else if(read_enable)
            reg_data_read <= sdram_data_rw;
    end

    always_ff @ (posedge clk or posedge rst) begin : write_in_sdram_mode
        if (rst)
            choose_wr_rd_reg <= '0;
        else if (state == WRITE)
            choose_wr_rd_reg <= '1;
        else if (state != NOP || state != WRITE)
            choose_wr_rd_reg <= '0;
    end

    always_ff @ (posedge clk or posedge rst) begin : bank_adress
        if(rst)
            bank_adr_reg <= '0;
        else if(instr_vld && instr_rdy)
                bank_adr_reg <= instr [21: 20];
    end

    always_ff @ (posedge clk or posedge rst) begin : column_adress
        if(rst)
            column_adr_reg <= '0;
        else if(instr_vld && instr_rdy)
                column_adr_reg <= instr [7:0];
    end

    always_ff @ (posedge clk or posedge rst) begin : return_state_logic
        if(rst)
            return_state_reg <= IDLE;
        else if (state == PALL || state == WRITE || state == READ || state == PRECHARDGE || state == IDLE)
            return_state_reg <= return_state;
    end

    always_ff @ (posedge clk or posedge rst) begin : data_ready_reg
        if(rst)
            data_rdy_reg <= '0;
        else if(state == WRITE)
                data_rdy_reg <= data_rdy;
        else if(state != NOP)
                data_rdy_reg <= '0;
    end

    logic read_mode_flg;
    always_ff @ (posedge clk or posedge rst) begin : read_mode
        if(rst)
            read_mode_flg <= '0;
        else if(state == READ)
                read_mode_flg <= '1;
        else if(state != NOP)
                read_mode_flg <= '0;
    end

    always_comb begin
        
        next_state      = state;
        return_state    = IDLE;
        ras             = 1'b1;
        cas             = 1'b1;
        we_sdram        = 1'b1;
        adr             = '0;
        bank_adr        = '0;
        output_enable   = '0;
        read_enable     = '0;
        instr_rdy       = '0;
        data_rdy        = '0;
        cnt_vld         = '0;
        mode_flg        = '0;

        case (state)
            IDLE: begin
                if(set_mode_flg) begin
                    if (instr_vld) begin
                        ras           = 1'b0;
                        cas           = 1'b1;
                        we_sdram      = 1'b1;

                        bank_adr      = instr [21: 20];
                        adr           = instr [19: 8];

                        instr_rdy     = '1;

                        cnt_vld       = '1;
                        next_state    = NOP;
                        return_state  = (wr_e) ? WRITE : READ;

                    end
                end else begin
                    next_state   = NOP;
                    return_state = PALL;
                    cnt_vld      = '1;

                end   
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

                mode_flg   = '1;
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

                data_rdy      = '1;

                output_enable = '1;
                cnt_vld       = '1;
            end

            READ: begin
                ras           = 1'b1;
                cas           = 1'b0;
                we_sdram      = 1'b1;

                bank_adr      = bank_adr_reg;
                adr           = column_adr_reg;

                next_state    = NOP;
                return_state  = PRECHARDGE; 
                cnt_vld       = '1;            
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
                else
                    if(cnt < w_cnt'(delay_full_page + delay_dpl) && read_mode_flg)
                        read_enable = '1;

            end         

        endcase
    end

    assign sdram_data_rw = (output_enable) ? data_in : 'z; 
    assign data_out = reg_data_read;
    assign data_read_vld = read_enable;
    assign data_rdy_out = data_rdy_reg || data_rdy;
    assign cke = '1;
    assign cs = '0;
    assign ldqm = '0;
    assign udqm = '0;

    //DEBUG
    // logic [w_led - 1:0] signal_state;
    // always_ff @ (posedge clk or posedge rst) begin
    //     if(rst)
    //         signal_state <= '0;
    //     else begin
    //         if(state == WRITE)
    //             signal_state [0] <= 1'b1;
    //         if(state == READ)
    //             signal_state [1] <= 1'b1;
    //         if(state == PRECHARDGE)
    //             signal_state [2] <= 1'b1;
    //         if (choose_wr_rd_reg)  
    //             signal_state[3] <= 1'b1;          
    //     end

    // end

    // // assign leds [1:0] = signal_state [1:0];
    // // assign leds [2] = set_mode_flg;
    // // assign leds [3] = signal_state [3];
    // assign leds = signal_state;
endmodule