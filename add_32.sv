/*
 * Alejandro Hernandez-Farias
 * Carlos A Morelos-Escalera
 * 4/14/2024
 * EE 469
 * Lab 2
 *
 * Adds two 32-bit numbers together
 * The Cin value is for using this adder as a subtractor, where either a or b
 *   is inverted on input and the cin value is 1, otherwise cin should be 0
 * The cout_31 value is from the overall 32-bit addition, so 1 if the addition
 *   on the 31st bits from a and b has a carry out
 * If the addition of A and B (and Cin) can't be represented in 32 bits, 
 *   Cout will show the extra bit
 * Input ports:
 *		a - 32-bits, the first number to be added
 *		b - 32-bits, the second number to be added
 *		cin - 1-bit, carry in bit for using this adder as a subtractor
 *	Output ports:
 *		sum_32 - 32-bits, the sum of A and B
 *		cout_31 - 1-bit, the extra bit value from adding A and B (and cin)
 */
module add_32 (a, b, cin, sum_32, cout_31);

	// Variable declaration
		input logic [31:0] a, b;
		input logic cin;
		output logic cout_31;
		output logic [31:0] sum_32;
	
	// Intermediate variables
		logic c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15,
				c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30;
	
	// Creates instantiations of fullAdder
	// Each instantiation is for adding up one bit of the 32-bit a and b values at a time
	// Carries the extra bits from each addition from the lesser to more significant bit
	// Saves the sum of each bit addition to the corresponding bit value of the 32-bit sum
	// The Cout of the 31st bit is outputted as the overall carry out of the 32-bit number
		fullAdder fa0 (.A(a[0]), .B(b[0]), .Cin(cin), .Sum(sum_32[0]), .Cout(c0));
		fullAdder fa1 (.A(a[1]), .B(b[1]), .Cin(c0), .Sum(sum_32[1]), .Cout(c1));
		fullAdder fa2 (.A(a[2]), .B(b[2]), .Cin(c1), .Sum(sum_32[2]), .Cout(c2));
		fullAdder fa3 (.A(a[3]), .B(b[3]), .Cin(c2), .Sum(sum_32[3]), .Cout(c3));
		fullAdder fa4 (.A(a[4]), .B(b[4]), .Cin(c3), .Sum(sum_32[4]), .Cout(c4));
		fullAdder fa5 (.A(a[5]), .B(b[5]), .Cin(c4), .Sum(sum_32[5]), .Cout(c5));
		fullAdder fa6 (.A(a[6]), .B(b[6]), .Cin(c5), .Sum(sum_32[6]), .Cout(c6));
		fullAdder fa7 (.A(a[7]), .B(b[7]), .Cin(c6), .Sum(sum_32[7]), .Cout(c7));
		fullAdder fa8 (.A(a[8]), .B(b[8]), .Cin(c7), .Sum(sum_32[8]), .Cout(c8));
		fullAdder fa9 (.A(a[9]), .B(b[9]), .Cin(c8), .Sum(sum_32[9]), .Cout(c9));
		fullAdder fa10 (.A(a[10]), .B(b[10]), .Cin(c9), .Sum(sum_32[10]), .Cout(c10));
		fullAdder fa11 (.A(a[11]), .B(b[11]), .Cin(c10), .Sum(sum_32[11]), .Cout(c11));
		fullAdder fa12 (.A(a[12]), .B(b[12]), .Cin(c11), .Sum(sum_32[12]), .Cout(c12));
		fullAdder fa13 (.A(a[13]), .B(b[13]), .Cin(c12), .Sum(sum_32[13]), .Cout(c13));
		fullAdder fa14 (.A(a[14]), .B(b[14]), .Cin(c13), .Sum(sum_32[14]), .Cout(c14));
		fullAdder fa15 (.A(a[15]), .B(b[15]), .Cin(c14), .Sum(sum_32[15]), .Cout(c15));
		fullAdder fa16 (.A(a[16]), .B(b[16]), .Cin(c15), .Sum(sum_32[16]), .Cout(c16));
		fullAdder fa17 (.A(a[17]), .B(b[17]), .Cin(c16), .Sum(sum_32[17]), .Cout(c17));
		fullAdder fa18 (.A(a[18]), .B(b[18]), .Cin(c17), .Sum(sum_32[18]), .Cout(c18));
		fullAdder fa19 (.A(a[19]), .B(b[19]), .Cin(c18), .Sum(sum_32[19]), .Cout(c19));
		fullAdder fa20 (.A(a[20]), .B(b[20]), .Cin(c19), .Sum(sum_32[20]), .Cout(c20));
		fullAdder fa21 (.A(a[21]), .B(b[21]), .Cin(c20), .Sum(sum_32[21]), .Cout(c21));
		fullAdder fa22 (.A(a[22]), .B(b[22]), .Cin(c21), .Sum(sum_32[22]), .Cout(c22));
		fullAdder fa23 (.A(a[23]), .B(b[23]), .Cin(c22), .Sum(sum_32[23]), .Cout(c23));
		fullAdder fa24 (.A(a[24]), .B(b[24]), .Cin(c23), .Sum(sum_32[24]), .Cout(c24));
		fullAdder fa25 (.A(a[25]), .B(b[25]), .Cin(c24), .Sum(sum_32[25]), .Cout(c25));
		fullAdder fa26 (.A(a[26]), .B(b[26]), .Cin(c25), .Sum(sum_32[26]), .Cout(c26));
		fullAdder fa27 (.A(a[27]), .B(b[27]), .Cin(c26), .Sum(sum_32[27]), .Cout(c27));
		fullAdder fa28 (.A(a[28]), .B(b[28]), .Cin(c27), .Sum(sum_32[28]), .Cout(c28));
		fullAdder fa29 (.A(a[29]), .B(b[29]), .Cin(c28), .Sum(sum_32[29]), .Cout(c29));
		fullAdder fa30 (.A(a[30]), .B(b[30]), .Cin(c29), .Sum(sum_32[30]), .Cout(c30));
		fullAdder fa31 (.A(a[31]), .B(b[31]), .Cin(c30), .Sum(sum_32[31]), .Cout(cout_31));
				
endmodule // add_32



/* Tests the add_32 module on its behavior with possible combinations of input */
module add_32_tb();

	// Variable declaration
		logic [31:0] a, b, sum_32;
		logic cin, cout_31;
		
	// Instantiates a fullAdder module with the combinations below
		add_32 dut (.a, .b, .cin, .sum_32, .cout_31);
		
	// Combinations of inputs
		initial begin
			// Addition
			cin = 0; a = 32'h00000000; b = 32'h00000000; #10; // Zero add
						a = 32'h00000000; b = 32'hFFFFFFFF; #10; // Boundary add
						a = 32'h00000001; b = 32'hFFFFFFFF; #10; // Overflow add
						a = 32'h000000FF; b = 32'h00000001; #10; // Carry in add
						a = 32'h000000FF; b = 32'hFFFFFF00; #10; // Boundary add
								  
			// Subtraction (as inputted from ALU with b inverted)
			cin = 1; a = 32'h00000000; b = ~32'h00000000; #10;
						a = 32'h00000000; b = ~32'hFFFFFFFF; #10;
						a = 32'h00000001; b = ~32'h00000001; #10;
						a = 32'h00000100; b = ~32'h00000001; #10;
			
		end // initial
	
endmodule // add_32_tb
