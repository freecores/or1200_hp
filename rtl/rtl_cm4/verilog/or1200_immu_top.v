//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Instruction MMU top level                          ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of all IMMU blocks.                           ////
////                                                              ////
////  To Do:                                                      ////
////   - cache inhibit                                            ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.14  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.12.4.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.12.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.12  2003/06/06 02:54:47  lampret
// When OR1200_NO_IMMU and OR1200_NO_IC are not both defined or undefined at the same time, results in a IC bug. Fixed.
//
// Revision 1.11  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.10  2002/09/16 03:08:56  lampret
// Disabled cache inhibit atttribute.
//
// Revision 1.9  2002/08/18 19:54:17  lampret
// Added store buffer.
//
// Revision 1.8  2002/08/14 06:23:50  lampret
// Disabled ITLB translation when 1) doing access to ITLB SPRs or 2) crossing page. This modification was tested only with parts of IMMU test - remaining test cases needs to be run.
//
// Revision 1.7  2002/08/12 05:31:30  lampret
// Delayed external access at page crossing.
//
// Revision 1.6  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.6  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.5  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/17 08:03:35  lampret
// *** empty log message ***
//
// Revision 1.2  2001/07/22 03:31:53  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Insn MMU
//

module or1200_immu_top_cm4(
		clk_i_cml_1,
		clk_i_cml_2,
		clk_i_cml_3,
		cmls,
		
	// Rst and clk
	clk, rst,

	// CPU i/f
	ic_en, immu_en, supv, icpu_adr_i, icpu_cycstb_i,
	icpu_adr_o, icpu_tag_o, icpu_rty_o, icpu_err_o,

	// SPR access
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// QMEM i/f
	qmemimmu_rty_i, qmemimmu_err_i, qmemimmu_tag_i, qmemimmu_adr_o, qmemimmu_cycstb_o, qmemimmu_ci_o
);


input clk_i_cml_1;
input clk_i_cml_2;
input clk_i_cml_3;
input [1:0] cmls;
reg  immu_en_cml_3;
reg  immu_en_cml_2;
reg  immu_en_cml_1;
reg  supv_cml_2;
reg [ 32 - 1 : 0 ] icpu_adr_i_cml_3;
reg [ 32 - 1 : 0 ] icpu_adr_i_cml_2;
reg [ 32 - 1 : 0 ] icpu_adr_o_cml_3;
reg [ 32 - 1 : 0 ] icpu_adr_o_cml_2;
reg [ 32 - 1 : 0 ] icpu_adr_o_cml_1;
reg  icpu_rty_o_cml_3;
reg  icpu_rty_o_cml_2;
reg  spr_cs_cml_3;
reg  spr_cs_cml_2;
reg  spr_cs_cml_1;
reg  qmemimmu_err_i_cml_2;
reg  itlb_spr_access_cml_3;
reg  itlb_spr_access_cml_2;
reg  itlb_spr_access_cml_1;
reg [ 31 : 13 ] itlb_ppn_cml_2;
reg  itlb_uxe_cml_2;
reg  itlb_sxe_cml_2;
reg  itlb_done_cml_3;
reg  fault_cml_3;
reg  miss_cml_3;
reg  page_cross_cml_3;
reg [ 31 : 13 ] icpu_vpn_r_cml_3;
reg [ 31 : 13 ] icpu_vpn_r_cml_2;
reg [ 31 : 13 ] icpu_vpn_r_cml_1;
reg  itlb_en_r_cml_3;
reg  itlb_en_r_cml_2;
reg  itlb_en_r_cml_1;
reg  dis_spr_access_cml_3;
reg  dis_spr_access_cml_2;
reg  dis_spr_access_cml_1;



parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// CPU I/F
//
input				ic_en;
input				immu_en;
input				supv;
input	[aw-1:0]		icpu_adr_i;
input				icpu_cycstb_i;
output	[aw-1:0]		icpu_adr_o;
output	[3:0]			icpu_tag_o;
output				icpu_rty_o;
output				icpu_err_o;

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[aw-1:0]		spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// IC I/F
//
input				qmemimmu_rty_i;
input				qmemimmu_err_i;
input	[3:0]			qmemimmu_tag_i;
output	[aw-1:0]		qmemimmu_adr_o;
output				qmemimmu_cycstb_o;
output				qmemimmu_ci_o;

