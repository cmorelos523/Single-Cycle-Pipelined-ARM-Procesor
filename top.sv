/* top is a structurally made toplevel module. It consists of 3 instantiations, as well as the signals that link them. 
** It is almost totally self-contained, with no outputs and two system inputs: clk and rst. clk represents the clock 
** the system runs on, with one instruction being read and executed every cycle. rst is the system reset and should 
** be run for at least a cycle when simulating the system.
*/

// clk - system clock
// rst - system reset. Technically unnecessary
module top(
    input logic clk, rst
);
    
    // processor io signals
    logic [31:0] InstrF;
    logic [31:0] ReadDataM;
    logic [31:0] WriteDataM;
    logic [31:0] PCF, ALUOutM;
    logic        MemWriteM;

    // our single cycle arm processor
    arm processor (
        .clk        (clk        ), 
        .rst        (rst        ),
        .InstrF     (InstrF     ),
        .ReadDataM  (ReadDataM   ),
        .WriteDataM (WriteDataM  ), 
        .PCF        (PCF         ), 
        .ALUOutM    (ALUOutM    ),
        .MemWriteM  (MemWriteM  )
    );

    // instruction memory
    // contained machine code instructions which instruct processor on which operations to make
    // effectively a rom because our processor cannot write to it
    imem imemory (
        .addr   (PCF     ),
        .instr  (InstrF  )
    );

    // data memory
    // containes data accessible by the processor through ldr and str commands
    dmem dmemory (
        .clk     (clk       ), 
        .wr_en   (MemWriteM  ),
        .addr    (ALUOutM ),
        .wr_data (WriteDataM ),
        .rd_data (ReadDataM  )
    );


endmodule

// processor instantion. Within is the processor as well as imem and dmem
module top_tb();
	
	logic clk, rst;
	
	top cpu (.clk(clk), .rst(rst));

    initial begin
        // start with a basic reset
        rst = 1; @(posedge clk);
        rst <= 0; @(posedge clk);

        // repeat for 50 cycles. Not all 50 are necessary, however a loop at the end of the program will keep anything weird from happening
        repeat(70) @(posedge clk);

        // basic checking to ensure the right final answer is achieved. These DO NOT prove your system works. A more careful look at your 
        // simulation and code will be made.

        // task 1:
       // assert(cpu.processor.u_reg_file.register[8] == 32'd11) $display("Task 1 Passed");
         //else                                                   $display("Task 1 Failed");

        // task 2:
        //assert(cpu.processor.u_reg_file.register[8] == 32'd1)  $display("Task 2 Passed");
        //else                                                 $display("Task 2 Failed");

        $stop;
    end

endmodule
