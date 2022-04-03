// Copyright 2012-2018 The MathWorks, Inc.

#include "version.h"

#include "ModelBlockInterfaceManager.hpp"

#include "sl_services_mi/slsv_mcos.hpp"

#include "sl_blks/modelref.hpp"
#include "sl_lang_blocks/mdlref/ModelRefBlock.hpp"
#include "sl_blks/modelref_signals.hpp"
#include "sl_lang_blocks/mdlref/slModelBlockPorts.hpp"
#include "simulink/SimulinkBlockAPI/blocksup_export.hpp"
#include "simulink/SimulinkBlockAPI/utname_export.hpp" // BPATH
#include "sl_loadsave/slsFileNameUtils.hpp"

#include "sl_lang_blocks/ModelBlockGraphicalIntrfInfo.hpp"
#include "sl_lang_blocks/ModelBlockInterface.hpp"
#include "sl_lang_blocks/ModelBlockReferencedPackageManager.hpp"

#include "sl_services/slsv_diagnostic.hpp"
#include "sl_services/slsvStringTable.hpp"

#include "sl_glue/SLGlueNotify.hpp"

#include "sl_graphical_classes/slBlockDiagramEditParams.hpp"
#include "sl_graphical_classes/SLRootBDConfigSetDebugOps.hpp"
#include "sl_graphical_classes/platform/LinkInfo.hpp"
#include "sl_graphical_classes/SLMaskInterface.hpp"
#include "sl_graphical_classes/slBlockDiagramMisc.hpp"

#include "sltopo/HierEvents.hpp"

#include "sltp/mm/core/ScheduleWith.hpp"

#include "sl_libraries/ReferenceBlock.hpp"
#include "sl_cmds/ModelMaskPartHandler.hpp"
#include "sl_graphical_classes/tipalert.hpp"
#include "sl_obj/block.hpp"
#include "sl_obj/blk_diag_engine.hpp"
#include "sl_graphical_classes/maskhelper.hpp"
#include "sl_obj/blk_diag_engine.hpp" // IsBdExecuting
#include "sl_util/slevalml.hpp"
#include "sl_util/utblock.hpp"
#include "sl_graphical_classes/SlBranding.hpp"
#include "sl_prm_engine/SlBlockEvalClient.hpp"
#include "sl_utility/ModelFileParameter.hpp"

#include "i18n/filesystem/upath.hpp"
#include "modelref_utils.hpp" // GetModelRefName

#include "mf0/Model.hpp"
#include "mf0/collections/ElementMap.hpp"
#include "slid/slid/Block.hpp"
#include "slid/slid/System.hpp" // For getParameterMutable
#include "slid/slid/Data.hpp"

SLF_UseFeature(ExportedModelPartitions, SLF_IMPORTED);
SLF_UseFeature(PartitionsWithoutSchedulingConstraints, SLF_IMPORTED);
SLF_UseFeature(ParameterTestPoint, SLF_IMPORTED);

using mdlref::ModelBlockInterfaceManager;
using mdlref::ModelBlockReferencedPackageManager;

ModelBlockInterfaceManager::ModelBlockInterfaceManager(ModelRefBlock *block,
                                                       SLRootBD *bd,
                                                       const mdlref::ModelRefEvalType evalType,
                                                       const bool isProtected,
                                                       const slsvString &refFileName)
    : fModelBlock(block),
      fBlockDiagram(bd),
      fRefModelFileName(refFileName),
      fIsProtected(isProtected),
      fEvalType(evalType),
      fForceSync(false),
      fHasVersionMismatch(false),
      fHasPortParamMismatch(false),
      fLoadStatus(mdlref::MDLREF_MODEL_LOADED_OK),
      fVersionDisplay(),
      fConfigSetVersionDiagnostic(SLRootBDAPI::getMdlRefVersionMismatchMessage(bd)),
      fConfigSetPortParamDiagnostic(SLRootBDAPI::getMdlRefIOMismatchMessage(bd)),
      fNumInports(static_cast<sizet_CastToAvoid64BitWarning>(block->getGrNumNonMdlEventDataInputPorts())),
      fNumOutports(static_cast<sizet_CastToAvoid64BitWarning>(block->getGrNumOutputPorts())),
      fIOMismatchTransaction(),
      fAdaptAsyncExportFunctions(
          slGetFeatureValue(PartitionsWithoutSchedulingConstraints) > 0)
{ }

ModelBlockInterfaceManager::~ModelBlockInterfaceManager()
{
    if (fCacheInterface) {
        // Something went wrong, so no version info is displayed
        if (fLoadStatus != mdlref::MDLREF_MODEL_LOADED_OK) {
            fVersionDisplay = std::string("Rev= ?");
        } else {

            FL_DIAG_ASSERT(fModelBlock != nullptr);
            UpdateBlockAndParentMismatchFlags(fModelBlock,
                                              fModelBlock->getBPI()->getGrIOMismatch(),
                                              fHasPortParamMismatch,
                                              DRAW_IO_DIAGNOSTICS);
            
            UpdateBlockAndParentMismatchFlags(fModelBlock,
                                              fModelBlock->getBPI()->getGrVersionMismatch(),
                                              fHasVersionMismatch,
                                              DRAW_REV_DIAGNOSTICS);
        }
        mdlref::ModelBlockGraphicalIntrfInfo& graphInfo
            = fModelBlock->getModelBlockGraphicalIntrfInfo();

        graphInfo.setVersionStringForDisplay(fVersionDisplay);
    }
    
    endIOMismatchTransactionIfActive();
}


void ModelBlockInterfaceManager::updateProtectedModelParameter() {
    fModelBlock->setGrParamValue(
                          P_MODELREF_PROTECTED_MODEL_FROM_REFRESH,
                          (fIsProtected ? "on" : "off"));
}

