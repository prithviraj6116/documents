# -*-gdb-script-*-

#--------------------------------------------------------------#
# SBTools GDB setup. See sbgdb help, http://inside.mathworks.com/wiki/SBTools#sbgdb #
#--------------------------------------------------------------#
#

source /mathworks/hub/share/sbtools/.gdbinit
# set auto-solib-add off
# shar stateflow
source /sandbox/savadhan/sbtools/mw-gdbscripts/.gdbinit

# Uncomment following to improve debugging STL, etc. (see sb-gdb).
# load-sbtools-python-extensions
# or type it when desired while running gdb.

#------------------#
# MATLAB debugging #
#------------------#
#set auto-solib-add off
#set auto-solib-add off
define loadsymsSFML
  # libraries needed so breaksegv works:
  sharedlibrary libmwmcr.so
  sharedlibrary libmwfl.so
  # libraries I work on:
  sharedlibrary libmex.so
  sharedlibrary libmwm_dispatcher.so
  sharedlibrary libmwm_interpreter.so
  sharedlibrary libmwservices.so
  sharedlibrary libmwlxeindexing.so
  sharedlibrary libmwlxeirgen.so
  sharedlibrary libmwm_lxe.so
  sharedlibrary libmwlxeinterfaces.so
  sharedlibrary libmwlxetypes.so
  sharedlibrary libmwmexcheck_builtin.so
  sharedlibrary libmwsaveload.so
  # display breakpoint status, so one knows symbols were loaded
  info break
end
define loadsymsSF
  # libraries needed so breaksegv works:
  sharedlibrary libmwmcr.so
  sharedlibrary libmwfl.so
  # libraries I work on:
  sharedlibrary libmwcgir_algorithm.so
  sharedlibrary libmwcgir_cgel.so
  sharedlibrary libmwcgir_clair.so
  sharedlibrary libmwcgir_construct.so
  sharedlibrary libmwcgir_cpp_emitter.so
  sharedlibrary libmwcgir_dvir.so
  sharedlibrary libmwcgir_eml_emitter.so
  sharedlibrary libmwcgir_fe.so
  sharedlibrary libmwcgir_fixpt.so
  sharedlibrary libmwcgir_float2fixed.so
  sharedlibrary libmwcgir_gpu.so
  sharedlibrary libmwcgir_hdl.so
  sharedlibrary libmwcgir_interp.so
  sharedlibrary libmwcgir_mi.so
  sharedlibrary libmwcgir_plc.so
  sharedlibrary libmwcg_ir.so
  sharedlibrary libmwcgir_spike.so
  sharedlibrary libmwcgir_support.so
  sharedlibrary libmwcgir_tests.so
  sharedlibrary libmwcgir_tfl.so
  sharedlibrary libmwcgir_vm_rt.so
  sharedlibrary libmwcgir_vm.so
  sharedlibrary libmwcgir_xform.so
  sharedlibrary libmweml.so
  sharedlibrary libmwpd_cg_ir.so
  sharedlibrary libmwrtwcg.so
  sharedlibrary libmwsf_badges.so
  sharedlibrary libmwsfdi_datamodel_mi.so
  sharedlibrary libmwsfdi_datamodel.so
  sharedlibrary libmwsf_editor.so
  sharedlibrary libmwsf_runtime.so
  sharedlibrary libmwsf_test_infrastructure.so
  sharedlibrary libmwsf_transform_tests.so
  sharedlibrary libmwstateflow_resolver.so
  sharedlibrary libmwstateflow.so
  sharedlibrary libmwsf_ir.so
  sharedlibrary libmwsf_xform.so
  sharedlibrary libmwsimulink_cmd_file


  # display breakpoint status, so one knows symbols were loaded
  info break
end
#---------------------#
# Unit test debugging #
#---------------------#
define loadprog
  if ($argc != 1)
    echo PROGRAM to debug is missing\n
  else
    set auto-solib-add on
    file $arg0
  end
end

breaksegv