//
// Internal wires and regs
//
wire				itlb_spr_access;
wire	[31:`OR1200_IMMU_PS]	itlb_ppn;
wire				itlb_hit;
wire				itlb_uxe;
wire				itlb_sxe;
wire	[31:0]			itlb_dat_o;
wire				itlb_en;
wire				itlb_ci;
wire				itlb_done;
wire				fault;
wire				miss;
wire				page_cross;
reg	[31:0]			icpu_adr_o;
reg	[31:`OR1200_IMMU_PS]	icpu_vpn_r;
`ifdef OR1200_NO_IMMU
`else
reg				itlb_en_r;
reg				dis_spr_access;
`endif

//
// Implemented bits inside match and translate registers
//
// itlbwYmrX: vpn 31-10  v 0
// itlbwYtrX: ppn 31-10  uxe 7  sxe 6
//
// itlb memory width:
// 19 bits for ppn
// 13 bits for vpn
// 1 bit for valid
// 2 bits for protection
// 1 bit for cache inhibit

//
// icpu_adr_o
//
`ifdef OR1200_REGISTERED_OUTPUTS

// SynEDA CoreMultiplier
// assignment(s): icpu_adr_o
// replace(s): icpu_adr_i, icpu_adr_o
always @(posedge rst or posedge clk)
	if (rst)
		icpu_adr_o <= #1 32'h0000_0100;
	else begin  icpu_adr_o <= icpu_adr_o_cml_3;
		icpu_adr_o <= #1 icpu_adr_i_cml_3; end
`else
Unsupported !!!
`endif

//
// Page cross
//
// Asserted when CPU address crosses page boundary. Most of the time it is zero.
//