void ModelBlockInterfaceManager::updateExportingRatesParameter(
    const boost::shared_ptr<ModelGraphicalInterface>& mdlrefgi) {

    if (slGetFeatureValue(ExportedModelPartitions) == 0) {
        return;
    }

    FL_DIAG_ASSERT(mdlrefgi);

    mdlref::ModelBlockGraphicalIntrfInfo& graphInfo =
        fModelBlock->getModelBlockGraphicalIntrfInfo();

    // Cache if the model used to be an export function model.
    const bool wasExportFunctionModel =
        fEvalType != mdlref::MDLREF_EVAL_ON_LOAD &&
        graphInfo.getIsExportFunctionModel();

    // Update the exporting settings if needed.
    if (slGetFeatureValue(ExportedModelPartitions) > 0) {
        if (mdlrefgi->getIsExportFunctionModel()) {
            // Export function models must export their functions. This should
            // not set the dirty flag because this is coming from the reference
            // model.
            PreserveBlockDiagramDirtyFlag aPreserveDirtyBit(fBlockDiagram);
            fModelBlock->setGrBooleanParamValue(
                            P_MODELREF_SHOW_MDL_PERIODIC_EVENT_PORTS,
                            true);
        } else if (wasExportFunctionModel &&
                   !mdlrefgi->getIsExportFunctionModel() &&
                   fModelBlock->getGrEnumPrmValue(
                       P_MODELREF_SCHEDULE_RATES_WITH) ==
                       static_cast<int>(sltp::mm::core::ScheduleWith::Ports)) {
            // If we were exporting ports and we are switching to a non-export
            // function model, then the exporting parameter should be cleared.
            // This is done to emulate what would have happened before these
            // parameters existed.
            PreserveBlockDiagramDirtyFlag aPreserveDirtyBit(fBlockDiagram);
            fModelBlock->setGrBooleanParamValue(
                            P_MODELREF_SHOW_MDL_PERIODIC_EVENT_PORTS,
                            false);
        }
    }
}

// Main API to refresh a Model block against a referenced model.
void ModelBlockInterfaceManager::refreshGraphicalInterface(mdlref::ModelBlockReferencedPackageManager& aPkgMgr)
{
    mdlref::ModelBlockGraphicalIntrfInfo& graphInfo
        = fModelBlock->getModelBlockGraphicalIntrfInfo();

    updateCacheFlags();

    fLoadStatus = graphInfo.getLoadStatus();

    // If the model is loading we don't yet have all graphical info. We use the
    // saved block port states.
    if (fEvalType != mdlref::MDLREF_EVAL_ON_LOAD) {
        // Compute visible inports based on block info.
        computeNonHidableInports();
    }

    if (fCacheInterface) {
        const bool updateSignals = doTestPointedSignalsNeedUpdate();
        /*
         * Load all the interface info from the referenced model, and
         * store it in mdlrefgi
         */
        ModelGraphicalInterfaceFactory factory(fBlockDiagram->isRegionPostUpdateReferenceToCompileEnd());
        
        // If createGraphicalInterface throws, the value of
        // fLoadStatus is never set. See g1105666.
        // So, we set fLoadStatus in the catch block

        boost::shared_ptr<ModelGraphicalInterface> mdlrefgi;
        try {
        mdlrefgi = factory.createGraphicalInterface(
			aPkgMgr,
            slsvString(mdlref::GetModelRefName(fModelBlock)),
            fRefModelFileName,
            updateSignals,
            fIsProtected,
            fModelBlock,
            fEvalType,
            fLoadStatus);
        } catch(...) {
            graphInfo.setLoadStatus(fLoadStatus);
            throw;
        }

        graphInfo.setLoadStatus(fLoadStatus);

        updateProtectedModelParameter();

        if (fLoadStatus != mdlref::MDLREF_MODEL_LOADED_OK) {
            if (fLoadStatus == mdlref::MDLREF_MODEL_NOT_FOUND) {
                handleModelNotFound();
            }
            return;
        } else {
            // Check for pre-R14 models and warn
            warnAboutModelsWithNoInterfaceInfo(mdlrefgi);
        }

        updateExportingRatesParameter(mdlrefgi);

        // Compute graphical info based visible ports now that we have finalized the
        // exporting settings.
        mdlrefgi->nonHidableInports(computeNonHidableInports(*mdlrefgi));

        checkForRefreshAgainstDirtyModel(mdlrefgi);

        refreshModelBlockInterface(mdlrefgi);

        checkForModelNameDialogFileNameExtensionMismatch(mdlrefgi);
    }
    
    refreshModelBlockPorts();

    // If we found the model, reset the PREV parameters on the Model block
    // which are used to look for state changes.
    if (fLoadStatus != mdlref::MDLREF_MODEL_NOT_FOUND) {
        fModelBlock->setGrParamValue(
                        P_MODELREF_PREV_FILE,
                        GetModelRefNameDialog(fModelBlock).getString<char>());
        fModelBlock->setGrParamValue(
                        P_MODELREF_PREV_PROTECTED,
                        (fIsProtected ? "on" : "off"));
    }
}

/**
 * @brief This method iterates through masks on a block(model ref block) and
 *        finds auto generated Model Mask if present. If it finds one, it
 *        returns the pointer else returns nullptr.
 *
 * @param[in]  inModelRefBlock  Pointer to the model reference block
 *
 * @returns Pointer to the auto generated model mask if found, else returns null
 */
static SLMaskInterface* GetAutoGeneratedModelMask(SLBlock* inModelRefBlock)
{
    SLMaskInterface* mask = inModelRefBlock->getBPI()->getGrMask();
    // There could be a stack of mask (Mask on Mask). Iterate 
    // through the masks to reach the auto generated mask
    SLMaskInterface* autogen_mask = nullptr;
    while (mask) {
        if (mask->isAutoGenModelRefMask()) {
            autogen_mask = mask;
            break;
        }
        mask = mask->getChildMask(); // move to the next child mask
    }

   return autogen_mask; 
}

/**
 * @brief If a model reference block has got auto generated model mask, this method
 *        deletes it. Generally this method gets called, if someone deletes the
 *        target model's Model Mask. If the model ref block doesn't have an auto
 *        generated Model Mask, this method doesn't do anything.
 *
 * @param[in out] inoutModelRefBlock  The model reference block whose auto generated
 *                                    Model Mask will be deleted.
 */
static void DeleteAutoGeneratedModelMaskIfPresent(SLBlock* inoutModelRefBlock)
{
    // There could be a stack of mask (Mask on Mask). Get the right mask 
    SLMaskInterface* autogen_mask = GetAutoGeneratedModelMask(inoutModelRefBlock);
    if (!autogen_mask) {
        return;
    }

    // auto generated mask is found delete it and update
    SLMaskInterface* parent_mask = autogen_mask->getParentMask();
    
    // If auto generated model mask has a parent mask update the parent mask.
    if (parent_mask) {
        parent_mask->clearChildMaskReference();
    }

    delete autogen_mask;

    // If it doesn't have a parent mask, it means it is the top most mask. Since
    // it can't have a child mask, set the mask of the block to null
    if (!parent_mask) {
        inoutModelRefBlock->getBPI()->setGrMask(nullptr);
    }
}

