/*
 * Alejandro Hernandez-Farias
 * Carlos A Morelos-Escalera
 * 4/14/2024
 * EE 469
 * Lab 2
 *
 * This Arithmetic Logic Unit has the ability to add, subtract, AND, or OR
 *	  two numbers together based on the ALUControl signal where:
 *	    00 -> adds a and b together
 *		 01 -> subtracts b from a
 *     10 -> performs a AND b
 *     11 -> performs a OR b
 * This ALU saves resources by reusing the built-in adder as a subtractor by
 *   adding a with the negative of b
 * This ALU has alerts on the result where:
 *		 3rd bit is on -> the result is negative
 *		 2nd bit is on -> the result is zero
 *		 1st bit is on -> the adder produced a carry out
 *     0th bit is on -> the adder produced an overflow
 *   The ALUFlags can produce multiple alerts based on which bits are 1
 * Input ports:
 *		a - 32-bits, the first number to be operated on
 *		b - 32-bits, the second number to be operated on
 *		ALUControl - 2-bits, control signal that designates desired operation on
 *						 a and b
 *	Output ports:
 *		Result - 32-bits, the result of the operation performed on a and b
 *		ALUFlags - 4-bits, alert based on the outcome of the operation
 *					  performed on a and b
 */
module alu (a, b, ALUControl, Result, ALUFlags);

	// Variable declaration
		input logic [31:0] a, b;
		input logic [1:0] ALUControl;
		output logic [31:0] Result;
		output logic [3:0] ALUFlags;
	
	// Intermediate variables
		logic cout_31;
		logic [31:0] b_mod, sum_32;
	
	// Inverts b depending on if subtraction is desired
		always_comb begin
			if (ALUControl[0]) // Subtraction
				b_mod = ~b;
			else // Addition
				b_mod = b;
		end
	
	// Creates an instantiation of add_32
	// Adds a and b together
	// If the last bit of ALUControl is 1, it will use the adder as a subtractor by
	//   using the inverted value of b and adding 1 from the ALUControl signal
	// If the last bit of ALUControl is 0, it will use the adder as normal with a
	//   carry in value of 0
		add_32 add (.a, .b(b_mod), .cin(ALUControl[0]), .sum_32, .cout_31);
	
	// Control (MUX) signal for ALU to designate operation on inputs
	// If addition or subtraction is chosen, the value of the sum is assigned to the
	//   outputted Result
		always_comb begin
			if (ALUControl[1] == 1'b0) // Add or subtract
				Result = sum_32;
			else if (ALUControl == 2'b10) // AND
				Result = a & b;
			else // OR
				Result = a | b;
				
		end
	
	// Assign negative flag bit
		assign ALUFlags[3] = Result[31];
	
	// Assign zero flag bit
		assign ALUFlags[2] = Result == 32'b0;
	
	// Assign carry out flag bit
		assign ALUFlags[1] = cout_31 & ~ALUControl[1];
	
	// Assign overflow flag bit
		assign ALUFlags[0] = ~ALUControl[1] & (a[31] ^ sum_32[31]) & ~(a[31] ^ b[31] ^ ALUControl[0]);
	
endmodule // alu



/* Tests the alu module with various possible combinations of input */
module alu_tb();

	// Variable declaration
		logic [31:0] a, b, Result;
		logic [1:0] ALUControl;
		logic [3:0] ALUFlags;
		logic [103:0] testvectors [1000:0];
		
	// Instantiates a fullAdder module with the combinations below
		alu dut (.a, .b, .ALUControl, .Result, .ALUFlags);
		
	// Combinations of inputs
		initial begin
			// Read in test vectors from tv file
			$readmemh("alu.tv", testvectors);
			
			for (int i = 0; i < 16 ; i++) begin
				{ALUControl, a, b, Result, ALUFlags} = testvectors[i]; #10;
				
			end
			
		end // initial
	
endmodule // alu_tb
