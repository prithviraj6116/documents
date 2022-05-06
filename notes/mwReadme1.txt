1. c chart, local data, DRSO, bus type: IV is not taken from signal object   
2. symbol window hover over sfix shows double type
3. whos in MATLAB command line shows bytes column. for string and fi objects, its values are confusing
4. does cdr_data_reset_props leak memory
5. non-string initial value for string data cal:ignore mal:error
6. SF::parse_data_types: slLocalErrorMessage not used
sf param data inherit/-1/VS (slparam=double/4)(or slparam=bus/4):
C chart: ignores VS
M chart: throws following error but no way of removing VS
         Error:Parameters for variable-size arrays are currently unsupported
7. allowed types:?enum, Bus: ?enum, busObject
8. do we need     "} else if (!(data_is_external_dsm(data) || data_is_inplace_output_in_eml_chart(data))) {SF::ppp_print(__FILE__, __LINE__);" in SF::parse_data_size


C/M chart does not vectorize slparam(busobject/1) to sfparam data(busobject/4)
C/M chart does     vectorize slparam(double/1) to sfparam data(double/4)

C chart does        vectorize slparam(double/1) to sfoutdataIVFW data(double/4)
M chart does   NOT  vectorize slparam(double/1) to sfoutdataIVFW data(double/4)
C/M chart does NOT  vectorize slparam(busobject/1) to sfoutdataIVFW data(busobject/4)



fix1: for param_scope, disable/ignore VS and IVFW,IV
fix2: for bus l/o/fi/fo: enable IV/IVFW, disable VS
fix3: for bus i/: disable IV/IVFW, disable VS



M: param explicit bus type scalar, VS field : crash
C: param explicit bus type scalar, VS field : throws confusing error "Stateflow supports dynamic matrices only as inputs or outputs of a chart, a MATLAB function, or a Simulink function. As a result, data 'a1' is not supported."


M(ignore): output data IVFW(1) VS(1) busobject/1  slparam(busobject/1) 
C(ignore): output data IVFW(1) VS(1) busobject/1  slparam(busobject/1) 

M(runtime error + crash): output data IVFW(1) VS(0) busobject/1  slparam(busobject/1) bus has variable field
C(runtime error + crash): output data IVFW(1) VS(0) busobject/1  slparam(busobject/1) bus has variable field

M/C: i/o VS data passed to functionI VS of MATLAB : works for double, not for bus
C: local data VS is ignored
M: local data VS works


M(works): output data IVFW(0) VS(1) double/3 
C(error if direct access): output data IVFW(0) VS(1) double/3 

M(error): output data bus/[1,4] VS and in chart data=[struct(), struct()]
M(works): output data double/[1,4] VS and in chart data=[2,2]


parse_data_message_priority is called for non-messages in DES charts
fill_initial_value_from_expression->data_set_compiled_initial_value: do we need to mark it mexMakeArrayPersistent: when does it get deleted.
get_sf_block_port_info: if we move this to cpp(mdlInitializeSizes), can we avoid calling mexMakeArrayPersistent

when IV is disabled (e.g. Bus/must resolve to signal object), it still shows up in SymbolWindow 


MLW:Matlab base workspace
SLW: Simulink model workspace
MV: matlab vairble
SF data type: MLW/SLW MV(string/charvector), MLW/SLW Alias, SFMaskEditParam(string/char-vector)/SFMaskDatatypestringParam, MLW function returning string/char vector, type(dataName)
SF data size/initial value: MLW/SLW MV(numeric), MLW/SLW/SFMaskEditParam(numeric), size(dataName)(only for size)

Model explorer data type: MLW/SLW alias
Model explorer data size: numeric literal, MLW/SLW MV, 

MLW Simulink.Signal,Simulink.Parameter, Simulink.AliasType datatype/dimensions/initialvalue fields cannot use Simulink model workspace variable/parameter

data_does_not_need_initialization: do we need to check if chart is sfx

rename: ValidatedArray: ValidateDoubles

parse_data_compiled_min_max_helper: ErrorSizeTypeEnum::INTEGER/UNSIGNED: do we need this? also duplicate code


crash: mal, output data, type:inherit size:-1 IV=c   where c=[BasicColors.Blue;BasicColors.Blue];c(2)=[];c(1)=[]

get_CDRtype_from_initial_value can be optimized

mal scope:l/o type:-1 size=-1 iv=Simulink.Bus.createMATLABStruct('busName')  compiles to double

mal: if size is specified via literal/var/param, then IV is not vectorized. but if size is specified as size(anotherData) then IV is vectorized accordingly

may be not necessary: set_data_size_from_initial_value_dimensions>if (!data_get_compiled_initial_value_is_non_scalar(data) && parsedNDims == 0) {

when stopped at breakpoint, model ref MLFB instance does not open in modelref instance context; same is true with TT. TT library instance also lacks context

synchronous domain(HDL state control block) allows only discrete update method and only eml-non-direct-feedthough and SF-moore 

moore chart: no continous update method
des: always inherited update method