/*
 * TopTester: matlab/test/toolbox/simulink/masking/tModelMaskAndModelRef.m
 *
 * Gets called after model mask is created on the model block. 
 * After creating the model mask we promote some of the block parameters like 'SimulationMode' on model block.
 */
static void promoteModelRefBlockParametersOnMask(SLBlock* pModelRefBlock, SLMaskInterface* pAutogeneratedModelRefMask)
{
	/* We do not support model block variant for model mask */
	if (pModelRefBlock->getGrBooleanPrmValue(P_MODELREF_VARIANT)) {
		return;
	}

    slModelMask::ScopedAutoGeneratedModelRefMaskCreation aScopedAutoGeneratedModelRefMaskCreation(pAutogeneratedModelRefMask);

	sl::mi::Handle* pMaskHdl = pAutogeneratedModelRefMask->getCOSHandle();
	mcos::COSValue aMaskObj = mcos::factory::MarshalingClarifier<sl::mi::Handle*>::toM(pMaskHdl);

	MxArrayScopedPtr aMaskObjMxArray(mcos::typedValue<mxArray*>(aMaskObj));
	matrix::unique_mxarray_ptr aTypeNameMxArray = matrix::create("Type");
    matrix::unique_mxarray_ptr aTypeValueMxArray = matrix::create("promote");
    matrix::unique_mxarray_ptr aTypeOptionNameMxArray = matrix::create("TypeOptions");
    matrix::unique_mxarray_ptr aTypeOptionValueMxArray = matrix::create_cell({ mdlref::PrmDescsData::sSIMULATIONMODE });
    matrix::unique_mxarray_ptr aPromptNameMxArray = matrix::create("Prompt");
    matrix::unique_mxarray_ptr aPromptValueMxArray = matrix::create({ "Simulink:blkprm_prompts:ModelRefSimulationMode" });
    const mxArray* pRHSArr[] = { aMaskObjMxArray.get(), aTypeNameMxArray.get(), aTypeValueMxArray.get(), aTypeOptionNameMxArray.get(), aTypeOptionValueMxArray.get(), aPromptNameMxArray.get(), aPromptValueMxArray.get() };
	mxArray* pLHSArr[] = { nullptr };
	omCallMethod("Simulink.Mask", "addParameter", COSGetPublicClient(), 1, pLHSArr, 7, pRHSArr);
	mxDestroyArray(pLHSArr[0]);

    matrix::unique_mxarray_ptr aParamNameMxArray = matrix::create(mdlref::PrmDescsData::sSIMULATIONMODE);
    const mxArray* pRHSArr2[] = { aMaskObjMxArray.get(), aParamNameMxArray.get() };
    mxArray* pLHSArr2[] = { nullptr };
    omCallMethod("Simulink.Mask", "getDialogControl", COSGetPublicClient(), 1, pLHSArr2, 2, pRHSArr2);

    matrix::unique_mxarray_ptr aPromptLocationMxArray = matrix::create("left");
    mcos::COSInterfacePtr aDialogControlObjPtr = omGetArrayElement(pLHSArr2[0], 0);
    mcos::COSPropInfoPtr aPromptLocationProperty = aDialogControlObjPtr->getProperty("PromptLocation");
    mcos::COSDataTypePtr aDataType = aPromptLocationProperty->getDataType();
    const mcos::COSTypeConversion* pTypeConversion = mcos::COSTypeRepository::getConversion("any", aDataType.getID());
    mcos::COSTypedValue aNativeValue(pTypeConversion->from(aPromptLocationMxArray.get()), aDataType);
    aPromptLocationProperty->setValue(aDialogControlObjPtr, aNativeValue.takeValue());

    mxDestroyArray(pLHSArr2[0]);
}

/*
 * TopTester: matlab/test/toolbox/simulink/masking/tModelMaskAndModelRef.m
 *
 * Create auto-generated model mask on the model block
 */
static void createModelRefBlockMask(ModelRefBlock* pModelRefBlock, SLRootBD* pRefBD)
{
    SLBlock* pModelMaskBlock = pRefBD->getModelMaskBlock();
    if (!pModelMaskBlock || !pModelMaskBlock->getBPI()->getGrMask()) {
        return;
    }

    ModelMaskTimeStamp aLatestModelMaskTimeStamp(pRefBD);

    PreserveBlockDiagramDirtyFlag aPreserveDirtyBit(pModelRefBlock->getBPI()->getGrBlockDiagram());

    SLMaskInterface* pExistingAutogeneratedModelRefMask = GetAutoGeneratedModelMask(pModelRefBlock);

    bool bSameRefModel = true; /* Assume it is the same referenced model */

    /*
    * We cache the Model Ref Auto Generated mask values in link instance data.
    * After the Auto generate the Model Ref mask again based on Ref Model Mask
    * We reapply the caches values.
    */
    if (bSameRefModel) {
        LinkInfo* pLinkInfo = pModelRefBlock->getBPI()->getLinkInfo(true);  // create if necessary
        if (pExistingAutogeneratedModelRefMask) {
            for (int i = 0, iNumParams = pExistingAutogeneratedModelRefMask->getMaskNumParams(); i < iNumParams; ++i) {
                pLinkInfo->setInstanceDataParam(
                    ModelFileParameter::makeQuotedParameter(
                        pExistingAutogeneratedModelRefMask->getParamName(i),
                        slsvString(pExistingAutogeneratedModelRefMask->getParamUValue(i))));
            }
        }
        else {
            fl::ustring aModelArgNames = pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES, false);
            fl::ustring aModelArgValues = pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_VALUES, false);

            if (aModelArgNames != aModelArgValues) {
                vector_strings aModelArgNameStrings;
                delimited_string_to_vector(aModelArgNameStrings, ConvertUStringToStdString(aModelArgNames), ',');

                vector_ustrings aModelArgValueStrings;
                delimited_ustring_to_vector(aModelArgValueStrings, aModelArgValues, ',');

                if (aModelArgNameStrings.size() == aModelArgValueStrings.size()) {
                    auto isDefaultValue = [](const fl::ustring& aValue) {
                        return aValue.empty() || aValue == USTR("[]");
                    };

                    for (size_t i = 0, iNumParams = aModelArgNameStrings.size(); i < iNumParams; ++i) {
                        /* At the time of creating mask on the model block if the value of the parameter on the model block is still the default value we skip setting the instance data below so that it starts out with the value on the model mask */
                        if (!isDefaultValue(aModelArgValueStrings[i])) {
                            pLinkInfo->setInstanceDataParam(
                                ModelFileParameter::makeQuotedParameter(
                                    aModelArgNameStrings[i],
                                    slsvString(aModelArgValueStrings[i])));
                        }
                    }
                }
            }
        }
    }

    DeleteAutoGeneratedModelMaskIfPresent(pModelRefBlock);

    SLMaskInterface* pParentMask = pModelRefBlock->getBPI()->getGrMask();
    pModelRefBlock->getBPI()->setGrMask(nullptr);

    pExistingAutogeneratedModelRefMask = SlGrClasses::smCopyMask(pModelMaskBlock, pModelRefBlock);
    pExistingAutogeneratedModelRefMask->setAutoGenModelRefMask(true);

	promoteModelRefBlockParametersOnMask(pModelRefBlock, pExistingAutogeneratedModelRefMask);

    if (pParentMask) {
        SLMaskInterface* pInnerMostParent = pParentMask;
        while (pInnerMostParent->getChildMask()) {
            pInnerMostParent = pInnerMostParent->getChildMask();
        }

        pInnerMostParent->setChildMask(pExistingAutogeneratedModelRefMask);
        pModelRefBlock->getBPI()->setGrMask(pParentMask);
    }

    pModelRefBlock->updateParamArguments(pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES,false),
                                         pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES,false));
    pModelRefBlock->setReferenceModelFileMTime(aLatestModelMaskTimeStamp);

    /*
    * Model Ref mask regenerated based on Ref Model Mask.
    * Apply the cached mask values.
    */
    if (bSameRefModel && pExistingAutogeneratedModelRefMask) {
        bool bIgnoreIsLinkEval = false;
        CloneDialogValuesFromRefBlockHelper aCloneDialogValues(pModelRefBlock, pModelRefBlock);
        aCloneDialogValues.clone(bIgnoreIsLinkEval);
    }

    LinkInfo* pLinkInfo = pModelRefBlock->getBPI()->getLinkInfo();
    if (pLinkInfo) {
        pLinkInfo->freeGrInstanceData();
    }
}

