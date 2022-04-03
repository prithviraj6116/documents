/* Copyright 2001-2019 The MathWorks, Inc. */
/*
 * SYSTEM includes
 */
#include "version.h"

#include "modelref.hpp"


#include <string>
#include <ctype.h>      /* isspace */
#include <boost/scope_exit.hpp>

/*
 * REQUIRED includes
 */
#include "sl_lang_blocks/MDLInfoGraphicalInterface.hpp"
#include "sl_lang_blocks/ProtectedModelUtils.hpp"
#include "sl_lang_blocks/mdlref/modelref_comp_tgt.hpp"
#include "sl_lang_blocks/mdlref/ModelRefCompBlock.hpp"
#include "sl_lang_blocks/ModelBlockGraphicalIntrfInfo.hpp"
#include "sl_lang_blocks/ModelBlockInterfaceMismatch.hpp"
#include "sl_lang_blocks/ModelBlockInterface.hpp"
#include "sl_lang_blocks/ModelBlockReferencedPackageManager.hpp"
#include "sl_lang_blocks/mdlref/ModelRefCompBlock.hpp"
#include "sl_lang_blocks/mdlref/parameterArguments/ParamArgParser.hpp" // For ParameterArgumentTokenizer
#include "sl_lang_blocks/param_rw/ParamAccessorMgr.hpp"
#include "resources/Simulink/Variants.hpp"
#include "resources/Simulink/Parameters.hpp"
#include "resources/Simulink/General.hpp"
#include "resources/Simulink/Commands.hpp"
#include "slcg/coder_groups/CoderDataGroup.hpp"

#include "simstruct/simstruc.h" /* ssMacro's */
#include "services.h" /* svIsFeatureEnabled */ 
#include "modelref_utils.hpp"


/*
 * SIMULINK_EXPORT includes
 */
#include "util.h"     /* utFcn's */
#include "jmi.h"      /* jmiUseMWT */
#include "matrix.h"   /* mxArray support */
#include "sl_feature/slf_feature_def.hpp"
#include "sl_services/slsv_errors.hpp"
#include "sl_services/slsv_scoped_ptr.hpp"
#include "sl_services/slsv_matlab_wrappers.hpp"
#include "performance_tracer/PerformanceTracingPoint.hpp"
#include "sl_services_mi/slsv_mcos.hpp"
#include "sl_services/slsvStringTable.hpp"
#include "resources/Simulink/modelReference.hpp"
#include "sl_utility/mxArrayWrapper.hpp"
#include "matrix/char_codecvt.hpp"

/*
 * PUBLIC includes
 */
#include "cdata_types_def.hpp"
#include "main.h"
#include "sl_lang_blocks/fcncall/RootIOFcnCall.hpp"

#include "sl_utility/mxsafeapi.hpp"
#include "sl_util/utparam.hpp"
#include "sl_compile/comp_params.hpp"
#include "sl_compile/variants/InlineVariantUtils.hpp"
#include "sl_compile/variants/InlineVariantVCCustomizer.hpp"
#include "simulink/SimulinkBlockAPI/slmsgcontext_export.hpp"
#include "SimulinkBlock/DynamicInfo.hpp"
#include "sl_obj/dtypetbl.hpp"
#include "sl_obj/SIDServiceSL.hpp"
#include "sl_compile/rtwgen/paramtbl.hpp"
#include "sl_prm_engine/ast_export.hpp"
#include "sl_compile/rtwgen/astsup.hpp"
#include "sldd/SlDataDictionaryUtilities.hpp"

#include "sl_graphical_classes/SLMaskInterface.hpp"
#include "sl_graphical_classes/SLRootBDConfigSetRTWOps.hpp"
#include "sl_graphical_classes/slBlockDiagramSet.hpp"
#include "sl_graphical_classes/allslobj.hpp"
#include "sl_prm_engine/sl_workspace.hpp"
#include "sl_prm_engine/NdIndexingParamUtils.hpp"

#include "sl_sfcn/sfun_evalprms.hpp"
#include "sl_obj/SlDataDictInterface.hpp"

#include "sl_engine_classes/bdCompInfo.hpp"
#include "sl_engine_classes/ModelReferenceCompileInformation.hpp"
#include "sl_compile/SlCodeVariantMgr.hpp"
#include "sl_engin/comp_bd.hpp"
#include "sl_util/scopehier.hpp"
#include "sl_loadsave/slsFileNameUtils.hpp"
#include "sl_mdlref/slModelRefUtils.hpp"
#include "sl_compile/rtwgen/SLCGCoderGroupUtils.hpp"
#include "sl_modelref_info/ModelRefInfoRepo/ModelRefInfoRoot.hpp"
#include "sl_modelref_info/ModelRefInfoRepo/ArgumentValueMap.hpp"
#include "sl_modelref_info/ModelRefInfoRepo/ArgumentValue.hpp"
#include "mf0/collections/ElementMap.hpp"

/*
 * PACKAGE includes
 */

// Do not include modelref_comp_sfun_tgt.h
#include "modelref_bd_tgt.hpp"
#include "sl_lang_blocks/mdlref/modelref_comp_prm.hpp"
#include "sl_lang_blocks/mdlref/SlMdlRefBlkPrmChk.hpp"
#include "sl_lang_blocks/ControlPortBlock.hpp"
#include "sl_lang_blocks/ParameterArgumentCollector.hpp"
#include <boost/algorithm/string/trim.hpp>
#include <boost/mem_fn.hpp>
#include "sl_mdlref/slModelBlockIcon.hpp"
#include "sl_compile/mdlref/slModelBlockIO.hpp"
#include "sl_compile/mdlref/modelref_testpoint.hpp"
#include "sl_lang_blocks/mdlref/slModelBlockPorts.hpp"

#include "slid/slid/Parameter.hpp"

#include "modelref_signals.hpp"
#include <boost/filesystem/path.hpp>
#include "matrix/smart_ptr.hpp"
#include "sl_util/utvariants.hpp"

#include "sl_prm_engine/SlLookupTable.hpp" // For SlLookupTable
#include "sl_prm_engine/SlBreakpoint.hpp" // For SlBreakpoint


#include "dastudio_util/utils/MatlabStringUtil.hpp"
#include "sl_compile/bus/SlSignalLabelProp.hpp"

#include "sl_compile/variants/ExpressionValidator.hpp"
#include "sl_compile/variants/ExpressionValidatorFactory.hpp"
#include "sl_util/slevalml.hpp"

#include "mf0/collections/ElementMap.hpp"
#include "slid/slid/System.hpp"
#include "slid/slid/Element.hpp"
#include "slid/slid/Data.hpp"
#include "slid/slid/AbstractParameter.hpp"

#ifdef modelref_sfun_tgt_HPP
#error "modelref.cpp cannot include modelref_sfun_tgt.hpp"
#endif
#ifdef modelref_bd_tgt_HPP
#error "modelref.cpp cannot include modelref_bd_tgt.hpp"
#endif
#if defined(_MODELREF_BD_MSTGT_HPP_)
#error "modelref.cpp cannot include modelref_bd_mstgt.hpp"
#endif

/*
 * SIMULINK_EXPORT includes
 */
#include "slexec/execspec/sampletime/legacy/AsyncSampleTime.hpp"
#include "boost/pointer_cast.hpp"

SLF_RegisterFeature(EvalInactiveModelArgForFindVars,
                    "Include inactive model arguments in Simulink.findVars",
                    "Simulink Engine [Parameter]",
                    803304,
                    1, nullptr, SLF_IN_MODULE);

SLF_RegisterFeature(TopModelIncrementalBuild,
                    "Enable top model incremental builds",
                    "Simulink Engine [ModelRef]",
                    718128,
                    1, nullptr, SLF_IN_MODULE);

SLF_RegisterFeature(ModelRefSimBuildNoTMF,
                    "Enable non-TMF Model Reference sim builds",
                    "Simulink Engine [ModelRef]",
                    667870,
                    0, nullptr, SLF_IN_MODULE);

SLF_UseFeature(MultiSolverSimulationSupport, SLF_IMPORTED);

SLF_RegisterFeature(ProtectedModelTestProgressStatus,
                    "Test the value of the progress bar when testing models",	 
                    "Simulink Engine [ModelRef]",	 
                    871579,	 
                    0,	 
                    nullptr,	 
                    SLF_IN_MODULE);

SLF_UseFeature(ParameterTestPoint, SLF_IMPORTED);

SLF_UseFeature(DefaultModelArgValues, SLF_IMPORTED);

// Feature to control showing Model block dialog as a
// slim dialog in the Property Inspector
//    0 - Only show the Open button
//    1 - Show the Main and Interface section, but not arguments
//    2 - Show everything including arguments (not variants)
SLF_RegisterFeature(ShowModelBlockDialogInPI,
                    "Show the Model block dialog in Property Inspector",
                    "Simulink Subsystem and Models [Model Reference]",
                    1644498,	 
                    2,	 
                    nullptr,	 
                    SLF_IN_MODULE);

SLF_UseFeature(AllowStructAsLUTArgument, SLF_IMPORTED);

/*=======================*
 * typedefs and defines *
 *=======================*/
#include "modelref_unit.hpp"

#include "sl_lang_blocks/mdlref/ModelRefBlock.hpp"
#include "sl_lang_blocks/mdlref/ModelRefCompBlock.hpp"
#include "sl_mdlref/ModelRefExecBlock.hpp"
#include "slerror.hpp" // slsvCreateOutOfMemoryDiagnostic

namespace {
    ModelRefBlock *safeCastToModelRefBlock(SLBlock *block) {
        return boost::polymorphic_downcast<ModelRefBlock *>(block);
    }

    const ModelRefBlock *safeCastToModelRefBlock(const SLBlock *block) {
        return boost::polymorphic_downcast<const ModelRefBlock *>(block);
    }

    //
    /// Error out if Simulink.Parameter or Simulink.LookupTable objects intend to preserve dimensions
    /// and are passed to model reference blocks "Model Parameter"'s. See g1807044 for details.
    //
    static slsvDiagnostic isNdIndexingUsedWithModelParameters(const ModelRefBlock *aMdlRefBlock,
                                                              const char* aParamName,
                                                              const SlArray* aPrmSlArray)
    {
        slsvDiagnostic errmsg = SLSV_NoDiagnostic;

        MxArrayScopedRefPtr paramMxArrPtr;
        errmsg = aPrmSlArray->getSharedCopyOfOrigMxArray(&paramMxArrPtr);
        if (errmsg != SLSV_NoDiagnostic) { return errmsg; }
        SlParam* paramObj = nullptr;
        if (mxIsA(paramMxArrPtr, "Simulink.Parameter")) {
            paramObj = slGetWritableParamObjectFromMxArray(paramMxArrPtr);
        } else if (slIsLUTObjectFromMxArray(paramMxArrPtr)) {
            if (auto lutObj = slGetLUTObjectFromMxArray(paramMxArrPtr)) {
                paramObj = lutObj->getParameterObject();
            }
        }
        if (paramObj &&
            slprmeng::NdIndexingParamUtils::isWsParameterNdForError(
                paramObj, aMdlRefBlock->getBPI()->getCompBD())) {
            errmsg = slsvCreateDiagnostic(
                aMdlRefBlock->getHandle(),
                Simulink::Data::NdIndexingNotSupportedForModelParameters(
                    aParamName, msgBlockFullPath(aMdlRefBlock)));
            return errmsg;
        }
        
        return errmsg;
    }
}

/* Start of methods for dealing with protected models */

slsvDiagnostic matl_get_extensions_for_model_block_browse(int nlhs, mxArray *plhs[],
                                                          int nrhs, mxArray *prhs[]) {
    UNUSED_PARAMETER(prhs);

    if (nrhs > 0) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyInputArgs());
    } else if (nlhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyOutputArgs());
    }
    
    // Create a cell array to pass into the MCOS object constructor
    mwSize dims[2] = {1, 4};
    slu::mxCellArrayWrapper extensionCell = slu::mxCellArrayWrapper(2, dims);
    extensionCell.setCell(0, slsFileNameUtils::FileExt::SLX);
    extensionCell.setCell(1, slsFileNameUtils::FileExt::MDL);
    extensionCell.setCell(2, slsFileNameUtils::FileExt::SLXP);
    extensionCell.setCell(3, slsFileNameUtils::FileExt::SFX);

    plhs[0] = extensionCell.getMxArraySharedCopy();
    if(plhs[0] == nullptr) {
        return slsvCreateOutOfMemoryDiagnostic();
    }

    return(SLSV_NoDiagnostic);
}


slsvDiagnostic matl_is_protected_model_file(int nlhs, mxArray *plhs[],
                                            int nrhs, mxArray *prhs[]) {
    if (nrhs < 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooFewInputArgs());
    } else if (nrhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyInputArgs());
    } else if (nlhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyOutputArgs());
    }

    const mxArray* const input = prhs[0];
    if (!MatlabStringUtils::isMatlabScalarText(input)) {
        return slsvCreateDiagnostic(Simulink::Commands::ParamValueMustBeString());
    }

    slsvString name(MatlabStringUtils::getMatlabUString(input));
    
    const bool isProtected = slsFileNameUtils::HasSimulinkProtectedModelExtension(name);

    plhs[0] = mxCreateLogicalScalar(isProtected);
    if(plhs[0] == nullptr) {
        return slsvCreateOutOfMemoryDiagnostic();
    }

    return(SLSV_NoDiagnostic);
}

