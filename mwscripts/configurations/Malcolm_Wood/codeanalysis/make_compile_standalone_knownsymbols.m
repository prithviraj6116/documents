function make_compile_standalone_knownsymbols(header,message)

if nargin<2 || isempty(message)
    try
        sbcc(header);
        fprintf('Compiled without error\n');
        return;
    catch E
        message = E.message;
    end
end

fulldefs = containers.Map;
fulldefs('class SLSampleTimePrmDesc') = 'SimulinkBlock/SLSampleTimePrmDesc.hpp';
fulldefs('class SLBlock') = 'SimulinkBlock/SLCoreBlock.hpp';
fulldefs('class SLModelTiming') = 'SimulinkBlock/SLModelTiming_def.hpp';
fulldefs('class SLPrmDescList') = 'SimulinkBlock/SLPrmDescList.hpp';
fulldefs('class SLSampleTimePrmDesc') = 'SimulinkBlock/SLSampleTimePrmDesc.hpp';

incomplete_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: invalid use of incomplete type ''(const )?(?<symbol>[^'']*)''','names');
for i=1:numel(incomplete_symbols)
    s = incomplete_symbols(i).symbol;
    if fulldefs.isKey(s)
        insert_header(incomplete_symbols(i).file,fulldefs(s));
    end
end


symbols = containers.Map;

symbols('Point') = 'gui/ui_types.hpp';
symbols('Rect') = 'gui/ui_types.hpp';
symbols('WinRec') = 'gui/ui_types.hpp';

symbols('mxArray') = 'matrix/matrix_fwd.hpp';
symbols('slsvDiagnostic') = 'sl_services/slsv_diagnostic_forward.hpp';
symbols('SLRootBD') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slSegment') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slGraph') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slLine') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slLine') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slPort') = 'sl_graphical_classes/graphical_fwd.hpp';
symbols('slCommand') = 'sl_graphical_classes/slCommand.hpp';
symbols('SlSigHierInfoIter') = 'sl_graphical_classes/SlSigHierInfo.hpp';

symbols('fxpArrayProp') = 'fixpoint/fxp_array_prop.hpp';
symbols('fxpScalarUnionAll') = 'fixpoint/BasicTypes/fxpScalarUnionAll.hpp';
symbols('fxpBlockProperties') = 'fixpoint/fxpBlockProperties.hpp';
symbols('SLPrmDesc') = 'sl_prm_descriptor/sl_prm_descriptor_fwd.hpp';
symbols('SLBlock') = 'SimulinkBlock/SimulinkBlock_fwd.hpp';
symbols('SLExecBlock') = 'SimulinkBlock/SimulinkBlock_fwd.hpp';
symbols('SlBlockContext') = 'SimulinkBlock/SimulinkBlock_fwd.hpp';
symbols('slSimBlock') = 'SimulinkBlock/SimulinkBlock_fwd.hpp';
symbols('SLMaskInterface') = 'SimulinkBlock/SimulinkBlock_fwd.hpp';
symbols('SlDims') = 'SimulinkBlock/SlDims.hpp';
symbols('FixptRec') = 'SimulinkBlock/FixptRec.hpp';
symbols('slAggParamTableEl') = 'sl_prm_engine/parameter_def.hpp';
symbols('DTypeId') = 'fixpoint/fixpoint_DTypeId.hpp';
symbols('SLSVMWObjectBase') = 'sl_services/slsv_mwobject.hpp';
symbols('slsvString') = 'sl_services/slsvStringTable.hpp';
symbols('Init_fxpArrayProp') = 'SimulinkBlock/BlockFixptSettingsFcn.hpp';
symbols('BDErrorValue') = 'simstruct/sl_datatype_access.h';
symbols('StringOrID') = 'sl_prm_descriptor/StringOrID.hpp';

symbols('slDataTypeTable') = 'sl_obj/slDataTypeTable.hpp';

symbols('SLCompBus') = 'simulink/sl_types_compile.hpp';
symbols('slModel') = 'simulink/sl_types_sim.hpp';
symbols('ECStatus') = 'simulink/sl_types_misc.hpp';
symbols('WorkProcMode') = 'simulink/sl_types_misc.hpp';

symbols('bdCompInfo') = 'sl_engine_classes/bdCompInfo.hpp';
symbols('SleTmpActSrcs') = 'sl_engine_classes/SLCData.hpp';
symbols('SleActDsts') = 'sl_engine_classes/SLCData.hpp';
symbols('SLCompBD') = 'sl_engine_classes/SLCompBD.hpp';

symbols('BlockCapCreator') = 'simulink/bcst_friends.hpp';
symbols('UDInterface') = 'simulink/sl_types_udd.hpp';
symbols('UDClass') = 'simulink/sl_types_udd.hpp';
symbols('Vector') = 'simulink/sl_types_udd.hpp';
symbols('BlockRTIMthCallFcn') = 'simulink/sl_types_avoid_warnings.hpp';
symbols('sl_vector') = 'simulink/slstlwraps.hpp';
symbols('BlockRTIEventType') = 'simulink/sl_types_compile.hpp';
symbols('BdWriteInfo') = 'sl_util/bdwrite.hpp';
symbols('SlVariable') = 'sl_prm_engine/SlVariable.hpp';
symbols('utStrcmp') = 'util/strfun.hpp';
symbols('utStrdup') = 'util/strfun.hpp';
symbols('utFree') = 'util/memmgr/memalloc.hpp';
symbols('utMalloc') = 'util/memmgr/memalloc.hpp';
symbols('utAssert') = 'util/utassert.hpp';
symbols('fl') = 'fl/ustring.hpp'; % most likely

symbols('shared_ptr'' in namespace ''boost') = 'boost/shared_ptr.hpp';
symbols('scoped_ptr'' in namespace ''boost') = 'boost/scoped_ptr.hpp';
symbols('vector'' in namespace ''std') = 'vector';
symbols('set'' in namespace ''std') = 'set';
symbols('map'' in namespace ''std') = 'map';

k = symbols.keys;
for i=1:numel(k)
    r = ['''' k{i} ''' does not name a type'];
    if ~isempty(regexp(message,r,'once'))
        v = symbols.values;
        insert_header(header,v{i});
        continue;
    end
    r = ['''' k{i} ''' was not declared in this scope'];
    if ~isempty(regexp(message,r,'once'))
        v = symbols.values;
        insert_header(header,v{i});
        continue;
    end
    r = ['''' k{i} ''' has not been declared'];
    if ~isempty(regexp(message,r,'once'))
        v = symbols.values;
        insert_header(header,v{i});
        continue;
    end
    r = ['no arguments to ''' k{i} ''' that depend on'];
    if ~isempty(regexp(message,r,'once'))
        v = symbols.values;
        insert_header(header,v{i});
        continue;
    end
end

try
    sbcc(header);
catch E
    edit(header);
    fprintf('<a href="matlab:make_compile_standalone %s\n">make_compile_standalone %s</a>\n',header,header);
    rethrow(E);
end
fprintf('Compiled without error\n');

