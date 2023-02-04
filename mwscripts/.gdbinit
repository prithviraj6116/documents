# -*-gdb-script-*-

set height 0
set breakpoint pending on
#breaksegv

define pps
    call pp($arg0, "/tmp/foo.html")
end


define sfbreaksegv1
  handle SIGSEGV nostop noprint pass
  break assertion_func
  break mnDebugRuntimeFault
  break svHandleSignalFaults
  break fl_diag_terminate
  break SF::assertion_failed
  break ThrowAssertion
  break client_assertion_failed(char const*, int, char const*)
  break rtwcg_assertion_failed
  break SF::Lint::MATLAB_GDB_Debugger
end

define load_common_libs_lcm
    sharedlibrary libmwstateflow
    sharedlibrary libmwsf_
    sharedlibrary libmwcg_ir
    sharedlibrary libmwcgir_support
    sharedlibrary libmwcgir_xform
    sharedlibrary libmwmcr
    sharedlibrary libmwfl
    sharedlibrary libmwsl_services
    sharedlibrary libmwlxemainservices
    sharedlibrary libmex
    sharedlibrary libmwm_dispatcher
end

define mstackr
  printf "--start--stack---m"
  printf "%s", SF::dbstack()
  printf "--end--stack---m\n"
end

define quick_attach_sf
    set auto-solib-add off
    attach $arg0
    load_common_libs_lcm
    sfbreaksegv1
end



