// Function called by slInternal('getPackageNameForModel');  Used 
// for protected models.
slsvDiagnostic matl_get_package_name_for_model(int nlhs, mxArray *plhs[],
                                               int nrhs, mxArray *prhs[]) {
    if (nrhs < 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooFewInputArgs());
    } else if (nrhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyInputArgs());
    } else if (nlhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyOutputArgs());
    }
    
    const mxArray* const input = prhs[0];
    if (!MatlabStringUtils::isMatlabScalarText(input)) {
        return slsvCreateDiagnostic(Simulink::Commands::ParamValueMustBeString());
    }
    
    if(nlhs == 1) {
        std::string package = MatlabStringUtils::getMatlabStdString(input);
        if (package.empty()) {
            return slsvCreateOutOfMemoryDiagnostic();
        }

        package += slsFileNameUtils::FileExt::SLXP;
        plhs[0] = mxCreateString(package.c_str());
    }

    return(SLSV_NoDiagnostic);
}

// Function call by slInternal('getParameterArguments'); Used
// for creating protected models. This is the internal command used by Bosch
slsvDiagnostic matl_get_parameter_arguments(
    int nlhs, mxArray* plhs[],
    int nrhs, mxArray* prhs[])
{
    slsvDiagnostic errmsg = slCheckNumArgs(nlhs, 2, nrhs, 1, 1);
    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    // The right side must be a string
    const mxArray* const input = prhs[0];
    if (!MatlabStringUtils::isMatlabScalarText(input)) {
        return slsvCreateDiagnostic(Simulink::Commands::ParamValueMustBeString());
    }

    const slsvString modelName = slsvString(matrix::get_ustring(input));
    // Get ParameterArguments from model name
    mdlref::ParameterArgumentCollector collector(modelName);
    plhs[0] = collector.getParameterArgumentsAsMxArray();
    return errmsg;
}

void SetModelRefDerivedLocalPreprocessorCondition(const SLBlock *blk, 
                                         const char *condition) {
    const ModelRefBlock *mdlBlk = boost::polymorphic_downcast<const ModelRefBlock*>(blk);
    SLCompBD *cbd = blk->getBPI()->getCompBD();
    FL_DIAG_ASSERT(cbd != nullptr);
    SlCodeVariantMgr::SetModelRefDerivedLocalPreprocessorCondition(mdlBlk, condition, cbd);
}

const char* GetModelRefLocalPreprocessorCondition(const SLBlock *blk) {
    const ModelRefBlock *mdlBlk = boost::polymorphic_downcast<const ModelRefBlock*>(blk);
    SLCompBD* cbd = blk->getBPI()->getCompBD();
    FL_DIAG_ASSERT(cbd != nullptr);
    return SlCodeVariantMgr::GetModelRefLocalPreprocessorCondition(mdlBlk, cbd);
}

const char* GetModelRefDerivedLocalPreprocessorCondition(const SLBlock *blk) {
    const ModelRefBlock *mdlBlk = boost::polymorphic_downcast<const ModelRefBlock*>(blk);
    SLCompBD *cbd = blk->getBPI()->getCompBD();
    FL_DIAG_ASSERT(cbd != nullptr);
    return SlCodeVariantMgr::GetModelRefDerivedLocalPreprocessorCondition(mdlBlk,cbd);
}

//==============================================================================
// End of methods for supporting Implicit Iterator Subsystem loop bound reuse.
//==============================================================================


slsvDiagnostic matl_get_referenced_model_file_information(int nlhs, mxArray *plhs[],
                                                          int nrhs, mxArray *prhs[]) {
    slsvDiagnostic errmsg = slCheckNumArgs(nlhs, 2, nrhs, 1, 1);
    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    const slsvString input(MatlabStringUtils::getMatlabUString(prhs[0]));
    const std::pair<bool, slsvString> result = mdlref::askDispatcherForModelFileInformation(input);

    if(nlhs == 1) {
        plhs[0] = mxCreateLogicalScalar(result.first);
    } else if(nlhs == 2) {
        plhs[0] = mxCreateLogicalScalar(result.first);
        plhs[1] = result.second.getMxArray();
    }

    return(errmsg);
}


SolverMode GetModelRefSolverMode(const SLBlock *block)
{
    const ModelRefBlock* mdlRefBlk = safeCastToModelRefBlock(block);
    return mdlRefBlk->getCompBlock()->getSolverMode();
}

// This function returns the value of P_MODELREF_OVERRIDE_USING_VARIANT
const char* GetModelBlockOverrideUsingVariant(const SLBlock *block)
{
    FL_DIAG_ASSERT(block->getBlockType() == SL_MODELREF_BLOCK);
    FL_DIAG_ASSERT(GetMdlRefHasVariants(block));

    return ggb_param_value(block, P_MODELREF_OVERRIDE_USING_VARIANT);
}

// This function sets the parameter P_MODELREF_OVERRIDE_USING_VARIANT
slsvDiagnostic SetModelBlockOverrideUsingVariant(SLBlock *block, const char* param_value)
{
    FL_DIAG_ASSERT(block->getBlockType() == SL_MODELREF_BLOCK);
    FL_DIAG_ASSERT(GetMdlRefHasVariants(block));
    try {
        block->setGrParamValue(P_MODELREF_OVERRIDE_USING_VARIANT, param_value);
    } catch (const fl::except::IException& ex) {
        return slsvCreateDiagnosticFromIException(ex);
    }
    return SLSV_NoDiagnostic;
}

slsvDiagnostic validateVariantConditionExpressionForVariantChoices(SLBlock *block)
{
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    const ModelRefVariants& variants = mdlref::GetModelRefVariants(block);
    SlEvalClientScopedRefPtr evalClient(slEvalCreateInternalClient(block));

    for (ModelRefVariants::constIterator variantIter = variants.firstVariant(); 
         variantIter.isValid(); ++variantIter) {
        std::string varName = variantIter.variantName();
        
        // validate the variant condition in the Variants structure
        errmsg = (ExpressionValidatorFactory().createVariantExpressionValidator(varName, block, block->getBPI()->getGrBlockDiagram(), evalClient).get())->validateConditionExpression();        
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
    }
    return errmsg;
}

fl::ustring get_modelref_trigport_display_name_unicode(const SLBlock *block)
{
    return GetModelRefName(block);
}


/** Function: GetModelRefEnableStatesParam ====================================
 *  Abstract:
 *    If this is a function-call model reference block, then it has 
 *    a parameter which says whether the block resets its internal
 *    states on enable events.  This function is used to get this parameter
 *    value.
 */
const char *GetModelRefEnableStatesParam(const SLBlock *block)
{
    const ModelRefBlock *mdlBlock = boost::polymorphic_downcast<const ModelRefBlock*>(block);
    
    FL_DIAG_ASSERT(IsFcnCallModelRefBlock(block));
    FL_DIAG_ASSERT(utStrcmp(mdlBlock->getTriggerPortEnableStates(),"") != 0);

    return(mdlBlock->getTriggerPortEnableStates());
}

/* Function: mrpi_GetDataTypeName ===========================================
 * Abstract:
 *   Function to return data type of interface parameter.
 */
static const std::string mrpi_GetDataTypeName
(
 const SLBlock *block, 
 ModelRefIntfParamType pType, 
 int prmIdx
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    return(prmIntf->getDataTypeName(pType, prmIdx));
}
/* Function: mrpi_GetDataTypeChecksum =================================================
 * Abstract:
 *   Function to return data type checksum of interface parameter.
 */
static slChecksumValue mrpi_GetStructDtChecksum
(
 const SLBlock *block, 
 ModelRefIntfParamType pType, 
 int prmIdx
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    return prmIntf->getStructDtChecksum(pType, prmIdx);
 
}
/* Function: mrpi_SetDataType =================================================
 * Abstract:
 *   Function to set data type of interface parameter.
 */
void mrpi_SetDataType
(
 const SLBlock *block, 
 ModelRefIntfParamType pType, 
 int prmIdx,
 DTypeId dtId
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    prmIntf->setDataType(pType, prmIdx, dtId);
}

/* Function: mrpi_GetNumDimensions ===============================================
 * Abstract:
 *   Function to return number of dimensions of interface parameter.
 */
static int mrpi_GetNumDimensions
(
 const SLBlock *block, 
 ModelRefIntfParamType  pType, 
 int prmIdx
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    return(prmIntf->getNumDimensions(pType, prmIdx));
}

/* Function: mrpi_GetDimensions ===============================================
 * Abstract:
 *   Function to return dimensions of interface parameter.
 */
static const std::vector<SLSize> mrpi_GetDimensions
(
 const SLBlock *block, 
 ModelRefIntfParamType  pType, 
 int prmIdx
)
{
   slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
   return(prmIntf->getDimensions(pType, prmIdx));
}

/* Function: mrpi_GetComplexity ===============================================
 * Abstract:
 *   Function to return complexity of interface parameter.
 */
static bool mrpi_GetComplexity
(
 const SLBlock *block, 
 ModelRefIntfParamType  pType, 
 int prmIdx
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    return(prmIntf->getComplexity(pType, prmIdx));
}


/* Function: mrpi_StealParamArgValueStrings ===============================
 * Abstract:
 *   Cache the evaluated parameter strings for the interface parameters.
 */
static void mrpi_StealParamArgValueStrings
(
 const SLBlock *block, 
 int nParamStrings,
 char ***prmStrings
)
{
    slMdlRefCompPrmIntf *prmIntf = GetModelRefParamInterface(block);
    prmIntf->stealParamArgValueStrings(nParamStrings, prmStrings);
} /* end mrpi_StealParamValueStrings */


/* Inlined functions to get logical index for parameter arguments / global parameters
 *
 * See: ModelRefGetLogicalDlgParamIdx
 */

namespace {
    /* prmIdx: Index of the parameter argument among all (block and model parameter
     *         arguments.
     */
    inline int ModelRefGetLogicalIdxFromPrmArgIdx(const SLBlock *, int prmIdx)
    {
        return mdlref::ModelRefGetLogicalDlgParamIdx(prmIdx);
    }

    /* prmIdx: Index of the parameter argument among all (block parameter
     *         arguments.
     */
    inline int ModelRefGetLogicalIdxFromBlockPrmArgIdx(const SLBlock *, int prmIdx)
    {
        return mdlref::ModelRefGetLogicalDlgParamIdx(prmIdx);
    }

    /* prmIdx: Index of the parameter argument among all (model parameter
     *         arguments.
     */
    inline int ModelRefGetLogicalIdxFromModelPrmArgIdx(const SLBlock *block, int prmIdx)
    {
        return mdlref::ModelRefGetLogicalDlgParamIdx(ModelRefGetCorrectModelPrmArgIdx(block, prmIdx));
    }

    /* prmIdx: Index of the parameter argument among all (global parameters)
     */
    inline int ModelRefGetLogicalIdxFromGlobalPrmIdx(const SLBlock *block, int prmIdx) 
    {
        return mdlref::ModelRefGetLogicalDlgParamIdx(ModelRefGetCorrectGlobalPrmIdx(block, prmIdx));
    }
}

/* Function: ModelRefGetInterfacePrmData=======================================
 * Abstract:
 *   Function to return the run-time parameter data for an interface parameter.
 */
void ModelRefGetInterfacePrmData
(
 const ModelRefBlock   *block, 
 ModelRefIntfParamType pType,
 int                   prmIdx, 
 void                  **dataPtr,
 const SLExecBD* ebd
)
{
    slParam *rtPrm     = nullptr;
    int     corrPrmIdx = 0;

    FL_DIAG_ASSERT(dataPtr != nullptr);
    FL_DIAG_ASSERT(IsBdContainingBlockExecuting(block));

    switch (pType) {
      case MODELREF_INTFPARAM_BLOCK: 
        // No adjustment needed. Args occur first
        corrPrmIdx = prmIdx;
        break;
      case MODELREF_INTFPARAM_MODEL:
        // Need to adjust for block parameter test points
        corrPrmIdx = ModelRefGetCorrectModelPrmArgIdx(block, prmIdx);
        break;
      case MODELREF_INTFPARAM_GLOBAL:
        // When generating code for this model, we don't need to override global
        // parameter values, use the value embedded in the SIM target.
        // We are planning on removing the call to mdlStart when generating code for
        // the parent model when we remove the reliance of codegen on the SIM target.
        if (block->isParentGeneratingCode()) {
            return;
        }
          
        // Need to adjust for param args that occur first
        corrPrmIdx = ModelRefGetCorrectGlobalPrmIdx(block,prmIdx);
        break;
    }

    rtPrm = block->getBPI()->getCompRTP(corrPrmIdx);

    const SLRootBD *bd = getRootBDFromCompBlock(block);
    const SLExecBlock *eb = nullptr;
    if (bd->getBDSubPhase() >= BD_CPHASE_POST_LINK
        && block->getBPI()->getGrExecBlockIndex() >= 0) {
        FL_DIAG_ASSERT(ebd != nullptr);
        eb = static_cast<SLExecBlock*>(ebd->sluGetSimBlockForBlock(block));
    }
    
    (*dataPtr) =  const_cast<void *>(static_cast<SlRTPrmAttribs *>(rtPrm->mpPrmDataAttribs)->getRTPData(eb));
} /* ModelRefGetInterfacePrmData */


/* Function: matl_get_model_ref_default_model_name ==============================
 * Abstract:
 *   Return the default value of the model name parameter (for sl_internal)
 */
