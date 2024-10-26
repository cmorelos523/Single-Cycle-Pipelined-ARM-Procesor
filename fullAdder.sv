/*
 * Alejandro Hernandez-Farias
 * Carlos A Morelos-Escalera
 * 4/14/2024
 * EE 469
 * Lab 2
 *
 * Adds two bits together
 * The Cin value is added with A and B for combining fullAdder modules to add
 *   multi-bit numbers
 * If the addition of A and B (and Cin) can't be represented in one bit, 
 *   Cout will show the extra bit
 * Input ports:
 *		A - 1-bit, first bit to be added
 *		B - 1-bit, second bit to be added
 *		Cin - 1-bit, carry in bit (could be from another fullAdder)
 *	Output ports:
 *		Sum - 1-bit, the sum of A and B
 *		Cout - 1-bit, the extra bit value from adding A and B (and Cin)
 */
module fullAdder (A, B, Cin, Sum, Cout);

	// Variable declaration
		input logic A, B, Cin;
		output logic Sum, Cout;
	
	// Assign Sum and Cout outputs
		assign Sum = A ^ B ^ Cin;
		assign Cout = A & B | Cin & (A ^ B);
	
endmodule // fullAdder



/* Tests the fullAdder module on its behavior with all possible combinations
 *   of input
 */
module fullAdder_tb();

	// Variable declaration
		logic A, B, Cin, Sum, Cout;
		
	// Instantiates a fullAdder module with the combinations below
		fullAdder dut (.A, .B, .Cin, .Sum, .Cout);
		
	// Combinations of inputs
		integer i;
		initial begin
			for (i = 0; i < 2**3; i++) begin
				{A, B, Cin} = i; #10;
				
			end
			
		end // initial
	
endmodule // fullAdder_tb
