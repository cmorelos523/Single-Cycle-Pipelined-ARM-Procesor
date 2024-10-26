/* arm is the spotlight of the show and contains the bulk of the datapath and control logic. This module is split into two parts, the datapath and control. 
*/

// clk - system clock
// rst - system reset
// Instr - incoming 32 bit instruction from imem, contains opcode, condition, addresses and or immediates
// ReadData - data read out of the dmem
// WriteData - data to be written to the dmem
// MemWrite - write enable to allowed WriteData to overwrite an existing dmem word
// PC - the current program count value, goes to imem to fetch instruciton
// ALUResult - result of the ALU operation, sent as address to the dmem

module arm (
    input  logic        clk, rst,
    input  logic [31:0] InstrF,
    input  logic [31:0] ReadDataM,
    output logic [31:0] WriteDataM, 
    output logic [31:0] PCF, ALUOutM,
    output logic        MemWriteM
);

    // datapath buses and signals
    logic [31:0] PC, PCPrime, PCPlus4F, PCPlus8D; // pc signals
    logic [31:0] ALUResultM, ALUResultE;
	 logic [ 3:0] RA1D, RA2D, RA1E, RA2E;                  			// regfile input addresses
	 logic [31:0] RD1, RD2, RD1E, RD2E;                  			// raw regfile outputs
    logic [ 3:0] ALUFlags;                  // alu combinational flag outputs
    logic [31:0] ExtImm, ExtImmE;        // immediate and alu inputs 
    logic [31:0] ResultW;                    // computed or fetched value to be written into regfile or pc
	 logic [ 3:0] FlagsPrime, FlagsE;						  // stores the alu flags from the most recent cmp instruction
	 logic [31:0] ALUOutW;
	 logic [31:0] WriteDataE;
	 logic [31:0] ReadDataW;
	 
	 // intermediate registers
	 logic [31:0] InstrD;
	 logic [31:0] SrcAE, SrcBE;
	 logic [3:0] WA3E, WA3M, WA3W;
	 

    // control signals
    logic PCSrcD, PCSrcE, PCSrcM, PCSrcW;
	 logic RegWriteD, RegWriteE, RegWriteM, RegWriteW;
	 logic MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;
	 logic MemWriteD, MemWriteE, MemWriteW;
	 logic BranchD, BranchE;
	 logic ALUSrcD, ALUSrcE;
	 logic FlagWriteD, FlagWriteE;
	 logic BranchTakenE;
	 logic CondExE;
    logic [1:0] ALUControlD, ALUControlE;
	 logic [1:0] RegSrcD;
	 logic [1:0] ImmSrcD;
	 logic [3:0] CondE;
	 
	 // Hazard Signals
	 logic StallF, StallD, FlushD, FlushE;
	 logic [1:0] ForwardAE, ForwardBE;
	 logic Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W, Match_12D_E, ldrStallD;
	 logic PCWrPendingF;


    /* The datapath consists of a PC as well as a series of muxes to make decisions about which data words to pass forward and operate on. It is 
    ** noticeably missing the register file and alu, which you will fill in using the modules made in lab 1. To correctly match up signals to the 
    ** ports of the register file and alu take some time to study and understand the logic and flow of the datapath.
    */
    //-------------------------------------------------------------------------------
    //                                      DATAPATH
    //-------------------------------------------------------------------------------

	 assign PC = PCSrcW ? ResultW : PCPlus8D;
    assign PCPrime = BranchTakenE ? ALUResultE : PC;  // mux, use either default or newly computed value
    assign PCPlus4F = PCF + 'd4;                		// default value to access next instruction
    assign PCPlus8D = PCPlus4F;             				// value read when reading from reg[15]

    // update the PC, at rst initialize to 0
    always_ff @(posedge clk) begin
        if (rst) 				PCF <= '0;
        else if (~StallF)	PCF <= PCPrime;
    end

    // determine the register addresses based on control signals
    // RegSrc[0] is set if doing a branch instruction
    // RefSrc[1] is set when doing memory instructions
    assign RA1D = RegSrcD[0] ? 4'd15      : InstrD[19:16];
    assign RA2D = RegSrcD[1] ? InstrD[15:12] : InstrD[3:0];

    // Instantiates a register file module with the same clock, a write enable that is connected to RegWrite,
	 //   the data being written comes from the result, the address is found in the instruction, the 
	 //   addresses come from the muxes powered by the RegSrc signal, and the read data is outputted
    reg_file u_reg_file (
        .clk(~clk)      , 
        .wr_en(RegWriteW), 
        .write_data(ResultW), 
        .write_addr(WA3W), 
        .read_addr1(RA1D), 
        .read_addr2(RA2D), 
        .read_data1(RD1), 
        .read_data2(RD2)
    );

    // two muxes, put together into an always_comb for clarity
    // determines which set of instruction bits are used for the immediate
    always_comb begin
        if      (ImmSrcD == 'b00) ExtImm = {{24{InstrD[7]}},InstrD[7:0]};          // 8 bit immediate - reg operations
        else if (ImmSrcD == 'b01) ExtImm = {20'b0, InstrD[11:0]};                  // 12 bit immediate - mem operations
        else                      ExtImm = {{6{InstrD[23]}}, InstrD[23:0], 2'b00}; // 24 bit immediate - branch operation
    end

    // WriteData and SrcA are direct outputs of the register file, wheras SrcB is chosen between reg file output and the immediate
	always_comb begin
		if (ForwardAE == 2'b00) 		SrcAE = RD1E;
		else if (ForwardAE == 2'b01) 	SrcAE = ResultW;
		else if (ForwardAE == 2'b10) 	SrcAE = ALUOutM;
		else 									SrcAE = '0;
	end
	
	always_comb begin
		if (ForwardBE == 2'b00) 		WriteDataE = RD2E;
		else if (ForwardBE == 2'b01) 	WriteDataE = ResultW;
		else if (ForwardBE == 2'b10) 	WriteDataE = ALUOutM;
		else 									WriteDataE = '0;
	end
	
	assign SrcBE = ALUSrcE ? ExtImmE : WriteDataE;

    // Instantiates an Arithmetic Logic Unit. The inputs are SrcA and SrcB, where SrcA is from the RD1 and SrcB is from the mux
	 //   powered by the ALUSrc signal. The result is saved as ALUResult. The control signals are inputted into this and the flags
	 //   are outputted
    alu u_alu (
        .a(SrcAE), 
        .b(SrcBE),
        .ALUControl(ALUControlE),
        .Result(ALUResultE),
        .ALUFlags   
    );

	 // Pipeline registers
	 // 1st pipeline after Intruction Memory
	 always_ff @(posedge clk) begin
		if (rst || FlushD)	InstrD <= '0;
		else if (~StallD) 	InstrD <= InstrF;
			
	 end
	 // 2nd pipeline after Register File
	 always_ff @(posedge clk) begin
		if (rst || FlushE) begin
			PCSrcE      <= 0;
			RegWriteE   <= 0;
         MemtoRegE   <= 0; 
         MemWriteE   <= 0; 
			ALUControlE <= 'b00;
			BranchE     <= '0;
         ALUSrcE     <= 0;
			FlagWriteE  <= '0;
			CondE	      <= '0;
			FlagsE      <= '0;
			RA1E			<= '0;
			RA2E			<= '0;
			RD1E        <= '0;
			RD2E        <= '0;
			WA3E        <= '0;
			ExtImmE     <= '0;
		end else begin	
			PCSrcE      <= PCSrcD;
			RegWriteE   <= RegWriteD;
         MemtoRegE   <= MemtoRegD; 
         MemWriteE   <= MemWriteD;
			ALUControlE <= ALUControlD;
			BranchE     <= BranchD;
         ALUSrcE     <= ALUSrcD;
			FlagWriteE  <= FlagWriteD;
			CondE	      <= InstrD[31:28];	
			FlagsE      <= FlagsPrime;
			RA1E			<= RA1D;
			RA2E			<= RA2D;
			RD1E        <= (RA1D == 'd15) ? PCPlus8D : RD1;
			RD2E        <= (RA2D == 'd15) ? PCPlus8D : RD2;
			WA3E        <= InstrD[15:12];
			ExtImmE     <= ExtImm;
		end
	end
	
	// 3rd pipeline after ALU
	always_ff @(posedge clk) begin
		if (rst) begin
			PCSrcM <= 0;
			RegWriteM <= 0;
			MemtoRegM <= 0;
			MemWriteM <= 0;
			ALUOutM <= '0;
			WriteDataM <= '0;
			WA3M <= '0;
		end else begin
			PCSrcM <= PCSrcE & CondExE;
			RegWriteM <= RegWriteE & CondExE;
			MemtoRegM <= MemtoRegE;
			MemWriteM <= MemWriteE & CondExE;
			ALUOutM <= ALUResultE;
			WriteDataM <= WriteDataE;
			WA3M <= WA3E;
		end
	end
	
	// 4th pipeline after Data Memory
	always_ff @(posedge clk) begin
		if (rst) begin
			PCSrcW <= 0;
			RegWriteW <= 0;
			MemtoRegW <= 0;
			ReadDataW <= '0;
			ALUOutW <= '0;
			WA3W <= '0;
		end
		else begin
			PCSrcW <= PCSrcM;
			RegWriteW <= RegWriteM;
			MemtoRegW <= MemtoRegM;
			ReadDataW <= ReadDataM;
			ALUOutW <= ALUOutM;
			WA3W <= WA3M;
		end
	end
	
	assign BranchTakenE = BranchE & CondExE;
	
	assign ResultW = MemtoRegW ? ReadDataW : ALUOutW;
	

    /* The control conists of a large decoder, which evaluates the top bits of the instruction and produces the control bits 
    ** which become the select bits and write enables of the system. The write enables (RegWrite, MemWrite and PCSrc) are 
    ** especially important because they are representative of your processors current state. 
    */
    //-------------------------------------------------------------------------------
    //                                      CONTROL
    //-------------------------------------------------------------------------------
    
    always_comb begin
        casez (InstrD[27:20])

            // ADD (Imm or Reg)
            8'b00?_0100_0 : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we add
                PCSrcD    = 0;
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b00;
					 FlagWriteD = 0;
					 BranchD = 0;
            end

            // SUB (Imm or Reg) Or CMP
            8'b00?_0010_? : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we sub
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b01;
					 FlagWriteD = InstrD[20] ? 1 : 0; // for reusing SUB as a CMP. Only on if the instruction is a CMP, off otherwise
					 BranchD = 0;
            end

            // AND
            8'b000_0000_0 : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b10;  
					 FlagWriteD = 0;
					 BranchD = 0;
            end

            // ORR
            8'b000_1100_0 : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b11;
					 FlagWriteD = 0;
					 BranchD = 0;
            end

            // LDR
            8'b010_1100_1 : begin
                PCSrcD    = 0; 
                MemtoRegD = 1; 
                MemWriteD = 0; 
                ALUSrcD   = 1;
                RegWriteD = 1;
                RegSrcD   = 'b10;    // msb doesn't matter
                ImmSrcD   = 'b01; 
                ALUControlD = 'b00;  // do an add
					 FlagWriteD = 0;
					 BranchD = 0;

            end

            // STR
            8'b010_1100_0 : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; // doesn't matter
                MemWriteD = 1; 
                ALUSrcD   = 1;
                RegWriteD = 0;
                RegSrcD   = 'b10;    // msb doesn't matter
                ImmSrcD   = 'b01; 
                ALUControlD = 'b00;  // do an add
					 FlagWriteD = 0;
					 BranchD = 0;
            end

            // B
            8'b1010_???? : begin
					PCSrcD = 1;
					MemtoRegD = 0;
               MemWriteD = 0; 
               ALUSrcD   = 1;
               RegWriteD = 0;
               RegSrcD   = 'b01;
               ImmSrcD   = 'b10; 
               ALUControlD = 'b00;  // do an add
					FlagWriteD = 0;
					BranchD = 1;
            end

			default: begin
					PCSrcD    = 0; 
               MemtoRegD = 0; // doesn't matter
               MemWriteD = 0; 
               ALUSrcD   = 0;
               RegWriteD = 0;
               RegSrcD   = 'b00;
               ImmSrcD   = 'b00; 
               ALUControlD = 'b00; // do an add
					FlagWriteD = 0;
				   BranchD = 0;

			end
        endcase
    end
	 
	//-------------------------------------------------------------------------------
	//                                    COND UNIT
   //-------------------------------------------------------------------------------
		
	// mux for updating the flag register when flag write is on
	 always_comb begin
		  if (FlagWriteE)
				FlagsPrime = ALUFlags;
			else 
				FlagsPrime = '0;
	 end
	
	 always_comb begin
		case(CondE)
			4'b1110 : CondExE = 1; // Unconditional
			4'b0000 : CondExE = FlagsE[2]; // Equal
			4'b0001 : CondExE = ~FlagsE[2]; // Not equal
			4'b1010 : CondExE = ~(FlagsE[3] ^ FlagsE[0]); // Greater than or equal to
			4'b1100 : CondExE = ~FlagsE[2] & ~(FlagsE[3] ^ FlagsE[0]); // Greater than
			4'b1101 : CondExE = FlagsE[2] | (FlagsE[3] ^ FlagsE[0]); // Less than or equal to
			4'b1011 : CondExE = (FlagsE[3] ^ FlagsE[0]); // Less than
			default : CondExE = 0;
		endcase
	end
		
	//-------------------------------------------------------------------------------
	//                                    HAZARD UNIT
   //-------------------------------------------------------------------------------
	
	// Data Forwarding Hazards
	always_comb begin
		// Match signals
		Match_1E_M = (RA1E == WA3M);
		Match_2E_M = (RA2E == WA3M);
		
		Match_1E_W = (RA1E == WA3W);
		Match_2E_W = (RA2E == WA3W);
		
		// ForwardAE signal
		if (Match_1E_M && RegWriteM) 			ForwardAE = 10;
		else if (Match_1E_W && RegWriteW) 	ForwardAE = 01;
		else 											ForwardAE = 00;
		
		// ForwardBE signal
		if (Match_2E_M && RegWriteM) 			ForwardBE = 10;
		else if (Match_2E_W && RegWriteW) 	ForwardBE = 01;
		else 											ForwardBE = 00;
		
	end
	
	// Stalling Hazards
	always_comb begin
		Match_12D_E = (RA1D == WA3E) | (RA2D == WA3E);
		ldrStallD = Match_12D_E & MemtoRegE;
		
		PCWrPendingF = PCSrcD | PCSrcE | PCSrcM;
		StallF = ldrStallD | PCWrPendingF;
		FlushD = PCWrPendingF | PCSrcW | BranchTakenE;
		FlushE = ldrStallD | BranchTakenE;
		StallD = ldrStallD;
	end

endmodule