slsvDiagnostic matl_get_model_ref_default_model_name(int nlhs, mxArray *plhs[],
                                                     int nrhs, mxArray *prhs[])
{
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    UNUSED_PARAMETER(prhs);

    errmsg = slCheckNumArgs(nlhs, 1, nrhs, 0, 0);
    if (errmsg != SLSV_NoDiagnostic) {
        return errmsg;
    }

    plhs[0] = mdlref::GetModelRefDefaultModelName().getMxArray();
    if(plhs[0] == nullptr) {
        return slsvCreateOutOfMemoryDiagnostic();
    }

    return errmsg;
}


/**
 * @brief This routine take the model name and return the handle to the hidden system, 
 *        which is used in busesv2/SigHierProp/tsighierprop.m.
 *
 * @note For hd = sl_internal('getModelRefHiddenSystemHandle', mdlName)
 */
slsvDiagnostic matl_get_hidden_root_subsystem_handle(int nlhs, mxArray *plhs[],
                                                     int nrhs, mxArray *prhs[])
{
    // Only accept one input argument and return one output argument.
    slsvDiagnostic errmsg = slCheckNumArgs(nlhs , 1 , nrhs, 1 , 1);
    if (errmsg != SLSV_NoDiagnostic) {
        return errmsg;
    }

    // If the input parameter is not a string then return
    if (!MatlabStringUtils::isMatlabScalarText(prhs[0])) {
        return errmsg;
    }
    const std::string mdlName = MatlabStringUtils::getMatlabStdString(prhs[0]);

    // The output is a scalar which contains the handle of the hidden system
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL); 
    double* mdlHandle = mxGetPr(plhs[0]);
    if (mdlHandle == nullptr) {
        return errmsg;
    }

    // Get the pointer to the SLRootBD then update model pointer  
    const SLRootBD *const bd = slBlockDiagramSet::nameToBlockDiagram(mdlName.c_str());
    if (bd == nullptr) {
        return errmsg;
    }
    
    const SLCompBD* const compBd = bd->getCompBd(true);
    if (compBd == nullptr) {
        return errmsg;
    }

    // Return hidden root subsystem handle
    SLBlock *hiddenSys = compBd->getHiddenRootSubsystem();
    if (hiddenSys != nullptr) {
        mdlHandle[0] = hiddenSys->getHandle();
    } else {
        mdlHandle[0] = 0.0;
    }
    
    return errmsg;
}

/* Function: matl_determine_active_variant ==============================
 * Abstract:
 *   Determine the active variant for the specified subsystem or model block.
 *   ==> for sl_internal('determineActiveVariant', block)
 */
slsvDiagnostic matl_determine_active_variant(int nlhs, mxArray *plhs[],
                                       int nrhs, mxArray *prhs[])
{
    UNUSED_PARAMETER(plhs);
    slsvDiagnostic errmsg     = SLSV_NoDiagnostic;
    SLBlock  *block     = nullptr;
    size_t   numObjects = 0;
    int      i;

    errmsg = slCheckNumArgs(nlhs, 0, nrhs, 1, 1);
    if (errmsg != SLSV_NoDiagnostic) {
        return errmsg;
    }

    // Determine number of input objects
    if (MatlabStringUtils::isMatlabScalarText(prhs[0])) {
        numObjects = 1;
    } else if (mxIsCell(prhs[0]) || mxIsDouble(prhs[0])) {
        if (!mxIsVector(prhs[0])) {
            return slsvCreateDiagnostic(Simulink::Commands::ObjectListMustBeVector());
        }
        numObjects = mxGetNumberOfElements(prhs[0]);
    } else {
        return slsvCreateDiagnostic(Simulink::Commands::InvSimulinkObjSpecifier());
    }

    // Determine object and variant
    for (i = 0; i < static_cast<int>(numObjects); i++) {
        SLSVMWObjectBase     *object = nullptr;
        
        errmsg = slgc::sluGetSimulinkObjectFromMxArray(prhs[0], i, &object);
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }

        // Call the determine code to find the active variant
        block  = static_cast<SLBlock *>(object);
        if(block->getBlockType() == SL_MODELREF_BLOCK) {
            errmsg = DetermineVariant(block);
        } else {
            FL_DIAG_ASSERT(block->getBlockType() == SL_SUBSYSTEM_BLOCK);
            errmsg = DetermineVariant(block);
        }

        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
    }

    return errmsg;
}

/* Function: matl_get_model_parameter_argument_names ==============================
 * Abstract:
 *   Return the parameter argument names for the specified model.
 *   ==> for sl_internal('getModelParameterArgumentNames', block, mdlName)
 */
slsvDiagnostic matl_get_model_parameter_argument_names(int nlhs, mxArray *plhs[],
                                                 int nrhs, mxArray *prhs[])
{
    slsvDiagnostic         errmsg   = SLSV_NoDiagnostic;
    mdlref::ModelRefLoadStatus loadStatus = mdlref::MDLREF_MODEL_LOADED_OK;
    SLSVMWObjectBase *object  = nullptr;
    SLBlock          *block   = nullptr;
    SLRootBD   *bd      = nullptr;
    fl::ustring strippedName;
    boost::shared_ptr<mdlref::ModelGraphicalInterface> mdlrefgi;

    errmsg = slCheckNumArgs(nlhs, 1, nrhs, 2, 2);
    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    // Get the Simulink object to which the input refers
    errmsg = slgc::sluGetSimulinkObjectFromMxArray(prhs[0], 0, &object);
    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    // This seems to happen if prhs[0] is a logical scalar:
    if (object == nullptr || get_sl_object_type(object) != SIMULINK_BLOCK_object) {
        return slsvCreateDiagnostic(Simulink::Commands::InvSimulinkObjHandle());
    }
    block  = static_cast<SLBlock *>(object);
    bd     = block->getBPI()->getGrBlockDiagram();
    
    // We need a model name
    if (!MatlabStringUtils::isMatlabScalarText(prhs[1])) {
        return slsvCreateDiagnostic(Simulink::Commands::ParamNameMustBeString());
    }
    const slsvString mdlName = slsvString(MatlabStringUtils::getMatlabUString(prhs[1]));

    // Strip, check and get valid model name
    errmsg = StripCheckModelName(block, mdlName, mdlref::MDLREF_EVAL_REGULAR, strippedName);
    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    /*
     * Load all the interface info from the referenced model, and store it
     * in the temporary structure mdlIntrf.
     */
    const std::pair<bool, slsvString> refModelInfo =
        mdlref::askDispatcherForModelFileInformation(slsvString(strippedName));
    const bool isProtected = refModelInfo.first;
    const slsvString refModelFile = refModelInfo.second;
    mdlref::ModelGraphicalInterfaceFactory factory(bd->isRegionPostUpdateReferenceToCompileEnd());

    try {
        slsvString refName(strippedName);
        mdlref::ModelBlockReferencedPackageManager aPkgMgr(block, refName, isProtected);
        mdlrefgi = factory.createGraphicalInterface(aPkgMgr,
                                                    refName,
                                                    refModelFile,
                                                    false,
                                                    isProtected,
                                                    block,
                                                    mdlref::MDLREF_EVAL_REFRESH_THIS_BLK,
                                                    loadStatus);
    } catch(MathWorks::System::IException &e) {
        errmsg = slsvCreateDiagnosticFromIException(e);
    }

    FL_DIAG_ASSERT((errmsg != SLSV_NoDiagnostic) || (loadStatus == mdlref::MDLREF_MODEL_LOADED_OK));

    if (errmsg != SLSV_NoDiagnostic) {
        return(errmsg);
    }

    // Return answer
    plhs[0] = mdlrefgi->getParamArgNames(true).getMxArray();  // skip sorting
    return errmsg;
}

bool GetMdlRefOutputPortIsNonContinuous(SLBlock *block, int portIdx)
{
    return getCompTgtFromBlock(block).getOutputPortIsNonContinuous(portIdx);
}

slexec::execspec::rate::RateSpec GetMdlRefFundamentalRateSpec(
    const SLBlock *block)
{
    const ModelRefCompBlock* mdlRefCompBlk = safeCastToModelRefBlock(block)->getCompBlock();
    return mdlRefCompBlk->getFundamentalRateSpec();    
}

slsvDiagnostic MdlRefRegDWorkDType(SLBlock* block,
                                   int* dwtypeId)
{
    return getCompTgtFromBlock(block).regMdlrefDWorkDType(dwtypeId);
}

rtwCAPI_ModelMappingInfo *GetMdlRefModelMappingInfo(const SLBlock *block)
{
    return getCompTgtFromBlock(block).getModelMappingInfo();
}

//
/// @brief returns true if a given model reference block (@param aMdlRefBlock )
/// input port (@param aInPortIdx ) has a none auto storage class
//
bool ModelRefInputHasNonAutoStorage(const SLBlock* aMdlRefBlock,
                                    const int aInPortIdx)
{
    if (safeCastToModelRefBlock(aMdlRefBlock)->
        getGrInputPortIsMdlEventInputPort(aInPortIdx)) {
        return false;
    }
        
    // slModelBlockIO needs a non-const pointer to ModelRefBlock,
    // so we need to keep this const_cast<>() around. Making the
    // local instance of slModelBlockIO non-const to document that
    // we have removed const-ness from the input block.
    slcomp::slModelBlockIO modelBlockIO(safeCastToModelRefBlock(const_cast<SLBlock*>(aMdlRefBlock)));

    return modelBlockIO.hasNonAutoStorage(aInPortIdx);
}

void ModelRefSetupContStates(SLBlock *block, slSimBlock *mrSimBlk)
{
    getCompTgtFromBlock(block).setupCStates(mrSimBlk);
}

// Function: ModelRefSetupPeriodicContStates
void ModelRefSetupPeriodicContStates(SLBlock* block, slSimBlock* simBlock) {
    getCompTgtFromBlock(block).setupPeriodicCStates(simBlock);
}

void ModelRefSetupZCInfo(SLBlock *block, slSimBlock *mrSimBlk)
{
    getCompTgtFromBlock(block).setupZCInfo(block, mrSimBlk);
}


int ModelRefGetNumberOfCompiledInputs(const SLBlock *block)
{
    const size_t rv
        = safeCastToModelRefBlock(block)->getSlModelBlockPorts().getNumberOfCompiledInports();

    return static_cast<int_CastToAvoid64BitWarning>(rv);
}


static std::string getParamGraphicalName(const SLBlock* block, 
                                         ModelRefIntfParamType pType, 
                                         int prmIdx)
{
    FL_DIAG_ASSERT(block->getBlockType() == SL_MODELREF_BLOCK);
    int logPrmIdx = -1; //invalid value;

    switch (pType) {
      case MODELREF_INTFPARAM_GLOBAL:
        logPrmIdx = ModelRefGetLogicalIdxFromGlobalPrmIdx(block, prmIdx);
        break;
      case MODELREF_INTFPARAM_BLOCK:
        logPrmIdx = ModelRefGetLogicalIdxFromBlockPrmArgIdx(block, prmIdx);
        break;
      case MODELREF_INTFPARAM_MODEL:    
        logPrmIdx = ModelRefGetLogicalIdxFromModelPrmArgIdx(block, prmIdx);
        break;
    }
    FL_DIAG_ASSERT(logPrmIdx > 0);
        return ModelRefGetParamGraphicalName(block, logPrmIdx);
}


