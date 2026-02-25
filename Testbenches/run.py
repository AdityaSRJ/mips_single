from vunit import VUnit



# 1. Initialize with explicit builtin compilation enabled

ui = VUnit.from_argv(compile_builtins=True)



# 2. EXPLICITLY add the VUnit Verification Components

# This forces it to build the "vunit_pkg" that ModelSim is missing

#  ui.add_vhdl_builtins()

ui.add_verilog_builtins()



# 3. Create your library

lib = ui.add_library("lib")

lib.add_source_files("*.v")

lib.add_source_files("*.sv")



# 4. Run 

ui.main()