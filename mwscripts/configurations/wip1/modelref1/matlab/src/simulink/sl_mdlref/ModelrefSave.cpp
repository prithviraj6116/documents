/* Copyright 2013-2015 The MathWorks, Inc. */
#include "version.h"

#include "ModelrefSave.hpp"

#include "sl_lang_blocks/mdlref/ModelrefRefresh.hpp"
#include "sl_lang_blocks/mdlref/ModelRefBlock.hpp"
#include "sl_loadsave/slsFileNameUtils.hpp"
#include "sl_graphical_classes/slBlockDiagramSet.hpp"
#include "sl_graphical_classes/slBlockDiagramEditParams.hpp"
#include "sl_graphical_classes/GraphicalGraphIterator.hpp"
#include "sl_obj/blk_diag.hpp"
#include "sl_engin/comp_bd.hpp"
#include "sl_cmds/slSave.hpp"
#include "sl_blks/modelref.hpp"
#include "sl_graphical_classes/uiutils/uidialogs.hpp" 
#include "resources/Simulink/modelReference.hpp"
#include "sl_utility/SLNextElementUtil.hpp"
#include "sl_lang_blocks/ModelBlockInterface.hpp"
#include "sl_lang_blocks/ModelGraphicalInterface.hpp"
#include "sl_lang_blocks/SubsystemHelpers.hpp"
#include "sl_services/slsv_matlab_wrappers.hpp"
#include "i18n/ustring_conversions.hpp"
#include "simulink/SimulinkBlockAPI/utname_export.hpp" // BPATH
#include "simulink/slerror_export.hpp"

namespace mdlref
{
    ModelrefSave::ModelrefSave(SLRootBD * bd, slSaveOptions * opts) : 
        Refresh(bd), Bd(bd), TopRootGraph(Bd->getRootGraph()) , SaveOptions(opts)
    {
        // Do nothing
    }
    

    ModelrefSave::~ModelrefSave()
    {
        // Do nothing
    }

    /**
     * Reset the mdlrefSaveVisitedFlag to false when we begin saving a block
     * diagram
     */
    void ModelrefSave::resetAllBlockDiagramsModelRefSaveVisitedFlag(void)
    {
        SLRootBD *bd;
        /*
         * Reset mdlrefSaveVisitedFlag to false for all bd's
         */
        bd = NULL;
        while((bd = slBlockDiagramSet::getNext(bd)) != NULL) {
            sbd_mdlrefSaveVisitedFlag(bd, false);
        }

    }


    /**
     * Show the alert window for save and refresh and get the the user
     * selection.
     */
    slsvDiagnostic ModelrefSave::showModelSaveRefreshAlertWindow(const SLBlock* const blk,
                                                                           const std::string & refMdlName,
                                                                           MdlRefSaveAlertValue & selectedValue)
    {
        slsvDiagnostic errmsg = SLSV_NoDiagnostic;
        int selection;

        if(GetModelRefModalDlgTestingMode(blk) == MDLREF_QUEST_CMDLINE_SELECT0 ) {

            if (!SaveOptions->isAllowPrompt())   {  // from command line "save_system"
                if (SaveOptions->getSaveDirtyReferencedModels())  {
                    selection = MDLREF_SAVEALERT_SAVE_ALL;
                } else   {     
                    selection = MDLREF_SAVEALERT_CANCEL;    // just to suppress compile warning
                    blk->CreateDiagnosticAndThrow(    // throw out an error and save nothing
                        Simulink::modelReference::SaveSystemWithDirtyReferencedModels(blk->getFullPath()));
		}
	    } else    {		// from GUI
                selection = slModalAlert(                                          
                    Simulink::modelReference::SaveBlockAlertTitle(),
                    Simulink::modelReference::SaveBlockAlertMessage(
                        BPATH(blk), refMdlName, refMdlName, refMdlName),
                    Simulink::modelReference::SaveButton(),
                    Simulink::modelReference::SaveAllButton(),
                    Simulink::modelReference::CancelButton(),
                    1);
	    }
        } else {
            /*  We are in testing mode. Get the selection from the
             * block parameter. We do not show the modal dialog
             */
            selection = getSaveSelectionFromModelRefBlock(blk);
        }

        switch(selection) {
          case 1:
            selectedValue = MDLREF_SAVEALERT_SAVE;
            break;

          case 2:
            selectedValue = MDLREF_SAVEALERT_SAVE_ALL;
            break;

          case 3:
            selectedValue = MDLREF_SAVEALERT_CANCEL;
            break;

          default:
            selectedValue = MDLREF_SAVEALERT_CANCEL;
            FL_DIAG_ASSERT_ALWAYS("Unexpected case in switch statement");
            break;
        }

        return(errmsg);
    }