namespace {
/* Function : ModelRefValidateEvaledParam =====================================
 * Abstract :
 *   Validate the evaluated dialog parameters for an interface parameter.
 */
slsvDiagnostic ModelRefValidateEvaledParam
(
 const SLBlock *block,
 ModelRefIntfParamType pType,
 int idx,
 const SlPrmDataAttribs *rtpAttribs
)
{
    slsvDiagnostic   errmsg = SLSV_NoDiagnostic;

    // paramGraphicalName doesn't contain prefix like rtp_, rtu_ etc.
    // Use ModelRefParamGraphicalName instead of registered param name 
    //const char *pName = p->name;
    // for error message
    // Note: ModelRefParamGraphicalName allocates/deallocates memory and
    // parses model argument string. 
    // Call it if we really need to generate error message.

    /* Dimensions */
    int nDims        = mrpi_GetNumDimensions(block, pType, idx);
    const std::vector<SLSize> dims = mrpi_GetDimensions(block, pType, idx);

    if ((rtpAttribs->getDims()->getNumDims() != nDims) ||
        (memcmp(rtpAttribs->getDimsSLSizeArray(), dims.data(), nDims*sizeof(SLSize)) != 0)) {
        std::string actualDimsStr;
        std::string expectedDimsStr;
        std::string paramGraphicalName=getParamGraphicalName(block, pType, idx);
               
        SlDims::getDimsArrayAsStrForError(actualDimsStr, rtpAttribs->getDims()->getNumDims/*AsSLSize*/(), rtpAttribs->getDimsSLSizeArray());
        SlDims::getDimsArrayAsStrForError(expectedDimsStr, nDims, dims.data());

        switch (pType) {
        case MODELREF_INTFPARAM_GLOBAL:
            return slsvCreateDiagnostic(block->getHandle(),
                                        Simulink::modelReference::ParamIntf_GlobalParam_DimsMismatch(
                                            paramGraphicalName.c_str(), 
                                            msgBlockFullPath(block),
                                            actualDimsStr.c_str(), expectedDimsStr.c_str()));
        case MODELREF_INTFPARAM_BLOCK:
            // if ParameterTestPoint == 3
            if (slGetFeatureValue(ParameterTestPoint) == 3) {
                const ModelRefBlock* mdlrefBlock = boost::polymorphic_downcast<const ModelRefBlock*>(block);
                const mdlref::ModelBlockGraphicalIntrfInfo& intrfInfo = mdlrefBlock->getModelBlockGraphicalIntrfInfo();
                const mxArray* paramInfoPtr = intrfInfo.getParameterArguments();

                std::vector<slsvString> path;
                size_t eleNum = mxGetNumberOfElements(paramInfoPtr);
                slsvString slsvParamGraphicalName = slsvString(ConvertStdStringToUString(paramGraphicalName));
                fl::ustring displayName;
                for(size_t eleIdx = 0; eleIdx != eleNum; ++eleIdx) {
                    slsvString argName = slsvString(matrix::get_ustring(mxGetField(paramInfoPtr, eleIdx, GraphicalInterface::ParameterArgument::scArgName)));
                    if(argName == slsvParamGraphicalName) {
                        mxArray* fullPathPtr = mxGetField(paramInfoPtr, eleIdx, GraphicalInterface::ParameterArgument::scFullPath);
                        displayName = matrix::get_ustring(mxGetField(paramInfoPtr, eleIdx, GraphicalInterface::ParameterArgument::scDisplayName));
                        
                        FL_DIAG_ASSERT(
                            (mxIsA(fullPathPtr, "Simulink.BlockPath") && mxIsOpaque(fullPathPtr)) ||
                            (mxIsChar(fullPathPtr) && mxIsEmpty(fullPathPtr)));
                        if(mxIsA(fullPathPtr, "Simulink.BlockPath") && mxIsOpaque(fullPathPtr)) {
                            path = mdlref::convertSimulinkBlockPathToSlsvStringVec(fullPathPtr);
                        }
                        break;
                    }
                }
                path.emplace_back(displayName);
                displayName.clear();
                fl::ustring colon;
                for(const auto& pth : path) {
                    displayName += colon;
                    displayName += pth.str();
                    if(!displayName.empty()) {
                        colon = USTR(":");
                    }
                }
                return slsvCreateDiagnostic(block->getHandle(),
                                            Simulink::modelReference::ParamIntf_ParamArg_DimsMismatch(
                                                displayName.c_str(), 
                                                msgBlockFullPath(block),
                                                actualDimsStr.c_str(), expectedDimsStr.c_str()));
            } else {
                return slsvCreateDiagnostic(block->getHandle(),
                                            Simulink::modelReference::ParamIntf_ParamArg_DimsMismatch(
                                                paramGraphicalName.c_str(), 
                                                msgBlockFullPath(block),
                                                actualDimsStr.c_str(), expectedDimsStr.c_str()));
            }
        case MODELREF_INTFPARAM_MODEL:
            return slsvCreateDiagnostic(block->getHandle(),
                                        Simulink::modelReference::ParamIntf_ParamArg_DimsMismatch(
                                            paramGraphicalName.c_str(), 
                                            msgBlockFullPath(block),
                                            actualDimsStr.c_str(), expectedDimsStr.c_str()));
        }
    }

    /* Complexity */
    {
        const bool isComplex = mrpi_GetComplexity(block, pType, idx);
        if (static_cast<bool>(rtpAttribs->getComplexity()) != isComplex) {
            std::string paramGraphicalName=getParamGraphicalName(block, pType, idx);

            switch (pType) {
              case MODELREF_INTFPARAM_GLOBAL:
                if (isComplex == true) {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                           Simulink::modelReference::ParamIntf_GlobalParam_ShouldBeComplex(
                                           paramGraphicalName.c_str(),
                                           msgBlockFullPath(block)));
                } else {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                           Simulink::modelReference::ParamIntf_GlobalParam_ShouldNotBeComplex(
                                           paramGraphicalName.c_str(), 
                                           msgBlockFullPath(block)));
                }
                return errmsg;
              case MODELREF_INTFPARAM_BLOCK:
                if (isComplex == true) {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                                Simulink::modelReference::ParamIntf_ParamArg_ShouldBeComplex(
                                                    paramGraphicalName.c_str(),
                                                    msgBlockFullPath(block)));
                } else {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                                Simulink::modelReference::ParamIntf_ParamArg_ShouldNotBeComplex(
                                                    paramGraphicalName.c_str(), 
                                                    msgBlockFullPath(block)));
                }
                return errmsg;
              case MODELREF_INTFPARAM_MODEL:     
                // (ParamTestPoint TODO) 
                // Produce error message appropriate for block parameter arguments
                if (isComplex == true) {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                           Simulink::modelReference::ParamIntf_ParamArg_ShouldBeComplex(
                                           paramGraphicalName.c_str(), 
                                           msgBlockFullPath(block)));
                } else {
                    errmsg = slsvCreateDiagnostic(block->getHandle(),
                                           Simulink::modelReference::ParamIntf_ParamArg_ShouldNotBeComplex(
                                           paramGraphicalName.c_str(), 
                                           msgBlockFullPath(block)));
                }
            }
        }
    }

    return(errmsg);
} /* end ModelRefValidateEvaledParam */

namespace // anonymous
{

static slsvDiagnostic lateBindLUT(SLRootBD* bd, SlBaseObject* pLUT, const std::string& name)
{
    FL_DIAG_ASSERT(nullptr != bd);
    SlEvalClientScopedRefPtr pInternalClient(slEvalCreateInternalClient());
    SlBaseObjEvalClient objEvalClient(nullptr, pInternalClient, std::string(), fl::ustring());
    slsvDiagnostic errmsg = pLUT->lateBinding(bd, name.c_str(), bd->getMdlWorkspace(), &objEvalClient);
    return errmsg;
}

} //namespace anynymous


/* Function:  CheckModelRefStructParamArgMismatch ============================================
 * Abstract:
 *      Check mismatch field for ModelRef struct argument during compile time
 *      Note that cbd can be a nullptr
 */
slsvDiagnostic CheckModelRefStructParamArgMismatch(ModelRefBlock *block, 
                                                   const std::string& argName,
                                                   const std::string& name, 
                                                   const SlArray* value)
{
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    
    std::string synthesizedArgname = name;
    std::string prefix = "rtp_";
    if (synthesizedArgname.compare(0, prefix.size(), prefix) == 0) {
        //remove prefix
        synthesizedArgname.erase(0, prefix.size());  
    }
    const SLRootBD* bd = block->getBPI()->getGrBlockDiagram();

    // Get default argument value
    FL_DIAG_ASSERT(block->hasCompBlock());
    const mxArray* mxDefValue =  block->getCompBlock()->getArgumentDefaultValue(name);
    FL_DIAG_ASSERT(mxDefValue != nullptr);

    // get the argument value being passed
    MxArrayScopedRefPtr mxValue;
    errmsg = value->getValueAsSharedMxArray(&mxValue);
    if(errmsg != SLSV_NoDiagnostic) {
        slsvDiscardDiagnostic(errmsg); 
        return errmsg;
    }
    
    // check if the default value and passed value are consistent
    if (slIsLUTObjectFromMxArray(mxDefValue))
    {
        // late bind if not done.
        SlLookupTable* pDefaultLUT = const_cast<SlLookupTable*>(slGetLUTObjectFromMxArray(mxDefValue));
        if (pDefaultLUT->lateBindingOutOfDate(block->getBPI()->getGrBlockDiagram()))
        {
            slsvDiagnostic cause = lateBindLUT(block->getBPI()->getGrBlockDiagram(), pDefaultLUT, name);
            if (SLSV_NoDiagnostic != cause)
            {
                errmsg = slsvCreateDiagnostic(
                    Simulink::modelReference::LUTIntf_LUTArg_Mismatch(argName, block->getFullPath(), name));
                slsvAddCauseToLastDiagnosticItem(errmsg, cause);
                return errmsg;
            }
        }
        
        if (slIsLUTObjectFromMxArray(mxValue.get()))
        {
            errmsg = slCheckLUTObjectMismatch(mxValue.get(), mxDefValue, argName, name, block);
        }
        else if (sl::data::util::IsNumericStructMxArray(mxValue))
        {
            if (slGetFeatureValue(AllowStructAsLUTArgument) > 0)
            {
                // The synthesizer deep copies a LUT object, copies struct value in it
                // and runs late binding on this new LUT object.
                LUTObjectSynthesizer lutSynthFromStruct(mxDefValue, block->getBPI()->getGrBlockDiagram());
                mxArray* synthLUTLocMat = nullptr;

                const slsvString bdRootName = block->getBPI()->getGrBlockDiagram()->getName();
                synthesizedArgname += std::string("_") + std::string(bdRootName.get_converted_lcp_str());

                std::tie(errmsg, synthLUTLocMat) = lutSynthFromStruct.createLateBoundLUTObj(mxValue, synthesizedArgname);
                if (errmsg != SLSV_NoDiagnostic) return errmsg;

                MxArrayScopedPtr synthLUTLocMatVar(synthLUTLocMat);
                synthLUTLocMat = nullptr;

                // The checker is used to check consistency between LUT object in model workspace
                // and the synthesized LUT object.
                LUTObjectChecker checker(mxDefValue, name, synthLUTLocMatVar.get(), argName, block, bd);
                errmsg = checker.check();

            }
            else 
            {
                errmsg = slsvCreateDiagnosticFromMessageID(Simulink::Data::LUT_Invalid_Model_Argument(argName));
            }
        }
        else
        {
            errmsg = slsvCreateDiagnosticFromMessageID(Simulink::Data::LUT_Invalid_Model_Argument(argName));
        }
    }
    else
    {
        // Breakpoint object is not allowed to be model argument.
        FL_DIAG_ASSERT(false == slIsBreakpointObjectFromMxArray(mxDefValue));
        if (!mxIsStruct(mxValue) || !mxIsStruct(mxDefValue)) {
            return errmsg;
        }
        const bool ignoreDims = false; // No variable-size support for breakpoint objects.
        errmsg = slprmeng::CheckStructParamMismatch(block, synthesizedArgname, mxValue, mxDefValue, ignoreDims); 
    }


    return errmsg;
}

// pull out significant code duplicates and put them here
slsvDiagnostic doCompTgtSetNumDlgParamsAdded(SLBlock *block, int nPrms) {
    FL_DIAG_ASSERT(block->getBPI()->getGrBlockDiagram()->isRegionPostUpdateReferenceToCompileEnd());
    
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    
    int const nTmpParams =
        ModelRefGetLogicalIdxFromGlobalPrmIdx(block, nPrms) -
        P_MODELREF_NUM_DLG_PARAMS;
    
    errmsg = (block->getBPI()->AddElementsToGrEDPArray(nTmpParams));
    
    if (SLSV_NoDiagnostic != errmsg) {
        return errmsg;
    }
    
    slMdlRefCompTgt &compTgt = getCompTgtFromBlock(block);
    
    if (compTgt.getNumDlgParamsAdded() < nTmpParams) {
        compTgt.setNumDlgParamsAdded(nTmpParams);
    }
    
    return errmsg;
}

/// @brief If the model block parameter has unstructured SC and is marked as an
/// argument then it is a code gen error.
static slsvDiagnostic isValidInstanceSpecificSetupForRTW(const SLRootBD* bd, const ModelRefBlock* block, AST** pParamMaps)
{
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;

    if (SLCompBD::configForPureRTW(bd) &&
        !(bd->getRapidAcceleratorIsActive() || bd->getCompBd(true)->compileSupportsAcceleration())
       )
    {
        auto dictBlk = block->getDictBlock();
        if (dictBlk)
        {
            for (const auto & dictParamMapEntry : dictBlk->getParameter())
            {
                auto dictParam = dictParamMapEntry.second;
                if (true == dictParam->getHierarchical()) { // grouped
                    // no op
                } else if (dictParam->getInstanceSpecific()) { // isarg,  ungrouped
                    const mxArray* pParameterArgumentInfo =
                        block->getModelBlockGraphicalIntrfInfo().getParameterArguments();

                    std::string parameterCreatedFrom =
                        mxArrayToString(mxGetField(pParameterArgumentInfo, 0,
                                                   GraphicalInterface::ParameterArgument::scParameterCreatedFrom));
                        
                    errmsg = slsvCreateDiagnostic(
                        block->getHandle(),
                        Simulink::modelReference::ParamIntf_UngroupedArgument(
                            dictParam->getIdentifier(),
                            msgBlockFullPath(block),
                            parameterCreatedFrom));
                        
                    break;
                }
            }
        }
    }
    return errmsg;
}


void addArgumentDefaultValueToModelRefCompiledInformation(ModelRefBlock* pBlock,
                                                          const std::string& argumentName)
{
    FL_DIAG_ASSERT(pBlock->hasCompBlock());

    SLRootBD *bd        = pBlock->getBPI()->getGrBlockDiagram();
    SLCompBD *cbd       = pBlock->getBPI()->getCompBD();

    const mxArray* mxDefValue = pBlock->getCompBlock()->getArgumentDefaultValue(argumentName);
    FL_DIAG_ASSERT(mxDefValue != nullptr);

    // Always add default value to compiled information (even for scalars)
    if (cbd != nullptr && !IsBdExecuting(bd))
    {
        std::string key (SIDServiceSL::getCompactSID(pBlock) + "." + argumentName);
        matrix::unique_mxarray_ptr mxDupVal = matrix::shared_copy(mxDefValue);
        ModelReferenceCompileInformation* mrci = cbd->getModelReferenceCompileInformation();
        mrci->addArgumentDefaultValue(key, mxDupVal.release());
    }
}

