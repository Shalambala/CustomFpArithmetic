module FpToReal
#(
	parameter	ExpWidth	=	8,
	parameter	ManWidth	=	23,
	parameter	InWidth		=	32
)
(
	input Clk_i,
	input [InWidth-1:0] Data_i,
	input DataNd_i,
	output	reg	[InWidth-1:0]	Data_o
);
	
	assign	Data_o	=	dataReal;
	
	localparam	ExpConst		=	(2**(ExpWidth-1))-1;
	
	function real Fp32ToRealFunc;
		input [InWidth-1:0] Data;
		reg sign;
		reg [ExpWidth-1:0] exp;
		reg [ManWidth-1:0] frac;
		real realFrac;
		real realDiv;
		real realExp;
		reg	[63:0]	Test64bitReg;
	begin
		sign = Data[InWidth-1];
		exp = Data[InWidth-2 -:ExpWidth];
		frac = Data[ManWidth-1:0];
		Test64bitReg	=	2**(exp - ExpConst);
		realFrac = frac;
		realDiv = 2**ManWidth;
		
		if (exp > ExpConst)
			realExp = 2.0**(exp - ExpConst);
		else if (exp < ExpConst)
			realExp = 1.0 / (2.0**(ExpConst-exp));
		else 
			realExp = 1.0;

		if ((exp == 0) && (frac == 0))
			Fp32ToRealFunc = 0;
		else
			Fp32ToRealFunc = ((-1)**sign) * (1.0 + (realFrac / realDiv)) * Test64bitReg;
	end
	endfunction

	real dataReal;
	always @ (posedge Clk_i)
		if (DataNd_i) begin
			dataReal = Fp32ToRealFunc(Data_i);
			$display("%e\n", dataReal);
		end

endmodule