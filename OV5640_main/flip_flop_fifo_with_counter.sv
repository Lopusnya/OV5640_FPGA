//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module flip_flop_fifo_with_counter
# (
    parameter width = 16, depth = 10
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [width - 1:0] write_data,
    output [width - 1:0] read_data,
    output               empty,
    output               full,
    output               almost_empty,
    output               locked
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth),
               counter_width = $clog2 (depth + 1);

    localparam max_ptr = pointer_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, rd_ptr;
    logic [counter_width - 1:0] cnt;

    logic [width - 1:0] data [0: depth - 1];

    logic almost_empty_r;

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            wr_ptr <= '0;
        else if (push)
            wr_ptr <= wr_ptr == max_ptr ? '0 : wr_ptr + 1'b1;

    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= '0;
            almost_empty_r <= '0;            
        end else if (pop)
                if ((rd_ptr > wr_ptr & ((rd_ptr - wr_ptr) > 2559)) || ((rd_ptr < wr_ptr) & (wr_ptr - rd_ptr > 640))) begin
                    rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
                    almost_empty_r <= '1;
                end else begin
                    rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
                    almost_empty_r <= '0;
                end
                // rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
    end
    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (push & ~ pop)
            cnt <= cnt + 1'b1;
        else if (pop & ~ push)
            cnt <= cnt - 1'b1;

    //------------------------------------------------------------------------

    logic lock;
    always_ff @( posedge clk or posedge rst ) begin : lck
        if(rst)
            lock <= 1'b0;
        else if(full)
            lock <= 1'b1;
        else if(empty)
            lock <= 1'b0;
    end

    //------------------------------------------------------------------------

    assign empty  = (cnt == '0);  // Same as "~| cnt"
    assign full   = (cnt == counter_width' (depth) );
    assign locked = lock;
    // assign almost_empty = almost_empty_r;

endmodule