static slsvDiagnostic compareDataTypesOfStruct(ModelRefBlock* pBlock,
                                        ModelRefIntfParamType intfPrmType,
                                        int typedPrmArgIdx,
                                        int prmArgIdx,
                                        bool isHidden,
                                        DTypeId origDT,
                                        SlArray* locArray)
{
    // Compile model (prior to simulation / code generation)
    // For structure arguments, we can't register the mrpiDT
    // from the submodel (we only have the checksum).
    // So, we use the value in the top model to determine
    // the DTId (if the data type checksums match).
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    
    const SLRootBD *bd = pBlock->getBPI()->getGrBlockDiagram();
    slDataTypeTable* table = gbd_dataTypeTable(bd);

    const slChecksumValue& dtChecksum =  DtGetStructDataTypeChecksum(table, origDT);

    slChecksumValue mrpiDtChecksum = 
        mrpi_GetStructDtChecksum(pBlock, intfPrmType, typedPrmArgIdx);

    if (!isHidden)
    {
        if (!slChecksumsEqual(&dtChecksum, &mrpiDtChecksum))
        {
            // Even if the checksums are different, it is still possible
            // that the two data types are compatible. Such is the case when
            // one data type is a bus type, and one of whose bus elements
            // has dimension 2 and the other data type contains and element
            // with dimension [1 2] or [2 1].

            // Such cases should be allowed and the following call to
            // CheckModelRefStructParamArgMismatch makes the correct
            // decision

            const std::string paramGraphicalName =
                mrpi_GetParamArgValueString(pBlock, prmArgIdx);

            const std::string pName = mrpi_GetName(pBlock, intfPrmType, typedPrmArgIdx);

            // cause
            slsvDiagnostic cause = CheckModelRefStructParamArgMismatch(
                pBlock, paramGraphicalName, pName, locArray);
            if (cause != SLSV_NoDiagnostic)
            {
                // generic errmsg
                errmsg = slsvCreateDiagnostic(
                    Simulink::Parameters::InvParamSetting(BPATH(pBlock), pName));
                slsvAddCauseToLastDiagnosticItem(errmsg, cause);
            }
        }
    }
    return errmsg;
}
}

/* Function: ModelRefEvalParamArgs ============================================
 * Abstract:
 *      Evaluate the parameter arguments and check their consistency.
 */
