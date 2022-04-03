#!/usr/bin/env bash

ROOTDIR=`pwd`
cd ${ROOTDIR}
sbcpptags -mods-all
#slengine foundation/matrix shared/cgxe cgir_vm_rt   shared_simulink_lang_blocks sl_utility sl_compile sl_services sl_graphical_classes sl_loadsave
sb -update-debug-source-path

