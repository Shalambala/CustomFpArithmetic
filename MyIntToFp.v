`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:14:34 01/28/2021 
// Design Name: 
// Module Name:    FpConvTop 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module	MyIntToFp	
#(	
	parameter	InWidth		=	32,
	parameter	ExpWidth	=	8,
	parameter	ManWidth	=	23,
	parameter	ExpConst	=	8'd127
)
(Clk_i,Rst_i,InData_i,InDataVal_i,OutData_o,OutDataVal_o);

//================================================================================
//	FUNCTIONS	

	function integer Log2;
	input integer value;
		begin
			Log2 = 0;
			while (value > 1) begin
				value   = value >> 1;
				Log2    = Log2 + 1;
			end
		end
	endfunction
	
//================================================================================
//	PARAMETERS

	localparam Stages = Log2(InWidth);
	localparam OutWidth	= 1+ExpWidth+ManWidth;	//sign+ExpWidth+ManWidth
	
//================================================================================
//	PORTS
	
	input						Clk_i;
	input						Rst_i;
	input	[InWidth-1:0]		InData_i;
	input						InDataVal_i;
	
	output	reg	[OutWidth-1:0]	OutData_o;
	output	reg					OutDataVal_o;
	
//================================================================================
//	REG/WIRE

	reg		[InWidth-1:0]	inDataR;
	reg		signR;
	reg		outValR;
	wire	[OutWidth-1:0]	fpOut;
	wire	[Stages-1:0]	distance;
	genvar  i;
	wire	[7:0]	fpExp;
	
	wire	[InWidth-1:0]	scaledData	=	dataArray[(Stages+1)*InWidth-1:Stages*InWidth];
	wire	[ManWidth-1:0]	mantisa		=	scaledData[InWidth-2 -:ManWidth];
	
	wire	[(Stages+1)*InWidth-1:0]	dataArray;
	
//================================================================================
//	ASSIGNMENTS

	assign  dataArray [InWidth-1:0] = inDataR;
	
	assign	fpExp = ExpConst+InWidth-1-distance;
	assign	fpOut = &distance ? {signR, 31'h0}:	{signR, fpExp,	mantisa};
	
//================================================================================
//	CODING	

	always	@(posedge	Clk_i)	begin
		if	(Rst_i)	begin
			inDataR	<=	{InWidth{1'b0}};
			signR	<=	1'b0;
			outValR	<=	1'b0;
		end	else	begin
			if	(InData_i	[InWidth-1])	begin
				inDataR	<=	~InData_i+1'b1;
			end	else	begin
				inDataR	<=	InData_i;
			end
			signR	<=	InData_i[InWidth-1];
			outValR	<=	InDataVal_i;
		end
	end

	generate	
		for (i=0; i<Stages; i=i+1)	begin: searchMSB
			wire [InWidth-1:0] dataIn;	
			wire [InWidth-1:0] shiftedDataOut;
			wire [InWidth-1:0] dataOut;
			
			assign  dataIn = dataArray[(i+1)*InWidth-1:i*InWidth];

			wire    shiftDesired = ~|(dataIn[InWidth-1:InWidth-(1 << (Stages-1-i))]);
			assign  distance[(Stages-1-i)] = shiftDesired;		
			assign  shiftedDataOut = dataIn << (1 << (Stages-1-i));	
			assign  dataOut = shiftDesired ? shiftedDataOut : dataIn;	
			assign  dataArray[(i+2)*InWidth-1:(i+1)*InWidth] = dataOut;	
		end
	endgenerate

	always	@(posedge	Clk_i	or	posedge	Rst_i)	begin
		if	(Rst_i)	begin
			OutData_o		<=	{OutWidth{1'b0}};
			OutDataVal_o	<=	1'b0;
		end	else	begin
			if	(outValR)	begin
				OutData_o	<=	fpOut;
			end
			OutDataVal_o	<=	outValR;
		end
	end
	
endmodule