/*
 * TopTester: matlab/test/toolbox/simulink/masking/tModelMaskAndModelRef.m
 * 
 * Create auto-generated model mask on the model block
 */
static void createModelRefBlockMask(ModelRefBlock* pModelRefBlock, const slModelMask::ModelMaskPartReader& modelMaskReader) 
{
    const ModelMaskTimeStamp& aCachedModelMaskTimeStamp = pModelRefBlock->getReferenceModelFileMTime();
    ModelMaskTimeStamp aLatestModelMaskTimeStamp(modelMaskReader.getFileName());

    /*
     * The Ref Model name has not changed and the Ref Model has not changed.
     * So no need to create/change mask on the Model Ref block
     * When the ModelRef block is being evaluated, do not update its mask. 
     */
    if (aCachedModelMaskTimeStamp == aLatestModelMaskTimeStamp) {
        return;
    }
    
    PreserveBlockDiagramDirtyFlag aPreserveDirtyBit(pModelRefBlock->getBPI()->getGrBlockDiagram());

    SLMaskInterface* pExistingAutogeneratedModelRefMask = GetAutoGeneratedModelMask(pModelRefBlock);

    bool bSameRefModel = ((!pExistingAutogeneratedModelRefMask) || (pExistingAutogeneratedModelRefMask && aCachedModelMaskTimeStamp != ModelMaskTimeStamp())) ? true : false;

    /* 
     * We cache the Model Ref Auto Generated mask values in link instance data.
     * After the Auto generate the Model Ref mask again based on Ref Model Mask
     * We reapply the caches values.
     */
    if (bSameRefModel) {
        LinkInfo* pLinkInfo = pModelRefBlock->getBPI()->getLinkInfo(true); // create if necessary
        if (pExistingAutogeneratedModelRefMask) {
            for (int i = 0, iNumParams = pExistingAutogeneratedModelRefMask->getMaskNumParams(); i < iNumParams; ++i) {
                pLinkInfo->setInstanceDataParam(
                    ModelFileParameter::makeQuotedParameter(
                        pExistingAutogeneratedModelRefMask->getParamName(i),
                        slsvString(pExistingAutogeneratedModelRefMask->getParamUValue(i))));
            }
        }
        else {
            fl::ustring aModelArgNames = pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES, false);
            fl::ustring aModelArgValues = pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_VALUES, false);

            if (aModelArgNames != aModelArgValues) {
                vector_strings aModelArgNameStrings;
                delimited_string_to_vector(aModelArgNameStrings, ConvertUStringToStdString(aModelArgNames), ',');

                vector_ustrings aModelArgValueStrings;
                delimited_ustring_to_vector(aModelArgValueStrings, aModelArgValues, ',');

                if (aModelArgNameStrings.size() == aModelArgValueStrings.size()) {
                    auto isDefaultValue = [](const fl::ustring& aValue) {
                        return aValue.empty() || aValue == USTR("[]");
                    };

                    for (size_t i = 0, iNumParams = aModelArgNameStrings.size(); i < iNumParams; ++i) {
                        /* At the time of creating mask on the model block if
                         * the value of the parameter on the model block is
                         * still the default value we skip setting the instance
                         * data below so that it starts out with the value on
                         * the model mask */
                        if (!isDefaultValue(aModelArgValueStrings[i])) {
                            pLinkInfo->setInstanceDataParam(
                                ModelFileParameter::makeQuotedParameter(
                                    aModelArgNameStrings[i],
                                    slsvString(aModelArgValueStrings[i])));
                        }
                    }
                }
            }
        }
    }

    DeleteAutoGeneratedModelMaskIfPresent(pModelRefBlock);

    SLMaskInterface* pParentMask = pModelRefBlock->getBPI()->getGrMask();
    pModelRefBlock->getBPI()->setGrMask(nullptr);

    modelMaskReader.loadAutogeneratedModelMask(pModelRefBlock);
    pExistingAutogeneratedModelRefMask = GetAutoGeneratedModelMask(pModelRefBlock);

	promoteModelRefBlockParametersOnMask(pModelRefBlock, pExistingAutogeneratedModelRefMask);

    if (pParentMask) {
        SLMaskInterface* pInnerMostParent = pParentMask;
        while (pInnerMostParent->getChildMask()) {
            pInnerMostParent = pInnerMostParent->getChildMask();
        }

        pInnerMostParent->setChildMask(pExistingAutogeneratedModelRefMask);
        pModelRefBlock->getBPI()->setGrMask(pParentMask);
    }

    pModelRefBlock->updateParamArguments(pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES,false),
                                         pModelRefBlock->getGrParamUValue(P_MODELREF_PARAMARG_NAMES,false));
    pModelRefBlock->setReferenceModelFileMTime(aLatestModelMaskTimeStamp);

    /*
     * Model Ref mask regenerated based on Ref Model Mask.
     * Apply the cached mask values.
     */
    if (bSameRefModel && pExistingAutogeneratedModelRefMask) {
        bool bIgnoreIsLinkEval = false;
        CloneDialogValuesFromRefBlockHelper aCloneDialogValues(pModelRefBlock, pModelRefBlock);
        aCloneDialogValues.clone(bIgnoreIsLinkEval);
    }

    LinkInfo* pLinkInfo = pModelRefBlock->getBPI()->getLinkInfo();
    if (pLinkInfo) {
        pLinkInfo->freeGrInstanceData();
    }
}

