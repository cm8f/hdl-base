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
        #call(["gcovr", "--exclude-unreachable-branches", "--exclude-unreachable-branches", "-x", "coverage.xml", "coverage_data"])
        call(["gcovr", "--exclude-unreachable-branches", "--exclude-unreachable-branches", "-o", "coverage.txt", "--fail-under-line", "100", "coverage_data"])

def create_test_suites(prj, args):
    root = dirname(__file__)
    run_scripts = glob(join(root, "*", "run.py"))

    for run_script in run_scripts:
        file_handle, path_name, description = imp.find_module("run", [dirname(run_script)])
        run = imp.load_module("run", file_handle, path_name, description)
        run.create_test_suite(prj, args)
        file_handle.close()


cli = VUnitCLI()
cli.parser.add_argument('--cover', action='store_true', help='Enable ghdl coverage')
cli.parser.add_argument('--vhdl_ls', action='store_true', help='Generate vhdl_ls toml file')
args = cli.parse_args()

VU = VUnit.from_args(args=args)
VU.add_osvvm()
create_test_suites(VU, args)

if args.vhdl_ls:
    vhdl_ls(VU)

if args.cover:
    VU.main(post_run=post_run)
else:
    VU.main()
