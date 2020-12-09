#!/bin/python
from os.path import join, dirname
from subprocess import call
from vunit import VUnit, VUnitCLI

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "-x", "coverage.xml", "coverage_data"])
        call(["gcovr", "-o", "coverage.txt", "coverage_data"])

def create_test_suite(prj, args):
    root = dirname(__file__)

    losvvm = prj.library("osvvm")
    losvvm.add_source_files(join(root, "../osvvm/*"))

    try:
        lib = prj.library("work_lib")
    except:
        lib = prj.add_library("work_lib")
    lib.add_source_files(join(root, "./hdl/*.vhd"))
    #lib.add_source_files(join(root, "../ram/hdl/*.vhd"))
    lib.add_source_files(join(root, "./testbench/*.vhd"))

    prj.add_osvvm()
    prj.add_random()

    # configure simulator
    if prj.get_simulator_name() == "ghdl":
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])
        if args.cover > 0:
            lib.set_sim_option("enable_coverage", True)
            lib.set_compile_option("enable_coverage", True)

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


if __name__ == "__main__":
    cli = VUnitCLI()
    cli.parser.add_argument('--cover', type=int, default=0, help='Enable ghdl coverage')
    args = cli.parse_args()

    VU = VUnit.from_args(args=args)
    VU.add_osvvm()
    create_test_suite(VU, args)
    if args.cover < 1:
        VU.main()
    else:
        VU.main(post_run=post_run)
