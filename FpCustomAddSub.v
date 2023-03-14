module FpCustomAddSub 
# (
	parameter	ManWidth	=	16,
	parameter	ExpWidth	=	6
)
(Rst_i,Clk_i,A_i,B_i,AddSub_i,Nd_i,Result_o,ResultValid_o);	
		
	localparam	InOutWidth	=	1+ExpWidth+ManWidth;
	localparam	ExtManWidth	=	ManWidth+1;
//================================================================================
//  Ports
	input	Rst_i;
	input	Clk_i;
	
	input	[InOutWidth-1:0]	A_i;
	input	[InOutWidth-1:0]	B_i;
	input	AddSub_i;
	input	Nd_i;
	output	[InOutWidth-1:0]	Result_o;
	output	ResultValid_o;
	
//================================================================================
//	Coding		
	wire	signB	=	B_i[InOutWidth-1]^AddSub_i;
	
	wire	[InOutWidth-2:0]	absA	=	A_i[InOutWidth-2:0];
	wire	[InOutWidth-2:0]	absB	=	B_i[InOutWidth-2:0];
	
	reg		[InOutWidth-1:0]	muxA;
	reg		[InOutWidth-1:0]	muxB;


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

//if A<B then swap A and B	
	always	@(*)	begin
		if	(absA<absB)	begin
			muxA	<=	{signB,absB};
			muxB	<=	{A_i[InOutWidth-1],absA};
		end	else	begin
			muxA	<=	{A_i[InOutWidth-1],absA};
			muxB	<=	{signB,absB};
		end 
	end
	
	reg	impliedA;
	reg	impliedB;
	
	reg	[InOutWidth-1:0]	muxAReg;
	reg	[InOutWidth-1:0]	muxBReg;
	
	reg	[ExpWidth-1:0]		expDiff;
	reg	addSubOrepation;
	
	always	@(posedge	Clk_i)	begin
		if	(muxA	[InOutWidth-2 -:ExpWidth]	==	8'h00)	begin	//if	Exp(A)	==	0 
			impliedA	<=	1'b0;	//then A == 0 or denormalized  
		end	else	begin
			impliedA	<=	1'b1;	//else	need to add implied 1
		end
		
		if	(muxB	[InOutWidth-2 -:ExpWidth]	==	8'h00)	begin	//same as for A
			impliedB	<=	1'b0;
		end	else	begin
			impliedB	<=	1'b1;
		end

		muxAReg	<=	muxA;
		muxBReg	<=	muxB;
		
		expDiff	<=	muxA[InOutWidth-2 -:ExpWidth]	-	muxB[InOutWidth-2 -:ExpWidth];	//expDiff=exp(A)-exp(B)
		addSubOrepation	<=	muxA[InOutWidth-1]	^	muxB[InOutWidth-1];	//determine whether addition or subtraction in accordance to signs A and B
	end
		
	wire	[ManWidth:0]	manA	=	{impliedA,	muxAReg[ManWidth-1:0]};
	wire	[ManWidth:0]	manB	=	{impliedB,	muxBReg[ManWidth-1:0]};
	
	reg	[ManWidth:0]	manANorm;
	reg	[ManWidth:0]	manBNorm;
	reg	addSubOrepationReg;
	
	always	@(posedge	Clk_i)	begin
		manANorm	<=	manA;
		manBNorm	<=	manB	>>	expDiff;	//Getting man(B) using right (must be mult operation bu we have base 2 so we can use shift)	shifting by Exponents Differents value. Since our CustomFpValues<32 bit width, its enough to use only expDiff[4:0]. 
		addSubOrepationReg <= addSubOrepation;
	end
	
	reg	[ExtManWidth:0]	manSum;
	
	always	@(posedge	Clk_i)	begin
		if	(Rst_i)	begin
			manSum	<=	{ExtManWidth{1'b0}};
		end	else	if	(!addSubOrepationReg)	begin
			manSum	<=	{1'b0,	manANorm}	+	{1'b0,	manBNorm};
		end	else	begin
			manSum	<=	{1'b0,	manANorm}	-	{1'b0,	manBNorm};
		end
	end

//===========================================================
	parameter	Stages	=	Log2(InOutWidth);
	// parameter	Stages	=	6;
	wire	[Stages-1:0]	distance;
	
	wire	[ExtManWidth+1:0]	dataArray	[0:Stages];
	assign  dataArray [0]	=	manSum;			
	genvar	i;
	
	generate	
		for (i=0; i<Stages; i=i+1)	begin: searchMSB
			wire [ExtManWidth+1:0] dataIn;	
			wire [ExtManWidth+1:0] shitedDataOut;
			wire [ExtManWidth+1:0] dataOut;
			
			assign  dataIn = dataArray[i];

			wire    shiftDesired = ~|(dataIn[ExtManWidth+1:ExtManWidth+1-(1 << (Stages-1-i))]);
			assign  distance[(Stages-1-i)] = shiftDesired;		
			assign  shitedDataOut = dataIn << (1 << (Stages-1-i));	
			assign  dataOut = shiftDesired ? shitedDataOut : dataIn;	
			assign  dataArray[i+1] = dataOut;
			wire	[31:0]	test	=	1 << (Stages-1-i);
		end
		reg	[Stages-1:0]	distanceR1;
		
		always	@(posedge	Clk_i)	begin
			distanceR1	<=	distance;
		end
	endgenerate	
//===========================================================
	
	wire	[Stages+1:0]	distanceR	=	{2'b00,distanceR1};
	reg		[ExtManWidth-1:0]	manSumReg;
	always	@(posedge	Clk_i)	begin
		manSumReg	<=	manSum	[ExtManWidth-1 -:ExtManWidth];
	end

	wire	[ExtManWidth-1:0]	normCMan	=	manSumReg	<<	distanceR1[Stages-1:0];	//Normalize man(C) using left shifting by Distance value.(must be mult operation bu we have base 2 so we can use shift).
	
	reg	[ManWidth-1:0]	manC;
	always	@(posedge	Clk_i)	begin
		if	(Rst_i)	begin
			manC	<=	{ManWidth{1'b0}};
		end	else	begin
			manC	<=	normCMan	[ExtManWidth-1 -:ManWidth];	//Getting the Man(C).
		end
	end
	
	reg	[ExpWidth-1:0]	expAPipe	[0:4];
	always	@(posedge	Clk_i)	begin	
		expAPipe[0]	<=	muxA[InOutWidth-2 -:ExpWidth];	//Delaying  Exp(A)	
		expAPipe[1]	<=	expAPipe[0];
		expAPipe[2]	<=	expAPipe[1];
		expAPipe[3]	<=	expAPipe[2];
		expAPipe[4]	<=	expAPipe[3];
	end

	
	wire	test	=	(&distanceR1);
	reg	[ExpWidth-1:0]	expC;
	always	@(posedge	Clk_i)	begin
		if	(&distanceR1)	begin
			expC	<=	{ExpWidth{1'b0}};
		end	else	begin
			if	(expAPipe[3]	>=	distanceR)	begin
				expC	<=	expAPipe[3]-distanceR+1;			//exp(C)=exp(A)-distance+1;
			end	else	begin
				expC	<=	{{ExpWidth+1{1'b0}},1'b1};
			end
		end	
	end
	
	reg	[4:0]	signC;
	always	@(posedge	Clk_i)	begin
		signC	<=	{signC[3:0],	muxA[InOutWidth-1]};
	end
	
	reg	[8:0]	valid;
	always	@(posedge	Clk_i)	begin
		valid	<=	{valid[7:0],Nd_i};
	end	
	
	assign	Result_o	=	{signC[4],expC,manC};
	assign	ResultValid_o	=	valid[4];
endmodule