static void refreshModelMaskInterfaceFromReferencedBlockDiagram(ModelRefBlock* pModelRefBlock, SLRootBD* pRefBD)
{
    /* Do not add auto generated model mask for hidden synthesized model blocks */
    if (pModelRefBlock->getGrSynthesizedBlock()) {
        return;
    }

    SLBlock* pModelMaskBlock = pRefBD->getModelMaskBlock();
    if (!pModelMaskBlock || !pModelMaskBlock->getBPI()->getGrMask()) {
        DeleteAutoGeneratedModelMaskIfPresent(pModelRefBlock);
        return;
    }

    // So there is a Model Mask part. Check if we have a user defined mask
    // on the model reference block. If yes show a notification and return
    SLMaskInterface* pMask = pModelRefBlock->getBPI()->getGrMask();
    if (pMask && !pMask->isAutoGenModelRefMask() && !pMask->isMaskOnLinkBlock()) {
        /* So an user defined mask exists. Show the notification */
        slBlockDiagram* pBD = pModelRefBlock->getBPI()->getGrBlockDiagram();
        slShowUpgradeAlert(pBD, slsvString(USTR("modelmask_problem")), Simulink::modelReference::UpgradeToModelMask());
        return;
    }

    /* We have come so far, means we have to create a Model Mask or refresh the existing one */
    createModelRefBlockMask(pModelRefBlock, pRefBD);
}

static void refreshModelMaskInterfaceFromReferencedPackage(ModelRefBlock* pModelRefBlock, const mdlref::ModelBlockReferencedPackageManager& aPkgMgr, bool bIsProtected)
{
    /* Do not add auto generated model mask for hidden synthesized model blocks */
    if (pModelRefBlock->getGrSynthesizedBlock()) {
        return;
    }

    slModelMask::ModelMaskPartReader aModelMaskPartReader(aPkgMgr.getPackageReader(), bIsProtected);

    if (!aModelMaskPartReader.hasModelMaskPart()) {
        /* 
         * Note that user can explicitly refresh the model block without saving the sub-model and can have the auto-generated mask on the model block. 
         * In that case we do not want to delete the auto-generated mask on model block.
         */
        if (!aPkgMgr.getReferencedBD() || !aPkgMgr.getReferencedBD()->getModelMaskBlock() || !aPkgMgr.getReferencedBD()->getModelMaskBlock()->getBPI()->getGrMask()) {
            DeleteAutoGeneratedModelMaskIfPresent(pModelRefBlock);
        }
        return;
    }

    // So there is a Model Mask part. Check if we have a user defined mask
    // on the model reference block. If yes show a notification and return
    SLMaskInterface* pMask = pModelRefBlock->getBPI()->getGrMask();
    if (pMask && !pMask->isAutoGenModelRefMask() && !pMask->isMaskOnLinkBlock()) {
        /* So an user defined mask exists. Show the notification */
        slBlockDiagram* pBD = pModelRefBlock->getBPI()->getGrBlockDiagram();
        slShowUpgradeAlert(pBD, slsvString(USTR("modelmask_problem")), Simulink::modelReference::UpgradeToModelMask());
        return;
    }

    /* We have come so far, means we have to create a Model Mask or refresh the existing one */
    createModelRefBlockMask(pModelRefBlock, aModelMaskPartReader);
}

/**
 * @brief This method generates the Model Mask for a model reference block, if it
 *        finds the Model Mask part in the referenced model file. However if it
 *        finds the model reference block holding on to a user defined mask, it
 *        won't create a Model Mask, and instead flash a notification advising the
 *        user to upgrade to Model Mask.
 *
 * @param[in]  inModelRefBlock       Model reference block on which we are going to 
 *                                   create the Model Mask
 *
 * @param[in]  inReferenceModelName  Name of the referenced model  
 *
 * @param[in]  bIsProtectedModel     Are we dealing with a protected model
 *
 */
void ModelBlockInterfaceManager::refreshModelMaskInterface(const mdlref::ModelBlockReferencedPackageManager& aPkgMgr, const mdlref::ModelRefEvalType aEvalType)
{
    /* Is it a refresh triggered from right click 'Refresh Selected Model Block' menu item */
    if (aEvalType == MDLREF_EVAL_REFRESH_THIS_BLK && aPkgMgr.getReferencedBD()) {
        refreshModelMaskInterfaceFromReferencedBlockDiagram(fModelBlock, aPkgMgr.getReferencedBD());
    }
    else {
        refreshModelMaskInterfaceFromReferencedPackage(fModelBlock, aPkgMgr, fIsProtected);
    }
}

// Helper functions for refreshGraphicalInterface
void ModelBlockInterfaceManager::refreshModelBlockInterface(
    const boost::shared_ptr<mdlref::ModelGraphicalInterface> mdlrefgi)
{
    mdlref::ModelBlockGraphicalIntrfInfo& graphInfo
        = fModelBlock->getModelBlockGraphicalIntrfInfo();

    // We can only refresh the interface if we first cached the interface
    FL_DIAG_ASSERT(fCacheInterface);
    
    // First check for any IO/Version mismatch, this method may throw.
    // Library blocks never need to call this, they don't participate
    // in the mismatch diagnostic and can't set the dirty flag.
    if (!isModelBlockLibraryLink()) {
        checkForInterfaceMismatch(mdlrefgi);    
    }
    
    if (fForceSync) {
        DestroyAllAvailSigsVectors(fModelBlock);
    }

    // Based on the mismatch diagnostics, refresh all or part
    // of the Model block to the referenced model
    graphInfo.refreshUncheckedInterface(mdlrefgi,
                                        (fBlockDiagram)->isRegionPostUpdateReferenceToCompileEnd(),
                                        fEvalType);

    if (syncCheckedInterface()) {
        beginIOMismatchTransaction();
        
        graphInfo.refreshCheckedInterface(mdlrefgi, fEvalType);
    }
    
    // Initialize the display string, now that everything loaded.
    fVersionDisplay = std::string("Rev = ") + 
        std::string(fModelBlock->getModelVersion());

    fNumInports = graphInfo.numVisibleInports();
    fNumOutports = mdlrefgi->getNOutports();

    fModelBlock->clearMismatchTested();
}

