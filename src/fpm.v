/*
	F-PM unit (FPU microoperations)

	document: 12-006370-01-4A
	unit:     F-PM2-2
	pages:    2-17..2-28
*/

module fpm(
	output t_1_d,
	output m_1_d,
	input clk_sys,
	// sheet 1
	input [8:15] w,
	input l_d,
	input _0_d,
	input lkb,
	output [-2:7] d,
	// sheet 2
	input fcb,
	input scc,
	input pc8,
	// sheet 3
	input _0_f,
	input f2,
	input f5,
	input strob_fp,
	input strobb_fp,
	input strob2_fp,
	input strob2b_fp,
	output g,
	output wdt,
	output wt,
	// sheet 4
	output fic,
	// sheet 5
	input r03,
	input r02,
	input t16,
	output c_f,
	output v_f,
	output m_f,
	output z_f,
	output dw,
	// sheet 6
	input [7:9] ir,
	input pufa,
	input f9,
	input nrf,
	output ad,
	output sd,
	output mw,
	output af,
	output sf,
	output mf,
	output df,
	output dw_df,
	output mw_mf,
	output af_sf,
	output ad_sd,
	output ff,
	output ss,
	output puf,
	// sheet 7
	input f10,
	input f7,
	input f6,
	output fwz,
	output ws,
	// sheet 8
	input lp,
	input f8,
	input f13,
	output di,
	output wc,
	output fi0,
	output fi1,
	output fi2,
	output fi3,
	// sheet 9
	input w0_,
	input t_1_t_1,
	input fp0_,
	input fab,
	input faa,
	input c0,
	input _0_t,
	input t0_neq_t1,
	input c0_eq_c1,
	input t1,
	input t0,
	input clockta,
	input t_0_1,
	input t_2_7,
	input t_8_15,
	input t_16_23,
	input t_24_31,
	input t_32_39,
	input t_1,
	input t0_neq_t_1,
	output ok,
	output nz,
	output opsu,
	output ta,
	// sheet 10
	input trb,
	input t39,
	input m0,
	input mb,
	input c39,
	input f4,
	input clockm,
	input _0_m,
	input m39,
	input m15,
	input m38,
	input m14,
	input m_1,
	output ck,
	// sheet 11
	input m32,
	input t0_neq_c0,
	output m_40,
	output m_32,
	output sgn_t0_c0,
	output sgn
);

	parameter FP_FI0_TICKS;

	wor __NC;

	// --- L bus and D register ---------------------------------------------

	ld LD(
		.clk_sys(clk_sys),
		.lkb(lkb),
		._0_d(_0_d),
		.l_d(l_d),
		.sum_c(sum_c[0:7]),
		.sum_c_1(sum_c_1),
		.sum_c_2(sum_c_2),
		.w(w[8:15]),
		.d(d)
	);

	// --- B register and bus -----------------------------------------------

	wire f2strob = f2 & strob_fp;

	reg [0:7] b;
	always @ (posedge clk_sys) begin
		if (f2strob) b <= d[0:7];
	end

	wire [0:7] b_bus /* synthesis keep */;

	always @ (*) begin
		case ({fcb, scc})
			2'b00: b_bus <= ~b;
			2'b01: b_bus <= b;
			2'b10: b_bus <= 8'hff;
			2'b11: b_bus <= 8'h00;
		endcase
	end

	// --- Exponent adder ---------------------------------------------------

	wire [-1:7] sum_c = b_bus + d[0:7] + pc8;

	wire M9_3 = fcb ^ scc;
	wire M3_6 = ~((b[0] & M9_3) | (~b[0] & ~scc));
	wire M27_8 = M3_6 ^ ~d[-1];
	wire sum_c_2 = ~((sum_c[-1] & M3_6) | (sum_c[-1] & ~d[-1]) | (M3_6 & ~d[-1]));
	wire sum_c_1 = sum_c[-1] ^ M27_8;

	// --- |sum_c| >= 40 ----------------------------------------------------

	wire signed [0:8] v = {sum_c_1, sum_c[0:7]};
	wire abs_sum_c_ge_40 = (v >= 40) || (v <= -40);

	// --- FIC counter ------------------------------------------------------

	wire f4mf = f4 & mf;
	wire f4df = f4 & df;
	wire f4mw = f4 & mw;
	wire f4dw = f4 & dw;

	wire f5_af_sf = af_sf & f5;

	wire M46_11 = f5_af_sf & sum_c[7];
	wire M46_8 = f5_af_sf & sum_c[6];
	wire M46_6 = f5_af_sf & sum_c[5];
	wire M46_3 = f5_af_sf & sum_c[4];
	wire M43_3 = f5_af_sf & sum_c[3];
	wire M43_6 = f5_af_sf & sum_c[2];

	wire fic5 = M46_11 | f4dw | f4mf;
	wire fic4 = f4mf | M46_8;
	wire fic3 = f4mf | M46_6;
	wire fic2 = f4df | M46_3;
	wire fic1 = f4dw | M43_3 | f4mw;
	wire fic0 = f4mf | M43_6 | f4df;

	wire cda = strobb_fp & ~wdt & f8;
	wire cua = strobb_fp & wdt & f8;
	wire rab = (strob2b_fp & g & f5) | _0_f;
	wire fic_load = strob_fp & (f4 | f5_af_sf);

	fic CNT_FIC(
		.clk_sys(clk_sys),
		.cda(cda),
		.cua(cua),
		.rab(rab),
		.load(fic_load),
		.in({fic0, fic1, fic2, fic3, fic4, fic5}),
		.fic(fic)
	);

	// --- Instruction decoder ----------------------------------------------

	decoder8 IDEC_FP(
		.i(ir[7:9]),
		.ena(pufa),
		.o({ad, sd, mw, dw, af, sf, mf, df})
	);

	wire f9df = df & f9;
	assign dw_df = df | dw;
	assign mw_mf = mf | mw;
	assign af_sf = sf | af;
	wire mwdw = dw | mw;
	assign ad_sd = sd | ad;
	wire mwadsd = mw | sd | ad;

	assign ff = nrf | ir[7]; // any floating point instruction
	assign ss = pufa & ~ir[7]; // any fixed point instruction
	assign puf = pufa | nrf; // any AWP instruction

	// --- Indicators -------------------------------------------------------

	wire wdtwtg_clk = f5_af_sf & strobb_fp;

	// wskaźnik określający, że wartość różnicy cech przy AF i SF jest >= 40

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) g <= 1'b0;
		else if (wdtwtg_clk) g <= abs_sum_c_ge_40;
	end

	// wskaźnik denormalnizacji wartości rejestru T

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) wdt <= 1'b0;
		else if (wdtwtg_clk) wdt <= sum_c_1;
	end

	// wynik w rejestrze T

	wire wt_s = f2 & ~t & strob_fp & af_sf;
	wire wt_d = abs_sum_c_ge_40 & ~sum_c_1;

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) wt <= 1'b0;
		else if (wt_s) wt <= 1'b1;
		else if (wdtwtg_clk) wt <= wt_d;
	end

	// wskaźnik zera

	wire fwz_c = strob_fp & ((mw_mf & f2) | (f10) | (~af_sf & f4) | (f4 & wt));

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) fwz <= 1'b0;
		else if (fwz_c) fwz <= ~t;
	end

	// przeniesienie FP0 dla dodawania i odejmowania liczb długich

	wire ci_c = strobb_fp & f7 & ad_sd;

	reg ci;
	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) ci <= 1'b0;
		else if (ci_c) ci <= ~fp0_;
	end

	// wskaźnik zapalony po obliczeniu poprawki

	reg _end;
	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) _end <= 1'b0;
		else if (f7) _end <= ws;
	end

	// wskaźnik poprawki

	wire ws_c = f10 & strob_fp;
	wire ws_d = ok & ~df & m_1 & ~_end;

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) ws <= 1'b0;
		else if (ws_c) ws <= ws_d;
	end

	// wskaźnik przerwania

	wire di_c = idi & f6 & strob2b_fp;

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) di <= 1'b0;
		else if (fi3) di <= 1'b1;
		else if (di_c) di <= beta;
	end

	// wskaźnik do badania nadmiaru dzielenia stałoprzecinkowego

	wire idi_r = strob_fp & ~lp & f8;

	reg idi;
	always @ (posedge clk_sys, posedge idi_r) begin
		if (idi_r) idi <= 1'b0;
		else if (f4) idi <= dw;
	end

	// wynik w rejestrze C

	wire wc_s = f4 & af_sf & ~wt & ~t;
	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) wc <= 1'b0;
		else if (wc_s) wc <= 1'b1;
	end

	// ----------------------------------------------------------------------

	wire M3_8 = (~fab & ~c0) | (~faa & c0);
	wire M53_6 = ~M3_8 ^ t_1;
	wire M53_8 = fp0_ ^ M53_6;
	assign t_1_d = ~((w0_ & lkb) | (~sgn & f9df) | (t_1_t_1 & ~t_1) | (f6_f7 & M53_8));
	assign ta = t_8_15 | t_2_7 | t_0_1 | t_1;
	wire t = t_1 | t_0_1 | t_2_7 | t_8_15 | t_16_23 | t_24_31 | t_32_39 | m_1;

	wire M67_3 = t1 | t0;
	wire M12_8 = t_32_39 | t_24_31 | t_16_23 | t_8_15;
	wire M25_8 = ~M12_8 & dw_df & M67_3 & ~t_2_7;
	wire M52_8 = (mw_mf & mfwp) | (t0_neq_t1 & dw_df);
	wire M66_8 = c0_eq_c1 & dw & ta;
	assign opsu = M52_8 | M25_8 | M66_8; // operacje sumatora

	assign ok = ff & t & ~t0_neq_t_1 &  t0_neq_t1; // liczba znormalizowana
	assign nz = ff & t & ~t0_neq_t_1 & ~t0_neq_t1; // liczba nieznormalizowana

	wire M9_6 = ck ^ ~c39;
	wire f8_n_wdt = ~wdt & f8;
	assign m_1_d = (trb & t39) | (m0 & ~mb) | (t_1 & f4) | (af & c39 & f8_n_wdt) | (sf & f8_n_wdt & M9_6);

	// --- Indicators -------------------------------------------------------

	// przedłużenie sumatora mantys

	wire ck_s = f4 & sf;
	wire ck_d = ~c39 & ck;

	always @ (posedge clk_sys, posedge _0_m) begin
		if (_0_m) ck <= 1'b0;
		else if (ck_s) ck <= 1'b1;
		else if (clockm) ck <= ck_d;
	end

	// wskaźnik przyspieszania mnożenia

	wire M13_6 = (~m39 & mf) | (~m15 & mw);
	wire M13_8 = (~m38 & mf) | (~m14 & mw);
	wire pm_d = ~((~M13_6 & ~pm) | (~M13_8 & mfwp));

	reg pm;
	always @ (posedge clk_sys, posedge _0_m) begin
		if (_0_m) pm <= 1'b0;
		else if (clockm) pm <= pm_d;
	end

	wire mfwp = M13_6 ^ pm;

	// wskaźnik działania sumatora

	wire f6_f7 = f7 | f6;
	wire cd = f8 & strobb_fp;

	reg d$;
	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) d$ <= 1'b0;
		else if (f6_f7) d$ <= 1'b1;
		else if (cd) d$ <= 1'b0;
	end

	wire M38_8 = d$ ^ ~M39_8;
	wire M38_6 = ~d$ ^ ~M39_8;
	assign m_40 = M38_8 & f8 & df;
	assign m_32 = ~((M38_6 & dw) | (~dw & ~m32));
	assign sgn_t0_c0 = t0_neq_c0 ^ sgn;

	// wskaźnik znaku ilorazu

	always @ (posedge clk_sys, posedge _0_f) begin
		if (_0_f) sgn <= 1'b0;
		else if (f4) sgn <= t0_neq_c0;
	end

	wire M39_8 = (~sgn & ~t) | (~t0_neq_c0 & t);
	wire M38_11 = M38_8 ^ sgn;
	wire M6_12 = sgn & ~t & ~lp;
	wire beta = M38_11 & ~M6_12;

	// --- Interrupts -------------------------------------------------------

	wire fi0_q;
	univib #(.ticks(FP_FI0_TICKS)) VIB_FI0(
		.clk(clk_sys),
		.a_(~di_c),
		.b(1'b1),
		.q(fi0_q)
	);

	assign fi0 = di & fi0_q;
	wire fff13 = ff & f13;
	assign fi1 = fff13 &  d[-2] & ~(d[-1] & d[0]); // 100, 101, 110
	assign fi2 = fff13 & ~d[-2] &  (d[-1] | d[0]); // 001, 010, 011
	wire M64_8 = (~nrf & nz & f4) | (f2 & (dw_df & ~t)) | (nz & f2);
	assign fi3 = strob_fp & M64_8;

	// --- CPU flags --------------------------------------------------------

	assign c_f = (~df & ff & m_1) | (r03 & mwdw) | (ad_sd & ci);
	assign v_f = (r02) | (t0_neq_t_1 & mwadsd);
	assign m_f = ~((~t_1 & ~dw) | (~t16 & dw));
	assign z_f = (~t_24_31 & ~t_16_23 & dw) | (mwadsd & ~t) | (ff & fwz);

endmodule

// vim: tabstop=2 shiftwidth=2 autoindent noexpandtab