// SynEDA CoreMultiplier
// assignment(s): page_cross
// replace(s): icpu_adr_i, icpu_vpn_r
assign page_cross = icpu_adr_i_cml_2[31:`OR1200_IMMU_PS] != icpu_vpn_r_cml_2;

//
// Register icpu_adr_i's VPN for use when IMMU is not enabled but PPN is expected to come
// one clock cycle after offset part.
//

// SynEDA CoreMultiplier
// assignment(s): icpu_vpn_r
// replace(s): icpu_adr_i, icpu_vpn_r
always @(posedge clk or posedge rst)
	if (rst)
		icpu_vpn_r <= #1 {32-`OR1200_IMMU_PS{1'b0}};
	else begin  icpu_vpn_r <= icpu_vpn_r_cml_3;
		icpu_vpn_r <= #1 icpu_adr_i_cml_3[31:`OR1200_IMMU_PS]; end

`ifdef OR1200_NO_IMMU

//
// Put all outputs in inactive state
//
assign spr_dat_o = 32'h00000000;
assign qmemimmu_adr_o = icpu_adr_i;
assign icpu_tag_o = qmemimmu_tag_i;
assign qmemimmu_cycstb_o = icpu_cycstb_i & ~page_cross;
assign icpu_rty_o = qmemimmu_rty_i;
assign icpu_err_o = qmemimmu_err_i;
assign qmemimmu_ci_o = `OR1200_IMMU_CI;
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif
`else

//
// ITLB SPR access
//
// 1200 - 12FF  itlbmr w0
// 1200 - 123F  itlbmr w0 [63:0]
//
// 1300 - 13FF  itlbtr w0
// 1300 - 133F  itlbtr w0 [63:0]
//
assign itlb_spr_access = spr_cs & ~dis_spr_access;

//
// Disable ITLB SPR access
//
// This flop is used to mask ITLB miss/fault exception
// during first clock cycle of accessing ITLB SPR. In
// subsequent clock cycles it is assumed that ITLB SPR
// access was accomplished and that normal instruction fetching
// can proceed.
//
// spr_cs sets dis_spr_access and icpu_rty_o clears it.
//

// SynEDA CoreMultiplier
// assignment(s): dis_spr_access
// replace(s): icpu_rty_o, spr_cs, dis_spr_access
always @(posedge clk or posedge rst)
	if (rst)
		dis_spr_access <= #1 1'b0;
	else begin  dis_spr_access <= dis_spr_access_cml_3; if (!icpu_rty_o_cml_3)
		dis_spr_access <= #1 1'b0;
	else if (spr_cs_cml_3)
		dis_spr_access <= #1 1'b1; end

//
// Tags:
//
// OR1200_DTAG_TE - TLB miss Exception
// OR1200_DTAG_PE - Page fault Exception
//

// SynEDA CoreMultiplier
// assignment(s): icpu_tag_o
// replace(s): fault, miss
assign icpu_tag_o = miss_cml_3 ? `OR1200_DTAG_TE : fault_cml_3 ? `OR1200_DTAG_PE : qmemimmu_tag_i;

//
// icpu_rty_o
//
// assign icpu_rty_o = !icpu_err_o & qmemimmu_rty_i;

// SynEDA CoreMultiplier
// assignment(s): icpu_rty_o
// replace(s): immu_en, itlb_spr_access
assign icpu_rty_o = qmemimmu_rty_i | itlb_spr_access_cml_1 & immu_en_cml_1;

//
// icpu_err_o
//

// SynEDA CoreMultiplier
// assignment(s): icpu_err_o
// replace(s): qmemimmu_err_i
assign icpu_err_o = miss | fault | qmemimmu_err_i_cml_2;

//
// Assert itlb_en_r after one clock cycle and when there is no
// ITLB SPR access
//

// SynEDA CoreMultiplier
// assignment(s): itlb_en_r
// replace(s): itlb_spr_access, itlb_en_r
always @(posedge clk or posedge rst)
	if (rst)
		itlb_en_r <= #1 1'b0;
	else begin  itlb_en_r <= itlb_en_r_cml_3;
		itlb_en_r <= #1 itlb_en & ~itlb_spr_access_cml_3; end

//
// ITLB lookup successful
//

// SynEDA CoreMultiplier
// assignment(s): itlb_done
// replace(s): itlb_en_r
assign itlb_done = itlb_en_r_cml_2 & ~page_cross;

//
// Cut transfer if something goes wrong with translation. If IC is disabled,
// use delayed signals.
//
// assign qmemimmu_cycstb_o = (!ic_en & immu_en) ? ~(miss | fault) & icpu_cycstb_i & ~page_cross : (miss | fault) ? 1'b0 : icpu_cycstb_i & ~page_cross; // DL

// SynEDA CoreMultiplier
// assignment(s): qmemimmu_cycstb_o
// replace(s): immu_en, itlb_done, fault, miss, page_cross
assign qmemimmu_cycstb_o = immu_en_cml_3 ? ~(miss_cml_3 | fault_cml_3) & icpu_cycstb_i & ~page_cross_cml_3 & itlb_done_cml_3 : icpu_cycstb_i & ~page_cross_cml_3;

//
// Cache Inhibit
//
// Cache inhibit is not really needed for instruction memory subsystem.
// If we would doq it, we would doq it like this.
// assign qmemimmu_ci_o = immu_en ? itlb_done & itlb_ci : `OR1200_IMMU_CI;
// However this causes a async combinational loop so we stick to
// no cache inhibit.
assign qmemimmu_ci_o = `OR1200_IMMU_CI;


//
// Physical address is either translated virtual address or
// simply equal when IMMU is disabled
//

// SynEDA CoreMultiplier
// assignment(s): qmemimmu_adr_o
// replace(s): icpu_adr_i, itlb_ppn, icpu_vpn_r
assign qmemimmu_adr_o = itlb_done ? {itlb_ppn_cml_2, icpu_adr_i_cml_2[`OR1200_IMMU_PS-1:0]} : {icpu_vpn_r_cml_2, icpu_adr_i_cml_2[`OR1200_IMMU_PS-1:0]}; // DL: immu_en

//
// Output to SPRS unit
//

// SynEDA CoreMultiplier
// assignment(s): spr_dat_o
// replace(s): spr_cs
assign spr_dat_o = spr_cs_cml_2 ? itlb_dat_o : 32'h00000000;

//
// Page fault exception logic
//

// SynEDA CoreMultiplier
// assignment(s): fault
// replace(s): supv, itlb_uxe, itlb_sxe
assign fault = itlb_done &
			(  (!supv_cml_2 & !itlb_uxe_cml_2)		// Execute in user mode not enabled
			|| (supv_cml_2 & !itlb_sxe_cml_2));		// Execute in supv mode not enabled

//
// TLB Miss exception logic
//
assign miss = itlb_done & !itlb_hit;

//
// ITLB Enable
//

// SynEDA CoreMultiplier
// assignment(s): itlb_en
// replace(s): immu_en
assign itlb_en = immu_en_cml_3 & icpu_cycstb_i;

//
// Instantiation of ITLB
//
or1200_immu_tlb_cm4 or1200_immu_tlb(
		.clk_i_cml_1(clk_i_cml_1),
		.clk_i_cml_2(clk_i_cml_2),
		.clk_i_cml_3(clk_i_cml_3),
		.cmls(cmls),
	// Rst and clk
        .clk(clk),
	.rst(rst),

        // I/F for translation
        .tlb_en(itlb_en),
	.vaddr(icpu_adr_i),
	.hit(itlb_hit),
	.ppn(itlb_ppn),
	.uxe(itlb_uxe),
	.sxe(itlb_sxe),
	.ci(itlb_ci),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_si_i),
	.mbist_so_o(mbist_so_o),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

        // SPR access
        .spr_cs(itlb_spr_access),
	.spr_write(spr_write),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_i),
	.spr_dat_o(itlb_dat_o)
);

`endif


always @ (posedge clk_i_cml_1) begin
immu_en_cml_1 <= immu_en;
icpu_adr_o_cml_1 <= icpu_adr_o;
spr_cs_cml_1 <= spr_cs;
itlb_spr_access_cml_1 <= itlb_spr_access;
icpu_vpn_r_cml_1 <= icpu_vpn_r;
itlb_en_r_cml_1 <= itlb_en_r;
dis_spr_access_cml_1 <= dis_spr_access;
end
always @ (posedge clk_i_cml_2) begin
immu_en_cml_2 <= immu_en_cml_1;
supv_cml_2 <= supv;
icpu_adr_i_cml_2 <= icpu_adr_i;
icpu_adr_o_cml_2 <= icpu_adr_o_cml_1;
icpu_rty_o_cml_2 <= icpu_rty_o;
spr_cs_cml_2 <= spr_cs_cml_1;
qmemimmu_err_i_cml_2 <= qmemimmu_err_i;
itlb_spr_access_cml_2 <= itlb_spr_access_cml_1;
itlb_ppn_cml_2 <= itlb_ppn;
itlb_uxe_cml_2 <= itlb_uxe;
itlb_sxe_cml_2 <= itlb_sxe;
icpu_vpn_r_cml_2 <= icpu_vpn_r_cml_1;
itlb_en_r_cml_2 <= itlb_en_r_cml_1;
dis_spr_access_cml_2 <= dis_spr_access_cml_1;
end
always @ (posedge clk_i_cml_3) begin
immu_en_cml_3 <= immu_en_cml_2;
icpu_adr_i_cml_3 <= icpu_adr_i_cml_2;
icpu_adr_o_cml_3 <= icpu_adr_o_cml_2;
icpu_rty_o_cml_3 <= icpu_rty_o_cml_2;
spr_cs_cml_3 <= spr_cs_cml_2;
itlb_spr_access_cml_3 <= itlb_spr_access_cml_2;
itlb_done_cml_3 <= itlb_done;
fault_cml_3 <= fault;
miss_cml_3 <= miss;
page_cross_cml_3 <= page_cross;
icpu_vpn_r_cml_3 <= icpu_vpn_r_cml_2;
itlb_en_r_cml_3 <= itlb_en_r_cml_2;
dis_spr_access_cml_3 <= dis_spr_access_cml_2;
end
endmodule