// The fooIOMismatchTransaction() functions are part of the fix for
// g1087946. Previously, the transaction object was destroyed before the
// I/O mismatch bit in the BPI is cleared in ~ModelBlockInterfaceManager().
void ModelBlockInterfaceManager::beginIOMismatchTransaction()
{
    FL_DIAG_ASSERT(!hasIOMismatchTransaction());
    
    try 
    {
        // This will force the Model block to update the number
        // of ports in the diagram if they were changed.
        fIOMismatchTransaction.reset(new SLGlue::Transaction(fModelBlock->getBPI()->getGrOwner()));
    }
    catch(std::bad_alloc&)
    {
        slsvThrowOutOfMemoryException();
    }

    // Just in case we ever switch to a noexcept new.   
    if (!hasIOMismatchTransaction())
    {
        slsvThrowOutOfMemoryException();
    }
}

bool ModelBlockInterfaceManager::hasIOMismatchTransaction() const
{
    return NULL != fIOMismatchTransaction.get();
}

void ModelBlockInterfaceManager::endIOMismatchTransactionIfActive()
{
    // This function does nothing if (!hasIOMismatchTransaction()).
    //
    // Technically, this function isn't even needed, but its presence
    // at the end of the destructor allows us to break just prior to its
    // destruction, and documents the endpoint of the transaction.
    fIOMismatchTransaction.reset(NULL);
}

void ModelBlockInterfaceManager::refreshModelBlockPorts()
{
    boost::unique_ptr<slModelBlockPorts> theSlModelBlockPorts(
        slModelBlockPorts::createPortInformation(fModelBlock));
    
    fModelBlock->setSlModelBlockPorts(move(theSlModelBlockPorts));
    
    if (!fModelBlock->hasSlModelBlockPorts()) {
        slsvThrowOutOfMemoryException();
    }

    // We need to redraw the Model block only if there was a refresh
    // of the checked interface, since the number of ports is checked
    // by the mismatch diagnostics.
    if (hasIOMismatchTransaction() || 
        fModelBlock->hasMdlEventInputPortCountMismatch()) {
        // We have already properly set the dirty flag if needed:
        // don't allow changing the number of ports to reset the flag.
        PreserveBlockDiagramDirtyFlag dirtyRestore(fBlockDiagram);

        slModelBlockPorts& modelBlockPorts = fModelBlock->getSlModelBlockPorts();
        ModelEventPortInfo newMdlEventPortInfo = fModelBlock->computeModelEventPortInfo();

        // The event ports sometimes disappear due to the model changing to a
        // non-export model. In such cases, we show a notification explaining
        // the reason.
        fModelBlock->notifyUserAboutEventPortsIfNeeded(newMdlEventPortInfo);
        
        slsvDiagnostic errmsg
            = modelBlockPorts.updateModelBlockPorts(
                fNumInports + newMdlEventPortInfo.getNumEventPorts(),
                fNumOutports);
        
        slsvThrowIException(errmsg);
    }
}


void ModelBlockInterfaceManager::checkForInterfaceMismatch(
    const boost::shared_ptr<mdlref::ModelGraphicalInterface> mdlrefgi)
{
    // Info on Model block ports, used by the mismatch check
    mdlref::ModelBlockPortInfo portInfo;

    fModelBlock->createPortInfo(portInfo);
    // Info that is not stored in the ModelBlockGraphicalIntrfInfo
    const char* paramNames =
        ggb_param_value(fModelBlock, P_MODELREF_PARAMARG_NAMES);
    slsvString paramNamesStr = (paramNames == NULL ? slsvString() : slsvString(slsvToUString(paramNames)));
    
    const char* blkVersion = fModelBlock->getModelVersion();
    const slsvString blkVersionStr(blkVersion == NULL
                                   ? slsvString()
                                   : slsvString(slsvToUString(blkVersion)));
    BDErrorValue ioDiag =
        getActualMismatchDiagnostic(fConfigSetPortParamDiagnostic);
    BDErrorValue verDiag =
        getActualMismatchDiagnostic(fConfigSetVersionDiagnostic);
    mdlref::ModelBlockGraphicalIntrfInfo& graphInfo =
        fModelBlock->getModelBlockGraphicalIntrfInfo();

    const ModelEventPortInfo& modelEventPortInfo =
        dynamic_cast<ModelRefBlock*>(fModelBlock)->getModelEventPortInfo();
    const size_t numInportsIRT(modelEventPortInfo.getNumEventPorts());

    const bool showResetPorts = fModelBlock->showMdlResetPorts();
    const size_t numResetPorts = static_cast<size_t>(modelEventPortInfo.getNumResetPorts());

    std::vector<slsvString> resetPortNames(numResetPorts);
    if (numResetPorts>0)
    {
        const int firstResetPortIdx = modelEventPortInfo.getFirstResetPortIdx();
        FL_DIAG_ASSERT(firstResetPortIdx>=0);
        for (size_t idx = 0; idx < numResetPorts; ++idx)
        {
            resetPortNames[idx] = modelEventPortInfo.getEventPorts()[idx+static_cast<size_t>(firstResetPortIdx)]->getPortLabel();
        }
    }

    mdlref::ModelBlockInterfaceMismatch mismatchObj(
        fModelBlock,
        mdlref::GetModelRefName(fModelBlock),
        paramNamesStr,
        blkVersionStr,
        portInfo,
        numInportsIRT,
        showResetPorts,
        resetPortNames,
        ioDiag,
        (fConfigSetPortParamDiagnostic == BD_ERR_VALUE_ERROR),
        verDiag,
        (fConfigSetVersionDiagnostic == BD_ERR_VALUE_ERROR),
        mdlrefgi,
        &graphInfo);

    // Throws an error (if any), and whether there was a reported
    // mismatch in either diagnostic.  We need this because we may have
    // reported a warning, and this class updates the Model block icon
    // in the destructor.
    mismatchObj.checkForMismatchAndReportDiagnostic(
        fBlockDiagram->getDisplayName(),
        fHasVersionMismatch,
        fHasPortParamMismatch);

    setBlockDiagramDirtyFlagIfNeeded(mismatchObj);
}


