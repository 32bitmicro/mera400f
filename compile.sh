#!/bin/bash
YOSYS=$YOSYS_ROOT/yosys

PROJECT=mera400f
TOPLEVEL=platform
SOURCES="src/platform.v \
    src/mera400f.v \
	src/decoder16.v src/decoder8.v \
    src/alu181.v src/carry182.v \
	src/dly.v \
	src/uart.v \
	src/pr.v src/regs.v src/r0.v src/rb.v src/bar.v src/ki.v src/l.v \
	src/pd.v src/ir.v src/idec1.v \
	src/px.v src/strobgen.v src/ifctl.v src/alarm.v \
	src/pm.v src/lk.v src/mc.v src/lg.v src/kcpc.v \
	src/pp.v src/rm.v src/rzrp.v src/dok.v \
	src/pa.v src/alu.v src/at.v src/ac.v src/ar.v src/ic.v src/w.v src/a.v \
	src/pk.v src/sevenseg.v src/display.v src/timer.v src/rot_dec.v \
	src/puks.v \
	src/isk.v \
	src/cpu.v \
	src/iobus.v src/msg_cmd_dec.v src/msg_cmd_enc.v src/msg_rx.v src/msg_tx.v src/drv_cp_in.v src/drv_bus_req.v src/drv_bus_resp.v src/recv_cl.v src/recv_cp.v src/recv_bus.v \
	src/mem_elwro_sram.v src/memcfg.v \
	src/awp.v src/fps.v src/fpm.v src/fpa.v src/fic.v src/lp.v src/fpalu.v src/m.v src/t.v src/c.v src/k.v src/zp.v src/ld.v src/b.v src/expadd.v \
	src/fp_strobgen.v"

$YOSYS -D ICE40 -p "plugin -i systemverilog" -p "read -sv2005 $SOURCES" -p "synth_ice40 -top $TOPLEVEL -blif $PROJECT.blif" -p "write_json $PROJECT.json" -p "ls"