slsvDiagnostic ModelRefEvalParamArgs(ModelRefBlock * block) {
    slsvDiagnostic errmsg = SLSV_NoDiagnostic;
    SLRootBD* bd = block->getBPI()->getGrBlockDiagram();
    SLCompBD* cbd = block->getBPI()->getCompBD();
    ModelReferenceCompileInformation* mrci = cbd->getModelReferenceCompileInformation();
    
    FL_DIAG_ASSERT(bd->isRegionPostUpdateReferenceToCompileEnd() ||
                   IsBdContainingBlockExecuting(block));
    FL_DIAG_ASSERT(block->hasSlMdlRefCompTgt());
    
    const bool getPrmMapsAndStrs =
        block->hasSlMdlRefCompTgt(); // get param maps and strings if comp target exists
    SlArray** paramArrays = nullptr;
    AST** paramMaps = nullptr;
    char** pStrings = nullptr;
    void* dataPtr = nullptr;
    SLSize* dimsPtr = nullptr;
    int nArgs = 0;
    /* indices of interface parameters (model arguments and block parameter) with adjustment
     * for: missing value specification -- during codegen, instance-shared model block
     * parameters with structure S.C unused values specification -- model block
     * parameters recorded in graphical interface may not be present for various reasons,
     * such as model block being commented out; model block is inactive variant; underlying
     * model argument is unused hence has no corresponding r.t.p, or referenced model
     * interface changes (1 or more arguments removed but parent model block has not been
     * updated accordingly) valueIdx:    index for the evaled expressions supplied by the
     * model block (design information) paramArgIdx: index for the interface parameters
     * supplied by modelref interface (compiled information) diagPrmIdx:  index for user
     * visible model block parameters on dialog
     */
    int valueIdx = 0;
    int prmArgIdx = -1;
    int diagPrmIdx = 0;
    int cntSkippedValues = 0;
    
    slPrmDataFormat dataFormat = PRM_DATA_UNKNOWN;
    slDataTypeTable* table = gbd_dataTypeTable(bd);
    std::set<size_t> unusedValues;
    const ModelRefBlock* mdlrefBlk = safeCastToModelRefBlock(block);
    auto dictBlk = block->getDictBlock();
    
    // Handle old-style memory management
    BOOST_SCOPE_EXIT(&dataPtr, &dataFormat, &dimsPtr, &paramArrays, &paramMaps, &pStrings,
                     &nArgs) {
        FreePrmData(dataPtr, dataFormat);
        utFree(dimsPtr);
        
        for (int argIdx = 0; argIdx < nArgs; argIdx++) {
            delete (paramArrays[argIdx]);
        }
        utFree(paramArrays);
        paramArrays = nullptr;
        
        if (paramMaps != nullptr) {
            for (int argIdx = 0; argIdx < nArgs; argIdx++) {
                DeleteAST(paramMaps[argIdx]);
                utFree(paramMaps[argIdx]);
            }
                    utFree(paramMaps);
                    paramMaps = nullptr;
        }
        
        if (pStrings != nullptr) {
            for (int argIdx = 0; argIdx < nArgs; argIdx++) {
                utFree(pStrings[argIdx]);
            }
            utFree(pStrings);
            pStrings = nullptr;
        }
    }
    BOOST_SCOPE_EXIT_END
        
    bool usingRuntimeWks = SLCompBD::isUsingRuntimeWks(cbd);
    std::string mdlblkSid = SIDServiceSL::getCompactSID(block);
    const auto& groupedArgPrms = block->getCompBlock()->getGroupedModelArguments();
    
    const int nTotalBlkArgs = P_MODELREF_NUM_BLOCK_PARAMARGS(block);
    const int nHiddenBlkArgs = mrpi_GetNumHiddenBlockArgs(block);
    const int nModelPrmArgs = P_MODELREF_NUM_MODEL_PARAMARGS(block);
    
    std::vector<bool> arePublicMdlArgs;
    std::map<std::string, size_t> mapping;
    /* Evaluate the block's parameter arguments */
    {
        fl::ustring paramArgValues;
        std::tie(mapping, paramArgValues) = mdlrefBlk->mapNamesToValues();
        
        for (const auto& inactivePrm : block->getCompBlock()->getInactiveInstParams()) {
            auto findIt = mapping.find(inactivePrm);
            if (findIt != mapping.end()) {
                unusedValues.insert(findIt->second);
            }
        }
        
        /*
         * Hidden block parameters -- block parameters with structure S.C but not 
         * marked as instance specific.
         * For codegen purpose, we still have create runtime parameters for them
         * Unused block parameters -- block parameters visible as part of design
         * specification, but not present in compiled modelref interface for various 
         * reasons. Unlike unused model arguments, we cannot even
         * fake one because there is no backing to retrieve meta data information at all.
         */
        const int nExpectedArgs = nTotalBlkArgs - nHiddenBlkArgs + nModelPrmArgs +
            static_cast<int>(unusedValues.size());
        arePublicMdlArgs.reserve(nExpectedArgs);

        const char* propName =
            gdi_param_name((block->getDialogInfo()), P_MODELREF_PARAMARG_VALUES);
        // If the bd is executing, then we should tell this function how
        // many args to expect.  If there is a different amount in
        // paramArgValues, then the function will return an error.
        errmsg = sluEvalCommaSeparatedPrmString(
            block, paramArgValues, getPrmMapsAndStrs, propName, &nArgs, &paramArrays,
            &paramMaps, &pStrings,
            nullptr, // Error out for undefined vars
            arePublicMdlArgs, (IsBdContainingBlockExecuting(block) ? nExpectedArgs : -1));
        UNUSED_PARAMETER(arePublicMdlArgs);
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
        
        if (paramArrays != nullptr) {
            FL_DIAG_ASSERT(pStrings != nullptr);
            errmsg =
                isNdIndexingUsedWithModelParameters(mdlrefBlk, *pStrings, *paramArrays);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
        }
        
        errmsg = isValidInstanceSpecificSetupForRTW(bd, block, paramMaps);
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
        
        /* Check the number of evaluated dialog parameters */
        if (nArgs != nExpectedArgs) {
            errmsg = slsvCreateDiagnostic(
                block->getHandle(), Simulink::modelReference::ParamIntf_NumParamArgMismatch(
                    msgBlockFullPath(block), nExpectedArgs, nArgs));
            return errmsg;
        }
        
        /* Add extra slots for evaluated dialog parameters if required
         * NOTE: Only do this during model compilation because
         *       P_MODELREF_PARAMARG_VALUES is READONLY_IF_COMPILED_param */
        if (bd->isRegionPostUpdateReferenceToCompileEnd()) {
            errmsg = doCompTgtSetNumDlgParamsAdded(block, nArgs);
            
            if (SLSV_NoDiagnostic != errmsg)
                return (errmsg);
        }
        
        /* Set the parameter strings into the block's parameter interface
         * NOTE: This function nulls out the pStrings pointer */
        if (getPrmMapsAndStrs) {
            for (auto i : unusedValues) {
                utFree(pStrings[i]);
                pStrings[i] = nullptr;
            }
            std::remove(pStrings, pStrings + nArgs, nullptr);
            int nStrs = nArgs - static_cast<int>(unusedValues.size());
            FL_DIAG_ASSERT(nStrs >= 0);
            mrpi_StealParamArgValueStrings(block, nStrs, &pStrings);
        }
        
        /* Evaluate model arguments for inactive variants if
         * GeneratePreprocessorConditionals is 'on' and block diagram
         * is configured for code variants.
         * This behavior will be consistent with Subsystem
         * Variants after the g750309 is fixed (planned in 12b)
         */
        if (slGetFeatureValue(EvalInactiveModelArgForFindVars) > 0 &&
            GetMdlRefHasCodeVariants(block)) {
            ModelRefStringList modelArguments;
            GetModelRefParameters(block, true, P_MODELREF_PARAMARG_VALUES, modelArguments);
            
            for (ModelRefStringList::const_iterator iter = modelArguments.begin();
                 iter != modelArguments.end(); ++iter) {
                const fl::ustring argValues = fl::i18n::to_ustring(*iter);
                // Skip active variant
                if (!argValues.empty() && (argValues != paramArgValues)) {
                    int tmpNumArgs = 0;
                    SlArray** tmpParamArrays = nullptr;
                    std::vector<bool> arePublicArgs;
                    // Perform a 'fake' evaluation just to cache variable usage information
                    errmsg = sluEvalCommaSeparatedPrmString(
                        block, argValues, false, propName, &tmpNumArgs, &tmpParamArrays,
                        nullptr, nullptr, nullptr, arePublicArgs, nArgs);
                    UNUSED_PARAMETER(arePublicArgs);
                    // Destroy temp array used for 'fake' evaluation
                    for (int i = 0; i < tmpNumArgs; i++) {
                        delete (tmpParamArrays[i]);
                    }
                    utFree(tmpParamArrays);
                    tmpParamArrays = nullptr;
                    
                    // We report errors during the 'fake' evaluation
                    if (errmsg != SLSV_NoDiagnostic) {
                        return errmsg;
                    }
                }
            }
        }
    }
    
    for (int li = 0; li < (nArgs + nHiddenBlkArgs); ++li) {
        if (unusedValues.count(li) > 0) {
            ++cntSkippedValues;
            continue;
        }
        ++prmArgIdx;
        valueIdx = diagPrmIdx + cntSkippedValues;
        
        // Get the data type, name, coderGroup, and hidden flag from M.R.P.I
        int typedPrmArgIdx = prmArgIdx;
        ModelRefIntfParamType intfPrmType = MODELREF_INTFPARAM_BLOCK;
        bool isHidden = false;
        if (prmArgIdx >= nTotalBlkArgs) {
            typedPrmArgIdx = prmArgIdx - nTotalBlkArgs;
            intfPrmType = MODELREF_INTFPARAM_MODEL;
        } else {
            isHidden = mrpi_GetIsBlkPrmArgHidden(block, typedPrmArgIdx);
        }
        /* Note:  pName may differ from the actual model argument name due to decoration,
         * eg. rtp_ prefix for SIL mode, _prot postfix for protected model.
         */
        const std::string pName = mrpi_GetName(block, intfPrmType, typedPrmArgIdx);
        const bool promoteToAllAncestors =
            mrpi_GetPromoteToAllAncestors(block, intfPrmType, typedPrmArgIdx);
        const bool hasDescendantParamWrite = GetModelRefParamInterface(block)->
            getHasDescendantParamWrite(intfPrmType, typedPrmArgIdx);

        bool hasParamWrite = false;
        if (block->hasExternalAccessToParam()) {
            const auto accInfo = bd->getParamAccessorMgr()->getOwnerAccessorInfo();
            double blockH = block->getHandle();
            auto it = accInfo->find(blockH, ConvertStdStringToUString(pName));
            if (it != accInfo->end() &&
                (!it->second.mWriterSet.empty() || !it->second.mBothReadWriteSet.empty())) {
                hasParamWrite = true;
            }
        }
        
        const DTypeId mrpiDT = mrpi_GetDataType(block, intfPrmType, typedPrmArgIdx);
        bool isStructArgExpected =
            (mrpiDT == INVALID_DTYPE_ID || DtIsStructType(table, mrpiDT));
        
        // Get if this model block parameter is tunable from the top
        bool testpointed = false;
        const bool coderGroupsSupported = (slGetFeatureValue(ParameterTestPoint) > 1);
        std::string groupName;
        if (slGetFeatureValue(ParameterTestPoint) > 2 && bd->isModelReferenceSimTarget() &&
            dictBlk) {
            auto dictP = dictBlk->getParameter()[pName];
            if (dictP && dictP->getInstanceSpecific()) {
                testpointed = true;
                groupName = "_InstP";
            }
        }
        if (!testpointed && coderGroupsSupported) {
            auto findIt = groupedArgPrms.find(pName);
            if (findIt != groupedArgPrms.end()) {
                testpointed = true;
                groupName = findIt->second;
            }
        }
        if (testpointed && SLCG::getCastedCGModel(bd)) {
            // Consider moving the check into the pre-processing phase
            errmsg =
                slcomp::slCheckInstanceSpecificParam(cbd, groupName, block, pName.c_str());
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
        }
        
        int nDims = 0;
        DTypeId origDT = INVALID_DTYPE_ID;
        bool isComplex = false;
        int logPrmIdx = ModelRefGetLogicalIdxFromPrmArgIdx(block, prmArgIdx);
        bool unspecifiedValue = false;
        
        // Get metadata attributes from SlArray before it is destroyed
        SlArray* locArray = nullptr;
        if (!isHidden) {
            locArray = paramArrays[valueIdx];
            nDims = locArray->getNumDimensions();
            errmsg = locArray->getSLSizeCopyOfDimensions(&dimsPtr);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            unspecifiedValue = (nDims == 2 && 0 == *dimsPtr && 0 == *(dimsPtr + 1));
            
            
        }
        
        if (isHidden ||
            (unspecifiedValue && slGetFeatureValue(DefaultModelArgValues) > 0)) {
            const mxArray* mxDefValue =
                block->getCompBlock()->getArgumentDefaultValue(pName);
            FL_DIAG_ASSERT(mxDefValue != nullptr);
            // replace empty value with default value
            if (locArray) {
                delete locArray;
            }
            if (dimsPtr) {
                free(dimsPtr);
            }
            
            // Instance-specific LUT but not used anywhere. So it is never late bound and
            // hence its synthesized parameter is null. It is needed to answer question such
            // as getOrigDataTypeId.
            if (slIsLUTObjectFromMxArray(mxDefValue)) {
                SlLookupTable* lut =
                    const_cast<SlLookupTable*>(slGetLUTObjectFromMxArray(mxDefValue));
                
                if (lut->lateBindingOutOfDate(bd)) {
                    // pName is of the form <Number>.<Number>.<Name>
                    const std::string sep(".");
                    mdlref::ParameterArgumentTokenizer<std::string, char> paramNamesTokens(
                        pName, sep);
                    std::vector<std::string> tokens = paramNamesTokens.toVec();
                    std::string rawParamName = tokens.at(tokens.size() - 1);
                    
                    FL_DIAG_ASSERT(!rawParamName.empty());
                    errmsg = lateBindLUT(bd, lut, rawParamName);
                }
                
                if (errmsg != SLSV_NoDiagnostic) {
                    return errmsg;
                }
            }
            
            
            slCreateSlArray(mxDefValue, &locArray);
            if (nullptr != locArray) {
                nDims = locArray->getNumDimensions();
                errmsg = locArray->getSLSizeCopyOfDimensions(&dimsPtr);
            }
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
        }
        
        if (usingRuntimeWks && (locArray == nullptr)) {
            continue;
        }
        
        isComplex = locArray->isComplex();
        
        origDT = INVALID_DTYPE_ID;
        errmsg = locArray->getOrigDataTypeId(bd, &origDT);
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
        
        if (origDT == INVALID_DTYPE_ID) {
            errmsg = slsvCreateDiagnostic(
                Simulink::Parameters::InvParamSetting(BPATH(block), pName));
            return errmsg;
        }
        // Check data type for struct args
        if (mrpiDT != DYNAMICALLY_TYPED) {
            if (DtIsEnumType(table, origDT) != DtIsEnumType(table, mrpiDT)) {
                errmsg = slsvCreateDiagnostic(
                    // ParamTestPoint TODO: translate pName to parameter name for the test
                    // pointed
                    Simulink::modelReference::ParamIntf_ParamArg_DataTypeMismatch(
                        pName, BPATH(block)));
                return errmsg;
            }
            bool isStructParam = locArray->isNumericStruct();
            if (isStructParam && isStructArgExpected) {
                
                addArgumentDefaultValueToModelRefCompiledInformation(block, pName);
                
                if (IsBdContainingBlockExecuting(block)) {
                    // Update diagram during simulation
                    FL_DIAG_ASSERT(mrpiDT != INVALID_DTYPE_ID);
                    if (mrpiDT != origDT) {
                        errmsg = compareDataTypesOfStruct(block, intfPrmType,
                                                          typedPrmArgIdx, prmArgIdx,
                                                          isHidden, origDT, locArray);
                        
                        if (SLSV_NoDiagnostic != errmsg)
                        {
                            return errmsg;
                        }
                    }
                } else if (mrpiDT == INVALID_DTYPE_ID) {
                    
                    errmsg = compareDataTypesOfStruct(block, intfPrmType, typedPrmArgIdx, prmArgIdx, isHidden, origDT, locArray);
                    
                    if (SLSV_NoDiagnostic != errmsg) { return errmsg; }
                    // The two data types are compatible.
                    if (!isHidden) {
                        slMdlRefCompPrmIntf* prmIntf = GetModelRefParamInterface(block);
                        const std::string mrpiDtName =
                            prmIntf->getStructDtName(intfPrmType, typedPrmArgIdx);
                        bool mrpiDtIsAnonymous =
                            prmIntf->getStructDtIsAnonymous(intfPrmType, typedPrmArgIdx);
                        
                        const char* origDtName = DtGetDataTypeName(table, origDT);
                        bool origDtIsAnonymous = DtIsAnonymousStructType(table, origDT);
                        
                        if (utStrcmp(origDtName, mrpiDtName.c_str()) == 0) {
                            // do nothing
                        } else if (!origDtIsAnonymous && !mrpiDtIsAnonymous) {
                            // error type name mismatch
                            errmsg = slsvCreateDiagnostic(
                                block->getHandle(),
                                Simulink::modelReference::ParamIntf_ParamArg_InvalidStructDataType(
                                    pName, msgBlockFullPath(block), origDtName, mrpiDtName));
                            return errmsg;
                        } else if (mrpiDtIsAnonymous) {
                            // register anonymous type
                            int dtIdAnonymous = INVALID_DTYPE_ID;
                            MxArrayScopedRefPtr mxValue;
                            errmsg = locArray->getSharedCopyOfDataAsMxArray(&mxValue);
                            if (errmsg != SLSV_NoDiagnostic) {
                                return errmsg;
                            }
                            
                            errmsg = slRegisterDataTypeFromMxStruct(bd, mxValue, &dtIdAnonymous);
                            if (errmsg != SLSV_NoDiagnostic) {
                                return errmsg;
                            }
                            
                        } else if (origDtIsAnonymous) {
                            // register bus type
                            int dtIdBus = INVALID_DTYPE_ID;
                            const char* propName =
                                gdi_param_name((block->getDialogInfo()), P_MODELREF_PARAMARG_VALUES);
                            
                            MxArrayScopedRefPtr mxValue;
                            errmsg = locArray->getSharedCopyOfDataAsMxArray(&mxValue);
                            if (errmsg != SLSV_NoDiagnostic) {
                                return errmsg;
                            }
                            
                            mxArray* mxDefValue = const_cast<mxArray*>(
                                block->getCompBlock()->getArgumentDefaultValue(pName));
                            
                            // When the feature is turned on, a MATLAB struct can be
                            // specified as value of LUT object. In such case, do not
                            // register the structure origDtIsAnonymous (true) comes from
                            // SlArray which corresponds to structure.
                            if (!((slGetFeatureValue(AllowStructAsLUTArgument) > 0) && isStructParam &&
                                  slIsLUTObjectFromMxArray(mxDefValue))) {
                                errmsg = RegisterDataTypeForBlockFromString(block, mrpiDtName.c_str(),
                                                                            propName, &dtIdBus);
                                
                                if (errmsg != SLSV_NoDiagnostic) {
                                    return errmsg;
                                }
                                /*
                                 * The line below alone does fixing g1223764, and I think it
                                 * is right for model reference block to register a data
                                 * type from specified bus name for the interface anyway.
                                 */
                                origDT = dtIdBus;
                            }
                        }
                    }
                    mrpi_SetDataType(block, intfPrmType, typedPrmArgIdx, origDT);
                } else {
                    // Valid mrpiDT is determined by origDT when checksums match
                    FL_DIAG_ASSERT(mrpiDT == origDT);
                }
                
            } else if ((isStructParam && !isStructArgExpected) ||
                       (!isStructParam && isStructArgExpected)) {
                // Submodel expects non-structure argument, but parameter is structure
                // OR Submodel expects structure argument, but parameter is non-structure.
                // ParamTestPoint TODO: translate pName to parameter name for the test
                // pointed
                errmsg = slsvCreateDiagnostic(
                    Simulink::modelReference::ParamIntf_ParamArg_DataTypeMismatch(
                        pName, BPATH(block)));
                { return errmsg; }
            }
        }
        // stash the current default value via. compiled info
        if (promoteToAllAncestors) {
            SlArray* clone;
            errmsg = locArray->clone(&clone);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            mxArray* mxDupVal = nullptr;
            errmsg = SlArray::ConvertToMxArray(&clone, &mxDupVal);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            if (!IsBdExecuting(bd)) {
                mrci->addArgumentDefaultValue(mdlblkSid + "." + pName, mxDupVal);
            }
        }
        
        if (DtIsStructType(table, origDT) || DtIsEnumType(table, origDT)) {
            // Store struct & enum data as mxArray in EDP
            mxArray* locMat = nullptr;
            errmsg = SlArray::ConvertToMxArray(&locArray, &locMat);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            dataFormat = PRM_DATA_MXARRAY;
            dataPtr = static_cast<void*>(locMat);
        } else {
            errmsg = SlArray::ConvertToVoidPtr(bd, &locArray, &dataPtr);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            dataFormat = PRM_DATA_VOID_PTR;
        }
        /****************************************
         *   locArray is no longer available    *
         * (IT HAS BEEN DELETED AND NULLED OUT) *
         ****************************************/
        
        // If we have gotten this far, locArray has been deleted
        // Therefore, we need to NULL out paramArrays[valueIdx]
        if (!isHidden) {
            paramArrays[valueIdx] = nullptr; // ensure we don't double free
        }
        {
            SlDims prmDims;
            prmDims.initialize(nDims, dimsPtr);
            const char* pNameAsChar =
                mrpi_GetNameAsChar(block, intfPrmType, typedPrmArgIdx);
            
            SlEDPrmAttribs edpAttribs(pNameAsChar, // name
                                      &prmDims,    // dims
                                      origDT,      // dType
                                      isComplex,   // complexity
                                      dataFormat,  // dataFormat
                                      prmArgIdx,   // idx
                                      dataPtr);    // data
            if (IsBdContainingBlockExecuting(block)) {
                /* Update diagram during simulation, skip if the parameter has been test
                 * pointed, or, it has a coder group and bd is not the top model.
                 */
                if (!isHidden) {
                    bool skipEval = false;
                    auto key = mdlblkSid + "." + pName;
                    if (bd->isModelReferenceTarget() &&
                        0 < cbd->getMdlArgValOverride().count(key)) {
                        skipEval = true;
                    }
                    if (!skipEval) {
                        errmsg = slUpdateEvaledDlgParam(block, logPrmIdx, &edpAttribs);
                        if (errmsg != SLSV_NoDiagnostic) {
                            return errmsg;
                        }
                    }
                }
            } else {
                /* Compile model (prior to simulation / code generation) */
                
                /* Check the consistency of the evaluated dialog parameter */
                errmsg = ModelRefValidateEvaledParam(block, intfPrmType, typedPrmArgIdx,
                                                     &edpAttribs);
                if (errmsg != SLSV_NoDiagnostic) {
                    return errmsg;
                }
                /* Register evaluated dialog parameter */
                errmsg = slRegEvaledDlgParam(block, logPrmIdx, &edpAttribs,
                                             isHidden ? nullptr : paramMaps[valueIdx]);
                if (errmsg != SLSV_NoDiagnostic) {
                    return errmsg;
                }
                
                slParam* blockParam = block->getBPI()->getGrEDP(logPrmIdx);
                if (isHidden) {
                    ssp_HiddenForSim(blockParam);
                }
                if (promoteToAllAncestors) {
                    ssp_isPromotedToAllAncestors(blockParam);
                }
                if (hasParamWrite) {
                    ssp_hasParamWrite(blockParam);
                }
                if (hasDescendantParamWrite) {
                    ssp_hasDescendantParamWrite(blockParam);
                }
                
                ssp_IsTestpointed(blockParam, testpointed);
                if (testpointed) {
                    CollapseASTNodeForTestpointedPrm(block, logPrmIdx);
                    block->getBPI()->setCompHasInstP(true);
                    cbd->setHasInstP(true);
                }
            }
        }
        /*  Successful param reg. Null out data & AST - the param owns them. */
        dataPtr = nullptr;
        if (getPrmMapsAndStrs && !isHidden) {
            paramMaps[valueIdx] = nullptr;
        }
        
        /* Free temporary variables */
        if (dimsPtr) {
            utFree(dimsPtr); dimsPtr = nullptr;
        }
        
        if (!isHidden) { ++diagPrmIdx; }
        
    } /* loop through interface parameters */
    
    return(errmsg);
} /* end ModelRefEvalParamArgs */