    void ModelrefSave::checkForNeedToSaveOnOneModelBlock(const SLRootBD * const bd,
                                                         SLBlock *blk,
                                                         bool& refreshIsRequired) 
    {
        FL_DIAG_ASSERT(blk->getBlockType() == SL_MODELREF_BLOCK);

        ModelRefStringList modelNamesInDialog;
        GetModelRefParameters(blk, false, P_MODELREF_NAME_DIALOG, modelNamesInDialog);
        FL_DIAG_ASSERT(!modelNamesInDialog.empty());

        ModelRefStringList::const_iterator nameIter = modelNamesInDialog.begin();

        for(const std::string& refName : modelNamesInDialog) {

            slsvString uName(ConvertStdStringToUString(refName));
            if(slsFileNameUtils::HasExtension(uName, slsFileNameUtils::FileExt::getMDLP()) ||
               slsFileNameUtils::HasExtension(uName, slsFileNameUtils::FileExt::getSLXP()))
            {
                // A protected model.  We don't need to save it.
                continue;
            }

            slsvString refBDName;
            if (uName==mdlref::GetModelRefDefaultModelName()) {
                // The user hasn't entered a name.  No model to save.
                continue;
            }
            
            try {
                refBDName = slsFileNameUtils::GetBlockDiagramName(uName);
            } catch (...) {
                // The string isn't valid as a model name.  Nothing to save.
                continue;
            }
            
            SLRootBD* const refBD = slBlockDiagramSet::nameToBlockDiagram(refBDName);
            MdlRefSaveAlertValue saveSelection = MDLREF_SAVEALERT_CANCEL;

            if(refBD != NULL && gbd_dirty(refBD)) {
                if (!slsvStrcmpi(refBD->getTag(), slsvString(USTR("SFX_IN_SLX")))) {
                    refBD->getEditParams().overridePackageDirty();
                    continue;
                }
                if(gbd_mdlrefSaveVisitedFlag(refBD)) {
                    slsvDiagnostic errmsg = slsvCreateDiagnostic(blk->getHandle(),
                        Simulink::modelReference::SavingCycleDetected(
                            bd->getDisplayName(),
                            refBDName,
                            bd->getDisplayName(),
                            BPATH(blk),
                            refBDName,
                            bd->getDisplayName()));                                
                    slsvThrowIException(errmsg);
                }
                if (SaveOptions->isSaveReferencedModels()) {
                    // The user already pressed "Save All" further up the
                    // hierarchy, or passed the "SaveDirtyReferencedModels"
                    // flag to save_system.
                    saveSelection = MDLREF_SAVEALERT_SAVE_ALL;
                } else {
                    slsvDiagnostic errmsg = showModelSaveRefreshAlertWindow(
                        blk,
                        refBDName.getString<char>(),
                        saveSelection);
                    if (errmsg != SLSV_NoDiagnostic) {
                        slsvThrowIException(errmsg);
                    }
                }
                switch(saveSelection) {
                  case MDLREF_SAVEALERT_SAVE_ALL:
                    SaveOptions->setSaveReferencedModels(true);
                    /* Fall through and save the model */
                    //lint -fallthrough

                  case MDLREF_SAVEALERT_SAVE:
                    {
                        slSaveOptions new_opts;
                        // Don't reset the "visited" flags on models, so that we can
                        // detect cycles.
                        new_opts.setResetModelRefSaveVisitedFlag(false);
                        new_opts.setSaveReferencedModels(
                            SaveOptions->isSaveReferencedModels());
                        new_opts.setRefreshModelBlocks(
                            SaveOptions->isRefreshModelBlocks());
                        new_opts.setAllowPrompt(SaveOptions->isAllowPrompt());
                        // Things would get complicated if we allowed the user to
                        // change the model name during this process (e.g. if
                        // prompted to upgrade to SLX format).
                        new_opts.setAllowInteractiveRename(false);
                        new_opts.setSuppliedName(refBD->getFileName());
                        new_opts.setResolvedFileName(refBD->getFileName());
                        slSave::Normal::saveBlockDiagram(refBD, &new_opts);
                        // The slSaveOptions instance may have been modified during
                        // the call, so take copies of the properties we're interested in.
                        SaveOptions->setSaveReferencedModels(
                            new_opts.isSaveReferencedModels());
                        SaveOptions->setRefreshModelBlocks(
                            SaveOptions->isRefreshModelBlocks());
                    }
                    break;

                  case MDLREF_SAVEALERT_CANCEL:
                    {
                        slsvThrowIException(
                            Simulink::modelReference::MdlRefSaveCanceled());
                        break; //lint !e527

                    }
                  default:
                    FL_DIAG_ASSERT_ALWAYS("Unexpected case in switch statement");
                    break;
                }
                refreshIsRequired = true;

            } 
            else if(ModelRefBlockSyncedFromDirtyModel(blk) &&
                      (!refreshIsRequired)) {
                MdlRefRefreshAlertValue refreshSelection =
                    MDLREF_REFRESHALERT_CANCEL;

                if(SaveOptions->isRefreshModelBlocks()) 
                {
                    refreshSelection = MDLREF_REFRESHALERT_REFRESH;
                } 
                else 
                {
                    /* The block was refresh with a dirty model */
                    Refresh.showRefreshBlockAlertWindow(blk, (bd)->getName().getString<char>(), refreshSelection);
                }
                switch(refreshSelection) {
                  case MDLREF_REFRESHALERT_REFRESH_ALL:
                    SaveOptions->setRefreshModelBlocks(true);
                    /* Fall through and refresh all model blocks */
                    //lint -fallthrough

                  case MDLREF_REFRESHALERT_REFRESH:
                    refreshIsRequired = true;
                    break;

                  case MDLREF_REFRESHALERT_CANCEL:
                    slsvThrowIException(
                        Simulink::modelReference::MdlRefSaveCanceled());
                    break; //lint !e527

                  default:
                    FL_DIAG_ASSERT_ALWAYS("Unexpected case in switch statement");
                    break;
                }
            }
        }   
    }


