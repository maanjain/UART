`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2025 12:51:45
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_tx(
    input clk,
    input rst_n,
    input start,
    input [7:0] data,
    output reg rs232_tx,
    output reg done
);

reg [7:0] r_data;
reg state;
reg [12:0] baud_cnt;
reg bit_flag;
reg [3:0] bit_cnt;

// Baud rate counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 'd0;
    else if (state) begin
        if (baud_cnt == 'd30)
            baud_cnt <= 'd0;
        else
            baud_cnt <= baud_cnt + 1'b1;
    end
    else
        baud_cnt <= 'd0;
end

// Bit flag generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_flag <= 1'b0;
    else if (baud_cnt == 'd15)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

// State control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 1'b0;
        r_data <= 'd0;
    end
    else if (start) begin
        state <= 1'b1;
        r_data <= data;
    end
    else if (done) begin
        state <= 1'b0;
    end
end

// Bit counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_cnt <= 'd0;
    else if (state && bit_flag) begin
        if (bit_cnt == 'd10)
            bit_cnt <= 'd0;
        else
            bit_cnt <= bit_cnt + 1'b1;
    end
    else
        bit_cnt <= bit_cnt;
end

// Data transmission
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rs232_tx <= 1'b1;
    else if (state) begin
        if (bit_flag) begin
            case(bit_cnt)
                4'd0: rs232_tx <= 1'b0;         // Start bit
                4'd1: rs232_tx <= r_data[0];    // LSB
                4'd2: rs232_tx <= r_data[1];
                4'd3: rs232_tx <= r_data[2];
                4'd4: rs232_tx <= r_data[3];
                4'd5: rs232_tx <= r_data[4];
                4'd6: rs232_tx <= r_data[5];
                4'd7: rs232_tx <= r_data[6];
                4'd8: rs232_tx <= r_data[7];    // MSB
                4'd9: rs232_tx <= 1'b1;         // Stop bit
                default: rs232_tx <= 1'b1;
            endcase
        end
    end
    else
        rs232_tx <= 1'b1;
end

// Done signal generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        done <= 1'b0;
    else if (bit_cnt == 'd10 && bit_flag)
        done <= 1'b1;
    else
        done <= 1'b0;
end

endmodule
module uart_rx(
    input clk,
    input rst_n,
    input rs232,
    output reg [7:0] rx_data,
    output reg done
);

reg rs232_t, rs232_t1, rs232_t2;
reg [12:0] baud_cnt;
reg [3:0] bit_cnt;
reg bit_flag;
reg state;
reg start_flag;

// Metastability protection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rs232_t <= 1'b1;
        rs232_t1 <= 1'b1;
        rs232_t2 <= 1'b1;
    end
    else begin
        rs232_t <= rs232;
        rs232_t1 <= rs232_t;
        rs232_t2 <= rs232_t1;
    end
end

// Start bit detection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_flag <= 1'b0;
    else if (!state && !rs232_t2 && rs232_t1)
        start_flag <= 1'b1;
    else
        start_flag <= 1'b0;
end

// State control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= 1'b0;
    else if (start_flag)
        state <= 1'b1;
    else if (bit_cnt == 'd9 && bit_flag)
        state <= 1'b0;
end

// Baud rate counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 'd0;
    else if (state) begin
        if (baud_cnt == 'd30)
            baud_cnt <= 'd0;
        else
            baud_cnt <= baud_cnt + 1'b1;
    end
    else
        baud_cnt <= 'd0;
end

// Bit flag generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_flag <= 1'b0;
    else if (baud_cnt == 'd15)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

// Bit counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_cnt <= 'd0;
    else if (state && bit_flag) begin
        if (bit_cnt == 'd9)
            bit_cnt <= 'd0;
        else
            bit_cnt <= bit_cnt + 1'b1;
    end
    else if (!state)
        bit_cnt <= 'd0;
end

// Data reception
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_data <= 'd0;
    else if (state && bit_flag) begin
        case(bit_cnt)
            4'd1: rx_data[0] <= rs232_t2;
            4'd2: rx_data[1] <= rs232_t2;
            4'd3: rx_data[2] <= rs232_t2;
            4'd4: rx_data[3] <= rs232_t2;
            4'd5: rx_data[4] <= rs232_t2;
            4'd6: rx_data[5] <= rs232_t2;
            4'd7: rx_data[6] <= rs232_t2;
            4'd8: rx_data[7] <= rs232_t2;
            default: rx_data <= rx_data;
        endcase
    end
end

// Done signal generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        done <= 1'b0;
    else if (bit_cnt == 'd9 && bit_flag)
        done <= 1'b1;
    else
        done <= 1'b0;
end

endmodule


module uart_rx(
    input clk,
    input rst_n,
    input rs232,
    output reg [7:0] rx_data,
    output reg done
);

reg rs232_t, rs232_t1, rs232_t2;
reg [12:0] baud_cnt;
reg [3:0] bit_cnt;
reg bit_flag;
reg state;
reg start_flag;

// Metastability protection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rs232_t <= 1'b1;
        rs232_t1 <= 1'b1;
        rs232_t2 <= 1'b1;
    end
    else begin
        rs232_t <= rs232;
        rs232_t1 <= rs232_t;
        rs232_t2 <= rs232_t1;
    end
end

// Start bit detection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_flag <= 1'b0;
    else if (!state && !rs232_t2 && rs232_t1)
        start_flag <= 1'b1;
    else
        start_flag <= 1'b0;
end

// State control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= 1'b0;
    else if (start_flag)
        state <= 1'b1;
    else if (bit_cnt == 'd9 && bit_flag)
        state <= 1'b0;
end

// Baud rate counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 'd0;
    else if (state) begin
        if (baud_cnt == 'd30)
            baud_cnt <= 'd0;
        else
            baud_cnt <= baud_cnt + 1'b1;
    end
    else
        baud_cnt <= 'd0;
end

// Bit flag generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_flag <= 1'b0;
    else if (baud_cnt == 'd15)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

// Bit counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_cnt <= 'd0;
    else if (state && bit_flag) begin
        if (bit_cnt == 'd9)
            bit_cnt <= 'd0;
        else
            bit_cnt <= bit_cnt + 1'b1;
    end
    else if (!state)
        bit_cnt <= 'd0;
end

// Data reception
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_data <= 'd0;
    else if (state && bit_flag) begin
        case(bit_cnt)
            4'd1: rx_data[0] <= rs232_t2;
            4'd2: rx_data[1] <= rs232_t2;
            4'd3: rx_data[2] <= rs232_t2;
            4'd4: rx_data[3] <= rs232_t2;
            4'd5: rx_data[4] <= rs232_t2;
            4'd6: rx_data[5] <= rs232_t2;
            4'd7: rx_data[6] <= rs232_t2;
            4'd8: rx_data[7] <= rs232_t2;
            default: rx_data <= rx_data;
        endcase
    end
end

// Done signal generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        done <= 1'b0;
    else if (bit_cnt == 'd9 && bit_flag)
        done <= 1'b1;
    else
        done <= 1'b0;
end

endmodule