sllang::Selection ModelBlockInterfaceManager::computeNonHidableInports(
    sllang::Selection const& fcnCallOutputs) {

    bool isArchitectureSubdomain = IsBlockInArchitectureSubdomain(fModelBlock);

    // If the user did not request that partitions be exported, all ports are
    // visible.
    if (!isArchitectureSubdomain && (!fModelBlock->exportMdlPartitions() ||
        fModelBlock->hiddenFcnCallTransformState() ==
            ModelRefBlock::HiddenFcnCallTransformState::Active)) {
        return sllang::Selection(fcnCallOutputs.size(), true);
    }

    // Otherwise, all function call ports are hidable
    sllang::Selection visibleInports;
    for (auto const& v : fcnCallOutputs) {
        if (v) {
            visibleInports.push_back(false);
        } else {
            visibleInports.push_back(true);
        }
    }
    FL_DIAG_ASSERT(fcnCallOutputs.size() == visibleInports.size());
    return visibleInports;
}
void  ModelBlockInterfaceManager::computeNonHidableInports() {
    mdlref::ModelBlockGraphicalIntrfInfo& blkgi =
        fModelBlock->getModelBlockGraphicalIntrfInfo();
    blkgi.nonHidableInports(
        computeNonHidableInports(blkgi.inportsWithFcnCallOutput()));
}

sllang::Selection ModelBlockInterfaceManager::computeNonHidableInports(
    mdlref::ModelGraphicalInterface& mdlrefgi) {
    bool isArchitectureSubdomain = IsBlockInArchitectureSubdomain(fModelBlock);

    if (fModelBlock->exportMdlPartitions() || isArchitectureSubdomain) {
        return computeNonHidableInports(mdlrefgi.inportsWithFcnCallOutput());
    } else {
        // Not hiding ports, just return them all.
        return sllang::Selection(mdlrefgi.inportSampleTimes().size(), true);
    }
}

bool ModelBlockInterfaceManager::isModelBlockLibraryLink() const {
    return fModelBlock->getRootBPI()->getGrIsBlockLinked(fModelBlock) || BlockIsImplicitLink(fModelBlock);
}


void ModelBlockInterfaceManager::setBlockDiagramDirtyFlagIfNeeded(
    const mdlref::ModelBlockInterfaceMismatch &mismatchObj)
{
    // We only need to set the dirty flag on a bd in the following case:
    // 1. The user is doing a force-refresh on a Model block (i.e. right-click
    // on the Model block and choose refresh.
    //   AND
    // 2. The block is not in a library link.
    if ((fEvalType != mdlref::MDLREF_EVAL_REFRESH_THIS_BLK) ||
        isModelBlockLibraryLink()) {
        return;
    }

    if (mismatchObj.interfaceHasChanged()) {
        sbd_dirtyNotUpdatingBlockMTimesThrows(fBlockDiagram, true);
        sgb_LibraryBlockMTime(fModelBlock);
    }
}


BDErrorValue ModelBlockInterfaceManager::getActualMismatchDiagnostic(
    BDErrorValue dialogDiagnosticValue) const
{
    BDErrorValue retVal = dialogDiagnosticValue;
    
    // These are the cases where we want to override the user settings for either
    // Version or Port & Parameter mismatch diagnostic.  The forceSync flag happens
    // when the Model block is changed to point to a different model name.
    if (forceCacheAndRefresh() || isModelBlockLibraryLink()) {

        retVal = BD_ERR_VALUE_NONE;

    } else {
        bool okToReportMisErr = (fBlockDiagram)->isRegionPostUpdateReferenceToCompileEnd() ||
            (fEvalType == mdlref::MDLREF_EVAL_REFRESH_ALL_BLKS) ||
            (fEvalType == mdlref::MDLREF_EVAL_SYNC_BEFORE_TARGET_UPDATE);

        if(!okToReportMisErr && dialogDiagnosticValue == BD_ERR_VALUE_ERROR) {
            retVal = BD_ERR_VALUE_WARNING;
        }
    }

    return retVal;
}


void ModelBlockInterfaceManager::checkForRefreshAgainstDirtyModel(
    const boost::shared_ptr<mdlref::ModelGraphicalInterface> mdlrefgi) const
{
    /* 
     * Do not allow the Model block to be synced from a dirty Model,
     * when refreshing one block via right click, and version and IO
     * diagnostics are set to warning or none.
     */
    if (fEvalType == mdlref::MDLREF_EVAL_REFRESH_THIS_BLK &&
        mdlrefgi->isDirty() &&
        isModelReportingAnyMismatchDiagnostic()) {
            slsvThrowIException(
                Simulink::modelReference::CannotRefreshFromDirtyMdlDiagOn(
                    BPATH(fModelBlock),
                    mdlref::GetModelRefName(fModelBlock),
                    fBlockDiagram->getDisplayName(), 
                    mdlref::GetModelRefName(fModelBlock)));
    }
}

// Currently, we call refresh on all Model blocks early in the compile phase, so
// for efficiency reasons we skip refresh during the later call to evalParams on
// the Model block.
bool ModelBlockInterfaceManager::skipRefreshDuringCompile() const {
    return (fEvalType == mdlref::MDLREF_EVAL_REGULAR) && (fBlockDiagram)->isRegionPostUpdateReferenceToCompileEnd();
}

bool ModelBlockInterfaceManager::syncCheckedInterface() const
{
    FL_DIAG_ASSERT(forceCacheAndRefresh() || !skipRefreshDuringCompile());
    
    bool syncInterface = true;
    
    // If we aren't forcing, then check if there were any mismatches
    // and the user has asked us to lock down the interface.
    if (!forceCacheAndRefresh()) {
        const bool hasPortParamError
            = (fConfigSetPortParamDiagnostic == BD_ERR_VALUE_ERROR) && fHasPortParamMismatch;

        const bool hasVersionError
            = (fConfigSetVersionDiagnostic == BD_ERR_VALUE_ERROR) && fHasVersionMismatch;

        // No Errors ===> sync the interface
        syncInterface = !hasPortParamError && !hasVersionError;
    }
    
    return syncInterface;
}


void ModelBlockInterfaceManager::updateCacheFlags()
{    
    checkForNameChange();

    if (forceCacheAndRefresh()) {
        fCacheInterface = true;
    } else if (skipRefreshDuringCompile()) {
        fCacheInterface = false;
    } else {
        fCacheInterface = true;
    }
}

