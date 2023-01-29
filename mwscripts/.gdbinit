# -*-gdb-script-*-

#--------------------------------------------------------------#
# SBTools GDB setup. See sbgdb help, http://inside.mathworks.com/wiki/SBTools#sbgdb #
#--------------------------------------------------------------#
#


#source /mathworks/hub/share/sbtools/.gdbinit
#set height 0
set breakpoint pending on
#breaksegv

#define ppr
#    call pp($arg0, "/tmp/foo.html")
#end



#define load_common_libs
#    sb-auto-load-libs libmw\(stateflow\|sf_\)
#    sb-auto-load-libs libmw\(cg_ir\|cgir_support\|cgir_xform\)
#    sb-auto-load-libs libmw\(mcr\|fl\|sl_services\)
#    sb-auto-load-libs sf_sfun
#    sb-auto-load-libs sf_req
#    #sb-auto-load-libs sf_builtin
#    #sb-auto-load-libs sf.mexa64
#    #sb-auto-load-libs libmwlxemainservices
#    #sb-auto-load-libs libmex
#    #sb-auto-load-libs libmwm_dispatcher
#end
define load_common_libs2
    sharedlibrary libmwstateflow.so
end

define mstackr
  printf "--start--stack---m"
  printf "%s", SF::dbstack()
  printf "--end--stack---m\n"
end

define quick_attach_sf
    set auto-solib-add off
    attach $arg0
    load_common_libs2
end


define mstack
  printf "%s", SF::dbstack()
end



















define locals-up
  set $n    = ($arg0)
  set $upto = $n
  while $upto > 0
    info locals
    up-silently 1                                                                
    set $upto = $upto - 1
  end
  down-silently $n
end
document locals-up
  locals-up <n>: Lists local variables of n frames
end

define pps
    call pp($arg0, "/tmp/foo.html")
    shell x-www-browser /tmp/foo.html &
end
document pps
Call pp (the CGIR pretty printer), placing the output in /tmp/foo.html.
Also opens this file in firefox.
end

define bex
    breaksegv
    break SF::assertion_failed
    break ThrowAssertion
end
document bex
Break on a few common assertions etc.
end

handle SIGSEGV nostop noprint

document mstack
Dumps the MATLAB callstack (dbstack)
end

define d
    disable
end
define e
    enable
end
define a1
    set auto-solib-add off
    attach $arg0
    #sharedlibrary libmwstateflow
    load_ml_libs
    sb-auto-load-libs libmwstateflow
    #load_sf_libs
    #loadsymsSF
    #sharedlibrary stateflow/sf_sfun.mexa64
end
define load_ml_libs
    # libraries needed so breaksegv works:
    sharedlibrary libmwmcr.so
    sharedlibrary libmwfl.so
end
define load_sl_libs
    sharedlibrary libmwcg_ir.so
    sharedlibrary libmwsl_services.so
    sharedlibrary libmwcgir_xform.so
    sharedlibrary libmwcgir_support.so
    sharedlibrary libmwsl_graphical_classes.so
    sharedlibrary libmwsl_engine.so
    sharedlibrary libmwsl_engine_classes.so
    sharedlibrary libmwsl_lang_blocks.so
    sharedlibrary libmwsimulink.so
end
define load_sf_libs
    sharedlibrary libmwstateflow.so
    sharedlibrary stateflow/sf_sfun.mexa64
    sharedlibrary libmwsf_runtime.so
    sharedlibrary libmwsf_variants.so
end

define sfdebug1
    set auto-solib-add off
    attach $arg0
    load_common_libs
end






# shar stateflow
#source /sandbox/savadhan/sbtools/mw-gdbscripts/.gdbinit
#source /mathworks/inside/labs/dev/matlab_coder_tools/ydebug/ydebug.gdb

# Uncomment following to improve debugging STL, etc. (see sb-gdb).
# load-sbtools-python-extensions
# or type it when desired while running gdb.

#------------------#
# MATLAB debugging #
#------------------#
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
  sharedlibrary libmwcompiler.so

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
  #info break
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


define tb1
    set $bpn = 1
    #tbreak $arg0$arg1
    while ($bpn < $arg1)
        tbreak $arg0"$bpn"
        p $bpn = $bpn + 1
    end
end
define tb2
    set $bpn = 1
    #tbreak $arg0$arg1
    while ($bpn < $arg1)
        tbreak $arg0$bpn
        p $bpn = $bpn + 1
    end
end
define tb3
    set $bpn = 1
    #tbreak $arg0$arg1
    while ($bpn < $arg1)
        tbreak $arg0:"$bpn"
        p $bpn = $bpn + 1
    end
end

