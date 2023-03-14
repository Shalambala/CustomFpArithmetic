module IQPowSqrtAddPipe 
#(	
	parameter	IQDataWidth	=	32
)
(
    input	Clk_i,
    input	Rst_i,
    input	Val_i,
	input	[IQDataWidth-1:0]	DataI_i,
	input	[IQDataWidth-1:0]	DataQ_i,
	
	output	[IQDataWidth-1:0]	Result_o,
	output	ResultVal_o
);

//================================================================================
//  LOCALPARAMS
	wire	[IQDataWidth-1:0]	iPowResult;
	wire	iPowVal;
	wire	[IQDataWidth-1:0]	qPowResult;
	wire	qPowVal;
	
	wire	[IQDataWidth-1:0]	iqPowAddResult;
	wire	iqPowAddVal;
//================================================================================
//  REG/WIRE

	assign	Result_o	=	iqPowAddResult;
	assign	ResultVal_o	=	iqPowAddVal;
//================================================================================
//  ASSIGNMENTS
//================================================================================
//  CODING

FpCustomMultiplier
#(
	.ManWidth	(23),
	.ExpWidth	(8)
)
iPow2
(
	.Rst_i		(Rst_i),
	.Clk_i		(Clk_i),
	.A_i		(DataI_i),
	.B_i		(DataI_i),
	.Nd_i		(Val_i),
	.Result_o	(iPowResult),
	.ResultValid_o	(iPowVal)
);	

FpCustomMultiplier
#(
	.ManWidth	(23),
	.ExpWidth	(8)
)
qPow2
(
	.Rst_i		(Rst_i),
	.Clk_i		(Clk_i),
	.A_i		(DataQ_i),
	.B_i		(DataQ_i),
	.Nd_i		(Val_i),
	.Result_o	(qPowResult),
	.ResultValid_o	(qPowVal)
);	

FpCustomAddSub 
# (
	.ManWidth	(23),
	.ExpWidth	(8)
)
FpCustomAddSub
(
	.Rst_i		(Rst_i),
	.Clk_i		(Clk_i),
	.A_i		(iPowResult),
	.B_i		(qPowResult),
	.AddSub_i	(1'b0),
	.Nd_i		(iPowVal&qPowVal),
	.Result_o	(iqPowAddResult),
	.ResultValid_o	(iqPowAddVal)
);
	
endmodule