/* Function: ModelRefEvalGlobalParams =========================================
 * Abstract:
 *      Evaluate the global parameters and check their consistency.
 */
slsvDiagnostic ModelRefEvalGlobalParams(SLBlock *block)
{
    slsvDiagnostic errmsg    = SLSV_NoDiagnostic;
    SLRootBD *bd       = block->getBPI()->getGrBlockDiagram();
    SlVariable     *slVar    = nullptr;
    SLSize         *dimsPtr  = nullptr;
    void           *dataPtr  = nullptr;
    int            nGlobPrms = P_MODELREF_NUM_GLOBAL_PARAMS(block);
    int            prmIdx;
    slPrmDataFormat dataFormat = PRM_DATA_UNKNOWN;

    // Handle old style memory management
    BOOST_SCOPE_EXIT(&slVar, &dimsPtr, &dataPtr, &dataFormat) {
        delete(slVar);
        utFree(dimsPtr);
        FreePrmData(dataPtr, dataFormat);
    } BOOST_SCOPE_EXIT_END
    
    FL_DIAG_ASSERT(bd->isRegionPostUpdateReferenceToCompileEnd() || IsBdContainingBlockExecuting(block));

    if (nGlobPrms == 0) return(errmsg);

    /* Add extra slots for evaluated dialog parameters if required
     * NOTE: Only do this during model compilation because
     *       nGlobPrms can only change if submodel is recompiled */
    if (bd->isRegionPostUpdateReferenceToCompileEnd()) {
        errmsg = doCompTgtSetNumDlgParamsAdded(block, nGlobPrms);

        if (SLSV_NoDiagnostic != errmsg) return(errmsg);
    }

    // provide hint to dictionary interface that accesses may be coming
    SLDDI::DictionaryAccessIntervalNotifier dictNotifier;

    slDataTypeTable* table = gbd_dataTypeTable(bd);

    for (prmIdx = 0; prmIdx < nGlobPrms; prmIdx++) {
        const std::string pName    = mrpi_GetName(block, MODELREF_INTFPARAM_GLOBAL,
                                            prmIdx);
        int        corrPrmIdx= ModelRefGetCorrectGlobalPrmIdx(block,prmIdx);
        int        logPrmIdx = ModelRefGetLogicalIdxFromGlobalPrmIdx(block,prmIdx);
        DTypeId    origDT;

        // Evaluate the symbol name in global data source
        // Use information from model reference block because compilation target is not
        // always available.
        errmsg = ModelRefFindGlobalVariable(pName.c_str(), bd, block, &slVar);
        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
        
        std::string paramName = sldd::utilities::getVarAndDictionaryNameFromQualifiedVarName(pName).first;    
        /* If slVar == nullptr, the variable was removed from the base workspace.
         * This is most likely to happen if the submodel has a CloseFcn that
         * clears variables from the base workspace */
        if (slVar == nullptr) {
            errmsg = slsvCreateDiagnostic(block->getHandle(),Simulink::modelReference::ParamIntf_GlobalParam_Missing(
                    paramName,
                    msgBlockFullPath(block),
                    mdlref::GetModelRefName(block)));
            return errmsg;
        }
        
        slsv_scoped_ref_ptr<SlArray> locArray;
        errmsg = slVar->getSlArray(&locArray);
        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
        
        errmsg = locArray->getSLSizeCopyOfDimensions(&dimsPtr);
        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
        
        errmsg = locArray->getOrigDataTypeId(bd, &origDT);
        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}

        if (origDT == INVALID_DTYPE_ID) {
            errmsg = slsvCreateDiagnostic(Simulink::Parameters::InvParamSetting( BPATH(block), paramName));
            return errmsg;
        }
        
        
        DTypeId mrpiDT = 
            mrpi_GetDataType(block, MODELREF_INTFPARAM_GLOBAL, prmIdx);
        const std::string mpriDTName =
            mrpi_GetDataTypeName(block,  MODELREF_INTFPARAM_GLOBAL, prmIdx);
        
        if (locArray->isNumericStruct()) {
            if (IsBdContainingBlockExecuting(block)) {
                // Update diagram during simulation
                if (mrpiDT != origDT) {
                    errmsg = slsvCreateDiagnostic(Simulink::Parameters::InvParamSetting( BPATH(block), paramName));
                    return errmsg;
                }
            } else {
                // Compile model (prior to simulation / code generation) 
                FL_DIAG_ASSERT(mrpiDT == INVALID_DTYPE_ID);

                bool structIsMappedToBus = false;
                
                const ModelRefBlock* mdlRefBlk = safeCastToModelRefBlock(block);
        
        
                if (mdlRefBlk->hasSlMdlRefCompTgt()) {
                    const ModelRefCompBlock* compBlock = mdlRefBlk->getCompBlock();
                    const char* structTypeName = DtGetDataTypeName(table, origDT);
                    const char* busTypeName = compBlock->getBusForStructTypeName(
                        structTypeName);
                    structIsMappedToBus =
                        (nullptr != busTypeName) &&
                        (0 == strcmp(mpriDTName.c_str(), busTypeName));
                    //
                    // assert that we should not encounter any mismatching
                    // type names if a bus type has been registered
                    //
                    FL_DIAG_ASSERT(nullptr == busTypeName ||
                                   mpriDTName.empty() ||
                                   structIsMappedToBus);
                    
                }
                
                if (!structIsMappedToBus) {
                    // Check dtChecksum for struct parameter 
                    // In theory global parameters could be changed during model
                    // hierarchy compiling
                    const slChecksumValue& dtChecksum =
                        DtGetStructDataTypeChecksum(table, origDT);
                    slChecksumValue mrpiDtChecksum =  
                        mrpi_GetStructDtChecksum(
                            block, MODELREF_INTFPARAM_GLOBAL, prmIdx);

                    if (!slChecksumsEqual(&dtChecksum, &mrpiDtChecksum)) {
                        errmsg = slsvCreateDiagnostic(
                            Simulink::Parameters::InvParamSetting(
                                BPATH(block), paramName));
                        return errmsg;
                    }
                }

                mrpi_SetDataType(block, MODELREF_INTFPARAM_GLOBAL, prmIdx, origDT);
            }

        } else if (mrpiDT == INVALID_DTYPE_ID) {
            errmsg = RegisterDataTypeForBlockFromString(
                block, mpriDTName.c_str(), &mrpiDT);
            if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
            
            mrpi_SetDataType(block, MODELREF_INTFPARAM_GLOBAL, prmIdx, mrpiDT);
        }
        
        // Convert the SlArray to raw data
        if (DtIsStructType(table, origDT) || DtIsEnumType(table, origDT)) {
            // Store struct & enum data as mxArray in EDP
            mxArray *locMat = nullptr;
            /* aamrutka - bug geck - 1826807
             * Changed the below API call from SlArray::ConvertToMxArray to getSharedCopyOfDataAsMxArray
             * This change is only made with the understanding that, over here the EDP attribs updated
             * for Global Model ref Prms require only the underneath data as mxArray
            
             * this is on the basis that SlArray::ConvertToMxArray has special handling for
             * Simulink.LookupTable Object and Simulink.Breakpoint object
             * which is not required in this code-path, as we need the internal data
             * for Eg. Simulink.Breakpoint = enum array
             * over here we require the internal Enum array of the Breakpoint data to be stored in the
             * further used EDP attribs.
             */
            errmsg = locArray->getSharedCopyOfDataAsMxArray(&locMat);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            dataFormat = PRM_DATA_MXARRAY;
            dataPtr = static_cast<void*>(locMat);
        } else {
            // We need a second copy, because we are going to steal the data
            slsv_scoped_ref_ptr<SlArray> tmpArray;
            errmsg = locArray->clone(&tmpArray);
            if (errmsg != SLSV_NoDiagnostic) {return errmsg;}

            errmsg = SlArray::ConvertToVoidPtr(bd, &tmpArray, &dataPtr);
            if (errmsg != SLSV_NoDiagnostic) {
                return errmsg;
            }
            dataFormat = PRM_DATA_VOID_PTR;
        }
        
        {
            SlDims prmDims;
            prmDims.initialize(locArray->getNumDimensions(),
                               dimsPtr);

            // Need to use char * version of the API, SlEDPrmAttribs will
            // cache away the pointer when it is constructed.
            const char *locPName = mrpi_GetNameAsChar(block,
                                                      MODELREF_INTFPARAM_GLOBAL,
                                                      prmIdx);
            SlEDPrmAttribs edpAttribs(locPName,              // name
                                      &prmDims,              // dims
                                      origDT,                // dType
                                      locArray->isComplex(), // complexity
                                      dataFormat,            // dataFormat
                                      corrPrmIdx,            // idx
                                      dataPtr);              // data

            
            if (IsBdContainingBlockExecuting(block)) {
                /* Update diagram during simulation */
                errmsg = slUpdateEvaledDlgParam(block, logPrmIdx, &edpAttribs);
                if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
            } else {
                /* Compile model (prior to simulation / code generation) */
                
                /* Check the consistency of the evaluated dialog parameter
                 * (the variable in the base workspace may have been changed
                 *  during the rebuilding of this / other referenced models) */
                errmsg = ModelRefValidateEvaledParam(block, MODELREF_INTFPARAM_GLOBAL, prmIdx, &edpAttribs);
                if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
                
                if (!block->getBPI()->slBlockInCallbackTree(block, nullptr)) {
                    if (slDoGenerateParameterASTs(bd, block)) {
                        AST *prmAST   = nullptr;
                        // set up right context for looking up variables such as for qualified name
                        std::unique_ptr<ResolveGlobalVarContextSetter> varContextSetter;
                        if (sldd::utilities::useQualifiedVarNameForVarInDataDictionary() &&
                            sldd::utilities::isQualifiedVarName(pName)) {
                            varContextSetter.reset(
                                new ResolveGlobalVarContextSetter(bd->getGlobalWorkspace(), pName));
                        }

                        errmsg = slGenerateASTForPrmExpression(bd, block, nullptr, pName.c_str(),
                                                               paramName.c_str(), locArray, SL_RESOLVE_GLOBAL,
                                                               &prmAST);         // out
                        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
                        
                        /* Register evaluated dialog parameter */
                        errmsg = slRegEvaledDlgParam(block, logPrmIdx, &edpAttribs, prmAST);
                        if (errmsg != SLSV_NoDiagnostic) {
                            DeleteAST(prmAST);
                            return errmsg;
                        }

                        if (nullptr != prmAST)
                        {
                            MxArrayScopedRefPtr param;
                            slsvDiagnostic locErrMsg = locArray->getSharedCopyOfOrigMxArray(&param);
                            SlParam* pParam = nullptr;
                            if ((SLSV_NoDiagnostic == locErrMsg) &&
                                (param) && mxIsA(param, "Simulink.Parameter")) {
                                pParam = slGetWritableParamObjectFromMxArray(param);
                            }

                            if ((nullptr != pParam) && pParam->isValueExpressionPreserved())
                            {
                                slParam *wsPrmOwner = gast_TermWSParam(prmAST);
                                FL_DIAG_ASSERT(nullptr != wsPrmOwner);
                                registerSymbolsInValueExpression(pParam, bd, block, wsPrmOwner, param);
                            }
                        }
                        
                        /* Steal the AST - the param owns it */
                        prmAST = nullptr;
                        
                        /* 
                         * It is possible that a global parameter of a model reference
                         * block turns out not to be tunable from the top model's perspective.
                         * This is the case when the sub-model is configured to be inline off
                         * and the top model inline on. In such case, any variables
                         * not explicitly configured to be tunable is treated as tunable by
                         * the sub-model (thus appearing in the list of global parameters) 
                         * but non-tunable by the top model. This is an error condition and
                         * will be detected and reported in model reference consistency check
                         * (see slMdlrefSimTargetConsistencyChecks::EVAL_PARAMS_CHECKS in
                         * comp_bd.cpp).
                         */
                        if (gsp_MapsToInterfacedVars(block->getBPI()->getGrEDP(logPrmIdx))) {
                            block->getBPI()->setCompHasTunablePrms(true);
                        }
                    } else {
                        /* Register evaluated dialog parameter */
                        errmsg = slRegEvaledDlgParam(block, logPrmIdx, &edpAttribs, nullptr);
                        if (errmsg != SLSV_NoDiagnostic) {return errmsg;}
                    }
                } else {
                    errmsg = slsvCreateDiagnostic(
                        Simulink::Parameters::UpdateDiagramInCallback(bd->getDisplayName()));
                }
            }
        }

        /*
         * Successful param reg. Null out data - the param owns it.
         */
        dataPtr = nullptr;

        /* Free temporary variables */
        delete(slVar);    slVar    = nullptr;
        utFree(dimsPtr);  dimsPtr  = nullptr;
    } /* for (prmIdx = 0; prmIdx < nGlobPrms; prmIdx++) */

    return(errmsg);
} /* end ModelRefEvalGlobalParams */

