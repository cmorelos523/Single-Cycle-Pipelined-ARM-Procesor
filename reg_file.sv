// Carlos A. Morelos Escalera and Alejandro Hernandez-Farias
// 04/14/2024 
// EE469 
// Lab 2
// This program creates a register file

// This module creates a 2D array that represents a register file with 16 addresses, each with a 32bit
// word capacity
// Input ports:
//		* clk: the rate at which inputs are processed
//		* wr_en: Signal that enables writting into the register file
//		* write_data: 32bit word that stores the data being written in the register
//		* write_addr: 4bit signal storing the address to write to in the register
//		* read_addr1: 4bit signal storing one of the addresses to read from in the register
//		* read_addr2: 4bit signal storing one of the addresses to read from in the register
// Output ports:
//		* read_data1: 32bit word that stores the data in read_addr1
//		* read_data2: 32bit word that stores the data in read_addr2
module reg_file (clk, wr_en, write_data, write_addr, read_addr1, read_addr2, read_data1, read_data2);

	// Variable declaration
	input logic clk, wr_en;
	input logic [31:0] write_data;
	input logic [3:0] write_addr;
	input logic [3:0] read_addr1, read_addr2;
	output logic [31:0] read_data1, read_data2;
	
	// Internal logic, 2D array that represents the register file
	logic [15:0][31:0] register;
	
	// Sequential logic
	always_ff @(posedge clk) begin
		if (wr_en) begin
			register[write_addr] <= write_data;
		end
	end
	
	assign read_data1 = register[read_addr1];
	assign read_data2 = register[read_addr2];

endmodule

// Testbench module to simulate register behavior
module reg_file_tb();

	// Variable declaration
	logic clk, wr_en;
	logic [31:0] write_data;
	logic [3:0] write_addr;
	logic [3:0] read_addr1, read_addr2;
	logic [31:0] read_data1, read_data2;
	
	// reg_file module instantiation
	reg_file dut (.clk, .wr_en, .write_data, .write_addr, .read_addr1, .read_addr2, .read_data1, .read_data2);
	
	// Clock set up
	parameter clock_period = 100;

	initial begin
		clk <= 0;
		forever #(clock_period / 2) clk <= ~clk;
	 
	end
	 
	// User input simulation
	initial begin
		wr_en = 1'b0; write_data = 31'b0; write_addr = 4'b0;
		read_addr1 = 4'b1; read_addr2 = 4'b0;					@(posedge clk); // Setting inital state for input signals
																			@(posedge clk);
		write_data = 31'b1; write_addr = 4'b0001;				@(posedge clk); // Data not being written since wr_en is off
		wr_en = 1'b1;													@(posedge clk); // Write enable is on
																			@(posedge clk); // Test case 1: Data is available at read_data1 
																								 // after one cycle
		wr_en = 1'b0; read_addr2 = 4'b0100;						@(posedge clk); // write enable is off, read address is set to 4
		write_data = 31'b111; write_addr = 4'b0100;			@(posedge clk); // Data not being written since wr_en is off
		wr_en = 1'b1;													@(posedge clk); // Write enable is on
																			@(posedge clk); // Extra cycle to set the data
		wr_en = 1'b0;													@(posedge clk); // write enable is off
		read_addr1 = 4'b0100; read_addr2 = 4'b0001;			@(posedge clk); // Test case 2: Swap read addresses, read data also
																								 // changes in that same clock cycle for that addres
		wr_en = 1'b1;																		 // Write enable is on
		write_data = 31'b1011; write_addr = 4'b0101;			@(posedge clk); // Set address 9 to data = 1011
		write_data = 31'b1010; write_addr = 4'b0110;			@(posedge clk); // Set address 10 to data = 1010
		read_addr1 = 4'b0101;										@(posedge clk); // Point read_addr1 to address 9
		read_addr2 = 4'b0110;										@(posedge clk); // Point read_addr2 to address 10
		write_data = 31'b110; write_addr = 4'b0101;			@(posedge clk); // Update address 9 to data = 110
		write_data = 31'b010; write_addr = 4'b0110;			@(posedge clk); // Update address 10 to data = 010
															repeat(3)	@(posedge clk); // Test case 3: New data available one clock cycle after
																								 // data is updated in that same address
		$stop; // end simulation
	end
endmodule
	
	