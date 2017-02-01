module univib(
	input clk,
	input a, b,
	output reg q
);

	parameter ticks = 3'd5;
	localparam width = $clog2(ticks+1);

	wire done = ~|r;
	wire trig = ~a & b;

	reg [width-1:0] r = ticks;

	always @ (posedge trig, posedge done) begin
		if (done) q <= 1'b0;
		else if (trig) q <= 1'b1;
	end

	always @ (posedge clk) begin
		if (q) r <= r - 1'b1;
		else r <= ticks;
	end

endmodule

// vim: tabstop=2 shiftwidth=2 autoindent noexpandtab