void ModelBlockInterfaceManager::checkForNameChange()
{
    // If there is a "state change" in which model this Model block 
    // is referencing, then we will remove any cached information
    // and sync with the new model the block is pointing to.
    const char  *prvMdl          = ggb_param_value(fModelBlock, P_MODELREF_PREV_FILE);
    const char  *prvProtectedVal = ggb_param_value(fModelBlock, P_MODELREF_PREV_PROTECTED);
    const bool  prvProtected     = (strcmp(prvProtectedVal, "on") == 0);

    const bool emptyString = (utStrcmp(prvMdl, "") == 0);
    const bool dialogChange = (utStrcmp(prvMdl, GetModelRefNameDialog(fModelBlock).getString<char>()) != 0);
    const bool protectModel = (prvProtected != fIsProtected);

    if (emptyString || dialogChange || protectModel) {
        fForceSync = true;
        
        // Reset the normal mode model name on name/protected 
        // changes only when the block diagram is not executing
        // and not compiling
        //
        FL_DIAG_ASSERT(!IsBdExecuting(fBlockDiagram));
        
        if (!IsBdBeingCompiled(fBlockDiagram)) {
            SetModelRefNormalModeModelName(fModelBlock,USTR(""));
            // clear out the default values
            fModelBlock->setGrParamValue(P_MODELREF_USING_DEFAULT_VALUE, USTR(""));
            // We should clear parameter argument values when the referenced model is set to
            // empty or model name is changed in the dialog, at the same time, if we are
            // protecting the model, we should not clear the parameter argument value.
            if((emptyString || dialogChange) && (!protectModel))
            {
                if(!fModelBlock->getRootBPI()->getGrIsBlockLinked(fModelBlock))
                {
                    fModelBlock->clearArguments();

                    // Remove the dictionary parameters corresponding to old model.
                    const int paramTestPointFeatLvl = slGetFeatureValue(ParameterTestPoint);
                    if (paramTestPointFeatLvl >= 3)
                    {
                        if (fModelBlock->getDictBlock())
                        {
                            slid::Block dictBlk = mf::zero::static_mf0_cast<slid::Block>(fModelBlock->getDictBlock());

                            dictBlk->getParameterMutable().destroyAllContents();
                        }
                    }
                }
            }
        }
    }
}


bool ModelBlockInterfaceManager::doTestPointedSignalsNeedUpdate() const
{
    bool updateSignals = false;
    
    /*
     * Only update the test-pointed signals when a signal logging refresh
     * eval param was issued or we are compiling the model and default data
     * logging is specified on the model reference block.  If we are
     * compiling the model and this function is called multiple times
     * (for example, with different evalTypes) we must update the logged
     * signals during each call.  This is a bit wasteful, but we have no
     * way of knowing whether multiple calls are really part of the same
     * compilation or different compilations.  Therefore, we must err on
     * the side of caution and update the logged signals for each call.
     */
    if (fBlockDiagram->isRegionCompDataInitToEndOfCompile()) {
        updateSignals = get_default_data_logging(fModelBlock);
    } else if (refreshSignalLoggingInfo()) {
        updateSignals = true;
    }
    
    return updateSignals;
}

void ModelBlockInterfaceManager::handleModelNotFound()
{
    // We should have errored for models in compile mode
    FL_DIAG_ASSERT(!(fBlockDiagram)->isRegionPostUpdateReferenceToCompileEnd() &&
             !IsBdContainingBlockExecuting(fModelBlock));

    fHasVersionMismatch = false;
    fHasPortParamMismatch  = false;
    const char *prvMdl = ggb_param_value(fModelBlock, P_MODELREF_PREV_FILE);
    
    /*
     * Also, if the model was not found and user has entered a new model
     * name, clear out the previous model name parameter, so that when we do
     * find this model, we will load in all the interface information
     * without checking for mismatches.
     */
    if (utStrcmp(prvMdl, GetModelRefNameDialog(fModelBlock).getString<char>()) != 0) {
        fModelBlock->setGrParamValue( P_MODELREF_PREV_FILE, "");
    }
}

void ModelBlockInterfaceManager::checkForModelNameDialogFileNameExtensionMismatch(
    const boost::shared_ptr<mdlref::ModelGraphicalInterface>& mdlrefgi) const
{
    const slsvString modelNameDialog = GetModelRefNameDialog(fModelBlock);
    const fl::filesystem::upath path1(modelNameDialog.str());
    const fl::ustring extension1 = path1.extension();
    
    if(! extension1.empty() && extension1.compare(slsvString(USTR("sfx"))) != 0) {
        const slsvString modelFileName   = mdlrefgi->getModelFileName();
        const fl::filesystem::upath path2(modelFileName.str());
        const fl::ustring extension2 = path2.extension();
        

        if(extension1.compare(extension2) != 0 &&
           (mdlref::isProtectedModelAllowed() ||
            (!slsFileNameUtils::HasExtension(modelNameDialog, slsFileNameUtils::FileExt::getMDLP()) &&
             !slsFileNameUtils::HasExtension(modelNameDialog, slsFileNameUtils::FileExt::getSLXP()))))
        {
            slsvReportAsWarning(Simulink::modelReference::ModelFileExtensionMismatch( 
                      BPATH(fModelBlock), 
                      modelNameDialog,
                      modelFileName,
                      BPATH(fModelBlock),
                      path2.filename()));
        }
    }
}

void ModelBlockInterfaceManager::warnAboutModelsWithNoInterfaceInfo(
    const boost::shared_ptr<mdlref::ModelGraphicalInterface> mdlrefgi) const
{
    mdlref::ModelBlockGraphicalIntrfInfo& graphInfo
        = fModelBlock->getModelBlockGraphicalIntrfInfo();

    // Check for pre-R14 models that do not have a GraphicalInterface
    if (!mdlrefgi->mdlHasGraphicalInterface() && !mdlrefgi->getRefMdlInMemOnly()) {
        if (slsvStrcmpi(mdlref::GetModelRefName(fModelBlock).c_str(),
                        graphInfo.getOldVerWarnReportedMdl().c_str()) != 0) {
            const fl::ustring mdlName = mdlref::GetModelRefName(fModelBlock);

            slsvReportAsWarning(Simulink::modelReference::WarnSaveInterfaceInfoInMdlFile(
                      BPATH(fModelBlock), mdlName, mdlName, mdlName));

            // Cache away the name of the referenced model so we only report
            // this warning once.
            graphInfo.setOldVerWarnReportedMdl(mdlref::GetModelRefName(fModelBlock));
        }
    } else {
        graphInfo.setOldVerWarnReportedMdl(USTR(""));
    }
}


// LocalWords:  mdlrefgi PREV Intrf Xcode BPI inout modelmask noexcept BPATH
// LocalWords:  nullptr blkprm hidable
