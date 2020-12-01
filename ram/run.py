#!/bin/python
from os.path import join, dirname
from subprocess import call
from vunit import VUnit

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "coverage_data"])

def create_test_suite(prj):
    root = dirname(__file__)

    lib = prj.add_library("ram_lib")
    lib.add_source_files(join(root, "./hdl/*.vhd"))
    lib.add_source_files(join(root, "./testbench/*.vhd"))

    prj.add_osvvm()
    prj.add_random()

    # configure simulator
    if prj.get_simulator_name() == "ghdl":
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

        lib.set_sim_option("enable_coverage", True)
        lib.set_compile_option("enable_coverage", True)

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

    tb_ram_dp = lib.test_bench("tb_ram_dp")
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


if __name__ == "__main__":
    VU = VUnit.from_argv()
    VU.add_osvvm()
    create_test_suite(VU)
    #VU.main()
    VU.main(post_run=post_run)
