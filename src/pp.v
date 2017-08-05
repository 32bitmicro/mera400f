module pp(
	input __clk,

	input w_rm,
	input zer,
	input ck_rz_w,
	input zerrz,
	input przerw,
	input rpa,
	input ir14,
	input ir15,
	input wx,
	input sin,
	input rin,
	input zw,
	input zgpn_,
	output przerw_z,
	output irq,

	// system-wide signals
	input clm,
	input strob1,
	input strob1b,
	// CPU states
	input k1,
	input i1,
	input i2,
	input i4,
	// interrupts
	input pout,
	input oprq,
	input b_parz,
	input b_p0,
	input zegar,
	input xi,
	input fi0,
	input fi1,
	input fi2,
	input fi3,
	// internal buses
	input [0:15] w,
	output [0:15] bus_rz,
	output [0:9] rs,
	// system bus
	input [0:15] rdt,
	output dok,
	output [0:15] dad
);

	parameter DOK_DLY_TICKS;
	parameter DOK_TICKS;

	wor __NC; // unconnected signals here, to suppress warnings

	// sheet 1, 2
	// * RM - interrupt mask register

	wire clm$ = clm | (strob1 & i4);
	wire clrs = strob1b & w_rm;

	rm RM(
		.clk(__clk),
		.clm$(clm$),
		.clrs(clrs),
		.zi(zi),
		.w(w),
		.rs(rs)
	);

	// sheet 3..10
	// * RZ, RP - interrupt request and service registers

	// RZ input: async interrupt signals bus
	wire [0:31] IRQ = {
		pout,			// 0 power out (NMI)
		b_parz,		// 1 memory parity error
		b_p0,			// 2 no memory
		rz4,			// 3 other CPU, high priority
		rpa,			// 4 interface power out
		zegar,		// 5 timer
		xi,				// 6 illegal instruction
		fi0,			// 7 div overflow (fixed point)
		fi1,			// 8 floating point underflow
		fi2,			// 9 floating point overflow
		fi3,			// 10 div/0 or floating point error
		1'b0,			// 11 unused
		zk[0:15],	// 12-27 channel interrupts
		oprq,			// 28 operator request
		rz29,			// 29 other CPU, low priority
		soft_high,// 30 software interrupt high
		soft_low	// 31 software interrupt low
	};

	// FIX: missing connection from M104.12 to M89.5, M70.2

	// RZ input: software interrupt drivers (sheet 10)
	wire M104_12 = wx & sin & strob1;
	wire soft_high = ir14 & M104_12;
	wire soft_low = ir15 & M104_12;

	// RZ input: W bus, synchronous (software-set) interrupt sources
	wire [0:31] INT_SYNC = {
		w[0:11],		// software-settable interrupts
		16'b0, 			// channel interrupts cannot be set synchronously
		w[12:15]		// software-settable interrupts
	};

	// RZ input: clocks
	wire ck_rzwm = strob1 & ck_rz_w;
	wire ck_rzz = strob1 & i2;
	wire [0:31] RZ_CLK = {
		{12{ck_rzwm}},
		{16{ck_rzz}},
		{4{ck_rzwm}}
	};

	// RZ input: resets
	wire _0_rzw = clm | zerrz;
	wire _0_rzz = clm | k1;
	wire M94_3 = _0_rzw | (M104_12 & ~ir14 & ~ir15);
	wire [0:31] RZ_RESET = {
		{12{_0_rzw}},
		{16{_0_rzz}},
		{2{_0_rzw}},
		{2{M94_3}}
	};

	// RZ input: interrupt mask bus (right after RZ outputs)
	wire [0:31] IMASK = {
		1'b1,				// 0 (NMI)
		rs[0:3],		// 1-4
		{7{rs[4]}},	// 5-11
		{2{rs[5]}},	// 12-13
		{2{rs[6]}},	// 14-15
		{6{rs[7]}},	// 16-21
		{6{rs[8]}},	// 22-27
		{4{rs[9]}}	// 28-31
	};

	// RP input: clocks
	wire ez_rpz = i1 & przerw;

	// RP output: interrupt mask drivers (to RM)
	wire [0:9] zi = {
		PRIO_OUT[1],
		PRIO_OUT[2],
		PRIO_OUT[3],
		PRIO_OUT[4],
		PRIO_OUT[11],
		PRIO_OUT[13],
		PRIO_OUT[15],
		PRIO_OUT[21],
		PRIO_OUT[27],
		1'b1
	};

	// RP input/output: interrupt priority chain
	wire [0:31] PRIO_OUT;
	wire [0:31] PRIO_IN = {
		zer,
		PRIO_OUT[0:30]
	};

	// RZ output: only non-channel interrupts are available to the user
	wire [0:31] __rz;
	assign bus_rz = {
		__rz[0:11],
		__rz[28:31]
	};

	// RZ output: masked
	wire [0:31] sz;

	// RP output
	wire [0:31] rp;

	genvar j;
	generate
		for (j=0 ; j<32 ; j=j+1) begin : GEN_RZ_RP
			rzrp RZ_RP(
				.imask(IMASK[j]),				// IRQ mask input
				.irq(IRQ[j]),						// IRQ (async)
				.w(INT_SYNC[j]),				// synchronous interrupt set
				.rz_c(RZ_CLK[j]),				// RZ clock
				.rz_r(RZ_RESET[j]),			// RZ reset
				.rp_c(ez_rpz),					// RP clock
				.prio_in(PRIO_IN[j]),		// priority chain input
				.rz(__rz[j]),						// RZ content
				.sz(sz[j]),							// RZ & mask
				.rp(rp[j]),							// RP content
				.prio_out(PRIO_OUT[j])	// priority chain output
			);
		end
	endgenerate

	// sheet 3

	// sheet 5

	assign przerw_z = srps & ~zi[4];

	// sheet 6

	wire nk_ad = i2 & zw;

	// sheet 9

	wire srps = zi[8];

	// sheet 11

	wire dok_dly;
	dly #(.ticks(DOK_DLY_TICKS)) DLY_DOK(
		.clk(__clk),
		.i(rin),
		.o(dok_dly)
	);
	wire M12_3 = ~dok_dly;

	// TODO: cap + diode?
	wire zw_dly = ~zw;

	wire M14_6;
	univib #(.ticks(DOK_TICKS)) TRIG_DOK(
		.clk(__clk),
		.a_(M12_3),
		.b(zw_dly),
		.q(M14_6)
	);

	wire M11_3 = ~(~rdt[15] & zgpn_);
	wire M12_6 = ~(M11_3 & ~rdt[15]);

	wire M9_5;
	ffd REG_DOK(
		.s_(1'b1),
		.d(M12_6),
		.c(~M14_6),
		.r_(~M12_3),
		.q(M9_5)
	);
	assign dok = rin & M9_5;

	wire rz29 = M14_6 & rdt[15] & rdt[0];
	wire rz4 = M14_6 & rdt[15] & ~rdt[0];

	assign irq = |sz;

	wire [0:15] zk;
	decoder16 DEC_ZK(
		.en1(~M11_3),
		.en2(M14_6),
		.i(rdt[11:14]),
		.o(zk)
	);

	// sheet 12

	wire npbd = rp[24] | rp[25] | rp[26] | rp[28] | rp[29] | rp[30] | rp[27] | rp[31];
	wire npbc = rp[28] | rp[29] | rp[30] | rp[31] | rp[23] | rp[22] | rp[21] | rp[20];
	wire npbb = rp[22] | rp[23] | rp[26] | rp[30] | rp[27] | rp[31] | rp[19] | rp[18];
	wire npba = rp[19] | rp[21] | rp[23] | rp[25] | rp[29] | rp[27] | rp[31] | rp[17];

	// sheet 13

	wire npad = rp[ 8] | rp[ 9] | rp[10] | rp[11] | rp[12] | rp[13] | rp[14] | rp[15];
	wire npac = rp[ 4] | rp[ 5] | rp[ 6] | rp[ 7] | rp[12] | rp[13] | rp[14] | rp[15];
	wire npab = rp[ 2] | rp[ 3] | rp[ 6] | rp[ 7] | rp[10] | rp[11] | rp[14] | rp[15];
	wire npaa = rp[ 1] | rp[ 3] | rp[ 5] | rp[ 7] | rp[ 9] | rp[11] | rp[13] | rp[15];

	assign dad[4] = nk_ad;

	wire M85_11 = npbd ^ npad;
	wire M85_8  = npbc ^ npac;
	wire M85_6  = npbb ^ npab;
	wire M85_3  = npba ^ npaa;
	wire M99_6 = M85_11 ^ M85_8;

	wire M4_8 = przerw & zw & i4;

	assign dad[0:3] = 'd0;
	assign dad[5:10] = 'd0;
	assign dad[11] = (M4_8 & ~zi[6])  | (nk_ad & M99_6);
	assign dad[12] = (M4_8 & M85_11) | (nk_ad & ~M85_8);
	assign dad[13] = (M4_8 & M85_8)  | (nk_ad & M85_6);
	assign dad[14] = (M4_8 & M85_6)  | (nk_ad & M85_3);
	assign dad[15] = M4_8 & M85_3;

endmodule

// vim: tabstop=2 shiftwidth=2 autoindent noexpandtab