/* Function: ModelRefSetAllOutputDimsFcn ================================================
 * Abstract:
 *   Call the set all output dims fcn of the s-fcn
 */
slsvDiagnostic ModelRefSetAllOutputDimsFcn(SLBlock *block, slSimBlock* mrSimBlock)
{
    ModelRefExecBlock* mrExecBlock = boost::polymorphic_downcast<ModelRefExecBlock*>(mrSimBlock);
    slsvDiagnostic errmsg = getCompTgtFromBlock(block).setAllOutputDimsFcn(mrExecBlock);
    return errmsg;
}

 PortLogResults *ModelRefPortLogResults(slModel       *parentModel, 
                                        const SLBlock *block,
                                        UDInterface   *udi,
                                        int           numNormalMR)
{
    PortLogResults *plRes
        = getCompTgtFromBlock(block).createMdlRefPortLogRes(parentModel, udi,
                                                             numNormalMR);

    return plRes; 
}

/* Function: ModelRefLinkBlockToSimStruct ======================================
 * Abstract:
 *   For accelerated mode, link the underlying s-functions simstruct to
 * the memory in the simblock.  This is a no-op for normal mode.
 */
 slsvDiagnostic ModelRefLinkBlockToSimStruct(SLBlock *block, 
                                             slSimBlock *simBlock)
{
    return getCompTgtFromBlock(block).linkSimBlockToSimStruct(simBlock);
}

//////////////////////////// Code from sfunmodelref.cpp

 bool MdlRefCheckIfBlkHasState(const SLBlock* b, const SLExecBD& parentEBD)
{
    return getCompTgtFromBlock(b).hasLoggableState(parentEBD);
} 

 int MdlRefGetNumStateRecords(const SLBlock* b, bool contStatesOnly, const SLExecBD& parentEBD)
{
    return getCompTgtFromBlock(b).getNumStateRecords(contStatesOnly, parentEBD);
} 

 int MdlRefGetNumLoggableStateRecords(const SLBlock* b, bool contStatesOnly, const SLExecBD& parentEBD)
{
    return getCompTgtFromBlock(b).getNumLoggableStateRecords(contStatesOnly, parentEBD);
} 

slsvDiagnostic MdlRefUpdateStateRecordInfo(
                                     SLBlock*     block,
                                     SLBlock**    sigBlock,
                                     std::vector<slsvString> &sigBlockName,
                                     const char** sigLabel,
                                     std::vector<slsvString> &sigName,
                                     int*         sigWidth,
                                     int*         sigDataType,
                                     int*         logDataType,
                                     int*         sigComplexity,
                                     void**       sigDataAddr,
                                     boolean_T*   sigCrossMdlRef,
                                     boolean_T*   sigInProtectedMdl,
                                     std::vector<slsvString> &sigPathAlias,
                                     slexec::ConstSampleTimeRef* sigSampleTime,
                                     int*         sigHierInfoIdx,
                                     unsigned*    sigFlatElemIdx,
                                     const rtwCAPI_ModelMappingInfo** sigMMI,
                                     int*         sigIdx,
                                     bool         getStateDerivAddr,
                                     const SLBlock *topModelBlock,
                                     const SLExecBD& parentEBD,
                                     bool trueSynthesizedBlockPath)
{
    slsvDiagnostic errmsg
        = getCompTgtFromBlock(block).updateStateRecordInfo(sigBlock,
                                                            sigBlockName,
                                                            sigLabel,
                                                            sigName,
                                                            sigWidth,
                                                            sigDataType,
                                                            logDataType,
                                                            sigComplexity,
                                                            sigDataAddr,
                                                            sigCrossMdlRef,
                                                            sigInProtectedMdl,
                                                            sigPathAlias,
                                                            sigSampleTime,
                                                            sigHierInfoIdx,
                                                            sigFlatElemIdx,
                                                            sigMMI,
                                                            sigIdx,
                                                            getStateDerivAddr,
                                                            topModelBlock,
                                                            parentEBD,
                                                            trueSynthesizedBlockPath);
    return errmsg;

}

/* Ask the target language used by the referenced model, given a mdlref block */
ConfigSetRTWTargetLang getTargetLangForMdlRefBlock(const SLBlock* const block)
{
    return getCompTgtFromBlock(block).getTargetLang();

}


/* Ask the referenced model's CPPClassGenMode, given a mdlref block */
bool IsMdlRefBlockCppClassGenMode(const SLBlock* const block)
{
    return getCompTgtFromBlock(block).isCPPClassGenMode();
}


/* Ask the DWork index in the Subsystem DWork for the CPP Encap object, if
   the model reference block is within a non-root/non-hidden root subsystem. If
   it is not within a subsystem or if the model reference block's target language
   is not C++ (Encapsulated), then it should return -1, which is the default
   value */
int getCppObjInSubsysDWorkIdx(const SLBlock* const block)
{
    if(!IsMdlRefBlockCppClassGenMode(block)) {
        return -1;
    }
    return getCompTgtFromBlock(block).getCppObjInSubsysDWorkIdx();
}

bool IsModelBlockInportFunctionCallInitiator(const ModelRefBlock *block, size_t portIdx)
{
    return block->getCompBlock()->getInputPortIsFunctionCallInitiator(portIdx);
}

std::string GetModelBlockConstructorName(const ModelRefBlock * block)
{
    return getCompTgtFromBlock(block).getModelRefClassName();
}

fl::ustring GetModelRefBuildDir(const ModelRefBlock* block){
    return getCompTgtFromBlock(block).getModelRefBuildDir();
}

std::string GetModelRefRTMTypeName(const ModelRefBlock *block)
{
    return getCompTgtFromBlock(block).getModelRefRTMTypeName();
}

bool GetModelRefClassAllocatedInDWork(const ModelRefBlock *block)
{
    return getCompTgtFromBlock(block).isClassAllocatedInDWork();
}

std::string GetSLFcnImplementationName(const ModelRefBlock *block, const std::string& slFcnName)
{
    return getCompTgtFromBlock(block).getSLFcnImplementationName(slFcnName);
}

bool IsModelScopedSLFcnMultiInstance(const ModelRefBlock *block, const std::string& slFcnName)
{
    return getCompTgtFromBlock(block).isModelScopedSLFcnMultiInstance(slFcnName);
}

bool ModelRefHasSynthesizedSelf(const ModelRefBlock *block)
{
    return getCompTgtFromBlock(block).modelRefHasSynthesizedSelf();
}

bool IsModelRefUsingSimplifiedInterface(const ModelRefBlock *block)
{
    return getCompTgtFromBlock(block).isModelRefUsingSimplifiedInterface();
}

RTWCG::SynthesizeSelfReason GetModelRefSimplifiedInterfaceReason(const ModelRefBlock *block)
{
    return static_cast<RTWCG::SynthesizeSelfReason>(
        boost::lexical_cast<int>(getCompTgtFromBlock(block).getModelRefSimplifiedInterfaceReason()));
}

std::string GetSLFcnPrototype(const ModelRefBlock *block, const std::string &slFcnName,
                              bool &isFromMapping)
{
    return getCompTgtFromBlock(block).getSLFcnPrototype(slFcnName, isFromMapping);
}

int GetMdlRefNumModelRefVariants(const SLBlock* b)
{
    const size_t rv = mdlref::GetModelRefVariants(b).numVariants();
    return static_cast<int_CastToAvoid64BitWarning>(rv);
}

void SetMdlRefActiveVariantName(SLBlock* b, const std::string& varName)
{
    FL_DIAG_ASSERT(b->getBlockType() == SL_MODELREF_BLOCK);
    static_cast<ModelRefBlock*>(b)->setActiveVariantName(varName);
}

bool GetMdlRefContentPreviewEnabled(const SLBlock* b)
{
    FL_DIAG_ASSERT(b->getBlockType() == SL_MODELREF_BLOCK);
    return (b->getGrBooleanPrmValue(P_MODELREF_CONTENT_PREVIEW_ENABLED));
}

void SetMdlRefContentPreviewEnabled (SLBlock* b, bool cp)
{
    FL_DIAG_ASSERT (b->getBlockType () == SL_MODELREF_BLOCK);
    b->setGrBooleanParamValue(P_MODELREF_CONTENT_PREVIEW_ENABLED, cp);
}


void GetModelRefIsProtecteds (
        const SLBlock *b,
        const bool codeVariantsOnly,
        ModelRefStringList &protectedModels) {
    GetModelRefParameters(b, codeVariantsOnly, P_MODELREF_PROTECTED_MODEL, protectedModels);
}

void GetModelRefNames (
        const SLBlock *b,
        const bool codeVariantsOnly,
        ModelRefStringList &modelRefNames) {
    GetModelRefParameters(b, codeVariantsOnly, P_MODELREF_NAME, modelRefNames);
}

/* SetModelRefHiddenSFcnUserData  ----------------------------------------------------
 *    Set the user data pointer for the hidden s-function block
 */
void RelinkModelRefSimStructRuntimeData(SLBlock *block,
                                        void *  userData)
{
    getCompTgtFromBlock(block).relinkHiddenSFcnSimStructRuntimeData(userData);
}

// Function to help test the drawing of the Model block icon.  
// To use this function,
//    color = slInternal('getModelBlockIconColors', blockPath);
//
// The return argument is a struct with two fields.
//
// The first field is borderColor.  It can be:
//    "red-dashed"  or
//    "black"
//
// The second field is cornerColor.  It can be:
//    "red"   or
//    "gray",
//    "black",
//    "white"

slsvDiagnostic matl_get_model_block_icon_colors(int nlhs, mxArray *plhs[],
                                          int nrhs, mxArray *prhs[])
{
    if (nrhs < 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooFewInputArgs());
    } else if (nrhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyInputArgs());
    } else if (nlhs > 1) {
        return slsvCreateDiagnostic(Simulink::Commands::TooManyOutputArgs());
    }

    const mxArray* const input = prhs[0];
    if (!MatlabStringUtils::isMatlabScalarText(input)) {
        return slsvCreateDiagnostic(Simulink::Commands::ParamValueMustBeString());
    }
    
    if (nlhs == 1) {
        SLSVMWObjectBase *object = nullptr;
        slsvDiagnostic errmsg;
        ModelRefBlock  *block;
        
        errmsg = slgc::sluGetSimulinkObjectFromMxArray(prhs[0], 0, &object);
        if (errmsg != SLSV_NoDiagnostic) {
            return errmsg;
        }
        
        // Call the determine code to find the active variant - ignore errors
        block  = static_cast<ModelRefBlock *>(object);
        
        slModelBlockIcon modelIcon(block, nullptr, nullptr);

        const char *fieldNames[] = {"borderColor", "cornerColor"};
        matrix::unique_mxarray_ptr colorStruct(matrix::create_struct(1UL, 1UL, 2, fieldNames));

        std::string borderColor;
        if (modelIcon.showRedDashBorder()) {
            borderColor = "red-dashed";
        } else {
            borderColor = "black";
        }

        mxSetField(colorStruct.get(), 0UL, "borderColor", matrix::to_matlab(matrix::create(borderColor))); 
        
        slModelBlockIcon::ModelRefCornerColor cornerColorVal = modelIcon.getCornerColor();
        std::string color;
        
        switch(cornerColorVal) {
          case slModelBlockIcon::RED:
            color = "red";
            break;
            
          case slModelBlockIcon::GRAY:
            color = "gray";
            break;
            
          case slModelBlockIcon::FOREGROUND:
            color = "black";
            break;
            
          case slModelBlockIcon::BACKGROUND:
            color = "white";
            break;
        }
        
        mxSetField(colorStruct.get(), 0UL, "cornerColor", matrix::to_matlab(matrix::create(color)));

        plhs[0] = matrix::to_matlab(move(colorStruct));
    }

    return SLSV_NoDiagnostic;
}

void getModelRefServicePortInfo(
        const ModelRefBlock *block, int portIdx, bool isServiceProvider,
        std::string& accessorName, int& constructorArgIdx)
{
    return getCompTgtFromBlock(block).getModelRefServicePortInfo(
            portIdx, isServiceProvider, accessorName, constructorArgIdx);
}


/* [EOF] modelref.cpp */

// LocalWords:  sv wm Fcn's ut MWT gcmi sfun tgt UI typedefs MDLREF MDS sbm dsm
// LocalWords:  SIL mdlp Mis Mgrs Codevariant MAXNAM PARAMARG checksummed Sigs
// LocalWords:  trigport Walkthrough Dests Dlg subsys curr io modelfile Intf TP
// LocalWords:  mrpi ctor submodel submodel's glb Evaled matl prhs Intrf Deriv
// LocalWords:  gi testpoint resave testpointed evalparam gbd sp mstgt async
// LocalWords:  timeline Func Arwen msamp RTP rtp rtu deallocates dt dsm Async
// LocalWords:  checksums errmsg nullptrED Prms interfacable evaled ie sle CMDLINE
// LocalWords:  dworks frameness simblock ir jc Zc Conds simstruct btn Interf
// LocalWords:  mdlrefddg cb pnl bustype NVB sfunmodelref sgb OBJS mdlref DWork
// LocalWords:  Encap Async TMF mdlx busesv tsighierprop hd slx mdlrefgi Xcode
// LocalWords:  WS ness if's JMC SLP resaving cliu cbd isarg ungrouped
// LocalWords:  NULLED
