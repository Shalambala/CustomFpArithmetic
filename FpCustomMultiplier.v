module FpCustomMultiplier 
# (
	parameter	ManWidth	=	16,
	parameter	ExpWidth	=	6
)
(Rst_i,Clk_i,A_i,B_i,Nd_i,Result_o,ResultValid_o);	

//================================================================================
//	PARAMETERS

	localparam	InOutWidth = 1+ExpWidth+ManWidth;
	localparam	ExtManWidth = 2+ManWidth;
	localparam	MultResultWidth = (ExtManWidth*2)-2;
	localparam	ExpConst = (2**(ExpWidth-1))-1;
	
//================================================================================
//	PORTS

	input	Rst_i;
	input	Clk_i;
	
	input	[InOutWidth-1:0]	A_i;
	input	[InOutWidth-1:0]	B_i;
	input	Nd_i;
	output	[InOutWidth-1:0]	Result_o;
	output	ResultValid_o;

//================================================================================
//	REG/WIRE

	reg	expA_or;
	reg	expB_or;
	
	reg	signed	[ExtManWidth-1:0]	manAReg;
	reg	signed	[ExtManWidth-1:0]	manBReg;
	
	reg	[ExpWidth-1:0]	expAReg;
	reg	[ExpWidth-1:0]	expBReg;

	reg	[ExpWidth:0]	expAddProd;
	reg	expZero;
	reg	signed	[MultResultWidth-1:0]	manMultProd;
	
	reg	[ExpWidth-1:0]	expCReg;
	reg	expResultNegative;
	reg	[ManWidth-1:0]	manCReg;
	
	reg	[4:0]	signCShReg;
	reg	[5:0]	resValidShReg;
	
//================================================================================
//	ASSIGNMENTS

	assign Result_o = {signCShReg[2], expCReg,manCReg};
	assign ResultValid_o = resValidShReg[2];
	
//================================================================================
//	CODING	

	always	@(posedge	Clk_i)	begin
		expA_or	<=	|A_i[InOutWidth-2 -:ExpWidth];	//looking for zero exponents for mult operation
		expB_or	<=	|B_i[InOutWidth-2 -:ExpWidth];
		
		manAReg	<=	{2'b01,A_i[ManWidth-1 -:ManWidth]};	//add 0-sign and implied 1 to mantissa.
		manBReg	<=	{2'b01,B_i[ManWidth-1 -:ManWidth]};
		
		expAReg	<=	A_i[InOutWidth-2 -:ExpWidth];	//exp highlight
		expBReg	<=	B_i[InOutWidth-2 -:ExpWidth];
	end
	
	always	@(posedge	Clk_i)	begin
		manMultProd	<=	manAReg*manBReg;	//man(C)=man(A)*man(B)
		
		expAddProd	<=	expAReg+expBReg-ExpConst;	//exp(C)=exp(A)+exp(B)-ExpConst. ExpConst = 2^ExpWidth-1;
		
		expZero	<=	~(expA_or&expB_or);	//setting exp(C) = 0 when either A or B is zero or denormalized.
	end
	
	always	@(posedge	Clk_i)	begin
		expResultNegative	<=	expAddProd[ExpWidth]; //if exponents are too small then their result will be negative
		
		if	(Rst_i)	begin
			expCReg	<=	{ExpWidth{1'b0}};
		end	else	if	(expAddProd[ExpWidth]||expZero)	begin
			expCReg	<=	{ExpWidth{1'b0}};
		end	else	begin
			expCReg	<=	expAddProd[ExpWidth-1:0]+manMultProd[MultResultWidth-1];
		end
		
		if	(Rst_i)	begin
			manCReg	<=	{ManWidth{1'b0}};
		end	else	if	(expAddProd[ExpWidth]||expZero)	begin
			manCReg	<=	{ManWidth{1'b0}};
		end	else	if	(!manMultProd[MultResultWidth-1])	begin	//normalize man(C) in accordance to MSB value
			manCReg	<=	manMultProd[MultResultWidth-3 -:ManWidth];	
		end	else	begin
			manCReg	<=	manMultProd[MultResultWidth-2 -:ManWidth];
		end
	end
	
	always	@(posedge	Clk_i)	begin
		signCShReg	<=	{signCShReg[3:0], A_i[InOutWidth-1] ^ B_i[InOutWidth-1]};
	end
	
	always	@(posedge	Clk_i)	begin
		resValidShReg	<=	{resValidShReg[4:0],	Nd_i};
	end
	
endmodule