    /**
     *   Save all child models and refresh model blocks If the top model has
     *   dirty child models display a modal dialog with following options:
     *   1. 'Save' the referenced model.  2. 'Save All' referenced models
     *   3. 'Cancel'.
     *
     *    Given a referenced model graph check to see if its children are
     *    in the saving loop by checking if we have visit this model during saving.
     *    For example: Model A references B
     *                 Model B references C
     *                 Model C references A
     *      +--+        +--+         +--+
     *      |A | ---->  |B | ---->   |C |- ---->+
     *      +--+        +--+         +--+       |
     *       |                                  |
     *       |                                  |
     *       +---------------<----------------- +
     *    In this loop A and B are saved but we will error out when attempting to save C
     *
     * While saving a top model, check
     * (1) if any of the submodels are dirty, or
     * (2) if any of the Model blocks have synced from a dirty model.
     *
     * Note: During above check, we need to check/detect model reference
     * cycle. Otherwise, the save operation may go to infinite loop.
     */
    void ModelrefSave::saveModelrefBlocks(const slGraph* const graph,
                                                    bool & refreshIsRequired)
    {
        for (SLBlock* blk :
              slgg::graphicalBlocksOf(graph,
                 slgg::IterationStyle::DoNotUpdateBlock)) {
            if (blk->getBlockType() == SL_MODELREF_BLOCK) 
            {
                const SLRootBD * const bd = slGraph::GraphGetBlockDiagram(graph);
                checkForNeedToSaveOnOneModelBlock(bd, blk, refreshIsRequired);
            } 
            else if (blk->getBlockType() == SL_SUBSYSTEM_BLOCK) 
            {
                /* Recursive calls for subsystems */
                // Note, save can occur at edit or run-time. We don't need
                // to worry about the state of variant subsystems and thus
                // process all layers.
                saveModelrefBlocks(SubsystemHelpers::getSubsystemGraph(blk), refreshIsRequired);
            }
        }
    }


    /**
     * Save all the child model blocks and refresh model blocks "opts" contains
     * the options being used to save the top model.  This function can change
     * the values of its "saveReferencedModels" and "refreshModelBlocks" flags
     */
    void ModelrefSave::saveChildMdlsAndRefreshModelBlocks()
    {
        bool refreshIsRequired = false;
        sbd_mdlrefSaveVisitedFlag(Bd, true);

        /*  save the child models if needed */
        saveModelrefBlocks(TopRootGraph, refreshIsRequired);
        if(refreshIsRequired) {
            // Do not save the model if it is running
            if (gbd_model(Bd) != NULL) {
                slsvThrowIException(
                    Simulink::modelReference::MdlRefCannotSaveWhenCompiled(
                        (Bd)->getDisplayName()));
            }
            Refresh.sleRefreshBlocks();
        }
    }
}
