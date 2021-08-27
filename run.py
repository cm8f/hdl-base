#!/bin/python

from os.path import join,dirname
from vunit import VUnit, VUnitCLI
from glob import glob
from subprocess import call
import imp

def vhdl_ls(VU):
    libs = []
    srcfiles = VU.get_compile_order()
    for so in srcfiles:
        try:
            libs.index(so.library.name)
        except:
            libs.append(so.library.name)
    
    fd = open("vhdl_ls.toml", "w")
    fd.write("[libraries]\n")

    for l in libs:
        fd.write("%s.files = [\n" % l)

        flist = VU.get_source_files(library_name=l) 
        for f in flist:
            fd.write("  '%s',\n" % f.name)

        fd.write("]\n\n") 
    
    fd.close()

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "--exclude-unreachable-branches", "--exclude-unreachable-branches", "-x", "coverage.xml", "coverage_data"])
        #call(["gcovr", "--exclude-unreachable-branches", "--exclude-unreachable-branches", "-o", "coverage.txt", "--fail-under-line", "100", "coverage_data"])


cli = VUnitCLI()
cli.parser.add_argument('--cover', action='store_true', help='Enable ghdl coverage')
cli.parser.add_argument('--vhdl_ls', action='store_true', help='Generate vhdl_ls toml file')
args = cli.parse_args()

VU = VUnit.from_args(args=args)
VU.add_osvvm()
VU.add_random()
VU.add_com()
VU.add_verification_components()

root = dirname(__file__)

lib = VU.add_library("work_lib")
lib.add_source_files(join(root, "./*/hdl/*.vhd"))
lib.add_source_files(join(root, "./*/testbench/*.vhd"))

losvvm = VU.library("osvvm")
losvvm.add_source_files(join(root, "./osvvm/*.vhd"))

# configure simulator
if VU.get_simulator_name() == "ghdl":
    lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
    lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
    lib.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])
    if args.cover > 0:
        lib.set_sim_option("enable_coverage", True)
        lib.set_compile_option("enable_coverage", True)



tb_arbiter_rr = lib.test_bench("tb_arbiter_rr")
for test in tb_arbiter_rr.get_tests():
    for ports in [1, 2, 3, 4]:
        test.add_config(
            name="ports=%d" % ports, 
            generics=dict(
               g_number_ports = ports
            )
        )

depths = [64, 128, 256, 512]
widths = [8, 16, 32]
oreg = [True, False]

tb_fifo_sc_mixed = lib.test_bench("tb_fifo_sc_mixed")
for test in tb_fifo_sc_mixed.get_tests():
    for wr_width in widths:
        for rd_width in widths:
            for wr_depth in depths:
                for reg in oreg:
                    test.add_config(
                        name="wrwidth=%d,rdwidth=%d,wrdepth=%d,reg=%s" % (wr_width, rd_width, wr_depth, reg),
                        generics=dict(
                            g_wr_width=wr_width,
                            g_rd_width=rd_width,
                            g_wr_depth=wr_depth,
                            g_output_reg=reg
                        )
                    )

tb_ram_sp = lib.test_bench("tb_ram_sp")
addrw = [8, 9, 10]
widths = [8, 16]
oreg = [True, False]
for test in tb_ram_sp.get_tests():
    for width in widths:
        for reg in oreg:
            for awidth in addrw:
                test.add_config(
                    name="width=%d,depth=%d,reg=%s" %(width, 2<<(awidth-1), reg),
                    generics=dict(
                        g_addr_width=awidth,
                        g_width=width,
                        g_register=reg
                    )
                )

tb_ram_dp = lib.test_bench("tb_ram_tdp")
for test in tb_ram_dp.get_tests():
    for width in widths:
        for reg in oreg:
            for awidth in addrw:
                test.add_config(
                    name="width=%d,depth=%d,reg=%s" %(width, 2<<(awidth-1), reg),
                    generics=dict(
                        g_addr_width=awidth,
                        g_width=width,
                        g_register=reg
                    )
                )

depths = [512, 256]
widths = [4, 8, 16, 32]
tb_ram_sdp = lib.test_bench("tb_ram_sdp")
for test in tb_ram_sdp.get_tests():
    for depth_a in depths:
        for width_a in widths:
            for width_b in widths:
                depth_b = int(depth_a * width_a / width_b)
                for reg in oreg:
                    # due to memory model limitation
                    if not (width_a == 32 and width_b == 32):
                        test.add_config(
                            name="deptha=%d,depthb=%d,widtha=%d,widthb=%d,reg=%s" % (depth_a, depth_b, width_a, width_b, reg),
                            generics=dict(
                                g_width_a=width_a,
                                g_width_b=width_b,
                                g_depth_a=depth_a,
                                g_depth_b=depth_b,
                                g_register=reg
                            )
                        )

tb_reset_ctrl = lib.test_bench("tb_reset")
for test in tb_reset_ctrl.get_tests():
    for sync in [True, False]:
        test.add_config(
            name="sync_reset=%s" % sync,
            generics=dict(
                g_sync=sync
            )
        )


if args.vhdl_ls:
    vhdl_ls(VU)

if args.cover:
    VU.main(post_run=post_run)
else:
    VU.main()
