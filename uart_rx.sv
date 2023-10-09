module uart_rx #(
    parameter CLOCKS_PER_PULSE = 4,   // Number of clock cycles per pulse
    BITS_PER_WORD = 8,                // Number of bits per word
    W_OUT = 16                        // Width of the output data
)(
    input logic clk, rstn, rx,          // Clock, reset, and receive signal
    output logic m_valid,               // Data valid signal
    output logic [W_OUT-1:0] m_data    // Output data
);

localparam NUM_WORDS = W_OUT / BITS_PER_WORD;
enum {IDLE, START, DATA, END} state;     // UART receiver state machine states

// Counters to keep track of clock cycles and bits
logic [$clog2(CLOCKS_PER_PULSE) - 1:0] c_clocks;  // counting clocks
logic [$clog2(BITS_PER_WORD) - 1:0] c_bits;         // coumting the bits
logic [$clog2(NUM_WORDS) - 1:0] c_words;            // counting the received words 

// State Machine
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        {c_words, c_bits, c_clocks, m_valid, m_data} <= '0;  // Reset counters and signals
        state <= IDLE;  // Set state to IDLE
    end else begin
        m_valid <= 0;  // Reset data valid signal

        case (state)
            IDLE : if (rx == 0) 
                    state <= START;  // Transition to START state if start bit detected
            START: if (c_clocks == CLOCKS_PER_PULSE/2-1) begin
                    state <= DATA;  // Transition to DATA state after half of the pulse
                    c_clocks <= 0;  // Reset pulse counter
                end else
                    c_clocks <= c_clocks + 1;  // Increment pulse counter

            DATA : if (c_clocks == CLOCKS_PER_PULSE-1) begin
                    c_clocks <= 0;  // Reset pulse counter
                    m_data <= {rx, m_data[W_OUT-1:1]};  // Shift in received data
                    if (c_bits == BITS_PER_WORD-1) begin
                        state <= END;  // Transition to END state after receiving all data bits
                        c_bits <= 0;   // Reset bit counter
                        if (c_words == NUM_WORDS-1) begin
                            m_valid <= 1;  // Set data valid signal when all words received
                            c_words <= 0;  // Reset word counter
                        end else
                            c_words <= c_words + 1;  // Increment word counter
                    end else
                        c_bits <= c_bits + 1;  // Increment bit counter
                end else
                    c_clocks <= c_clocks + 1;  // Increment pulse counter

            END : if (c_clocks == CLOCKS_PER_PULSE-1) begin
                    state <= IDLE;  // Transition back to IDLE state after receiving stop bit
                    c_clocks <= 0;  // Reset pulse counter
                end else
                    c_clocks <= c_clocks + 1;  // Increment pulse counter
        endcase
    end
end

endmodule
