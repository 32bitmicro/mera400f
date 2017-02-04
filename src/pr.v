/*
	MERA-400 P-R unit (registers)

	document:	12-006368-01-8A
	unit:			P-R2-3
	pages:		2-58..2-68
	sheets:		12
*/

module pr(
	// sheet 1
	input blr_,				// A50 - BLokuj Rejestry
	input lpc,				// A94 - LPC instruction
	input wa_,				// B94 - state WA
	input rpc,				// B03 - RPC instruction
	input ra_,				// B48 - user register address
	input rb_,				// B49 - user register address
	input as2,				// B43
	input rc_,				// A49
	input w_r_,				// B47
	input strob1_,		// B32
	input strob2_,		// B42
	// sheet 2-5
	input [0:15] w,		// B07, B12, B11, B10, B22, B24, B25, B23, B13, B19, B20, B21, B16, B08, B17, B18 - bus W
	output wand [0:15] l,	// A04, A03, A28, A27, A09, A10, A26, A25, A07, A08, A16, A17, A06, A05, A18, A19 - bus L
	// sheet 6
	input bar_nb_,		// B83 - BAR->NB: output BAR register to system bus
	input w_rbb_,			// A51 - RB[4:9] clock in
	input w_rbc_,			// B46 - RB[0:3] clock in
	input w_rba_,			// B50 - RB[10:15] clock in
	output [0:3] dnb_,// A86,  A90, A87, B84 - DNB: NB system bus driver
	// sheet 7
	input rpn_,				// B85
	input bp_nb,			// B86
	input pn_nb,			// A92
	input q_nb,				// B90
	input w_bar,			// B56 - W->BAR: send W bus to {BAR, Q, BS} registers
	input zer_fp_,		// A89
	input clm_,				// B93
	input ustr0_fp_,	// A11
	input ust_leg,		// B39
	input aryt,				// B45
	input zs,					// A47
	input carry_,			// A48
	input s_1,				// B44
	output zgpn,			// B88
	output dpn_,			// B87 - PN system bus driver
	output dqb_,			// B89 - Q system bus driver
	output q,					// A53 - Q: system flag
	output zer_,			// A52
	// sheet 8
	input ust_z,			// B53
	input ust_mc,			// B55
	input s0,					// B92
	input ust_v,			// A93
	input zero_v,			// B91
	output [0:8] r0,	// A44, A46, A43, A42, A41, A45, A40, A39, B09 - CPU flags in R0 register
	// sheet 9
	input exy_,				// A37
	input ust_y,			// B40
	input exx_,				// A38
	input ust_x,			// B41
	// sheet 10-11
	input kia_,				// B81
	input kib_,				// A91
	input [0:15] rz,	// B70, B76, B60, B66, A60, A64, A68, A56, B80, A80, A74, A84, A77, B74, A71, B57
										// NOTE: rz[14] is rz30, rz[15] is rz31
	input [0:15] zp,	// B68, B72, B62, B64, A62, B63, A66, A58, B78, A82, A75, A85, A78, A83, A70, A54
	input [0:9] rs,		// B69, B75, B61, B65, A61, A63, A67, A57, B79, A81
	output [0:15] ki	// B71, B77, B59, B67, A59, A65, A69, A55, B82, A79, A73, B73, A76, A88, A72, B58
);

	parameter CPU_NUMBER = 1'b0;
	parameter AWP_PRESENT = 1'b1;

	// sheet 1, page 2-58
	// * user register control signals

	wire M53_6 = ~(rb_ & ra_ & rc_);
	wire M60_6 = ~(~wa_ & rpc);

	wire rpp = ~blr_;
	wire rpa = blr_ & ~(M53_6 & M60_6);
	wire rpb = ~(M53_6 & M60_6) & blr_;

	wire lr0 = ~(lpc & strob_a & ~wa_);
	wire czytrw_ = ~(blr_ & M60_6 & ~rc_);
	wire wr0 = rb_ & rc_ & ra_;
	wire ra = ~ra_;
	wire rb = ~rb_;
	wire czytrn_ = ~(blr_ & M60_6 & M53_6 & rc_);
	wire M63_12 = M53_6 & rc_ & ~w_r_;
	wire piszrn_ = ~((strob_a & M63_12) | (strob_b & M63_12));
	wire M64_6 = ~w_r_ & ~rc_;
	wire piszrw_ = ~((M64_6 & strob_a) | (M64_6 & strob_b));

	wire strob_a = ~(as2 | strob1_);
	wire strob_b = ~(~as2 | strob2_);

	wire w_r = ~w_r_;
	wire strob1 = ~strob1_;

	// sheets 2..5, pages 2-59..2-62
	// * R1-R7 user registers

	wire [0:15] __l_regs;
	regs USER_REGS(
		.w(w),
		.l(__l_regs),
		.czytrn_(czytrn_), .piszrn_(piszrn_),
		.czytrw_(czytrw_), .piszrw_(piszrw_),
		.ra(ra), .rb(rb)
	);

	// sheet 6, page 2-63
	// * RB register (binary load register)
	// * NB (BAR) register and system bus drivers
	// * R0 register positions 10-15 and system bus drivers

	wire [0:15] rRB;
	rb REG_RB(
		.w(w[10:15]),
		.w_rba_(w_rba_),
		.w_rbb_(w_rbb_),
		.w_rbc_(w_rbc_),
		.rb(rRB)
	);

	wire [0:3] nb;
	nb REG_NB(
		.w(w[12:15]),
		.cnb_(cnb0_3_),
		.clm_(clm_),
		.nb(nb)
	);
	assign dnb_ = ~(nb & {4{~bar_nb_}});

	wire [0:15] R0_;
	r0_9_15 R0_9_15(
		.w(w[9:15]),
		.lrp(lrp),
		.zer_(zer_),
		.r0_(R0_[9:15])
	);

	wire [9:15] __l_r0 = ~(R0_[9:15] & {7{rpb}});

	// sheet 7, page 2-64
	// * Q and BS flag registers and system bus drivers
	// * R0 control signals

	// jumper on 7-8 : CPU 0
	// jumper on 8-9 : CPU 1
	assign zgpn = ~rpn_ ^ ~CPU_NUMBER;
	wire M35_8 = CPU_NUMBER ^ bs;
	wire M23_11 = ~(CPU_NUMBER & pn_nb);
	assign dpn_ = ~(M35_8 & bp_nb) & M23_11;
	assign dqb_ = ~(q_nb & q);

	wire bs;
	ffd REG_BS(
		.c(cnb0_3_),
		.d(w[11]),
		.r_(clm_),
		.s_(1'b1),
		.q(bs)
	);

	wire cnb0_3_ = ~(w_bar & strob1);

	ffd REG_Q(
		.c(cnb0_3_),
		.d(w[10]),
		.r_(zer_),
		.s_(1'b1),
		.q(q)
	);

	assign zer_ = zer_fp_ & clm_;

	// jumper on C-D: no AWP
	wire M60_3 = ~(AWP_PRESENT & ustr0_fp_ & strob_a);
	wire M62_6 = ~(strob_a & w_r & wr0 & ~q); // NOTE: w_r is a guess (no connection on the schematic)
	wire M62_8 = ~(~q & wr0 & w_r & strob_b); // NOTE: w_r is a guess (no connection on the schematic)
	wire M61_12 = ~(wr0 & w_r & strob_b);
	wire M61_8 = ~(wr0 & w_r & strob_a); // NOTE: w_r is a guess (no connection on the schematic)

	wire w_zmvc = ~(M60_3 & lr0 & M62_8 & M62_6);
	wire w_legy = ~(M62_6 & lr0 & M62_8);
	wire lrp = lr0 & M61_8 & M61_12;
	wire w8_x = ~(M61_12 & lr0 & M61_8);
	wire cleg_ = ~(strob_b & ust_leg);

	wire vg_ = ~((~aryt & ~(zs | carry_)) | (~(zs | s_1) & aryt));
	wire vl_ = ~((~aryt & carry_) | (aryt & s_1));

	// sheets 8..9, pages 2-65..2-66
	// * R0 register positions 0-9: CPU flags: ZMVCLEGYX

	wire zer = ~zer_;
	r0 REG_R0(
		.w(w),
		.r0(r0),
		.zs(zs),
		.s_1(s_1),
		.s0(s0),
		.carry_(carry_),
		.vl_(vl_),
		.vg_(vg_),
		.exy_(exy_),
		.exx_(exx_),
		.strob1(strob1),
		.ust_z(ust_z),
		.ust_v(ust_v),
		.ust_mc(ust_mc),
		.ust_y(ust_y),
		.ust_x(ust_x),
		.cleg_(cleg_),
		.w_zmvc(w_zmvc),
		.w_legy(w_legy),
		.w8_x(w8_x),
		.zero_v(zero_v),
		.zer(zer)
	);

	// assignments below are on pages 2-59..2-62
	wire [0:8] __l_flags;
	wire [8:15] __l_flags2;
	assign __l_flags[0:3] = ~(~r0[0:3] & {4{rpa}});
	assign __l_flags[4:7] = ~(~r0[4:7] & {4{rpa}});
	assign __l_flags[8] = ~(~r0[8] & rpb);

	assign __l_flags2[8:11] = ~(~r0[0:3] & {4{rpp}});
	assign __l_flags2[12:15] = ~(~r0[4:7] & {4{rpp}});

	// L bus final open-collector composition
	assign l = 
		__l_regs // user registers
		& {{9{1'b1}}, __l_r0} // user-settable r0 part
		& {__l_flags, {7{1'b1}}} // r0 flags at original positions
		& {{8{1'b1}}, __l_flags2} // r0 flags shifted right 8 bits
	;

	// sheets 10..11, pages 2-67..2-68
	// * KI bus

	wire [0:1] sel = {~kia_, ~kib_};
	assign ki =
		(sel == 2'b00) ? rz :
		(sel == 2'b01) ? {rs[0:9], bs, q, nb[0:3]} :
		(sel == 2'b10) ? rRB :
		zp;

endmodule

// vim: tabstop=2 shiftwidth=2 autoindent noexpandtab