module sdram 
#(
    parameter clk_mhz = 100,
    parameter write_mode = 1'b0,
    parameter cas_latency = 3'b010,
    parameter burst_type = 1'b0,
    parameter burst_length = 3'b000,
    parameter w_led = 4 
) 
(
    input                        clk, //
    input                        rst, // 
    input            read_from_sdram,
    input             write_in_sdram,
    input  [15:0]write_in_sdram_data,
    output logic         read_strobe,
    input          next_state_strobe,
    output logic        sdram_locked,

    output logic  [15:0] data_from_sram,                     
    output logic  [ 3:0] burst,
       

    // Сигналы для SDRAM ----------------------------------------------------------------------------------
    output logic                cke, //clock enable
    output logic                 cs, //chip select
    output logic                ras, //row adress strobe
    output logic                cas, //Column Address Strobe,
    output logic           we_sdram, //write enable
    output logic   [1: 0]       dqm, //mask for data
    output logic   [1: 0]  bank_adr, //bank adress
    output logic   [11:0]       adr, //row and column adress. Row adress [11:0] RA, Column adress [7:0] CA

    inout          [15:0] sdram_data_inout // inout data
);

    localparam w_cnt    = 16;
    localparam start_delay = w_cnt' (50_000); // 500 мкс на 100 МГц, чтобы точно с запасом
    localparam bank_address = 2'b00;
    localparam w_cnt_burst  = 8;

    

    enum logic [3:0]
    {  
        START       = 4'd1,
        IDLE        = 4'd0, //Стартовая позиция автомата. Из нее две дороги: 1) Инициализация и 2)Циклы запись/чтение

        // Блок Инициализации ---------------------------------------------------------------------------------------
        PALL        = 4'd2, //
        AREF        = 4'd3, // Refresh
        SET_MODE    = 4'd4, //
        
        // Блок Основные команды в цикле запись/чтение --------------------------------------------------------------
        ACTIVE      = 4'd5,
        READ        = 4'd6,
        WRITE       = 4'd7,
        READ_DONE   = 4'd8,
        PRECHARDGE  = 4'd9,

        // Блок команд на задержку -----------------------------------------------------------------------------------
        NOP         = 4'd10,
        TRCD        = 4'd11,
        TRP         = 4'd12 
    }
    state, next_state;

    logic [w_cnt - 1:0]     start_timer_cnt;
    logic [       11:0]          adr_wr_cnt;
    logic [       11:0]          adr_rd_cnt;

    logic                     set_mode_flag;
    logic [w_cnt_burst - 1:0]     cnt_burst;
    logic                            wr_reg;
    logic                            rd_reg;
    logic                             delay;
    logic [       15:0] real_data_from_srame; 
    logic [       15:0] pipe_data_in [0:3];
    logic [        3:0] pipe_data_vld;
	logic               sel;
    logic               lock;

    wire                out_from_pipe_vld;
    wire [        15:0] out_from_pipe_data;

    // always_ff @ (posedge clk or posedge rst) begin : next_state_reg
    //     if(rst)
    //         sel <= 0;
    //     else
    //         if(read_from_sdram || write_in_sdram) begin
    //             sel <= 1'b0; //want to display state
    //         end
    //         // end else if(state == READ_DONE) begin
    //         //     sel <= 1'b1;
    //         // end
    // end
    // assign data_from_sram = sel ? real_data_from_srame :next_state;

    always_ff @ (posedge clk or posedge rst) begin 
        if(rst)
            state <= START;
        // else if(next_state_strobe)
        else
                state <= next_state;
    end

    always_ff @( posedge clk or posedge rst ) begin : start_timer
        if(rst)
            start_timer_cnt <= '0;
        else if((state == START) && (start_timer_cnt < start_delay))
            start_timer_cnt <= start_timer_cnt + 1'b1;
    end

    always_ff @ (posedge clk or posedge rst) begin : clock_enable
        if(rst)
            cke <= '0;
        else if (start_timer_cnt == (start_delay - w_cnt' (25_000))) // Включаю CKE в 1 за 250 мкс до PALL
            cke <= '1;
    end

    always_ff @(posedge clk or posedge rst) begin : flag_init
        if (rst)
            set_mode_flag <= '0;
        else if(state == SET_MODE)
            set_mode_flag <= '1;
    end

    always_ff @(posedge clk or posedge rst) begin : cnt_burst_logic
        if (rst)
            cnt_burst <= '0;
        else if((state == WRITE) || (state == READ_DONE))
            cnt_burst <= 8'd254;
        else if((cnt_burst > 8'h0) & (state == NOP))
            cnt_burst <= cnt_burst - 1'b1;
    end
    // assign burst = cnt_burst; //debug signals

    always_ff @(posedge clk or posedge rst) begin : read_write_command_reg
        if (rst) begin
            wr_reg <= '0;
            rd_reg <= '0;
        end else begin
            if (state == PRECHARDGE) begin
                wr_reg <= '0;
                rd_reg <= '0;
            end else if(read_from_sdram)
                    rd_reg <= '1;
                else if (write_in_sdram)
                    wr_reg <= '1;
        end
    end

    always_ff @(posedge clk or posedge rst) begin : address_write_cnt
        if(rst)
            adr_wr_cnt <= 12'd0;
        else if (adr_wr_cnt == 12'd2) // так как для 1 кадра нужно 1200 строк SDRAM 
            adr_wr_cnt <= 12'd0;
        else if(state == WRITE)
            adr_wr_cnt <= adr_wr_cnt + 12'd1;
    end

    always_ff @(posedge clk or posedge rst) begin : address_read_cnt
        if(rst)
            adr_rd_cnt <= 12'd0;
        else if (adr_rd_cnt == 12'd2)
            adr_rd_cnt <= 12'd0;
        else if(state == READ)
            adr_rd_cnt <= adr_rd_cnt + 12'd1;
    end

    //------------------------------- PIPELINE DATA IN -----------------------------------

    always_ff @ (posedge clk) begin
        pipe_data_in[0] <= (write_in_sdram) ? write_in_sdram_data : pipe_data_in[0];
        
        for (int i = 1; i <= 3; i ++)
            pipe_data_in [i] <= (pipe_data_vld[i-1]) ? pipe_data_in [i-1] : pipe_data_in[i];
    end

    always_ff @(posedge clk or posedge rst) begin   
        if(rst)
            pipe_data_vld <= '0;
        else    
            pipe_data_vld <= {pipe_data_vld[2: 0], write_in_sdram};
    end

    //--------------------------------------------------------------------------------

    always_ff @( posedge clk or posedge rst ) begin : Lock_logic
        if(rst)
            lock <= '0;
        else if(next_state == PRECHARDGE)
                lock <= '1;
        else if(state == IDLE)
                lock <= '0;
    end

    assign sdram_locked = lock && ~set_mode_flag;

    always_comb begin : state_machine
        next_state = state;
        case (state)
            START       : if(start_timer_cnt == start_delay)                next_state = PALL;
            PALL        :                                                   next_state = NOP;
            SET_MODE    :                                                   next_state = IDLE;

            IDLE        : if(!rst & set_mode_flag & (wr_reg | rd_reg))      next_state = ACTIVE;
            ACTIVE      :                                                   next_state = TRCD;
            WRITE       :                                                   next_state = NOP;
            READ        :                                                   next_state = NOP;
            PRECHARDGE  :                                                   next_state = TRP;
            READ_DONE   :                                                   next_state = NOP;

            NOP         : if(!set_mode_flag)                                next_state = SET_MODE;
                            else if(wr_reg & (cnt_burst == 8'h0))           next_state = PRECHARDGE;
                            else if(read_strobe & (cnt_burst == 8'h0))      next_state = PRECHARDGE;
                            else if(rd_reg && ~read_strobe)                 next_state = READ_DONE;
                            else                                            next_state = NOP;

            TRCD        : if(wr_reg)                                        next_state = WRITE;
                            else if(rd_reg)                                 next_state = READ;
            
            TRP         :                                                   next_state = IDLE;

            default:                                                        next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin : synchro_logic
        if ( rst )
			begin
				cs	        <= 1'b1;
				ras	        <= 1'b1;
				cas	        <= 1'b1;
				we_sdram	<= 1'b1;
				bank_adr	<= bank_address;
				adr         <= 12'd0;
				dqm		    <= 2'b0;
			end
		else
			if ( ( next_state == NOP ) | ( next_state == IDLE ) | ( next_state == TRCD ) ) //nop
				begin
					cs						<= 1'b0;
					ras						<= 1'b1;
					cas						<= 1'b1;
					we_sdram				<= 1'b1;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b00;				
				end
        else if ( next_state == SET_MODE )
				begin
					cs						<= 1'b0;
					ras						<= 1'b0;
					cas						<= 1'b0;
					we_sdram				<= 1'b0;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_010_0_111; 	
					dqm						<= 2'b00;					
				end	
			else if (  next_state == ACTIVE  )
				begin
					cs						<= 1'b0;
					ras						<= 1'b0;
					cas						<= 1'b1;
					we_sdram				<= 1'b1;
                        if (wr_reg) begin
                            adr             <= adr_wr_cnt;
                            bank_adr        <= bank_address;
                        end else 
                        if (rd_reg) begin
                            adr             <= adr_rd_cnt;
                            bank_adr        <= bank_address;
                        end else begin
                            adr             <= 12'd0;
                            bank_adr        <= bank_address;                            
                        end
					dqm						<= 2'b00;
				end	
			else if ( next_state == READ )
				begin 
                    cs						<= 1'b0;
					ras						<= 1'b1;
					cas						<= 1'b0;
					we_sdram				<= 1'b1;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b00;					
				end					
			else if ( next_state == WRITE )
				begin 
                    cs						<= 1'b0;
					ras						<= 1'b1;
					cas						<= 1'b0;
					we_sdram				<= 1'b0;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b00;					
				end		
			else if ( ( next_state == PRECHARDGE ) | ( next_state == TRP ) )
				begin 
                    cs						<= 1'b0;
					ras						<= 1'b0;
					cas						<= 1'b1;
					we_sdram				<= 1'b0;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b00;					
				end					
			else if ( next_state == PALL ) 
				begin
                    cs						<= 1'b0;
					ras						<= 1'b0;
					cas						<= 1'b1;
					we_sdram				<= 1'b0;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b1;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b11;			
				end		
			else
				begin
                    cs						<= 1'b0;
					ras						<= 1'b1;
					cas						<= 1'b1;
					we_sdram				<= 1'b1;
					bank_adr				<= bank_address;
					adr[10]					<= 1'b0;
					{adr[11],adr[9:0]}	    <= 11'b000__000_000_0_000; 	
					dqm						<= 2'b00;					
				end
    end

    // assign sdram_data_inout = ( state == WRITE ) | ( ( state == NOP ) & ( cnt_burst != 1'b0 ) & wr_reg )  ? write_in_sdram_data : 16'hZ;
    assign sdram_data_inout = (( state == WRITE ) || cnt_burst != 8'h0 )? ((pipe_data_vld [3]) ? pipe_data_in [3] : 16'hF0F0) : 16'hZ;

    always @( posedge clk or posedge rst ) begin
		if ( rst )
				read_strobe	<= '0;
		else if ( state == READ_DONE )
				read_strobe	<= '1;		
        else if (state == PRECHARDGE)
                read_strobe <= '0;
    end

    always @( posedge clk or posedge rst ) begin
		if ( rst )
				real_data_from_srame	<= '0;
		else if ( (state == READ_DONE) || read_strobe)
				real_data_from_srame	<= sdram_data_inout;		
    end
    assign data_from_sram = real_data_from_srame;

endmodule