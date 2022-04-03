// Copyright 2008-2018 The MathWorks, Inc.

#include "version.h"
#include <array>
#include "simulink/SLGlueAccess.hpp"
#include "simulink/sl_glue/SLGlueAccessBlock.hpp"
#include "simulink/sl_glue/SLGlueAccessGraph.hpp"
#include "simulink/sl_glue/SLGlueAccessPort.hpp"
#include "simulink/SLGlueServiceTypes.hpp"

#include "m_interpreter.h"

#include "SimulinkBlock/SLFontOverrides.hpp"
#include "sl_utility/SLColorCache.hpp"
#include "sl_libraries/BreakLinksHelper.hpp"
#include "dastudio/da_udd/DAEventDispatcher.hpp"
#include "glee_util/err/ErrorHolder.hpp"
#include <boost/optional.hpp>
#include "simharness/SlHarnessManager.hpp"
#include "simharness/SlHarnessCopyManager.hpp"
#include "simharness/SlHarnessUpdater.hpp"
#include "sl_engin/TransformedGraph.hpp"
#include "sl_glue/SLGluePortPlacement.hpp"
#include "sl_libraries/ReferenceBlock.hpp"
#include "sl_obj/blk_diag.hpp"
#include "sl_obj/graph.hpp"
#include "sl_obj/block.hpp"
#include "sl_obj/blockprm.hpp"
#include "sl_obj/LinkInfo.hpp"
#include "sl_obj/blockmth.hpp"
#include "sl_obj/portmeth.hpp"
#include "sl_obj/port.hpp"
#include "sl_obj/callbackmth.hpp"
#include "sl_obj/stateflow.hpp"
#include "sl_obj/SIDServiceSL.hpp"
#include "sl_lang_blocks/ControlPortMgr.hpp"
#include "sl_obj/udd_sl_obj.hpp"
#include "sl_obj/blk_diag_sample_time.hpp"
#include "sl_graphical_classes/maskhelper.hpp"
#include "sl_graphical_classes/platform/BlockTransform.hpp"
#include "sl_graphical_classes/SLContext.hpp"
#include "sl_graphical_classes/SLObjectAPI.hpp"
#include "sl_graphical_classes/platform/SLRootBlockPlatformInfo.hpp" //BlockIsParameterized, FindNearestQuasiLinkedParent
#include "sl_util/utbkdiag.hpp"
#include "sl_util/utgraph.hpp"
#include "sl_util/utblock.hpp"
#include "sl_graphical_classes/util/uthilite.hpp"
#include "sl_blks/modelref.hpp"
#include "sl_lang_blocks/subsys/InportBlock.hpp"
#include "sl_lang_blocks/subsys/OutportBlock.hpp"
#include "sl_lang_blocks/state_rw/StateAccessorMgr.hpp"
#include "sl_lang_blocks/param_rw/ParamAccessorMgr.hpp"
#include "sl_lang_blocks/partitioning/naming_utilities.hpp"
#include "sl_lang_blocks/PortInterfaceModifier.hpp"
#include "sl_lang_blocks/SlConnportBlk.hpp"
#include "sl_lang_blocks/SLLangBlocksUtil.hpp"
#include "sl_blks/configsub.hpp"
#include "sl_lang_blocks/ControlPortBlock.hpp"
#include "SimulinkBlock/Registry/slBlockRegistry.hpp"
#include "sl_blks/display.hpp"
#include "sl_blks/clockblk.hpp"
#include "sl_blks/ioprm.hpp"
#include "sl_bde/tooltip.hpp"
#include "sl_glee/SLDialog.hpp"
#include "slexec/slstor/slRootGraphTsTable.hpp"
#include "sl_cmds/addblock.hpp"
#include "sl_compile/variants/VCEUtils.hpp"
#include "sl_fcncall/SlFcnCallUtil.hpp"
#include "simulink/SimulinkBlockAPI/blocksup_export.hpp"
#include "simulink/SimulinkBlockAPI/parminfo_export.hpp"
#include "sl_graphical_classes/SLMaskInterface.hpp"
#include "sl_graphical_classes/slBlockDiagramUtilAPI.hpp"
#include "sl_graphical_classes/slBlockDiagramSet.hpp"
#include "sl_graphical_classes/slBlockDiagramEditParams.hpp"
#include "sl_graphical_classes/slBlockDiagramLoadSave.hpp"
#include "sl_graphical_classes/slBlockDiagramLoadOptions.hpp"
#include "sl_graphical_classes/GraphicalGraphIterator.hpp"
#include "sl_graphical_classes/CommonBlockFilters.hpp"
#include "simulink/SLGlueMenus.hpp"
#include "sl_lang_blocks/Domain/DomainBlockBase.hpp"
#include "sl_lang_blocks/SubsystemReferenceHelper.hpp"

#include "sl_glue/SLGlueUtils.hpp"
#include "sl_glue/SLGlueNotify.hpp"
#include "sl_util/utlibrary.hpp"
#include "sl_glue/RenderAdapterInterface.hpp"

#include "sl_util/s_color.hpp" 
#include "sl_mdlref/slModelBlockIcon.hpp" 
#include "sl_mdlref/slModelRefUtils.hpp"
#include "sl_lang_blocks/mdlref/ModelRefBlock.hpp"

#include "sl_lang_blocks/SubsystemBlock.hpp"
#include "sl_lang_blocks/TriggerPortBlock.hpp"
#include "sl_lang_blocks/ModelBlockInterface.hpp"
#include "sl_obj/slobjprm.hpp"
#include "sl_compile/MLSysBlockMgr.hpp"
#include "sl_deployment_diagram/DrawingUtilities.hpp"
#include "sl_compile/sl_deployment_diagram/SlDeploymentDiagramClient.hpp"

#include "sl_obj/graphdm.hpp"

#include "sl_obj/blockprm.hpp" 
#include "sl_sfcn/SFunction.hpp"
#include "services.h"
#include "SimulinkBlock/SLFlexiblePortPlacementController.hpp"
#include "SimulinkBlock/SLRootBlock.hpp"
#include "SimulinkBlock/SignalCGPropsPrmDesc.hpp"
#include "SimulinkBlock/BlockAccessStateInterface.hpp"
#include "SimulinkBlock/StateAttribPropInterface.hpp"
#include "sl_graphical_classes/domains/SlDomainPortType.hpp"
#include "sl_graphical_classes/glue/LineTracer.hpp"
#include "sltp/core/Graph.hpp"
#include "sltp/core/Task.hpp"
#include "sl_blks/SLImplicitIterSSUtil.hpp"
#include "sl_utility/BlockPathUtil.hpp"
#include "sl_graphical_classes/RegPlugins.hpp"

#include "sl_glee/SLBlockPropertyModel.hpp"
#include "simulink/sl_ip_protection/LibraryProtection.hpp"
#include "dastudio/utils/UDDUtils.hpp"

#include "diagram_resolver/resolve.hpp"
#include "simulink/ResolverTypes.hpp"
#include "sl_glee/SLDialogData.hpp"
#include "sl_lang_blocks/NumberedPortBlock.hpp"
#include "sl_lang_blocks/GraphUtil.hpp" // MakeBlockNameUnique
#include "mm_interface/features.hpp"
#include "sl_graphical_classes/slGraph.hpp"

#include "simulink/sl_glue/CommentedOutStyler.hpp"
#include "sl_obj/segment.hpp"
#include "sl_block_graphics/data/SLBlockGraphicalDescriptor.hpp"
#include "connector_placement/ConnectorPlacement/GraphicalContext.hpp"
#include "sl_services/slsv_matlab_wrappers_advanced.hpp" //slsvFEVAL_NoThrow
#include "sl_services/slsv_uostringstream.hpp"

#include <boost/algorithm/string.hpp>
#include <boost/range/adaptors.hpp>
#include "sl_blks/BusSelector.hpp"
#include "sl_blks/BusAssignment.hpp"
#include "sl_blks/mux.hpp"
#include "gui/g_obj/colorptr.hpp"
#include "resources/sl_glue/badges.hpp"

#include "simulink/SLBlockDialogUtil.hpp"

#include "sl_loadsave/slsFileNameUtils.hpp"
#include "sl_utility/SLBlockPath.hpp"
#include "sl_graphical_classes/BlockUtilities.hpp"

#include "sl_lang_blocks/hierConnProp/connRouterBlock.hpp"
#include "sl_lang_blocks/hierConnProp/ConnBrancherBlock.hpp"
#include "sl_lang_blocks/IOViewerUtils.hpp" // RemoveAllIOConnections

#include "glee_util/bones/ImageCompositor/ImageCompositorBuildHelpers.hpp" // GLEE::ImageCompositor::Builders
#include "glee_util/bones/ImageCompositor/ImageCompositorManager.hpp" // GLEE::ImageCompositor::Manager
#include "glee_util/bones/CastUtil.hpp"

#include "slio/core/utils/SignalDescriptor.hpp"
#include "slio/core/client/Client.hpp"
#include "sl_sim/SimulationInterfaceManager.hpp"

#include "sl_etrace/SLETrace.hpp"

#undef HIDDEN_POINTER  // Remove after fixing g943677

SLF_UseFeature(NewDES, SLF_IMPORTED);
SLF_UseFeature (SLContentPreview, SLF_IN_MODULE);
SLF_UseFeature(PHYSMOD_BUSES, SLF_IMPORTED);
SLF_UseFeature(AccessingMultipleStatesBlocks, SLF_IMPORTED);

// =======================================================================
// Blocks
// =======================================================================

bool IsBlockExecEventAffordanceShow(const SLBlock *block);

namespace SLGlue
{

SIMULINK_EXPORT_FCN
bool hasLegacyFrame(const SLBlock *block)
{
    return isMaskIconFrameVisible(block);
}

SIMULINK_EXPORT_FCN
BlockPortRotationType getBlockRotationType( const SLBlock *block )
{
    switch( GetBlockPortRotationType(block) )
    {
        case PORT_ROTATE_DEFAULT:   return BLOCK_PORT_ROTATION_DEFAULT;
        case PORT_ROTATE_PHYSICAL:  return BLOCK_PORT_ROTATION_PHYSICAL;
    }

    FL_DIAG_ASSERT_ALWAYS( "unreachable" );
    return BLOCK_PORT_ROTATION_DEFAULT;
}

SIMULINK_EXPORT_FCN
SLBlockOrientationType getOrientationFromRotationAndMirror( double rotation, bool mirror )
{
    return static_cast<SLBlockOrientationType>(SLRootBlock::rotation_mirror_to_orientation( rotation, mirror ));
}

SIMULINK_EXPORT_FCN
bool getBlockMirror( const SLBlock *block )
{
    FL_DIAG_ASSERT(block != nullptr);
    return block->getBPI()->getGrBlockTransform()->getMirror();
}

SIMULINK_EXPORT_FCN 
void setBlockMirror( SLBlock *block, bool mirror )
{
    FL_DIAG_ASSERT( block != nullptr );

    if( getBlockMirror( block ) == mirror )
        return;

    // Port orientation can depend on block orientation,
    // which can also affect the segments.  Mark them
    // as changing so they get back up before we change
    // them.
    int numPorts = getBlockNumPorts( block );
    
    for( int i=0; i<numPorts; i++ )
    {
        slPort *port = getBlockNthPort( block, i );
        
        SLGlue::notifyThatPortIsAboutToChange( port );
        
        slSegment *segment = port->getSegment();
        
        if( segment != nullptr )
            SLGlue::notifyThatSegmentIsAboutToChange( segment );
    }

    // Note, we don't alter name placement or block location
    
    if (block->getBPI()->getGrBlockTransform()->IsDefaultTransform()) {
        block->getBPI()->setGrBlockTransform(new BlockTransform());
    }

    block->getBPI()->getGrBlockTransform()->setMirror( mirror );
    block->getBPI()->getGrBlockTransform()->setRotation( getBlockRotation(block) );

    SLMaskInterface *mask = block->getBPI()->getGrMask();
    if( mask != nullptr )
        mask->setIconRotationPending();

    // This shouldn't be necessary, but we
    // fail to properly update block glyphs on
    // undo without it.
    BlockInvalidate( block );
}

SIMULINK_EXPORT_FCN 
double getBlockRotation( const SLBlock *block )
{
    return block->getBPI()->getGrBlockTransform()->getRotation();
}

SIMULINK_EXPORT_FCN
void setBlockRotation( SLBlock *block, double rotation )
{
    FL_DIAG_ASSERT( block != nullptr );
    FL_DIAG_ASSERT( rotation >= 0.0 && rotation < 360.0 );
    FL_DIAG_ASSERT( rotation == 0.0 
              || rotation == 90.0
              || rotation == 180.0
              || rotation == 270.0 );

    double oldRotation = getBlockRotation(block);
    if(oldRotation  == rotation )
        return;

    // Port orientation can depend on block orientation,
    // which can also affect the segments.  Mark them
    // as changing so they get back up before we change
    // them.
    int numPorts = getBlockNumPorts( block );
    
    for( int i=0; i<numPorts; i++ )
    {
        slPort *port = getBlockNthPort( block, i );
        
        SLGlue::notifyThatPortIsAboutToChange( port );
        
        slSegment *segment = port->getSegment();
        
        if( segment != nullptr )
            SLGlue::notifyThatSegmentIsAboutToChange( segment );
    }

    // Note, we don't alter name placement or block location
    
    if (block->getBPI()->getGrBlockTransform()->IsDefaultTransform()) {
        block->getBPI()->setGrBlockTransform(new BlockTransform());
    }

    block->getBPI()->getGrBlockTransform()->setMirror( getBlockMirror(block) );
    block->getBPI()->getGrBlockTransform()->setRotation( rotation );

    SLMaskInterface *mask = block->getBPI()->getGrMask();
    if( mask != nullptr )
        mask->setIconRotationPending();


    // Notify Simulink Plugin listeners that the orientation has changed
    // This handles when the orientation changes via the UI. 
    // If the orientation changes via set_param, we will handle the event notification 
    // via ***sgb_orientation***
    ParamChangeEventListener(block, getPrmDescFromBlockParams("Orientation"), oldRotation);

    // This shouldn't be necessary, but we
    // fail to properly update block glyphs on
    // undo without it.
    BlockInvalidate( block );
}

SIMULINK_EXPORT_FCN
bool getBlockIsInitTermResetSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->GetIsAnInitTermOrResetSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsInitializeSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsInitializeSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsMessageTriggeredSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsBroadcastFunction()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsRunFirstOrRunLastSubsystem(const SLBlock *block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *> (block)->IsRunFirstOrRunLastSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsRunFirstSubsystem(const SLBlock *block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *> (block)->IsRunFirstSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsRunLastSubsystem(const SLBlock *block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *> (block)->IsRunLastSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsTerminateSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsTerminateSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsCustomResetSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsCustomResetSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsCustomResetWithInitSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsCustomResetWithInitializeSubsystem()));
}

SIMULINK_EXPORT_FCN
bool getBlockIsResetSubsystem(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->IsCustomResetSubsystem() ||
             static_cast<const SubsystemBlock *>(block)->IsCustomResetWithInitializeSubsystem()));
}

SIMULINK_EXPORT_FCN bool getBlockIsSubsystemReference(const SLBlock* pBlock)
{
    return slsr::util::isSubsystemReference(pBlock);
}

SIMULINK_EXPORT_FCN
bool getBlockIsSimulinkFunction(const SLBlock * block)
{
    return ((block->getBlockType() == SL_SUBSYSTEM_BLOCK) &&
            (static_cast<const SubsystemBlock *>(block)->GetIsSimulinkFunctionBlock()));
}

SIMULINK_EXPORT_FCN 
bool  getBlockCanCallOrDefineSimulinkFunctions(const SLBlock *block)
{
    return (block->getCanCallSimulinkFunctions() ||
            block->getCanDefineSimulinkFunctions());
}

SIMULINK_EXPORT_FCN 
bool getBlockCanContainWirelessConnection(const SLBlock *block) {
    return (block->getCanContainWirelessDependency());
}

SIMULINK_EXPORT_FCN
bool getBlockNamePlacement(const SLBlock * block)
{
    FL_DIAG_ASSERT(block != nullptr);
    return block->getBPI()->getGrFlipName();
}

SIMULINK_EXPORT_FCN
void setBlockNamePlacement(SLBlock * block, bool flipped)
{
    sgb_alt_name_placement(block, flipped, false);
}

SIMULINK_EXPORT_FCN
slsvDiagnostic serviceSLBlockOpen(SLBlock *block, BlockOpenType openType)
{   
    SLGlue::ScopedSlimBlockDialogRefreshBlocker scopedSlimDialogRefreshBlocker(block);
    BlockOpenRec b;
    b.setBlockOpenType(openType);
    b.setInteractiveOpen(true);
    return BlockOpen(block, &b);
}


// Similar to MATLAB API: blockHandle = add_block('simulink/Sinks/Scope', [mdlName '/myScope'], 'MakeNameUnique', 'on', 'position', [140 80 220 180])
SIMULINK_EXPORT_FCN SLBlock* createLibraryBlock(const fl::ustring &pathToLibBlock, 
                                                slGraph* ownerGraph,
                                                const fl::ustring& newBlockName,
                                                const GLEE::DRect& rect)
{
    SLBlock* newBlockPtr = nullptr;
    FL_DIAG_ASSERT(!pathToLibBlock.empty());
    FL_DIAG_ASSERT(!newBlockName.empty());

    // record if library is already loaded
    std::size_t pos = pathToLibBlock.find(USTR("/"));
    fl::ustring lib = pathToLibBlock.substr(0, pos);
    SLRootBD *bd = slBlockDiagramSet::nameToBlockDiagram(slsvString(lib));
    bool isLibOpen = (bd != nullptr);
    const fl::ustring pathToNewBlock = ownerGraph->getFullPath() + fl::ustring(USTR("/")) + newBlockName;

    MxArrayScopedRefPtr result;
    matrix::unique_mxarray_ptr rhs0( matrix::create(pathToLibBlock) );
    matrix::unique_mxarray_ptr rhs1( matrix::create(pathToNewBlock) );
    matrix::unique_mxarray_ptr rhs2( matrix::create("MakeNameUnique") );
    matrix::unique_mxarray_ptr rhs3( matrix::create("on") );

    mxArray *rhs[] = {rhs0.get(), rhs1.get(), rhs2.get(), rhs3.get()};

    matl_add_block(1, &result, 4, rhs);

    double *pr = mxGetPr(result.get());
    if( pr != nullptr )
    {
        newBlockPtr = (SLBlock::Handle2Block(*pr));

        MWrect rectByCorners{static_cast<int>(rect.top()), static_cast<int>(rect.left()), static_cast<int>(rect.bottom()), static_cast<int>(rect.right())};
        BlockSetLocation(newBlockPtr, &rectByCorners, true);
    }

    fl::ustring builtIn = USTR("built-in");
    if(!isLibOpen && lib != builtIn) { // close lib bd
        slsvDiagnostic errmsg = slsvFEVAL_NoThrow("close_system", InArguments(lib));
        FL_DIAG_ASSERT(errmsg == SLSV_NoDiagnostic);
        UNUSED_PARAMETER(errmsg);
    }

    FL_DIAG_ASSERT(newBlockPtr != nullptr); // Caller should check ahead of time if editor is locked or some other business logic would block creation
    return newBlockPtr;
}


// Similar to MATLAB API: blockHandle = add_block('built-in/Subsystem', [mdlName '/mySubby'], 'MakeNameUnique', 'on', 'position', [140 80 220 180])
SIMULINK_EXPORT_FCN SLBlock* createBuiltInBlock(const fl::ustring &builtinBlockName, slGraph* ownerGraph, const fl::ustring& newBlockName, const GLEE::DRect& rect)
{
    FL_DIAG_ASSERT(!builtinBlockName.empty());
    const fl::ustring pathToLibBlock = fl::ustring(USTR("built-in/")) + builtinBlockName;
    return createLibraryBlock(pathToLibBlock, ownerGraph, newBlockName, rect);
}
SIMULINK_EXPORT_FCN 
void blockClose( SLBlock *block )
{
    BlockCloseChildren(block);

    // Interactively deleting the block. Close all parameter dialogs and 
    // clean up the source (g1849175)
    // And this need to be done after block children are closed. Masking code causes dialog refresh during dialog close, the reason is not clear.
    // If that happens, then we could be looking at a destroyed source.
    BlockCloseAllParamDialogs(block);
}

SIMULINK_EXPORT_FCN
void deleteBlock( SLBlock *block )
{
    FL_DIAG_ASSERT( getBlockGraph(block) == nullptr );
    FL_DIAG_ASSERT( getBlockNumInputPorts(block) == 0 );
    FL_DIAG_ASSERT( getBlockNumOutputPorts(block) == 0 );
    FL_DIAG_ASSERT( getBlockNumLeftConnPorts(block) == 0 );
    FL_DIAG_ASSERT( getBlockNumRightConnPorts(block) == 0 );

#ifdef HIDDEN_POINTER
    // g655374: restore "deleted" handle
    bool success = rebind_handle(block->getHandle(), static_cast<SLMWObjectBase*>(block));
    FL_DIAG_ASSERT( success );
#endif
    
    if( block->getBlockType() == SL_SUBSYSTEM_BLOCK )
    {
        slGraph *subsystemGraph = static_cast<SubsystemBlock*>(block)->get_subsystem_graph();

        if( subsystemGraph != nullptr )
        {
            SLGlue::SLClearUndoRedoStacks::call( subsystemGraph );
            {
                SLGlue::Transaction transaction( subsystemGraph );
                SLGlue::notifyThatGraphIsAboutToBeDeleted( subsystemGraph );
            }
            FL_DIAG_ASSERT( !SLGlue::hasGraphData( subsystemGraph ) );
        }
    }

    slsvDiagnostic errorQueue = BlockDestroyCallback(block, false);
    if( errorQueue != SLSV_NoDiagnostic )
        slsvReportAsWarning(errorQueue);
    
    diagram::notifyObjectIsAboutToBeDestroyed(diagram::resolver::resolve(block->getHandle(), diagram::Object::ELEMENT, "simulink"));

    BlockDestroy( block );
}

SIMULINK_EXPORT_FCN
void removeBlockIOConnections( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg =  RemoveAllIOConnections(block);
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );

}

SIMULINK_EXPORT_FCN
void pseudoDelete( SLBlock *block, slGraph *graph )
{  
    FL_DIAG_ASSERT( graph != nullptr );
    FL_DIAG_ASSERT( block != nullptr );
    FL_DIAG_ASSERT( !block->getBPI()->getGrIsOnUndoStack() );

    block->getBPI()->setGrIsOnUndoStack( true );
    
#ifdef HIDDEN_POINTER
    // g655374: hide "deleted" handle from the rest of MATLAB
    bool success = rebind_handle(block->getHandle(), HIDDEN_POINTER);
    FL_DIAG_ASSERT( success );
#endif

    if(!SLGlue::LineTracer::instance()->isBdInActiveHighlightMode((slGraph::GraphGetBlockDiagram(graph))->getHandle()))
        return;

    if( block->getBlockType() == SL_SUBSYSTEM_BLOCK )
    {
        std::vector<SLBlock*> queue;

        queue.push_back( block );
        size_t i=0;
        while( i < queue.size())
        {
            SLBlock *current = queue[i++];

            slGraph *subsystemGraph = static_cast<SubsystemBlock*>(current)->get_subsystem_graph();
            SLGlue::LineTracer::instance()->remove(subsystemGraph);

            for (SLBlock* b :
                  slgg::graphicalBlocksOf(subsystemGraph,
                     slgg::IterationStyle::DoNotUpdateBlock) |
                  boost::adaptors::filtered(slgg::onlySubsystemBlock)) {
               FL_DIAG_ASSERT( b->getBlockType() == SL_SUBSYSTEM_BLOCK );
               queue.push_back( b );
            }
        }
    }
}

SIMULINK_EXPORT_FCN
void setBlockEditTimestamp ( SLBlock *block)
{  
    FL_DIAG_ASSERT( block != nullptr );    
    sgb_LibraryBlockMTime (block);
}

SIMULINK_EXPORT_FCN
void pseudoUnDelete( SLBlock *block )
{
    FL_DIAG_ASSERT( block != nullptr );
    // Can happen if we cancel a transaction in the middle of create subsystem
    //FL_DIAG_ASSERT( block->getBPI()->getGrIsOnUndoStack() );

#ifdef HIDDEN_POINTER
    // g655374: restore "deleted" handle
    bool success = rebind_handle(block->getHandle(), static_cast<SLMWObjectBase*>(block));
    FL_DIAG_ASSERT( success );
#endif
    
    block->getBPI()->setGrIsOnUndoStack( false );
    
    sl::simharness::SlHarnessCopyManager::getInstance()->notifyUnDoDeleteBlock(block);
}

SIMULINK_EXPORT_FCN
std::string getBlockSID( SLBlock *block )
{
    return SIDServiceSL::getSIDFullString(block);
}

SIMULINK_EXPORT_FCN
    std::string getBlockCompactSID( SLBlock *block )
{
    return SIDServiceSL::getCompactSID(static_cast<const SLSVMWObjectBase*>(block));
}

SIMULINK_EXPORT_FCN
slGraph *getBlockGraph( const SLBlock *block )
{
    return( block->getBPI()->getGrOwner() );
}

SIMULINK_EXPORT_FCN
SLBlock * getParentSFChart (const SLBlock * block)
{
    SLBlock* parentSFChart = nullptr;
    if (BlockIsChildOfStateflowChart (block))
        parentSFChart = BlockGetParentStateflowChart (block);

    return parentSFChart;
}

SIMULINK_EXPORT_FCN 
slGraph *getSubsystemGraph(const SLBlock *block )
{
    FL_DIAG_ASSERT(isSubsystem(block));
    return static_cast<const SubsystemBlock*>(block)->get_subsystem_graph();
}

SIMULINK_EXPORT_FCN
void setBlockGraph( SLBlock *block, const slGraph *graph )
{
    slGraph *oldGraph = block->getBPI()->getGrOwner();

    if( oldGraph != nullptr )
    {
        // slGraph::getCurrentBlockHandle will do some checks in debug build,
        // and will assert on the very thing we're trying to correct.
        // It assumes the current block will be cleared before it's removed
        // from the graph, but we can't ensure that with M3I.
        // So use oldGraph->getCurrentBlockHandleDirectly().
        SLBlock *gcb = (SLBlock::Handle2Block(oldGraph->getCurrentBlockHandleDirectly()));

        if( block == gcb )
            setNextCurrentBlock( block );
    }
        
    // Fix up old graph properties.
    if( block->getBPI()->getGrSelected() && oldGraph != nullptr )
    {
        block->getBPI()->getGrOwner()->incrNumBlocksSelected(-1);
    }
     
    // g696018: Notify root sample time table in case 
    // this block is the owner of any sample times    
    
    SLRootBD *bd = block->getBPI()->getGrBlockDiagram();
    
    if (bd != nullptr) {
        const slRootGraphTsTable * rootTsTable = nullptr;
        if (bd->getBDSubPhase() >= BD_CPHASE_ALLOC_CBD) {
            FL_DIAG_ASSERT(block->getBPI()->getCompBD());
            rootTsTable = block->getBPI()->getCompBD()->getRootTsTable();
        }
        else {
            rootTsTable = compPersistData(bd)->getRootTsTableCache();
        }
                
        if (rootTsTable != nullptr) {
            (const_cast<slRootGraphTsTable*>(rootTsTable))->removeBlock(block);
        }
    }

    ScopedBlockDiagramDirtier dirtinessAnnouncer(block);    

    // SIDServiceSL::notifySetContainer() won't let you transfer
    // the block from one graph to another, so we need to set it to
    // null, then the correct graph.
    // This can occur when canceling a transaction in the middle
    // of create subsystem
    if( oldGraph != nullptr && graph != nullptr )
    {
        (block->getBPI()->setGrOwner(block,nullptr));
        SIDServiceSL::notifySetContainer(block, oldGraph);
    }
    
    (block->getBPI()->setGrOwner(block,const_cast<slGraph*>(graph)));

    // notify SIDService to manage SID upon cut-and-paste and undo
    if( oldGraph != nullptr && graph != nullptr )
        SIDServiceSL::notifySetContainer(block, nullptr);
    else
        SIDServiceSL::notifySetContainer(block, oldGraph);

    if( block->getBPI()->getGrSelected() && graph != nullptr )
    {
        const_cast<slGraph*>(graph)->incrNumBlocksSelected(1);
    }
}

SIMULINK_EXPORT_FCN 
bool blockHasValidOpenCallback(const SLBlock* block)
{
    return !ggb_OpenCallback(block).empty();
}

SIMULINK_EXPORT_FCN 
SLBlock* getSubsystemProxyParent(const SLBlock* block, bool recursive)
{
    return static_cast<const SubsystemBlock*>(block)->getProxyParent(const_cast<SLBlock*>(block), recursive);
}

SIMULINK_EXPORT_FCN
SLBlock* getSubsystemProxyChild(const SLBlock* block)
{
    return static_cast<const SubsystemBlock*>(block)->getProxyChild(const_cast<SLBlock*>(block));
}

SIMULINK_EXPORT_FCN 
SLBlock* getTopmostLinkedOrConfiguredParent(SLBlock *block)
{
    return FindTopmostLinkedOrConfiguredParent(block);
}

SIMULINK_EXPORT_FCN SLBlock* getParentBlock(SLBlock* block)
{
    slGraph *graph = SLGlue::getBlockGraph(block);
    return(((graph == nullptr) || SLGlue::isARootGraph(graph)) ? nullptr : SLGlue::getGraphOwner(graph));
}

SIMULINK_EXPORT_FCN 
SLBlock* findNearestMaskedParent(SLBlock* block)
{
    while ((block != nullptr) && !isMasked(block)) 
    {
        block = getParentBlock(block);
    }
    return block;
}

SIMULINK_EXPORT_FCN 
SLBlock* findNearestLinkedParent(SLBlock* block)
{
    while ((block != nullptr) && !isLinked(block)) 
    {
        block = getParentBlock(block);
    }
    return block;
}


// With the given orientation, mirror, and rotateType data returns how much the mask image should rotate in radians.
// Either clockWise or counter-clockwise depending on parameter.
SIMULINK_EXPORT_FCN
double determineMaskImageRotationAmount(SLBlockOrientationType orientation, bool blockIsMirrored, SLMaskRotateTypes rotateType, bool clockWise)
{
    if (rotateType == ROTATE_NONE) {
        return 0.0;
    }

    switch(orientation)
    {
    case SLBlockOrientationRight:
        if (rotateType == ROTATE_PURE && blockIsMirrored) {
            return GLEE::PI;
        }
        break;

    case SLBlockOrientationLeft:
        if (rotateType == ROTATE_PURE && !blockIsMirrored) {
            return GLEE::PI;
        }
        break;

    case SLBlockOrientationDown:
        if (rotateType == ROTATE_PURE && !blockIsMirrored) {
            if (clockWise) {
                return GLEE::kHalfPId;
            }
            else {
                return GLEE::kThreeHalvesPId;
            }
        }
        else {
            if (clockWise) {
                return GLEE::kThreeHalvesPId;
            }
            else {
                return GLEE::kHalfPId;
            }
        }

    case SLBlockOrientationUp:
        if (rotateType == ROTATE_PURE && blockIsMirrored) {
            if (clockWise) {
                return GLEE::kHalfPId;
            }
            else {
                return GLEE::kThreeHalvesPId;
            }
        }
        else {
            if (clockWise) {
                return GLEE::kThreeHalvesPId;
            }
            else {
                return GLEE::kHalfPId;
            }
        }
    }

    return 0.0;
}

// With the given orientation, mirror, and rotateType data returns if the mask image should mirror or not.
SIMULINK_EXPORT_FCN
bool determineMaskImagePortRotationShouldMirror(SLBlockOrientationType orientation, SLMaskRotateTypes rotateType)
{
    return (rotateType == ROTATE_PORT && (orientation == SLBlockOrientationDown || orientation == SLBlockOrientationLeft));
}

SIMULINK_EXPORT_FCN
bool determineMaskImageShouldClip(const MG::DPoint& xywhSize, const MG::DPoint& areaSize, MG::DPoint& clipAmount)
{
    double areaWidth = areaSize.x();
    double areaHeight = areaSize.y();
    double xywhWidth = xywhSize.x();
    double xywhHeight = xywhSize.y();

    double imageClipAmountX = 0.0;
    double imageClipAmountY = 0.0;

    if (xywhWidth <= 0.0 || xywhHeight <= 0.0) {
        return false;
    }

    if (xywhWidth > areaWidth) {
        imageClipAmountX = std::min(1.0, std::max(0.0, (xywhWidth - areaWidth) / xywhWidth));
    }

    if (xywhHeight > areaHeight) {
        imageClipAmountY = std::min(1.0, std::max(0.0, (xywhHeight - areaHeight) / xywhHeight));
    }

    clipAmount.setXY(imageClipAmountX, imageClipAmountY);
    return (xywhWidth > areaWidth) || (xywhHeight > areaHeight);
}

SIMULINK_EXPORT_FCN 
bool isEmpty(const slGraph *graph)
{
    return sluIsEmptyGraph(graph);
}

SIMULINK_EXPORT_FCN 
bool isGraphInConfigurableSubsystem( const slGraph *graph )
{
    return IsGraphInConfigurableSubsystem( graph );
}

SIMULINK_EXPORT_FCN 
bool queryLockedSystem( const slGraph *graph, bool *lockedLib, bool *linked, bool *writeProtected )
{
    bool isLocked         = false;   
    bool isInLink         = false;
    bool isWriteProtected = false;
    const SLRootBD *bd      = slGraph::GraphGetBlockDiagram(graph);
    if (bd != nullptr) {
        if (gbd_lock(bd) && !slsr::util::isSubsystemReference(graph->getOwner())) {
            /*
             * If the block diagram is locked, then all graphs
             * associated with it must be locked, so return true.
             */
            isLocked = true;
            if (lockedLib != nullptr) *lockedLib = isLocked;
        }
        else {
            /*
             * We may have a case where the graph belongs to
             * a linked subsystem or to a child of a linked
             * subsystem. Find that out and return locked.
             * The graph may also belong to a write protected
             * subsystem. In this case too, return locked.
             */
            isLocked = IsGraphInLockedSubsystem(graph, &isInLink, &isWriteProtected) || IsGraphInConfigurableSubsystem(graph);
			if (linked != nullptr) *linked = isInLink;             
			if (writeProtected != nullptr) *writeProtected = isWriteProtected;
        }
    }

    return isLocked;
}

SIMULINK_EXPORT_FCN 
bool queryLockedSystemAlert( const slGraph *graph )
{
    return QueryLockedSystemAlert( graph );
}

SIMULINK_EXPORT_FCN 
void disableLibraryLink( const slGraph *graph )
{
    SLRootBD *bd = slGraph::GraphGetBlockDiagram(graph);
    SLBlock *parentBlock = SLRootBlockPlatformInfo::FindNearestLinkedParent(slGraph::GraphGetOwner(graph));
    if (parentBlock != nullptr && !BlockIsLockedLinkOrInsideLockedLink( parentBlock ) ) 
    {
        BreakLibraryLinkIncludingParentHierarchy(parentBlock, true);

        FileChangedOnDiskAlert(bd);
        // If this block has a library version, then since it is being modified, dirty the version
        UpdateLibraryVersion(slGraph::GraphGetOwner(graph));

        if( SLGlue::SLHierarchyResetChangeNotifyService::hasConnection() )
        {
            // Notify that the link status has changed, refresh model browser
            SLGlue::SLHierarchyResetChangeNotifyService::call(false);
        }
    }

}

SIMULINK_EXPORT_FCN
void gotoLibraryLinkedBlock(const slGraph *graph)
{
    SLRootBD *bd = slGraph::GraphGetBlockDiagram(graph);
    SLBlock *parentBlock = SLRootBlockPlatformInfo::FindNearestLinkedParent(slGraph::GraphGetOwner(graph));
    if (parentBlock != nullptr && !BlockIsLockedLinkOrInsideLockedLink(parentBlock)) {
        slsvDiagnostic pErrMsg = GotoLibraryLinkOfBlock(parentBlock);
        if (SLSV_NoDiagnostic != pErrMsg) {
            slsvThrowIException(pErrMsg);
        }

        fl::ustring modelName = parentBlock->getRootBPI()->getReferenceBlock(parentBlock);
        slsvString modelPath = slu::BlockPathUtil::getModelFromPath(modelName.c_str());

        bd = slBlockDiagramSet::nameToBlockDiagram(modelPath);
        if (gbd_lock(bd))
        {
            (void)bd->setLock(SL_BD_UNLOCK,
                SL_BD_UNLOCK_ASSERT_FULLY_LOADED,
                SL_BD_SET_LOCK_RESET_MENUS,
                SL_BD_SET_LOCK_CAST_EVENT);
        }
        FileChangedOnDiskAlert(bd);
    }
}

SIMULINK_EXPORT_FCN 
void unlockLibrary( const slGraph *graph )
{
    SLRootBD *bd = slGraph::GraphGetBlockDiagram(graph);
    if( gbd_lock( bd ) )
    {
        (void)bd->setLock(SL_BD_UNLOCK,
            SL_BD_UNLOCK_ASSERT_FULLY_LOADED,
            SL_BD_SET_LOCK_RESET_MENUS,
            SL_BD_SET_LOCK_CAST_EVENT);
    }
    FileChangedOnDiskAlert(bd);
}

void lockLibrary(const slGraph *graph)
{
    SLRootBD *bd = slGraph::GraphGetBlockDiagram(graph);
    if (!gbd_lock(bd))
    {
        (void)bd->setLock(
            SL_BD_LOCK,
            SL_BD_UNLOCK_ASSERT_FULLY_LOADED,
            SL_BD_SET_LOCK_RESET_MENUS,
            SL_BD_SET_LOCK_CAST_EVENT);
    }
    FileChangedOnDiskAlert(bd);
}


SIMULINK_EXPORT_FCN 
bool isBdContainingGraphCompiled( const slGraph *graph )
{
    return graph->isBdContainingGraphCompiled();
}

SIMULINK_EXPORT_FCN
const slsvString &getBlockNameAsSLString( const SLBlock *block )
{
    return block->getGrNameString();
}

SIMULINK_EXPORT_FCN
void setBlockName( SLBlock *block, const fl::ustring& name, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errorMsg = SLSV_NoDiagnostic;
    fl::ustring nfc_normilizedName(name);
    fl::i18n::transform(nfc_normilizedName, fl::i18n::to_nfc()); //see g1125861
    errorMsg = BlockNameChange( block, slsvString(nfc_normilizedName) );

    if( errorMsg != SLSV_NoDiagnostic )
    {
        // Assuming that in case of an error, sgb_name 
        // hasn't changed the block's name to new name   
        FL_DIAG_ASSERT( name != (block)->getGrNameString().str() );        
        
        status = convertSLErrorToErrorHolder( errorMsg );
        return;
    }

    // Determining if this is really a stateflow
    // block happens inside the function.
    // This function also performs a setName on
    // toplevel chart. We should perform this operation
    // before doing slGraph::setName below. 
    slNotifyStateflowBlockEvent(block, BLK_NAMECHANGE);

    if( block->getBlockType() == SL_SUBSYSTEM_BLOCK )
    {
        (static_cast<SubsystemBlock*>(block)->get_subsystem_graph())->setName(slsvString(name));
    }

    // Notify clients such as model explorer name has changed
    UDInterface* udi = (block->getUDI());
    if(udi)
        broadcast_dispatcher_event("PropertyChangedEvent", udi);

}

SIMULINK_EXPORT_FCN
void setBlockNameUniquely(SLBlock *block, const fl::ustring& name, const std::unordered_set<fl::ustring> &restrictedNames /*= std::unordered_set<fl::ustring>()*/ )
{
    FL_DIAG_ASSERT( block != nullptr );
    FL_DIAG_ASSERT( getBlockGraph(block) != nullptr );

    fl::ustring safeName = name;

    // Block names are not allowed to start or end with "/". In order to prevent "setBlockName" from
    // having an error and causing an assert we need to remove any leading or trailing "/" from the block name
    static const fl::ustring::value_type separator = static_cast<fl::ustring::value_type>('/');
    while(safeName[0] == separator)
    {
        safeName.erase(safeName.begin());
    }

    while (safeName[safeName.length() - 1] == separator)
    {
        safeName.pop_back();
    }

    if(safeName.empty())
    {
        // If the name is now empty because it only consisted of "/" characters then fall back to the block type
        safeName = block->getBlockTypeString().str();
        FL_DIAG_ASSERT( !safeName.empty() );
    }

    GLEE::ErrorHolder status;
    
    setBlockName( block, GetUniqueName( slsvString(safeName), getBlockGraph(block), block, restrictedNames), status );
    FL_DIAG_ASSERT( !status.hasError() );
}

SIMULINK_EXPORT_FCN
void setBlockNameUniquelyAmongstGraphs( SLBlock *block, const std::vector<slGraph*> &graphs )
{
    slsvDiagnostic errMsg = MakeBlockNameUnique( block, graphs );
    (void)errMsg; // when NDEBUG defined
    FL_DIAG_ASSERT( errMsg == SLSV_NoDiagnostic );
}

SIMULINK_EXPORT_FCN
SLBlock* fullPathToBlock(const slsvString &fullPath, bool forceLoadModel)
{
    if( forceLoadModel )
    {
        //  Make sure the library/model is loaded first
        slsvString sysPath = slu::BlockPathUtil::getModelFromPath(fullPath.c_str());
        try {
            SLRootBD::loadSystem(sysPath);
        } catch (const fl::except::IException&) {
        }
    }

    return fullpath_to_block(fullPath);
}

/* The function loads only the specified block. For all other blocks in library, a dummy block is created.
* For the specified block - loads the block, all blocks within it if its a subsystem block and executes all callbacks.
* For other blocks in the library, no callbacks are executed. 
* 
* TopTester: test/toolbox/simulink/blocksearch/tQuickInsert.m
*/
SIMULINK_EXPORT_FCN
SLBlock* fullPathToBlockIncrementalLoad(const slsvString &fullPath)
{
    // First find the block in memory
    SLBlock *block = fullpath_to_block(fullPath);

    if (nullptr != block &&
        block->getBPI()->getGrLoadStatus() == SL_FULL_LOAD)
    {
        // Already fully loaded.
        return block;
    }

    // Not fully loaded.  Instruct the loader to find it and load it.
    const SLBlockPath pathToBlock(fullPath, true);
    slBlockDiagramLoadOptions opts(pathToBlock);
    slBlockDiagramLoadSave::loadSystem(opts);
    return fullpath_to_block(fullPath);
}

SIMULINK_EXPORT_FCN 
SLBlock* getBlockGivenSIDAndBlockDiagram(SLRootBD* bd, const std::string& sid)
{    
    UNUSED_PARAMETER(bd);
    SLSVMWObjectBase* slObj = SIDServiceSL::find (sid);
    if (slObj == nullptr || slObj->getSimulinkObjectType() != SIMULINK_BLOCK_object) {
        return nullptr;
    }
    return static_cast<SLBlock*>(slObj);
}

SIMULINK_EXPORT_FCN
GLEE::Font getBlockFont( const SLBlock *block )
{
    // When a subsystem graph is being destroyed, its owning
    // block is already removed from its graph, so any objects
    // in the subsystem graph will be disconnected from the root
    // block diagram.  We need access to the root block diagram
    // when getting fonts (defaults are stored there).  So if
    // our owner is being destroyed, don't really try and get the
    // font info. 
    
    auto owner = block->getBPI()->getGrOwner();
    if( owner != nullptr && !owner->getGlueBeingDestroyed() )
    {
        return SLFont2GLFont( ggb_font(block) );
    }
    
    return GLEE::Font();
}

SIMULINK_EXPORT_FCN 
void setBlockFont( SLBlock *block, const GLEE::Font &font )
{
    SLFontOverrides overrides(
        slsvString(slsvToUString(font.getFamily().getString())),
        font.getSize(),
        GL2SL(font.getWeight()),
        GL2SL(font.getStyle()));
    set_font_overrides(block,overrides);
}
 
SIMULINK_EXPORT_FCN
slsvString getBlockFullPathNameAsSLString( const SLBlock *block )
{
    return slsvString(block->getRootBPI()->getGrFullPathNameUnicode());
}

SIMULINK_EXPORT_FCN
double getBlockHandle (const SLBlock *block )
{
    return( (block->getHandle()) );
}

SIMULINK_EXPORT_FCN
SLBlock * getBlockFromHandle(double blockH)
{
    return (SLBlock::Handle2Block(blockH));
}

SIMULINK_EXPORT_FCN 
fl::ustring getModelRefName(const SLBlock *block )
{
    FL_DIAG_ASSERT_MSG(IsModelRefBlock(block), "block is not a modelref!");
    
    fl::ustring name = mdlref::GetModelRefName(block);
    if (mdlref::isModelRefDefaultModelName(name)) {
        name.clear();// = USTR("").getString<slsv_uchar>();
    }

    return name;
}

SIMULINK_EXPORT_FCN 
bool isMdlRefGraphLoaded(const SLBlock *mdlRefBlock )
{
    FL_DIAG_ASSERT_MSG(IsModelRefBlock(mdlRefBlock), "block is not a modelref!");

    slGraph* mdlRefGraph = SLGlue::fullPathToGraph(SLGlue::getModelRefName(mdlRefBlock));
    return (mdlRefGraph != nullptr);
}

SIMULINK_EXPORT_FCN 
GLEE::Color getMdlRefCornerColor(const SLBlock *mdlRefBlock )
{
    FL_DIAG_ASSERT_MSG(IsModelRefBlock(mdlRefBlock), "block is not a modelref!");
    
    slModelBlockIcon iconDrawer(static_cast<const ModelRefBlock*>(mdlRefBlock),
                                (mdlRefBlock->getGrLocationPtr()), nullptr);
    ColorPtr cornerColorPtr;
    switch(iconDrawer.getCornerColor())
    {
    case slModelBlockIcon::RED:
        cornerColorPtr = sluGetStandardColorPtr(USTR("red"));        
        break;

    case slModelBlockIcon::GRAY:
        cornerColorPtr = sluGetStandardColorPtr(USTR("gray"));
        break;

    case slModelBlockIcon::FOREGROUND:
        cornerColorPtr = ggb_foreground_ColorPtr(mdlRefBlock);
        break;

    default:
        FL_DIAG_ASSERT(iconDrawer.getCornerColor() == slModelBlockIcon::BACKGROUND);
        cornerColorPtr = ggb_background_ColorPtr(mdlRefBlock);
        break;
    }

    return GLEE::Color( cornerColorPtr->r, cornerColorPtr->g, cornerColorPtr->b, 1.0 );
}

SIMULINK_EXPORT_FCN 
bool isMdlRefDashBorder(const SLBlock *mdlRefBlock ) {
    FL_DIAG_ASSERT_MSG(IsModelRefBlock(mdlRefBlock), "block is not a modelref!");
    if(!isMaskEnabledAndOpaque(mdlRefBlock)) {
        slModelBlockIcon iconDrawer(static_cast<const ModelRefBlock*>(mdlRefBlock),
                                    (mdlRefBlock->getGrLocationPtr()), nullptr);
        return iconDrawer.showRedDashBorder();
    }
    return false;
}

SIMULINK_EXPORT_FCN
MG::DPoint getBlockPosition( const SLBlock *block )
{
    MWrect rect = *(block->getGrLocationPtr());
    
    return( MG::DPoint( rect.left, rect.top ) );
}

SIMULINK_EXPORT_FCN
void setBlockPosition( SLBlock *block, const MG::DPoint& pos )
{
    MWrect rect = *(block->getGrLocationPtr());
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;

    MWrect oldRect = rect;
    
    rect.left = static_cast<int>(pos.x());
    rect.top = static_cast<int>(pos.y());
    rect.right = rect.left + width;
    rect.bottom = rect.top + height;

    setBlockLocation( block, rect );

    // Notify Simulink Plugin listeners that the Position has changed
    // This handles the notification via set_param or via the UI
    // Please note that the UI and set_param have two different code paths to 
    // change the position but they both end-up calling sgb_location:
    // 
    //   1. UI calls: setBlockPosition but it does NOT call sgb_location  
    //
    //   2. set_param: calls set_block_position which eventually calls sgb_location
    //
    ParamChangeEventListener(block, getPrmDescFromBlockParams("Position"), oldRect);

}

SIMULINK_EXPORT_FCN
UDInterface* getBlockUDI(const SLBlock* block, bool checkStateflowChart)
{
    UDInterface* blkUdi = (block->getUDI());
    if (checkStateflowChart && blkUdi && !isMasked(block) && BlockIsStateflow(block)){
        MxArrayScopedPtr args0(mxCreateString("block2handle"));
        MxArrayScopedPtr args1(mxCreateDoubleScalar((block->getHandle())));
        mxArray *args[] = { args0, args1 };
        slsvDiagnostic err = SLSV_NoDiagnostic;

        mxArray *returnVals[1] = { nullptr };
        err = slsvFEVAL_NoThrow(1, returnVals, 2, args, "sfprivate");
        if (err != SLSV_NoDiagnostic) {
            slsvDiscardDiagnostic(err);
        }
        auto* chartUdi = static_cast<UDInterface*>(uddtConvertFromMatlab(UDTypeRepository::getType("handle"), returnVals[0]));
        mxDestroyArray(returnVals[0]);
        if (chartUdi)
            return chartUdi;
    }

    return blkUdi;
}

SIMULINK_EXPORT_FCN
UDInterface* stateflowGetSimFcnParentUDI(const SLBlock* block)
{
    return StateflowGetSimFcnParentUDI(block);
}

SIMULINK_EXPORT_FCN
SLBlockOrientationType getBlockOrientation( const SLBlock *block )
{
    return static_cast<SLBlockOrientationType>(static_cast<int>(block->getGrOrientation()));
}

SIMULINK_EXPORT_FCN 
void setBlockOrientation( SLBlock *block, SLBlockOrientationType orientation )
{
    FL_DIAG_ASSERT( block != nullptr );
    
    if( getBlockOrientation(block) == orientation )
        return;
        
    double rotation = 0;
    bool   mirror   = false;

    SLRootBlock::orientation_to_rotation_mirror_for_default_port_rotation( static_cast<BlockOrientation>(orientation), &rotation, &mirror );
    
    while( rotation >= 360.0 )
        rotation -= 360.0;
    
    setBlockMirror( block, mirror );
    setBlockRotation( block, rotation );
}

SIMULINK_EXPORT_FCN
int getBlockZOrder( const SLBlock *block )
{
    return block->getBPI()->getGrZOrder();
}

SIMULINK_EXPORT_FCN
void setBlockZOrder( SLBlock *block, int zOrder )
{
    sgb_ZOrder( block, zOrder );
}

SIMULINK_EXPORT_FCN
void setBlockPortNumberM3I( SLBlock *block, int portNumber )
{
    slGraph* graph = block->getBPI()->getGrOwner();
    auto setThePortNumber = [&]()
    {
            if (sl::sysarch::dataModelFeatIsOn()) {
                static_cast<NumberedPortBlock *>(block)->updateParamCaches();
            } else {
                auto* npb = static_cast<NumberedPortBlock *>(block);
                npb->setPortNumber(portNumber);
                npb->updateParamCaches();
                if (graph != nullptr) {
                    graph->refreshBlock_internal(block->getPortBlockInfo().portType);
                    PortBlockType bType = getBlockPortBlockType(block);
                    if (bType == FCNCALL_ARGIN_BLOCK || bType == FCNCALL_ARGOUT_BLOCK) {
                        SlFcnCallUtil::SyncPrototypeWithArgumentBlocks(block, graph);
                    }
                }
            }
    };
    
    switch( getBlockPortBlockType(block) )
    {
      case INPORT_BLOCK:
      case SHADOW_INPORT_BLOCK:
      case OUTPORT_BLOCK:
      case FCNCALL_ARGIN_BLOCK:
      case FCNCALL_ARGOUT_BLOCK:
        setThePortNumber();
        break;
      default:
        /* nothing */
        break;
    }
}

SIMULINK_EXPORT_FCN
void setBlockPortNumber(SLBlock *block, int portNumber)
{
    switch (getBlockPortBlockType(block)) {
        case LEFT_CONNECTION_PORT_BLOCK:
        case RIGHT_CONNECTION_PORT_BLOCK:
        case UNKNOWN_CONNECTION_PORT_BLOCK:
        {
            auto *connPortBlock = boost::polymorphic_downcast<SlConnportBlk *>(block);
            const int oldPortNumber = connPortBlock->getPortNumber();
            if (oldPortNumber != portNumber) {
                connPortBlock->setPortNumber(portNumber);
                UpdateGraphConnportBlocks(connPortBlock, oldPortNumber - 1, portNumber - 1,
                                          connPortBlock->getPortSide(), UNKNOWN_SIDE);
            }
            break;
        }
        default:
            setBlockPortNumberM3I(block, portNumber);
            break;
    }
}

SIMULINK_EXPORT_FCN
void bringBlockToTop( SLBlock *block )
{
    int newZOrder = 0;
    slGraph* graph = block->getBPI()->getGrOwner();
    if(graph != nullptr)
        newZOrder = graph->getBlockZOrderMax()+1;
    sgb_ZOrder( block, newZOrder );
}

SIMULINK_EXPORT_FCN
void sendBlockToBottom( SLBlock *block )
{
    int newZOrder = 0;
    slGraph* graph = block->getBPI()->getGrOwner();
    if(graph != nullptr)
        newZOrder = graph->getBlockZOrderMin()-1;
    sgb_ZOrder( block, newZOrder );
}

SIMULINK_EXPORT_FCN
void initZOrderOfBlockAddedToGraph(SLBlock *block)
{
    // any new block that had no Z value saved in the mdl is put on the bottom.
    // This should preserve the screwy way Simulink used the block name to
    // determine the z order.
    slGraph* graph = block->getBPI()->getGrOwner();
    if(!graph)
    {
        sgb_ZOrder(block, 0);
    }
    else
    {
        int blockz = block->getBPI()->getGrZOrder();
        if(!blockz)
        {
            SLGlue::sendBlockToBottom(block);
        }
        else
        {
            graph->setBlockZOrderMin(std::min(graph->getBlockZOrderMin(), blockz));
            graph->setBlockZOrderMax(std::max(graph->getBlockZOrderMax(), blockz));
        }
    }
}

SIMULINK_EXPORT_FCN
MG::DPoint getBlockSize( const SLBlock *block )
{
    MWrect rect = *(block->getGrLocationPtr());

    return( MG::DPoint( rect.right-rect.left, rect.bottom-rect.top ) );
}

SIMULINK_EXPORT_FCN
void setBlockSize( SLBlock *block, const MG::DPoint& size )
{
    MWrect rect = *(block->getGrLocationPtr());
    
    // If the size changes, and the block has requested the mask
    // init be done for all resizes, set the mask dirty so that
    // mask init will be rerun.
    bool sizeChanged = 
        size.x() != (rect.right-rect.left)
        || size.y() != (rect.bottom-rect.top);

    if (sizeChanged)
    {    
        SLMaskInterface *mask = block->getBPI()->getGrMask();
        if (mask && (ForceInitForIcon::IS_ON == mask->getForceInitForIcon())) { 
            mask->setWSDirty();
        }
    }
                    
    rect.right = rect.left + static_cast<int>(size.x());
    rect.bottom = rect.top + static_cast<int>(size.y());

    setBlockLocation( block, rect );

    if (sizeChanged)
        BlockInvalidate(block);
}

SIMULINK_EXPORT_FCN
std::string getBlockType( const SLBlock *block, bool useMaskTypes /*= true*/ )
{
    return getBlockTypeAsSLString(block, useMaskTypes).getString<char>();
}

SIMULINK_EXPORT_FCN
slsvString getBlockTypeAsSLString( const SLBlock *block, bool useMaskTypes /*= true*/ )
{
    static const slsvString ksStateflowBlockType(USTR("Stateflow"));
    static const slsvString ksMaskBlockType(USTR("Mask"));
    static const slsvString ksSingleImageMaskBlockType(USTR("SingleImageMask"));

    // In the case where we're using the single image path optimization (more info in CoreBlockGlyphDisplay ImageMaskBlockDisplayInfo) we need to
    // returning a specific type string.
    if (useMaskTypes) {
        if (isMaskEnabledAndUsingSingleImagePathOptimization(block)) {
            return ksSingleImageMaskBlockType;
        } else if (isMaskEnabledAndOpaque(block)) {
            return ksMaskBlockType;
        }
    }

    if (BlockIsStateflow(block)) {
        return ksStateflowBlockType;
    }

    return block->getBlockTypeString();
}

SIMULINK_EXPORT_FCN
std::string getBlockReferenceFullPath( const SLBlock *block )
{
    const fl::ustring& referenceFullPath = block->getRootBPI()->getReferenceBlock(block);
    if (!referenceFullPath.empty()) {   
        return ConvertUStringToStdString(referenceFullPath);
    }    
    return ConvertUStringToStdString(block->getBlockTypeName());;
}



SIMULINK_EXPORT_FCN
bool getBlockDrawName( const SLBlock *block )
{
    FL_DIAG_ASSERT(block != nullptr);
    return( block->getBPI()->getGrDisplayName() );
}

SIMULINK_EXPORT_FCN
void setBlockDrawName(const SLBlock *block, bool drawName)
{
    FL_DIAG_ASSERT(block != nullptr);
    return block->getBPI()->setGrDisplayNameFlag(drawName);
}

SIMULINK_EXPORT_FCN 
GLEE::StrokeStyle::Type getBlockStrokeStyle(const SLBlock* block)
{
    if(isUnresolvedObject(block))
        return GLEE::StrokeStyle::DASHED_STROKE;
    if(block->getBlockType() == SL_SUBSYSTEM_BLOCK && block->isVirtual(BLK_VIRTUAL_EDIT_TIME)) {
        const SubsystemBlock *subsysBlk = static_cast<const SubsystemBlock*>(block);
        if (!isGroupedSubsystemForVCProp(subsysBlk)) {
            return GLEE::StrokeStyle::DOTTED_STROKE;
        }
    }

    return GLEE::StrokeStyle::SOLID_STROKE;
}

SIMULINK_EXPORT_FCN 
GLEE::Color getBlockForegroundColor( const SLBlock* block )
{
    ColorPtr fgcolor = ggb_foreground_ColorPtr( block );
    return GLEE::Color( fgcolor->r, fgcolor->g, fgcolor->b, 1.0 );
}

SIMULINK_EXPORT_FCN 
void setBlockForegroundColor( SLBlock* block, const GLEE::Color& color )
{
    Color_tag pcolor;
    pcolor.r = color.redF();
    pcolor.g = color.greenF();
    pcolor.b = color.blueF();
    sgb_foreground_ColorPtr( block, &pcolor );
}

SIMULINK_EXPORT_FCN 
GLEE::Color getBlockBackgroundColor( const SLBlock* block )
{
    ColorPtr bgcolor = ggb_background_ColorPtr( block );
    return GLEE::Color( bgcolor->r, bgcolor->g, bgcolor->b, 1.0 );
}

SIMULINK_EXPORT_FCN 
void setBlockBackgroundColor( SLBlock* block, const GLEE::Color& color )
{
    Color_tag pcolor;
    pcolor.r = color.redF();
    pcolor.g = color.greenF();
    pcolor.b = color.blueF();
    sgb_background_ColorPtr( block, &pcolor );   
}

SIMULINK_EXPORT_FCN
LibraryLinkType getBlockLibraryLinkType(const SLBlock* pBlock)
{
    SLRootBD* pBD = pBlock->getBPI()->getGrBlockDiagram();
    BDLibraryLinkDisplay aLinkDisplayOption = gbd_library_link_display(pBD);

    if (BD_NO_LIBRARY_LINKS == aLinkDisplayOption) {
        return LibraryLinkType::NONE;
    }

    if (BD_DISABLED_LIBRARY_LINKS == aLinkDisplayOption) {
        return pBlock->getRootBPI()->getGrIsBlockInactiveLink(pBlock) ? LibraryLinkType::DISABLED : LibraryLinkType::NONE;
    }

    if (BD_USER_LIBRARY_LINKS == aLinkDisplayOption && ggb_from_tmw_library(pBlock)) {
        return LibraryLinkType::NONE;
    }

    LibraryLinkType aLinkDisplayType = LibraryLinkType::NONE;

    if (pBlock->getRootBPI()->getGrIsBlockLinked(pBlock)) {
        aLinkDisplayType = LibraryLinkType::DEFAULT;
    }

    /* Modified link */
    if (BlockIsParameterized(pBlock, true)) {
        aLinkDisplayType = LibraryLinkType::MODIFIED;
    }

    /* Disabled link */
    if (pBlock->getRootBPI()->getGrIsBlockInactiveLink(pBlock)) {
        aLinkDisplayType = LibraryLinkType::DISABLED;
    }

    return aLinkDisplayType;
}

SIMULINK_EXPORT_FCN
bool getBlockIsLockedLink( const SLBlock *block )
{
    return block->getRootBPI()->getGrIsLockedLink(block);
}

SIMULINK_EXPORT_FCN
bool getBlockFailedToResolveLink(const SLBlock *block)
{
    return block->getRootBPI()->getGrFailedToResolveLink(block);
}

// ----------------------------------------------------------------------------
// All Ports
// ----------------------------------------------------------------------------

SIMULINK_EXPORT_FCN
int getBlockNumPorts( const SLBlock *block )
{
    int result;
    
    result  = block->getGrNumInputPorts();
    result += block->getGrNumOutputPorts();
    result += block->getGrNumLeftConnectionPorts();
    result += block->getGrNumRightConnectionPorts();

    return( result );    
}

SIMULINK_EXPORT_FCN
slPort *getBlockNthPort( const SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumPorts(block) );
    
    if( index < block->getGrNumInputPorts() )
        return block->getGrInputPort( index );
    
    index -= block->getGrNumInputPorts();
    
    if( index < block->getGrNumOutputPorts() )
        return block->getGrOutputPort( index );
    
    index -= block->getGrNumOutputPorts();
    
    if( index < block->getGrNumLeftConnectionPorts() )
        return block->getGrLeftConnectionPort( index );
    
    index -= block->getGrNumLeftConnectionPorts();
    
    FL_DIAG_ASSERT( index < block->getGrNumRightConnectionPorts() );
    return block->getGrRightConnectionPort( index );
}

// ----------------------------------------------------------------------------
// Input Ports
// ----------------------------------------------------------------------------

SIMULINK_EXPORT_FCN
int getBlockNumInputPorts( const SLBlock *block )
{
    return( block->getGrNumInputPorts() );
}

SIMULINK_EXPORT_FCN
slPort *getBlockNthInputPort( const SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumInputPorts(block) );
    
    return block->getGrInputPort( index );
}

SIMULINK_EXPORT_FCN
void insertBlockInputPort( SLBlock *block, int index, slPort *port )
{
    FL_DIAG_ASSERT( !IsBdContainingBlockCompiled(block) );
    FL_DIAG_ASSERT( gp_type(port) == SL_INPUT_PORT );

    slplugin::addAddedPortToPortConnectivityChangeEventStateMgr(port);
    
    slPortVector& p = block->getGrInputPorts();
    p.insertPort(port,index);
    p.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void eraseBlockInputPort( SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumInputPorts(block) );

    FlexiblePortPlacementControllerPtr fppController = block->getFlexiblePortPlacementController();
    if (fppController != nullptr) {
        const SLPortLocator::SLPortArrayType portType = SLPortLocator::SLPortArrayType::In;
        fppController->repairPortPlacementOnPortDelete(block, portType, index);
    }

    slPortVector& p = block->getGrInputPorts();
    slPort* removedPort = p.getPort(index);
    slplugin::addRemovedPortToPortConnectivityChangeEventStateMgr(removedPort);
    p.removePort(removedPort);
    p.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void clearBlockInputPort( SLBlock *block )
{
    slPortVector& p = block->getGrInputPorts();
    p.releaseAllPorts();
}

// ----------------------------------------------------------------------------
// Output Ports
// ----------------------------------------------------------------------------

SIMULINK_EXPORT_FCN
int getBlockNumOutputPorts( const SLBlock *block )
{
    return( block->getGrNumOutputPorts() );
}

SIMULINK_EXPORT_FCN
slPort *getBlockNthOutputPort( const SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumOutputPorts(block) );
    
    return block->getGrOutputPort( index );
}

SIMULINK_EXPORT_FCN
void insertBlockOutputPort( SLBlock *block, int index, slPort *port )
{
    FL_DIAG_ASSERT( !IsBdContainingBlockCompiled(block) );
    FL_DIAG_ASSERT( gp_type(port) == SL_OUTPUT_PORT );

    slplugin::addAddedPortToPortConnectivityChangeEventStateMgr(port);

    slPortVector& p = block->getGrOutputPorts();
    p.insertPort(port,index);
    p.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void eraseBlockOutputPort( SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumOutputPorts(block) );

    FlexiblePortPlacementControllerPtr fppController = block->getFlexiblePortPlacementController();
    if (fppController != nullptr) {
        const SLPortLocator::SLPortArrayType portType = SLPortLocator::SLPortArrayType::Out;
        fppController->repairPortPlacementOnPortDelete(block, portType, index);
    }

    slPortVector& p = block->getGrOutputPorts();
    slPort* removedPort = p.getPort(index);
    slplugin::addRemovedPortToPortConnectivityChangeEventStateMgr(removedPort);
    p.removePort(removedPort);
    p.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void clearBlockOutputPort( SLBlock *block )
{
    block->getGrOutputPorts().releaseAllPorts();
}
    
// ----------------------------------------------------------------------------
// Left Connection Ports
// ----------------------------------------------------------------------------

SIMULINK_EXPORT_FCN
int getBlockNumLeftConnPorts( const SLBlock *block )
{
    return( block->getGrNumLeftConnectionPorts() );
}

SIMULINK_EXPORT_FCN
slPort *getBlockNthLeftConnPort( const SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumLeftConnPorts(block) );
    
    return block->getGrLeftConnectionPort( index );
}

SIMULINK_EXPORT_FCN slPort* addPortToBrancherBlock(double blockH, const int portIndex, const fl::ustring& newConnectionStr)
{   // adding a port ConnBrancherBlock
    //std::cout << "\n SLGLueAccessBlock    addPortToBrancherBlock" << std::endl;    
    SLBlock* block = getBlockFromHandle( blockH );
    auto *rtBlk = dynamic_cast<ConnBrancherBlock*>(block);
    FL_DIAG_ASSERT( rtBlk != nullptr );
    return rtBlk->addChildPort(portIndex, newConnectionStr, true);
}

SIMULINK_EXPORT_FCN
void insertBlockLeftConnPort( SLBlock *block, int index, slPort *port )
{
    FL_DIAG_ASSERT( !IsBdContainingBlockCompiled(block) );
    FL_DIAG_ASSERT( gp_type(port) == SL_CONNECTION_PORT );
    block->graphical.ports.createConnectionData();
    block->getGrLeftConnectionPorts().insertPort(port,index);
    block->getGrLeftConnectionPorts().assignPortIndices();
}

SIMULINK_EXPORT_FCN
void eraseBlockLeftConnPort( SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumLeftConnPorts(block) );

    FlexiblePortPlacementControllerPtr fppController = block->getFlexiblePortPlacementController();
    if (fppController != nullptr) {
        const SLPortLocator::SLPortArrayType portType = SLPortLocator::SLPortArrayType::LConn;
        fppController->repairPortPlacementOnPortDelete(block, portType, index);
    }

    slPortVector& pv = block->getGrLeftConnectionPorts();
    pv.removePort(pv.getPort(index));
    pv.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void clearBlockLeftConnPort( SLBlock *block )
{
    if (block->graphical.ports.hasConnectionData()) {
        block->getGrLeftConnectionPorts().releaseAllPorts();
    }
}

// ----------------------------------------------------------------------------
// Right Connection Ports
// ----------------------------------------------------------------------------

SIMULINK_EXPORT_FCN
int getBlockNumRightConnPorts( const SLBlock *block )
{
    return( block->getGrNumRightConnectionPorts() );
}

SIMULINK_EXPORT_FCN
slPort *getBlockNthRightConnPort( const SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumRightConnPorts(block) );
    
    return block->getGrRightConnectionPort( index );
}

SIMULINK_EXPORT_FCN
void insertBlockRightConnPort( SLBlock *block, int index, slPort *port )
{
    FL_DIAG_ASSERT( !IsBdContainingBlockCompiled(block) );
    FL_DIAG_ASSERT( gp_type(port) == SL_CONNECTION_PORT );
    block->graphical.ports.createConnectionData();
    block->getGrRightConnectionPorts().insertPort(port,index);
    block->getGrRightConnectionPorts().assignPortIndices();
}

SIMULINK_EXPORT_FCN
void eraseBlockRightConnPort( SLBlock *block, int index )
{
    FL_DIAG_ASSERT( index >= 0 );
    FL_DIAG_ASSERT( index < getBlockNumRightConnPorts(block) );

    FlexiblePortPlacementControllerPtr fppController = block->getFlexiblePortPlacementController();
    if (fppController != nullptr) {
        const SLPortLocator::SLPortArrayType portType = SLPortLocator::SLPortArrayType::RConn;
        fppController->repairPortPlacementOnPortDelete(block, portType, index);
    }

    slPortVector& pv = block->getGrRightConnectionPorts();
    pv.removePort(pv.getPort(index));
    pv.assignPortIndices();
}

SIMULINK_EXPORT_FCN
void clearBlockRightConnPort( SLBlock *block )
{
    if (block->graphical.ports.hasConnectionData()) {
        block->getGrRightConnectionPorts().releaseAllPorts();
    }
}

SIMULINK_EXPORT_FCN
int getBlockNumConnPorts( const SLBlock *block )
{
    return block->getGrNumRightConnectionPorts() + block->getGrNumLeftConnectionPorts();
}

namespace
{

bool isSFType(const SLBlock* block, const std::string& name) 
{
    if( !BlockIsStateflow(block) )
        return( false );
    
    // Need to look under the block to see
    // if it has a chart
    UDInterface *blockUdi = (block->getUDI());
    UDInterface *chartUdi = blockUdi->getFirstDown();
    
    while( chartUdi != nullptr )
    {        
        if( DAUtils::checkIsa( chartUdi, "Stateflow", name.c_str() ) )
        {
            return true ;
        }
        
        chartUdi = chartUdi->getRight();
    }
    
    return( false );
}

} // end anon namespace

SIMULINK_EXPORT_FCN
bool isStateflowBlock(const SLBlock *block)
{
    return BlockIsStateflow(block);
}
/// TBD (SM): Is this trying to find Linked Charts only 
/// or all SF based linked blocks? (G790488)
SIMULINK_EXPORT_FCN
bool isStateflowLinkedBlock(const SLBlock* block)
{   
    return isSFType(block, "LinkChart");
}

SIMULINK_EXPORT_FCN
bool isStateflowLinkedChart(const SLBlock* block)
{	
    return (isSFType(block, "LinkChart") && BlockIsStateflowChart(block));
}

SIMULINK_EXPORT_FCN
bool isSubsystemBlockSFBased (const SLBlock* block)
{
    FL_DIAG_ASSERT(block);
    FL_DIAG_ASSERT(isSubsystem (block));
    return block->IsStateflowBased();
}

SIMULINK_EXPORT_FCN
bool isEMLFunctionBlock(const SLBlock* block)
{
    return block != nullptr && isSubsystem(block) && 
        static_cast<const SubsystemBlock*>(block)->IsMATLABFunction();
}

SIMULINK_EXPORT_FCN
bool isStateflowChartBlock(const SLBlock *block)
{    
    return BlockIsStateflowChart(block);
}

SIMULINK_EXPORT_FCN
bool isStateflowEMLBlock(const SLBlock *block)
{
    return BlockIsMATLABFunction(block);
}

SIMULINK_EXPORT_FCN
bool isStateflowTruthTableBlock(const SLBlock *block)
{
    return BlockIsTruthTable(block);
}

bool isStateflowTransitionTableBlock(const SLBlock* block)
{
    return BlockIsTransitionTable(block);
}

bool isTestSequenceBlock(const SLBlock* block)
{
    return BlockIsTestSequence(block);
}

SIMULINK_EXPORT_FCN
double getConfigurableBlockChoiceHandle(double handle)
{    
    double retHandle = -1.0;
    SLBlock* block = getBlockFromHandle(handle);
    if(isBlockConfigurableSubsystem(block))
    {
        retHandle = getBlockHandle(getConfigSubsysBlockChoice(block));
    }
    return retHandle;
}

SIMULINK_EXPORT_FCN
bool isBlockConfigurableSubsystem (const SLBlock *block)
{
    return (SubsystemBlock::IsConfigurableSubsystem(const_cast<SLBlock*>(block)));
}

SIMULINK_EXPORT_FCN
bool isBlockConfigurableSubsystemInstance( const SLBlock* block )
{
    return (SubsystemBlock::IsConfigurableSubsystemInstance(const_cast<SLBlock*>(block)));
}

SIMULINK_EXPORT_FCN
bool isBlockConfigurableSubsystemTemplate( const SLBlock* block )
{
    return (SubsystemBlock::IsConfigurableSubsystemTemplate(const_cast<SLBlock*>(block)));
}

SIMULINK_EXPORT_FCN
void blockOpenConfigurableSubsystemTemplate(SLBlock* block )
{
    FL_DIAG_ASSERT(isBlockConfigurableSubsystemTemplate( block ));
    BlockOpenConfigurableSubsystem(block, nullptr);
}

SIMULINK_EXPORT_FCN
bool isContentPreviewEnabledSubsystemOrModelRef(const SLBlock* block)
{
    return ((isSubsystem (block) && SubsystemBlock::IsContentPreviewEnabled (block)) ||
            (isModelReference(block) && GetMdlRefContentPreviewEnabled(block)));
}

SIMULINK_EXPORT_FCN 
bool isConfigSubsysMaster(const slsvString &fullPath)
{
    SLBlock* block = fullPathToBlock(fullPath);
    if(block)
        return (SubsystemBlock::IsConfigurableSubsystemMaster(block));
    else
        return false;
}

SIMULINK_EXPORT_FCN 
SLBlock* getConfigSubsysBlockChoice(const SLBlock *block, SLUpdateReferenceOptions updateOption)
{
    // Master blocks are in libraries and we don't want
    // to warn about no block choice for such blocks
    // -sramaswa
    if ( !( SubsystemBlock::IsConfigurableSubsystemMaster(const_cast<SLBlock*>(block)) ) )
    {
        // Do not show warnings if block choice is not available
        bool showwarning = false;
        auto subsystemBlock = static_cast<SubsystemBlock*>(const_cast<SLBlock*>(block));
        return subsystemBlock->getConfigSubsysChoiceBlock(showwarning, static_cast<UpdateReferenceOptions>(updateOption));
    }
    return nullptr;
}

// if the hierarchical item type matches the expected type, and content preview is on by
// default, we enable content preview for that hierarchical item.
// To do: akaviman: Once Simulink Library browser starts showing content preview for root
// blocks it contains, this code below will be unnecessary and has to be removed. This is because
// root blocks from which elements are copied will have their content preview parameter set,
// and same will be copied over to target block.
bool enableContentPreview(const slsvString& sourceLocationStr, SLBlock* block)
{
    bool enabled = false;
    if (!isMasked(block))
    {
        if (isSubsystem(block) || isStateflowChartBlock(block) || isModelReference(block)) 
        {
            // We want to set content preview if source block location is Simulink library.
            // Otherwise we skip it.
            if (!sourceLocationStr.empty())
            {
                SLBlockPath blockpath(sourceLocationStr, true);
                const slsvString& bdName = blockpath.getBlockDiagramName();

                //static const std::unordered_set<slsvString> matchSet = { slsvString(USTR("simulink")), slsvString(USTR("sflib")), slsvString(USTR("built-in")) };
                static const std::unordered_set<slsvString> matchSet = { slsvString(USTR("simulink")), slsvString(USTR("sflib")) };
                if (matchSet.find(bdName) != matchSet.end())
                {
                    enabled = setContentPreviewEnabled(block, SLGlue::CPOnByDefault::isContentPreviewByDefaultOn());
                }
            }
        }
    }
    return enabled;
}

// maskedBlockContentsViewableForContentPreview: answers whether contents of this
// mask block can be shown in preview.
// 
// Assuming permissions allow it, mask block contents viewable when:
// 1. It is not opaque and does not have a drawing string in its mask code. 
// 2. The mask hide contents is not set on block.
//     
bool maskedBlockContentsViewableForContentPreview(const SLBlock* block)
{
    FL_DIAG_ASSERT (isMasked(block));      
    return (isSubsystemReadProtected(block) == false &&
            Simulink::ProtectedLibrary::blockIsProtected(block) == false && 
            maskIconTransparentAndDisplayStringEmpty(block) == true &&
            getSubsystemMaskHideContents(block) == false);
}


SIMULINK_EXPORT_FCN
bool isSubsystem(const SLBlock *block)
{
    return (block->getBlockType() == SL_SUBSYSTEM_BLOCK);
}



SIMULINK_EXPORT_FCN
bool setContentPreviewEnabled (SLBlock* block, bool withcp)
{
    FL_DIAG_ASSERT (dynamic_cast<SubsystemBlock*>(block) || dynamic_cast<ModelRefBlock*>(block));
    bool isDone = false;
    std::unique_ptr<CPOnByDefaultChecks> cpOnCheck;
    switch (block->getBlockType ())
    {
        case SL_SUBSYSTEM_BLOCK:
            SubsystemBlock::setcontentPreviewEnabled (block, withcp);
            FL_DIAG_ASSERT (SubsystemBlock::IsContentPreviewEnabled (block) == withcp);
            isDone = SubsystemBlock::IsContentPreviewEnabled (block);
            // Now perform content preview specific checks. At the moment,
            // doCheck() generates a message for listeners that in turn take
            // action e.g. show the message as a notification to User. We need
            // not worry with the return value of doChecks.
            cpOnCheck = std::make_unique<CPOnByDefaultChecks>(getBlockGraph(block));
            
            break;
        case SL_MODELREF_BLOCK:
            SetMdlRefContentPreviewEnabled (block, withcp);
            FL_DIAG_ASSERT (GetMdlRefContentPreviewEnabled (block) == withcp);
            break;
        default:
            break;
    }
    if (cpOnCheck)
    {
        cpOnCheck->doChecks();
    }
    return isDone;

}

SIMULINK_EXPORT_FCN
bool hasHarness(const SLBlock *block)
{
    FL_DIAG_ASSERT(block != nullptr);
    const SLRootBD * bd = block->getBPI()->getGrBlockDiagram();
    if(bd == nullptr) {
        return(false);
    }
    sl::simharness::SlHarnessManager *mgr = bd->getHarnessManager();
    if (mgr && mgr->hasHarness(block)) {
        return true;
    }
    return false;
}

SIMULINK_EXPORT_FCN
bool isObserver(const SLBlock *block)
{
    FL_DIAG_ASSERT(block != nullptr);
    if (block->getBlockType() == SL_SUBSYSTEM_BLOCK) {
        return static_cast<const SubsystemBlock*>(block)->isObserver();
    }
    return false;
}

SIMULINK_EXPORT_FCN
bool isObserverActive(const SLBlock *block)
{
    if (isObserver(block)) {
        return !SLLangBlocksUtil::BlockIsOrInsideCommentedBlock(block);
    }
    return false;
}

SIMULINK_EXPORT_FCN
void executeSimHarnessUpdaterOnBlockDelete(const SLBlock *block)
{
    FL_DIAG_ASSERT(block != nullptr);
    sl::simharness::SlHarnessUpdater harnessUpdater(sl::simharness::SlHarnessUpdater::PORTS_DELETED, block);
    return;
}


SIMULINK_EXPORT_FCN
bool isHierarchical(const SLBlock *block)
{
    return isSubsystem(block) || isModelReference(block);
}

SIMULINK_EXPORT_FCN
bool isThisBlockAccessible(const SLBlock *block)
{
    bool ret = true;
    GLEE::ErrorHolder status;
    if (block && (isSubsystemReadProtected(block) 
        || (isModelReference(block) && isModelReferenceProtected(block, status))
        || ( isMasked(block) && getSubsystemMaskHideContents(block))
        || Simulink::ProtectedLibrary::blockIsProtected(block)))
    {
        FL_DIAG_ASSERT(!status.hasError());
        ret = false;
    }
    return ret;
}

bool isBlockExecEventAffordanceShow(const SLBlock *block)
{
    return IsBlockExecEventAffordanceShow(block);
}

SIMULINK_EXPORT_FCN
bool isHierarchicalAndAccessible(const SLBlock *block)
{
    /* Block is not hierarchical and accessible if:
     * it is a subsystem block that is read protected
     * it is a model reference block that is protected
     * it is mask with hide contents
     * NOTE: We can add other use cases here to determine
     * whether it makes sense for this block to have a valid HID.
     */
    if(block == nullptr) /* e.g. when the block choice is changed */
        return false;
    
    slGraph *parent = nullptr;   
    if (block->getBlockType() == SL_SUBSYSTEM_BLOCK) {    
        parent = static_cast<const SubsystemBlock*>(block)->get_subsystem_graph();
    }
    
    while ( parent && block && (!SLGlue::isARootGraph (parent)) )
    {   
        const SLBlock* realBlock = SLGlue::getRealBlockForHierarchicalChildrenTraversal(const_cast<SLBlock *>(block));
        if(!(isThisBlockAccessible(block)))
        // Keep on going up in a tree, till you hit the top graph or
        // if you hit a block that is protected.
        {
            return false;
        }
        else if (realBlock != block)
        {
            if (!(isThisBlockAccessible(realBlock)))
            {
                return false;
            }
        }            
        // Get this graph's block owner for the next run. 
        parent = SLGlue::getBlockGraph (block);
        block = SLGlue::getGraphOwner (parent);        
    }
    // Parent can also be null for a Model reference block.
    // If so, check whether this block is protected.
    if (parent == nullptr && block && isModelReference(block))
    {
        GLEE::ErrorHolder status;
        if (isModelReferenceProtected(block, status))
        {
            FL_DIAG_ASSERT(!status.hasError());
            return false;
    }
    }
    return true;
}

SIMULINK_EXPORT_FCN
bool isShadowEnabled(const SLBlock *block)
{
    //this shadow is simulink shadow and since all the UE glyphs have a decorative shadow,
    //this one will present as a thinker shadow similar to what simulink had.
    return static_cast<bool>( block->graphical.flags.drop_shadow );
}

SIMULINK_EXPORT_FCN
void setShadowEnabled(SLBlock *block, bool dropShadow)
{
    FL_DIAG_ASSERT(block != nullptr);
    setBlockDropShadow(block, dropShadow);
}

SIMULINK_EXPORT_FCN
bool isWebBlock(const SLBlock *block)
{
    return block->static_data->flags.isCoreWebBlock || SubsystemBlock::isWebBlock(block);
}

SIMULINK_EXPORT_FCN
bool isHiddenFromUser(const SLBlock *block)
{
    return block->getIsHiddenFromUser();
}

SIMULINK_EXPORT_FCN
bool hasFixedAspectRatio(const SLBlock *block)
{
    // A block has a fixed aspect ratio iff it has a fixedAspectRatio mask parameter with a value of true.
    const char* FIXED_ASPECT_RATIO_PARAM = "fixedAspectRatio";
    try {
        std::string isFixedAspect = slobject::block::getParamAsStr(block, FIXED_ASPECT_RATIO_PARAM);
        if (isFixedAspect == "on") {
            return true;
        }
    }
    // There will be an error thrown if the block property does not exist, which will be the case for most webblocks.
    catch (const fl::except::IException&) {
        return false;
    }
    return false;
}

SIMULINK_EXPORT_FCN
bool isWebBlockPanel(const SLBlock *block)
{
    return SubsystemBlock::isWebBlockPanel(block);
}

SIMULINK_EXPORT_FCN
bool isMasked(const SLBlock *block)
{
    UpdateInportShadowBlockToInportBlock(block);
    return block->getBPI()->getGrMask();
}

SIMULINK_EXPORT_FCN
bool maskBlockHasAnyOpenDialog(const SLBlock *block)
{
    return (slHasAnyOpenDialog(block, MASK_DIALOG) || block->getBPI()->getGrMaskEditorOpen());
}

SIMULINK_EXPORT_FCN
bool isMaskForceInitForIcon(const SLBlock *block)
{
    SLMaskInterface *mask = block->getBPI()->getGrMask();
    return (mask && (ForceInitForIcon::IS_ON == mask->getForceInitForIcon()));
}

SIMULINK_EXPORT_FCN
bool hasSimpleMask(const SLBlock *block)
{
    // There are two functions gmi_mask_with_no_dialog(), and
    // gmi_simpleMask(), which seem to have the same function but
    // have slightly different checks.  gmi_mask_with_no_dialog()
    // is used by the open code, which is what we care about, so
    // use that.
    return block->getBPI()->getGrMask() && block->getBPI()->getGrMaskWithNoDialog(block);
}

SIMULINK_EXPORT_FCN 
bool getSubsystemMaskHideContents(const SLBlock *block)
{
    if (block->getBlockType() != SL_SUBSYSTEM_BLOCK) return false;
    return static_cast<const SubsystemBlock*>(block)->getMaskHideContents();
}

static bool isSubsystemViewableForTransparency(const SLBlock *block)
{
    FL_DIAG_ASSERT(block != nullptr && isSubsystem(block));
    bool isViewable = false;
    if (slsr::util::isSubsystemReference(block) &&
          slsr::util::isSRBlockOpaque(block)) {
       isViewable = false;
    }
    else if (isMasked(block)) {
        isViewable = maskedBlockContentsViewableForContentPreview(block);
    }
    else {
        if (isSubsystemReadProtected(block) == false &&
           Simulink::ProtectedLibrary::blockIsProtected(block) == false) {
               isViewable = !(isStateflowBlock(block) && !isStateflowChartBlock(block));
        }
   }
   return isViewable;
}

static bool isModelReferenceViewableForTransparency(const SLBlock *block)
{
    FL_DIAG_ASSERT(block != nullptr && isModelReference(block));

    GLEE::ErrorHolder status;
    if (!slsvStrcmpi(block->getTag(), slsvString(USTR("SFX_IN_SLX")))){
        return true;
    }
    if(block->getBPI()->getGrMask() || isModelReferenceProtected(block, status))
    {
        FL_DIAG_ASSERT(!status.hasError());
        return false;
    }
    else 
    {
        bool isOnPath = isModelFileOnPathCached(getModelRefName(block), status);
        if (!isOnPath && !status.hasError ()) 
        {
            return false;
        }
    }

    return true;
}

// It's odd that status isn't used or assigned to?
SIMULINK_EXPORT_FCN
bool isSubsystemContentsViewableForTransparency(const SLBlock *block, GLEE::ErrorHolder& /*status*/)
{
    // When is it possible to show transparency?
    // - A simple subsystem or a loaded model ref that is not protected.
    // - No mask.
    // - Non-read protected subsystem.

    // If this block is a configurable subsystem, then we need to operate both the block and also
    // the block choice to know if it's correct to show the transparency.
    if (isBlockConfigurableSubsystem(block))
    {
        FL_DIAG_ASSERT(isSubsystem(block));
        if (!isSubsystemViewableForTransparency(block))
        {
            return false;
        }

        SLBlock* choiceBlock = SLGlue::getConfigSubsysBlockChoice(block, SLGlue::NO_UPDATE);
        if (choiceBlock == nullptr)
        {
            return false;
        }
        block = choiceBlock;
    }
    
    if (isSubsystem(block))
    {
        if (block->getBlockContext()->isAdapterBlockInComposition(block))
        {
            return false;
        }
        else
        {
            return isSubsystemViewableForTransparency(block);
        }
    }
   else if (isModelReference(block))
    {
        return isModelReferenceViewableForTransparency(block);
    }
    else
    {
        return false;
    }
}


SIMULINK_EXPORT_FCN 
bool isMaskEnabledAndOpaque(const SLBlock *block)
{
    //tells us that a mask is active, that it disables all default block drawing
    //and that it contains a string with drawing code.
    //This is the case when we should stop all default drawing and allow the user to
    //do what the hell they want.
    return isMaskEnabledAndIconOpaque(block);
}


SIMULINK_EXPORT_FCN 
bool isMaskEnabledAndUsingSingleImagePathOptimization(const SLBlock *block)
{
    return isMaskEnabledUsingSingleImagePathOptimization(const_cast<SLBlock*>(block));
}

SIMULINK_EXPORT_FCN
bool isSubsystemReadProtected(const SLBlock *block)
{
    return block->getBlockType() == SL_SUBSYSTEM_BLOCK && 
        static_cast<const SubsystemBlock*>(block)->IsReadProtected();
}

SIMULINK_EXPORT_FCN
bool isSubsystemWriteProtected(const SLBlock *block)
{
    return block->getBlockType() == SL_SUBSYSTEM_BLOCK && static_cast<const SubsystemBlock*>(block)->IsWriteProtected();
}

SIMULINK_EXPORT_FCN 
bool isModelReference(const SLBlock *block)
{
    return (block->getBlockType() == SL_MODELREF_BLOCK);
}

SIMULINK_EXPORT_FCN 
bool isModelReferenceProtected(const SLBlock *block, GLEE::ErrorHolder& status)
{
    bool ret = false;    
    FL_DIAG_ASSERT(isModelReference(block));
    try
    {
        ret = mdlref::didModelBlockReferenceProtectedModelAtLastRefresh(static_cast<const ModelRefBlock*>(block));
    }
    catch (const MathWorks::System::IException &e)
    {   
        slsvDiagnostic errmsg = slsvCreateDiagnosticFromIException(e);
        if( errmsg != SLSV_NoDiagnostic )
        {
            status = convertSLErrorToErrorHolder( errmsg);            
        }
    }
    return ret;
}

bool isModelReferenceIncompatible(const SLBlock *block)
{
    FL_DIAG_ASSERT(isModelReference(block));

    const ModelRefBlock* mdlRefBlk = static_cast<const ModelRefBlock*>(block);

    const mdlref::ModelBlockGraphicalIntrfInfo& graphInfo
        = mdlRefBlk->getModelBlockGraphicalIntrfInfo();

    return graphInfo.getLoadStatus() == mdlref::MDLREF_PROTECTED_MODEL_INCOMPATIBILITY;
}



SIMULINK_EXPORT_FCN 
bool isLinked(const SLBlock *block)
{
    return block->getRootBPI()->getGrIsBlockLinked(block);
}

SIMULINK_EXPORT_FCN 
bool isUserLink(const SLBlock *block)
{
    return BreakLinksHelper::isUserLink(block);
}


SIMULINK_EXPORT_FCN
SLBlock* getLinkedBlock(const SLBlock* block)
{
    return fullpath_to_block(slsvString(block->getRootBPI()->getReferenceBlock(block)));
}

SIMULINK_EXPORT_FCN 
bool isImplicitLinked(const SLBlock *block)
{
    return BlockIsImplicitLink(block);
}

SIMULINK_EXPORT_FCN 
bool isInactiveLinked(const SLBlock *block)
{
    return block->getRootBPI()->getGrIsBlockInactiveLink(block);
}

SLBlock * nearestQuasiLinkedParent(const SLBlock *block)
{
    return SLRootBlockPlatformInfo::FindNearestQuasiLinkedParent(block);
}

SIMULINK_EXPORT_FCN 
bool isUnresolvedObject(const SLBlock *block)
{
    return block->getBlockType() == SL_REFERENCE_BLOCK || !MLSysBlockMgr::SystemObjectNameResolved(block) ||
        !MLSysBlockMgr::FMUNameResolved(block);
}

//SIMULINK_EXPORT_FCN 
//bool containsViewableSubsystems(const SLBlock *block)
//{
//    if(!isSubsystem(block))
//        return false;
//
//    slGraph* graph = get_subsystem_graph(block);
//    Set* blocks = graph->getBlocks();
//    SLBlock* b = nullptr;
//    while ((b = (SLBlock *) utGetNextSetElement(blocks, b)) != nullptr) 
//    {
//        if(BlockIsStateflow(b) || ( (isSubsystem(b) || isModelReference(b)) && !isMasked(b) && !isBlockConfigurableSubsystem(b)))
//            return true;
//    }
//    return false;
//}

SIMULINK_EXPORT_FCN
bool getBlockPortShowsImplicitIterator( const SLBlock* block )
{
    return SLImplicitIterSSUtil::ShowParentDims(block);
}

SIMULINK_EXPORT_FCN 
bool isBusSelectorBlock( const SLBlock* block )
{
    FL_DIAG_ASSERT(block);
    return (block->getBlockType() == SL_BUS_SELECTOR_BLOCK);
}

SIMULINK_EXPORT_FCN
bool isObserverPortBlock(const SLBlock* block)
{
    FL_DIAG_ASSERT(block);
    return (block->getBlockType() == SL_ANONYMOUS_BLOCK && 
        block->getBlockTypeString().equals(USTR("ObserverPort")));
}

SIMULINK_EXPORT_FCN
bool isObserverReference(const SLBlock* block)
{
    FL_DIAG_ASSERT(block);
    return (block->getBlockType() == SL_ANONYMOUS_BLOCK &&
        block->getBlockTypeString().equals(USTR("ObserverReference")));
}

SIMULINK_EXPORT_FCN
bool isConnectivityBrancherBlock(const SLBlock* block)
{
    FL_DIAG_ASSERT(block);
    return ((slGetFeatureValue(PHYSMOD_BUSES) > 0) && (block->getBlockType() == SL_CONN_BRANCHER_BLOCK));
}

SIMULINK_EXPORT_FCN 
bool getBlockPortShowsAsBus( const SLBlock* block )
{
    InternalBlockTypeEnum type = block->getBlockType();
    if (type == SL_INPORT_BLOCK || type == SL_INPORT_SHADOW_BLOCK)
    {
        return !InportGetBusObjectName(block).empty();
    }

    if (type == SL_OUTPORT_BLOCK)
    {
        return !IsOutportBusObjectNameEmpty(block);
    }
    return false;
}

SIMULINK_EXPORT_FCN
bool getBlockIsOutportWithEnsureVirtualStatus( const SLBlock* block )
{
    InternalBlockTypeEnum type = block->getBlockType();
    if (type == SL_OUTPORT_BLOCK)
    {
        const OutportBlock *oPortBlk = static_cast<const OutportBlock *>(block);
        return (oPortBlk->getEnsureOutportIsVirtual() ||
                oPortBlk->getEnsureOutportIsVirtualAfterUpdateDiagram());
    }
    return false;
}

SIMULINK_EXPORT_FCN
bool isRootOutportBlock(const SLBlock * block)
{
    InternalBlockTypeEnum type = block->getBlockType();
    if (type == SL_OUTPORT_BLOCK)
    {
        return (TransformedGraph::getTrueParent(*block) == nullptr);
    }
    return false;
}

SIMULINK_EXPORT_FCN 
bool useNewPortBlockIcons(SLBlock const * block)
{
    return (sl::sysarch::compositePortsFeatIsOn() &&
            block->getIsNumberedPortBlock() &&
            boost::polymorphic_downcast<NumberedPortBlock const *>(block)->getIsComposite());
}

SIMULINK_EXPORT_FCN
bool isCommented( const SLBlock* block )
{
    return( (block->getBPI()->getGrCommented()) != COMMENTED_OFF );
}

SIMULINK_EXPORT_FCN
bool isCommentedThrough(const SLBlock* block)
{
    return (block->getBPI()->getGrCommented()) == COMMENTED_THROUGH;
}

SIMULINK_EXPORT_FCN
bool hasSimulationCallbacks(const SLBlock* block)
{
    return(    !ggb_callback_unicode(block,INIT_CB).empty()
            || !ggb_callback_unicode(block,START_CB).empty()
            || !ggb_callback_unicode(block,PAUSE_CB).empty()
            || !ggb_callback_unicode(block,CONTINUE_CB).empty()
            || !ggb_callback_unicode(block,STOP_CB).empty() );
}
    
SIMULINK_EXPORT_FCN
SubsystemBlockType getBlockSubsystemType( const SLBlock *block )
{
    if( block->getBlockType() != SL_SUBSYSTEM_BLOCK )
        return( NOT_SUBSYSTEM );

    if( isSubsystemBlockSFBased( block ) )
        return( NOT_SUBSYSTEM );

    const auto subsystemBlock = static_cast<const SubsystemBlock *>(block);
    if( subsystemBlock->IsVariantSubsystem() )
        return( VARIANT_SUBSYSTEM );

    if( SLGlue::isBlockConfigurableSubsystem( block ) )
        return( CONFIGURABLE_SUBSYSTEM );

    if ( subsystemBlock->IsDataflowSS() )
        return( DATAFLOW_SUBSYSTEM );
           
    switch( subsystemBlock->getSubsystemType() )
    {
        case SL_ROOT_SYSTEM:
            FL_DIAG_ASSERT_ALWAYS( "block can't have root system" );
            break;
        
        case SL_VIRTUAL_SYSTEM:
            return( VIRTUAL_SUBSYSTEM );

        case SL_ATOMIC_SYSTEM:
        case SL_ATOMIC_SYSTEM_WITH_IC:
            return( ATOMIC_SUBSYSTEM );

        case SL_ENABLE_SYSTEM:
            return( ENABLED_SUBSYSTEM );

        case SL_TRIGGER_SYSTEM:
            return( TRIGGERED_SUBSYSTEM );

        case SL_ENABLE_AND_TRIGGER_SYSTEM:
            return( ENABLED_AND_TRIGGERED_SUBSYSTEM );

        case SL_FUNCTION_CALL_SYSTEM:
            return( FUNCTION_CALL_SUBSYSTEM );

        case SL_IFACTION_SYSTEM:
            return( IF_ACTION_SUBSYSTEM );

        case SL_ITERATOR_SYSTEM:
            return( ITERATOR_SUBSYSTEM );
             
        case SL_INVALID_TYPE_SYSTEM:
            FL_DIAG_ASSERT_ALWAYS("Not a valid subsystem type");
                  
    }

    FL_DIAG_ASSERT_ALWAYS( "unreachable code" );
    return( NOT_SUBSYSTEM );
}

SIMULINK_EXPORT_FCN
PortBlockType getBlockPortBlockType( const SLBlock *block )
{
    PortBlockType   result = NOT_PORT_BLOCK;
    
    switch( block->getBlockType() )
    {
        case SL_INPORT_BLOCK:
            result = INPORT_BLOCK;
        break;
        
        case SL_INPORT_SHADOW_BLOCK:
            result = SHADOW_INPORT_BLOCK;
        break;
        
        case SL_ARGIN_BLOCK:
            result = FCNCALL_ARGIN_BLOCK;
        break;

        case SL_OUTPORT_BLOCK:
            result = OUTPORT_BLOCK;
        break;
        
        case SL_ARGOUT_BLOCK:
            result = FCNCALL_ARGOUT_BLOCK;
        break;
        
        default:
            if( ControlPortMgr::IsControlPortBlock(block) )
                result = CONTROL_PORT_BLOCK;
            else if( SlConnportBlk::isConnportBlk(block) )
            {
                const SlConnportBlk *connPortBlock = static_cast<const SlConnportBlk *>(block);
                
                BlockSide side = connPortBlock->getPortSide();

                // Init to unknown in case side is corrupted. Code used to do size == -1 which
                // produced a compile warning.
                    result = UNKNOWN_CONNECTION_PORT_BLOCK;
                switch (side) {
                        case LEFT_SIDE:
                            result = LEFT_CONNECTION_PORT_BLOCK;
                        break;
                    
                        case RIGHT_SIDE:
                            result = RIGHT_CONNECTION_PORT_BLOCK;
                        break;
                    
                        case UNKNOWN_SIDE:
                            result = UNKNOWN_CONNECTION_PORT_BLOCK;
                        break;
                    }
                }
        break;
    }
    
    return( result );                
}

SIMULINK_EXPORT_FCN
int getBlockPortNumber( const SLBlock *block )
{
    switch( getBlockPortBlockType(block) )
    {
        case INPORT_BLOCK:
        case SHADOW_INPORT_BLOCK:
            return( GetInputPortNumber( block ) );
        
        case OUTPORT_BLOCK:
            return( GetOutputPortNumber( block ) );
        
        case FCNCALL_ARGIN_BLOCK:        
        case FCNCALL_ARGOUT_BLOCK:
          return( static_cast<const NumberedPortBlock*>( block )->
                  getPortNumber());

        case LEFT_CONNECTION_PORT_BLOCK:
        case RIGHT_CONNECTION_PORT_BLOCK:
        case UNKNOWN_CONNECTION_PORT_BLOCK:
            return( static_cast<const SlConnportBlk *>(block)->getPortNumber() );
        
        case NOT_PORT_BLOCK:
        case CONTROL_PORT_BLOCK:
          /* Do nothing */
        break;
    }
    
    return( -1 );
}

SIMULINK_EXPORT_FCN
PortBlockSide getBlockPortSide( const SLBlock *block )
{
    switch( getBlockPortBlockType(block) )
    {
        case LEFT_CONNECTION_PORT_BLOCK:
            return( PORT_BLOCK_LEFT_SIDE );
        
        case RIGHT_CONNECTION_PORT_BLOCK:
            return( PORT_BLOCK_RIGHT_SIDE );
        
        case UNKNOWN_CONNECTION_PORT_BLOCK:
            return( PORT_BLOCK_UNKNOWN_SIDE );
        
        case INPORT_BLOCK:
        case FCNCALL_ARGIN_BLOCK:
        case SHADOW_INPORT_BLOCK:
        case OUTPORT_BLOCK:
        case FCNCALL_ARGOUT_BLOCK:
        case NOT_PORT_BLOCK:
        case CONTROL_PORT_BLOCK:
            FL_DIAG_ASSERT_ALWAYS( "getBlockPortSide() called on non connection port block" );
        break;
    }
    
    FL_DIAG_ASSERT_ALWAYS( "unreachable code" );
    return PORT_BLOCK_UNKNOWN_SIDE;
}

SIMULINK_EXPORT_FCN
void setBlockPortSide( SLBlock *block, PortBlockSide side )
{
    FL_DIAG_ASSERT( side == PORT_BLOCK_LEFT_SIDE || side == PORT_BLOCK_RIGHT_SIDE );
    FL_DIAG_ASSERT( SlConnportBlk::isConnportBlk(block) );
    
    BlockSide slSide = LEFT_SIDE;
    
    switch( side )
    {
        case PORT_BLOCK_LEFT_SIDE:
            slSide = LEFT_SIDE;
        break;
    
        case PORT_BLOCK_RIGHT_SIDE:
            slSide = RIGHT_SIDE;
        break;
    
        default:
            FL_DIAG_ASSERT_ALWAYS( "setBlockPortSide() called with unknown side" );
        break;
    }

    SlConnportBlk *connPortBlock = static_cast<SlConnportBlk*>(block);
    
    slsvDiagnostic errmsg = connPortBlock->setSideOnParentSS( slSide );
    (void)errmsg; // when NDEBUG defined
    FL_DIAG_ASSERT( errmsg == SLSV_NoDiagnostic );
    
    block->setGrEnumParamValue(1, slSide);
}

SIMULINK_EXPORT_FCN
void renumberPort(SLBlock *portBlock, int newIndex)
{
    FL_DIAG_ASSERT(getRepresentedPort(portBlock) != nullptr);
    NumberedPortBlock *numberedPortBlock = boost::polymorphic_downcast<NumberedPortBlock *>(portBlock);
    sl::interfaceModel::modify::renumberPort(portBlock->getBPI()->getGrOwner(),
                                                            *numberedPortBlock->getInterfaceRealizationType(),
                                                            numberedPortBlock->getPortNumber(), newIndex, false);
}

SIMULINK_EXPORT_FCN
bool requiresMorphOnDelete( const SLBlock *block )
{
    if( block->getBlockType() != SL_INPORT_BLOCK )
        return( false );
        
    // if we have any shadow inports, we can morph
    Set *set = getBlockShadowPortBlocks(block);
    
    return( set != nullptr && utGetNumElementsInSet(set) > 0 );
}

SIMULINK_EXPORT_FCN
slPort *getRepresentedPort( const SLBlock *block )
{
    slGraph     *blockGraph = getBlockGraph( block );
    FL_DIAG_ASSERT( blockGraph != nullptr );
    
    SLBlock     *subsystemBlock = blockGraph->getOwner();
    
    if( subsystemBlock == nullptr )
        return( nullptr );

    if (sl::sysarch::compositePortsFeatIsOn()
        && block->getIsNumberedPortBlock()
        && !boost::polymorphic_downcast<NumberedPortBlock const *>(block)->getInterfaceModelBlock()) {
        // Return nullptr for numbered port blocks that are not part of the interface
        return nullptr;
    }

    slPort *result = nullptr;
    
    switch( block->getBlockType() )
    {
        case SL_INPORT_BLOCK:
        // case SL_INPORT_SHADOW_BLOCK:
        // No need to do this for shadow inport here, and in fact causes problems
        // during delete of shadow inports. See g694174.
            result = ggb_input_port( subsystemBlock, GetInputPortNumber(block)-1 );
        break;

        case SL_OUTPORT_BLOCK:
            result = ggb_output_port( subsystemBlock, GetOutputPortNumber(block)-1 );
        break;

        default:
            if( ControlPortMgr::IsControlPortBlock(block) )
            {
                const ControlPortBlock *ctrlPortBlk = static_cast<const ControlPortBlock *>(block);
            
                result = ctrlPortBlk->getParentSubsystPort(subsystemBlock);
            }
            else if( SlConnportBlk::isConnportBlk(block) )
            {
                result = static_cast<SubsystemBlock *>(subsystemBlock)->getPortGivenConnport(static_cast<const SlConnportBlk *>(block));
            }
        break;
    }
    
    return( result );
}

SIMULINK_EXPORT_FCN
SLBlock *getRepresentedPortBlock(slPort *port)
{
    SLBlock *result = nullptr;
    SLBlock *portOwner = port->getGrOwnerBlock();
    if (portOwner->getBlockType() == SL_SUBSYSTEM_BLOCK) {
        const slGraph *graph = static_cast<SubsystemBlock *>(portOwner)->get_subsystem_graph();
        const GraphPortMap &pmap = graph->getGraphPortMap();
        if (ControlPortMgr::IsControlPortObj(port)) {

            ControlPortBlock* ctrlBlk = ControlPortMgr::getControlPortBlockFromPortIndex(static_cast<SubsystemBlock *>(portOwner), port->getIndex());
            
            FL_DIAG_ASSERT( ctrlBlk != nullptr);
            result = ctrlBlk;
        } else {
            switch (port->getType()) {
                case SL_UNKNOWN_PORT:
                    break;
                case SL_INPUT_PORT:
                    result = pmap.getInportBlock(static_cast<size_t>(port->getIndex()));
                    break;
                case SL_OUTPUT_PORT:
                    result = pmap.getOutportBlock(static_cast<size_t>(port->getIndex()));
                    break;
                case SL_CONNECTION_PORT:
                    result = static_cast<const SubsystemBlock *>(port->getGrOwnerBlock())->getConnportGivenSubsystemPort(port);
                    break;
                default:
                    FL_DIAG_ASSERT_ALWAYS("Unknown port type: " + std::to_string(port->getType()));
            }
        }
    }
    return result;
}

SIMULINK_EXPORT_FCN
SLBlock *getBlockMasterPortBlock( const SLBlock *block )
{
    FL_DIAG_ASSERT( block != nullptr );
    
    if( block->getBlockType() == SL_INPORT_BLOCK || block->getBlockType() == SL_INPORT_SHADOW_BLOCK )
    {
        const InportBlock *inportBlk = static_cast<const InportBlock *>(block);

        // put this back once we figure out what's up with test/toolbox/simulink/gui/lines/tline
        //FL_DIAG_ASSERT( (block->getBlockType() == SL_INPORT_BLOCK && inportData->masterInport == nullptr)
        //          || (block->getBlockType() == SL_INPORT_SHADOW_BLOCK && inportData->masterInport != nullptr) );
        
        return( inportBlk->getMasterInport() );
    }
    else
        return( nullptr );
}

SIMULINK_EXPORT_FCN
void setBlockMasterPortBlock( SLBlock *block, SLBlock *masterBlock )
{
    FL_DIAG_ASSERT( block != nullptr );
    FL_DIAG_ASSERT( masterBlock == nullptr || block->getBlockType() == SL_INPORT_BLOCK || block->getBlockType() == SL_INPORT_SHADOW_BLOCK );
    FL_DIAG_ASSERT( masterBlock == nullptr || masterBlock->getBlockType() == SL_INPORT_BLOCK );
    
    // M3I doesn't know about block types, so we can't define
    // this relationship for only inport blocks.  So ignore
    // calls M3I makes for other blocks.
    if( block->getBlockType() != SL_INPORT_BLOCK && block->getBlockType() != SL_INPORT_SHADOW_BLOCK )
        return;
    
    InportBlock *inportBlk = static_cast<InportBlock *>(block);
    InportBlock *oldMaster = inportBlk->getMasterInport();

    // Early return if this would be a no-op.  Needed so
    // we don't mess up the side effects for mask/link info.
    if( block->getBlockType() == SL_INPORT_BLOCK && masterBlock == nullptr )
        return;
    
    if( block->getBlockType() == SL_INPORT_SHADOW_BLOCK && masterBlock == oldMaster )
        return;
    
    inportBlk->setMasterInport(masterBlock);
    
    if( inportBlk->getMasterInport() == nullptr )
    {
        FL_DIAG_ASSERT( oldMaster != nullptr );
        
        // it's now a inport block
        SLBlock::CloneStaticData( block, slBlockRegistry::getDefaultBlock(SL_INPORT_BLOCK) );
    
        // We need to create the shadowed inport set when assigning
        // new master block. Otherwise, while assigning a shadow to 
        // be the new master, slapplication modifies an empty m3i 
        // set that's never associated with the master port. See g699155
        // test case lvlTwo_G224504 for details.
        if( inportBlk->getShadowedInports() == nullptr )
            inportBlk->setShadowedInports(utCreateSet());
    
        // Clone any mask/link from the old master
        // (yes, src/dst are in different orders for these functions)
        if( oldMaster->getBPI()->getGrMask() != nullptr )
        {
            SLMaskInterface *mask = SlGrClasses::smCopyMask( oldMaster, inportBlk );
            mask->setWSDirty(); 
        }
        
        if( oldMaster->getBPI()->getLinkInfo() != nullptr )
            CloneInportLinkInfo( inportBlk, oldMaster );
    }
    else
    {
        // it's now a shadow inport block
        SLBlock::CloneStaticData( block, slBlockRegistry::getDefaultBlock(SL_INPORT_SHADOW_BLOCK) );
    
        // Update port number caches of this inportBlk
        // (They may need to be changed after being inserted to the graph)
        if (sl::sysarch::dataModelFeatIsOn()) {
            inportBlk->updateParamCaches();
        } else {
            inportBlk->setPortNumber(inportBlk->getMasterInport()->getPortNumber());
        }
    
        // Clear any mask/link info
        SLMaskInterface *shadowMask = block->getBPI()->getGrMask();
        if( shadowMask != nullptr )
        {
            delete shadowMask;
            block->getBPI()->setGrMask( nullptr );
        }
        
        block->getBPI()->destroyLinkInfo();
    }

    // Keep the graph sorted correctly, otherwise, unexpected
    // behavior may occur.
    if (!sl::sysarch::dataModelFeatIsOn()) {
        slGraph *graph = block->getBPI()->getGrOwner();
        FL_DIAG_ASSERT(graph != nullptr);
        graph->refreshBlock_internal(PortBlockInfo::INPUT);
    }
}
    
SIMULINK_EXPORT_FCN
Set *getBlockShadowPortBlocks( const SLBlock *block )
{
    FL_DIAG_ASSERT( block != nullptr );
    
    if( block->getBlockType() == SL_INPORT_BLOCK )
    {
        const InportBlock *inportBlk = static_cast<const InportBlock *>(block);
        Set *result = const_cast<Set *>(inportBlk->getShadowedInports());
        
        if( result == nullptr )
        {
            result = utCreateSet();
            const_cast<InportBlock *>(inportBlk)->setShadowedInports( result );
        }
        
        return( result );
    }
    else
        return( nullptr );
}
    
SIMULINK_EXPORT_FCN
void getBlockPortPositioning( SLBlock *block, MG::DRect &blockLocation, std::map<slPort*,PortPlacement> &ports )
{
    getBlockPortPositioning( block, blockLocation, block->getBPI()->getGrBlockTransform()->getRotation(), block->getBPI()->getGrBlockTransform()->getMirror(), block->getBPI()->getGrFlipName(), ports );
}

SIMULINK_EXPORT_FCN
void getBlockPortPositioning( SLBlock *block, MG::DRect &blockLocation, SLBlockOrientationType orientation, bool namePlacement, std::map<slPort*,PortPlacement> &ports )
{
    double rotation = 0;
    bool   mirror   = false;

    SLRootBlock::orientation_to_rotation_mirror_for_default_port_rotation( static_cast<BlockOrientation>(orientation), &rotation, &mirror );

    getBlockPortPositioning( block, blockLocation, rotation, mirror, namePlacement, ports );
}

SIMULINK_EXPORT_FCN
void getBlockPortPositioning( SLBlock *block, MG::DRect &blockLocation, double rotation, bool mirror, bool namePlacement, std::map<slPort*,PortPlacement> &ports )
{
    struct Hijacker
    {
        MG::DRect &m_blockLocation;
        std::map<slPort*,PortPlacement> &m_ports;
        
        // _NAME's to prevent shadow warnings
        Hijacker( SLBlock *_block, MG::DRect &_blockLocation, double _rotation, bool _mirror, bool _namePlacement, std::map<slPort*,PortPlacement> &_ports )
            : m_blockLocation(_blockLocation), m_ports(_ports)
        {
            MWrect mwBlockLocation;

            mwBlockLocation.left = static_cast<int>(_blockLocation.left());
            mwBlockLocation.right = static_cast<int>(_blockLocation.right());

            mwBlockLocation.top = static_cast<int>(_blockLocation.top());
            mwBlockLocation.bottom = static_cast<int>(_blockLocation.bottom());
            
            PortPlacementManager::get()->beginHijack( _block, mwBlockLocation, _rotation, _mirror, _namePlacement );
        }
        
        ~Hijacker( void )
        {
            MWrect mwBlockLocation;
    
            PortPlacementManager::get()->endHijack( mwBlockLocation, m_ports );
            
            m_blockLocation.setLeft( mwBlockLocation.left );
            m_blockLocation.setWidth( mwBlockLocation.right - mwBlockLocation.left );
            m_blockLocation.setTop( mwBlockLocation.top );
            m_blockLocation.setHeight( mwBlockLocation.bottom - mwBlockLocation.top );
        }
    };
    
    Hijacker hijacker(block, blockLocation, rotation, mirror, namePlacement, ports);
    GLEE::DRect rect;
    auto graphicalContext = block->getBlockGraphicalDescriptor().graphicalContext();
    if (PortPlacementManager::get()->m_originalMirror == mirror && PortPlacementManager::get()->m_originalRotation == rotation)
    {
        rect.setTop(PortPlacementManager::get()->m_originalBlockLocation.top);
        rect.setLeft(PortPlacementManager::get()->m_originalBlockLocation.left);
        rect.setBottom(PortPlacementManager::get()->m_originalBlockLocation.bottom);
        rect.setRight(PortPlacementManager::get()->m_originalBlockLocation.right);
        graphicalContext.setPreviousRect(rect);
    }
    else 
    {
        graphicalContext.setPreviousRotation(PortPlacementManager::get()->m_originalRotation);
        graphicalContext.setPreviousMirror(PortPlacementManager::get()->m_originalMirror);
    }
    

    BlockPositionPorts(block, &graphicalContext);
}

SIMULINK_EXPORT_FCN
void blockPositionPorts( SLBlock *block )
{
    FL_DIAG_ASSERT( block != nullptr );

    // TODO (anitschk) (MCW-2957) BlockPositionPorts may call
    // SLGlue::notifyThatPortIsAboutToChange. I have seen some cases with
    // setPortOrientation where this can cause issues with undo/redo. I am
    // worried that there may be similar issues with this method that I just
    // haven't found yet. We should consider implementing a version of
    // SLGlue::blockPositionPorts that does not call
    // SLGlue::notifyThatPortIsAboutToChange. See Jira task MCW-2957 for more
    // discussion

    BlockPositionPorts( block );
} 
    
SIMULINK_EXPORT_FCN
void beginBlockInteractiveDraw( SLBlock *block, const MG::DRect &blockLocation, const boost::optional<InteractivePortLocationMap> &portLocations )
{
    MWrect mwBlockLocation;

    mwBlockLocation.left    = static_cast<int>(blockLocation.left());
    mwBlockLocation.right   = static_cast<int>(blockLocation.right());

    mwBlockLocation.top     = static_cast<int>(blockLocation.top());
    mwBlockLocation.bottom  = static_cast<int>(blockLocation.bottom());

    PortPlacementManager::get()->beginHijack( block, mwBlockLocation, block->getBPI()->getGrBlockTransform()->getRotation(), block->getBPI()->getGrBlockTransform()->getMirror(), block->getBPI()->getGrFlipName() );

    // If we are provided port locations we will hijack the port positions
    // using those locations. Otherwise we will use BlockPositionPorts to
    // determine where ports should go.
    if (portLocations) {
        FL_DIAG_ASSERT(static_cast<std::size_t>(getBlockNumPorts(block)) == portLocations.get().size());
        for (const auto &pair : portLocations.get()) {
            slPort *port = pair.first;
            FL_DIAG_ASSERT(port->getGrOwner() == block);
            const MG::DPoint &location = pair.second;

            // m3i uses a different coordinate system then simulink so we need
            // to use setPortPosition to set the position instead of just
            // directly setting it.
            setPortPosition(port, location);
        }
    } else {
        GLEE::DRect rect;
        rect.setTop(PortPlacementManager::get()->m_originalBlockLocation.top);
        rect.setLeft(PortPlacementManager::get()->m_originalBlockLocation.left);
        rect.setBottom(PortPlacementManager::get()->m_originalBlockLocation.bottom);
        rect.setRight(PortPlacementManager::get()->m_originalBlockLocation.right);

        auto graphicalContext = block->getBlockGraphicalDescriptor().graphicalContext();
        graphicalContext.setPreviousRect(rect);
        BlockPositionPorts( block , &graphicalContext);
    }
}

SIMULINK_EXPORT_FCN
void endBlockInteractiveDraw( SLBlock * )
{
    MWrect mwBlockLocation;
    std::map<slPort*,PortPlacement> ports;
    PortPlacementManager::get()->endHijack( mwBlockLocation, ports );
}

SIMULINK_EXPORT_FCN
void callBlockDeleteFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockPreDeleteCallback(block);
    
    if( errMsg == SLSV_NoDiagnostic ) {
        errMsg = BlockDeleteCallback(block,false);
        slplugin::addDeletedBlockHierarchyToBatcher(block);
    }

    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
void callBlockUndoDeleteFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockUndoDeleteCallback(block);
    
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
void callBlockNameChangeFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockNameChangeCallback(block);
    
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
void callBlockPathChangeFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockPathChangeCallback(block);
    
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
void callBlockMoveFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockMoveCallback(block);
    
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
void callBlockParentCloseFcn( SLBlock *block, GLEE::ErrorHolder &status )
{
    slsvDiagnostic errMsg = BlockParentCloseCallback(block);
    
    if( errMsg != SLSV_NoDiagnostic )
        status = convertSLErrorToErrorHolder( errMsg );
}

SIMULINK_EXPORT_FCN
SLBlock * getBlockFrmHandle( double handle )
{
    FL_DIAG_ASSERT(handle != -1.0);
    return SLBlock::Handle2Block(handle);
}


static void updateBusBlockTooltip(const fl::ustring& inStr,fl::ustring& toolTip)
{
    static const fl::ustring NEWLINE = USTR("\n");
    static const fl::ustring COMMA = USTR(",");
    static const fl::ustring CONTINUATION = USTR("...");
    static const size_t MAX_COUNT = 10;
    
    std::vector<fl::ustring> vecSigs;
    boost::algorithm::split(
        vecSigs, inStr, boost::algorithm::is_any_of(COMMA));
    
    if (!toolTip.empty())
        toolTip.append(NEWLINE);
    
    for (size_t idx = 0; idx < vecSigs.size(); ++ idx) {
        if (!toolTip.empty())
            toolTip.append(NEWLINE);
        
        toolTip.append(vecSigs[idx]);
        if (idx + 1 == MAX_COUNT) {
            toolTip.append(NEWLINE);
            toolTip.append(CONTINUATION);
            break;
        }
    }
}

SIMULINK_EXPORT_FCN 
fl::ustring getBlockToolTip(const SLBlock *block )
{
    fl::ustring toolTip;

    if( block == nullptr)
        return toolTip;
    
    toolTip = gdt_text_from_block( block );
    if (block->getBlockType() == SL_BUS_ASSIGNMENT_BLOCK) {
        fl::ustring assignedStr = 
            BusAssignmentBlock::GetBusAssignedSignalStringU(block);
        updateBusBlockTooltip(assignedStr, toolTip);
    } else if (block->getBlockType() == SL_BUS_SELECTOR_BLOCK) {
        SLBlock *b = const_cast<SLBlock*>(block);
        const fl::ustring& outSignalStr = static_cast<
            BusSelectorBlock *>(b)->GetOutputSignalString();
        updateBusBlockTooltip(outSignalStr, toolTip);
    }
    
    if (SLGlue::getBlockIsOutportWithEnsureVirtualStatus(block)) {
        toolTip =  fl::i18n::MessageCatalog::get_message(
            sl_glue::badges::EnsureOutportIsVirtualTooltip());
    }

    return toolTip;
}

SIMULINK_EXPORT_FCN fl::ustring     getBlockAttributeString(const SLBlock* block)
{
    if (block)  return block->getBPI()->getGrAttributesString();

    return fl::ustring();
}

SIMULINK_EXPORT_FCN bool isPotentialStateOwnerBlock (SLBlock * block)
{
    return block->getGrIsPotentialStateOwnerBlock();
}

SIMULINK_EXPORT_FCN bool isStateOwnerBlock (SLBlock * block)
{
    return block->getGrIsStateOwnerBlock();
}

SIMULINK_EXPORT_FCN bool isStateReadOrWriteBlock (SLBlock * block)
{
    return BlockAccess::AccessUtil::getIsStateReadOrStateWriteBlock(block);
}

static bool hasExternalStateRW(const SLBlock *block) {
    
    // The owner block can get modified through set_param etc.
    if (!block->getGrIsStateOwnerBlock()) return false;
   
    bool retval = false;
    SLRootBD *bd = block->getBPI()->getGrBlockDiagram();
    
    if (bd != nullptr) {
        std::vector<SLBlock*> accBlk = block->getBlockContext()->ctxGetAccessorFromOwnerBlock(block);
        
        if (!accBlk.empty()) {
            retval = true; 
        }
    }
    return retval;
}

SIMULINK_EXPORT_FCN std::vector<fl::ustring> getStateNameForOwnerBlock (SLBlock * ownerBlk)
{
    FL_DIAG_ASSERT(ownerBlk->getGrIsStateOwnerBlock());
   
    std::vector<fl::ustring> stateNameList;
    
    if (hasExternalStateRW(ownerBlk)) {
        if (slGetFeatureValue(AccessingMultipleStatesBlocks) == 0) {
            stateNameList.push_back(ownerBlk->getGrNameString().
                                    getString<fl::ustring::value_type>());
        } else {
            const BlockAccess::ResourceOwnerPropInterface *propInterface = 
                BlockAccess::StateOwnerPropInterfaceRegistry::getInstance()->
                getBlkInterface(ownerBlk);
            FL_DIAG_ASSERT(propInterface != nullptr);
            std::vector<fl::ustring> stateNameFullList = propInterface->
                getOwnerResourceName(ownerBlk);
            
            if (stateNameFullList.size() == 1 && stateNameFullList[0].empty()) {
                stateNameList.push_back(ownerBlk->getGrNameString().
                getString<fl::ustring::value_type>());
            } else if (stateNameFullList.size() == 1 && !stateNameFullList[0].empty()) {
                stateNameList.push_back(stateNameFullList[0]);
            } else {
                for(auto stateName: stateNameFullList) {
                    std::vector<SLBlock*> accBlkList = ownerBlk->getBlockContext()->
                        ctxGetAccessorFromOwnerBlock(ownerBlk, stateName);
                    if (accBlkList.size() > 0) {
                        if (!stateName.empty())
                            stateNameList.push_back(stateName);
                        else 
                            stateNameList.push_back(accBlkList[0]->getAccessorInterface()[0]
                                                ->getResourceName());
                    }
                } 
            }
        }
    }
    
    return stateNameList;
}
   
SIMULINK_EXPORT_FCN fl::ustring getStateNameForAccessorBlock (SLBlock * accBlk)
{
    FL_DIAG_ASSERT(BlockAccess::AccessUtil::getIsStateReadOrStateWriteBlock(accBlk));

    fl::ustring accDisplayName;
    
    if (slGetFeatureValue(AccessingMultipleStatesBlocks) > 0) {
        const SLBlock* ownerBlk = accBlk->getAccessorInterface()[0]->getResourceOwnerBlock();
        if (ownerBlk != nullptr) {
            std::vector<fl::ustring> states = BlockAccess::ResourceOwnerPropInterface::getOwnerResourceName(ownerBlk);
            auto blkType = ownerBlk->getBlockType();
            bool displayBlockAndStateName = blkType == SL_MODELREF_BLOCK ? states.size() > 0 : states.size() > 1;
            if (displayBlockAndStateName) {
                accDisplayName = ownerBlk->getGrNameString().
                    getString<fl::ustring::value_type>();
                accDisplayName.append(USTR("."));
            }
            accDisplayName.append(accBlk->getAccessorInterface()[0]->getResourceName());

            if (accDisplayName.empty()) {                
                if (ownerBlk != nullptr) {
                    accDisplayName = ownerBlk->getGrNameString().
                        getString<fl::ustring::value_type>();
            }
            }
        } else {
            accDisplayName = USTR("?");
        }
    } else {
        accDisplayName.append(accBlk->getAccessorInterface()[0]->getResourceName());
    
        if (accDisplayName.empty()) {
        
            const SLBlock* ownerBlk = accBlk->getAccessorInterface()[0]->getResourceOwnerBlock();
        
            if (ownerBlk != nullptr) {
                accDisplayName = ownerBlk->getGrNameString().
                    getString<fl::ustring::value_type>();
            }
        }
    }
    return  accDisplayName;
}


SIMULINK_EXPORT_FCN void hiliteStateOwnerBlock (SLBlock * block)
{
    FL_DIAG_ASSERT(BlockAccess::AccessUtil::getIsStateReadOrStateWriteBlock(block));

    double ownerBlkH = block->getAccessorInterface()[0]->getResourceOwnerBlockHandle();
    
    SLBlock *ownerBlk = SLBDUtil::handle2block(ownerBlkH);
    if (ownerBlk != nullptr) {
        sluResetBlockAndLineHiliteAncestors(
            ownerBlk->getBPI()->getGrBlockDiagram());
        slGraph *ownerGraph = ownerBlk->getBPI()->getGrOwner();
        if (ownerGraph != nullptr) {
            sluClearAllSelectionsInGraph(ownerGraph);
            ownerBlk->getRootBPI()->setGrSelected(ownerBlk, true);
            ownerBlk->getBPI()->setGrHiliteAncestors(ownerBlk, HILITE_FIND);
            try {
                ownerGraph->open(nullptr);
            } catch (const fl::except::IException&) {
            }
        }
    }
}

SIMULINK_EXPORT_FCN bool isParamOwnerBlock (const SLBlock * block)
{
    return block->getGrIsParamOwnerBlock();
}

SIMULINK_EXPORT_FCN bool isParamReadOrWriteBlock (const SLBlock * block)
{
    return BlockAccess::AccessUtil::getIsParamReadOrParamWriteBlock(block);
}

SIMULINK_EXPORT_FCN bool isParamReadOrWriteBlockAccessingWSVar (const SLBlock * block)
{
    return (isParamReadOrWriteBlock(block) &&
            static_cast<const ParamAccessorBlock *>(block)->getAccessingWorkspaceVariable());
}

static bool hasExternalParamRW(const SLBlock *block) {
    
    // The owner block can get modified through set_param etc.
    if (!block->getGrIsParamOwnerBlock()) return false;
   
    bool retval = false;
    SLRootBD *bd = block->getBPI()->getGrBlockDiagram();
    
    if (bd != nullptr) {
        const auto paramAccessorInfo =  bd->getParamAccessorMgr()->getOwnerAccessorInfo();
        auto resourceNameAccessorMap =
            paramAccessorInfo->findResourceNameAccessorMapGivenOwner(block->getHandle());
        for(auto resourceNameAccessorPair : resourceNameAccessorMap) {
            if(!resourceNameAccessorPair.second.isEmpty()) {
                return true;
            }
        }
    }
    return retval;
}


SIMULINK_EXPORT_FCN fl::ustring getParamNameForOwnerOrAccessorBlock (SLBlock * block)
{
    FL_DIAG_ASSERT(block->getGrIsParamOwnerBlock() ||
                   BlockAccess::AccessUtil::getIsParamReadOrParamWriteBlock(block));
    const SLBlock *ownerBlk = block;
    if (BlockAccess::AccessUtil::getIsParamReadOrParamWriteBlock(block)) {
        auto paramRWBlk = static_cast<ParamAccessorBlock *>(block);
        if(paramRWBlk->getAccessingWorkspaceVariable()) {
            auto paramName = ConvertStdStringToUString(paramRWBlk->getWorkspaceVariableName());
            FL_DIAG_ASSERT(!paramName.empty());
            return paramName;
        } else {
            ownerBlk = block->getAccessorInterface()[0]->getResourceOwnerBlock();
            if (ownerBlk == nullptr) {
                // Try to get the block from the parameter.
                SLParamOwnerNameStringPrmDesc *ownerBlkPrmDesc = 
                    paramRWBlk->getPrmDescs()->mpParamOwnerBlockName.get();
                // Try to build the connection.
                (void)ownerBlkPrmDesc->getUStringValue(block, ownerBlkPrmDesc->getID(), false);
                ownerBlk = block->getAccessorInterface()[0]->getResourceOwnerBlock();
            }
        }
    }
    
    fl::ustring paramName;
    if (ownerBlk != nullptr && hasExternalParamRW(ownerBlk)) {
        // Try to get param name from block dialog parameter.
        paramName = ownerBlk->getGrNameString().
            getString<fl::ustring::value_type>();
        paramName.append(USTR("."));
        std::string selPara = " ";
        if (BlockAccess::AccessUtil::getIsParamReadOrParamWriteBlock(block))
            selPara = block->getAccessorInterface()[0]->getAccessorParameterName();
        
        /*if the parameter for the current block is not selected, then get a default one
          from the parameter list of the block, (for subsystem block and model reference block, 
          it will be set as " ", and it need to implement some new function to do get a default
          name)
        */
        if (selPara == " " && !isSubsystem(ownerBlk) && !IsModelRefBlock(ownerBlk))
            selPara =  ownerBlk->getAccessiblePrmDesc()->getNameStr();
        paramName.append(ConvertStdStringToUString(selPara));
    }

    return paramName;
}

SIMULINK_EXPORT_FCN void hiliteParamOwnerBlock (SLBlock * block)
{
    FL_DIAG_ASSERT(BlockAccess::AccessUtil::getIsParamReadOrParamWriteBlock(block));

    double ownerBlkH = block->getAccessorInterface()[0]->getResourceOwnerBlockHandle();
    
    SLBlock *ownerBlk = SLBDUtil::handle2block(ownerBlkH);
    if (ownerBlk != nullptr) {
        sluResetBlockAndLineHiliteAncestors(
            ownerBlk->getBPI()->getGrBlockDiagram());
        slGraph *ownerGraph = ownerBlk->getBPI()->getGrOwner();
        if (ownerGraph != nullptr) {
            sluClearAllSelectionsInGraph(ownerGraph);
            ownerBlk->getRootBPI()->setGrSelected(ownerBlk, true);
            ownerBlk->getBPI()->setGrHiliteAncestors(ownerBlk, HILITE_FIND);
            try {
                ownerGraph->open(nullptr);
            } catch (const fl::except::IException&) {
            }
        }
    }
}

SIMULINK_EXPORT_FCN std::vector<fl::ustring> getParamNameForOwnerBlock (SLBlock * ownerBlk)
{
    std::vector<fl::ustring> paramNameList;

    if (!ownerBlk->getGrIsParamOwnerBlock()) return paramNameList;
   
    SLRootBD *bd = ownerBlk->getBPI()->getGrBlockDiagram();
    if (bd != nullptr) {
        const auto paramAccessorInfo =  bd->getParamAccessorMgr()->getOwnerAccessorInfo();
        auto resourceNameAccessorMap =
            paramAccessorInfo->findResourceNameAccessorMapGivenOwner(ownerBlk->getHandle());
        for(auto resourceNameAccessorPair : resourceNameAccessorMap) {
            // Obtain the model argument display name (including model args promoted from sub-models)
            if (ownerBlk->getBlockType() == SL_MODELREF_BLOCK) {
                fl::ustring paramDisplayName;
                resourceNameAccessorPair.second.forEachAccessorBlock(
                    [&paramDisplayName] (SLBlock *blk) {
                        if (paramDisplayName.empty()) {
                            paramDisplayName = ConvertStdStringToUString(
                                static_cast<ParamAccessorBlock*>(blk)->getParameterDisplayName());
                        }  
                    });
                paramNameList.push_back(paramDisplayName);
            } else {
                paramNameList.push_back(resourceNameAccessorPair.first);
            }
         }
    }
    
    return paramNameList;
}    
    
SIMULINK_EXPORT_FCN
bool isDisplay ( SLBlock * block)
{
    return block->getBlockType() == SL_DISPLAY_BLOCK;
}

SIMULINK_EXPORT_FCN 
DispBlockInpValues getDisplayBlockInpValues (SLBlock * block)
{
    DispBlockInpValues inpValues;
    static_cast<DisplayBlock*>(block)->FetchInputValues(inpValues);
    return inpValues;
}

SIMULINK_EXPORT_FCN 
bool isClockBlock ( SLBlock * block)
{
    return block->getBlockType() == SL_CLOCK_BLOCK;
}

// isEventStorageBlock ===================================================
/**
 * @brief Determines if a block is an event domain storage block which
 *        includes generators, servers, queues, and sinks.  
 */
SIMULINK_EXPORT_FCN 
bool isEventStorageBlock (const SLBlock * block)
{
    // Feature control
    if (slGetFeatureValue(NewDES) == 0) {
        return false;
    }

    if (block->getBlockSuperType() == BLOCK_SUPER_TYPE_DOMAIN_BLOCK)
    {
        const DomainBlockBase * domainBlk = static_cast<const DomainBlockBase*>(block);
        return domainBlk->GetIsEventStorageBlock();
    }

    return false;
}

// getEventStorageStatLabel ==============================================
/**
 * @brief Given a logical port index, return the statistics label of
 *        an event block.
 */
SIMULINK_EXPORT_FCN
std::string getEventStorageStatLabel(const SLBlock * block, int logicalIdx)
{
    FL_DIAG_ASSERT(isEventStorageBlock(block));
    const DomainBlockBase * domainBlk = static_cast<const DomainBlockBase*>(block);
    return domainBlk->GetDomainStatLabel(logicalIdx);
}

SIMULINK_EXPORT_FCN 
bool isModelMaskBlock(const SLBlock* pBlock)
{
    return pBlock->getBlockType() == SL_MODEL_MASK_BLOCK;
}

SIMULINK_EXPORT_FCN 
double getClockBlockTime(SLBlock * block)
{
    return get_clock_block_time(block);
}

SIMULINK_EXPORT_FCN 
bool getClockBlockDisplayTime(SLBlock * block)
{
    return get_clock_block_display_time(block);
}

SIMULINK_EXPORT_FCN const mxArray * getBlockUserData(const SLBlock * block)
{
    return block->getGrUserData();
}


SIMULINK_EXPORT_FCN 
double getChartFromBlock (double handle)
{
    FL_DIAG_ASSERT((SLBlock::Handle2Block(handle)) != 0);
    FL_DIAG_ASSERT(BlockIsStateflow((SLBlock::Handle2Block(handle))) == true);

    mxArray* plhs[1] = { nullptr };        

    MxArrayScopedPtr rhs0(mxCreateString("block2chart"));
    MxArrayScopedPtr rhs1(mxCreateDoubleScalar(handle));

    mxArray* prhs[] = {rhs0.get(), rhs1.get()};

    bool success = (inCallFcnWithTrap(1, plhs, 2, prhs, "sfprivate", true) == 0);

    double chartId = -1.0;
    if(success)
    {
        FL_DIAG_ASSERT(plhs[0] && mxIsDouble(plhs[0]));
        chartId = *mxGetPr(plhs[0]);
    }

    mxDestroyArray(plhs[0]);
    return chartId;

}

SIMULINK_EXPORT_FCN
bool chartHasChildren(double handle)
{   
    if (BlockIsStateflow(SLBlock::Handle2Block(handle)) == false)
      return false;
    double chartId = SLGlue::getChartFromBlock(handle);

    bool hasChildren = false;
    

    slsvDiagnostic d = slsvFEVAL_NoThrow ("sfprivate",InArguments("chart_has_children", chartId), OutArguments(hasChildren));
    
    if(d != SLSV_NoDiagnostic) slsvThrowIExceptionFromDiagnostic(d);

    return hasChildren;
}


bool isSLFcnBlock (const SLBlock *block)
{
    if (block->getRootBPI()->getGrIsEmptyReferenceBlock(block) && block->getBlockType() == SL_SUBSYSTEM_BLOCK)
    {
        TriggerPortBlock* const trigPortBlk = static_cast<const SubsystemBlock*>(block)->getTriggerPortBlock();
        if (trigPortBlk)
        {        
            if (GetBlockTriggerType(trigPortBlk) == FUNCTION_CALL)
            {   
                return true;               
            }
        }
    }
    return false;
}

SIMULINK_EXPORT_FCN    
bool isPanelVertical(const SLBlock *blk)
{
    const SLRootBD *bd = blk->getBPI()->getGrBlockDiagram();
    FL_DIAG_ASSERT(bd);
    return(!gbd_deployment_HideTaskDetails(bd));
}

SIMULINK_EXPORT_FCN bool isBlockWithinSubsystemHierarchy (double blockH, double subsysH)
{
    slGraph * parent      = handle2graph(subsysH);
    SLBlock * ownerBlock  = SLGlue::getGraphOwner(parent);
    SLBlock * searchBlock = (SLBlock::Handle2Block(blockH));
    slGraph * searchGraph = static_cast<SubsystemBlock*>(searchBlock)->get_subsystem_graph ();

    FL_DIAG_ASSERT(parent && ownerBlock && searchGraph && searchBlock);

    while ( parent && ownerBlock && (!SLGlue::isARootGraph (parent)) )
    {
        if (parent == searchGraph)
        {
            return true;
        }
        // Keep on going up in a tree, till you hit the top graph or
        // your owner is the search block.                    
        // see if this block is the search block.
        if (ownerBlock == searchBlock)
        {
            return true;
        }

        // Get this graph's block owner for the next run. Easier to traverse with a
        // block, graph combo.
        parent = SLGlue::getBlockGraph (ownerBlock);
        ownerBlock = SLGlue::getGraphOwner (parent);        
    }

    return false;
}

SIMULINK_EXPORT_FCN bool isNonGraphical(const SLBlock* b)
{
    return IsNonGraphical(b);
}

SIMULINK_EXPORT_FCN
double getBlockDiagramHandle (const SLBlock *block )
{
    const SLRootBD *bd = block->getBPI()->getGrBlockDiagram();
    FL_DIAG_ASSERT(bd);
    
    return( (bd)->getHandle() );
}

SIMULINK_EXPORT_FCN
std::string getTaskTransitionImagePath (const slPort *port )
{
    return(mds::getTaskTransitionImagePath(port));
    
}

SIMULINK_EXPORT_FCN 
bool isModelRefTarget(SLRootBD* bd)
{
    return (bd->isModelReferenceTarget());
}

SIMULINK_EXPORT_FCN 
std::string getResetIdentifierFromResetSubsystem(const SLBlock* block)
{
    if (static_cast<const SubsystemBlock *>(block)->IsInitializeSubsystem()) {
        return "initialize";
    } else if(static_cast<const SubsystemBlock *>(block)->IsTerminateSubsystem()) {
        return "terminate";
    } else if (static_cast<const SubsystemBlock *> (block)->IsRunFirstSubsystem()) {
        return "First";
    } else if (static_cast<const SubsystemBlock *> (block)->IsRunLastSubsystem()) {
        return "Last";
    } else if (static_cast<const SubsystemBlock *> (block)->IsBroadcastFunction()) {
        return "message";
    } else {
        return static_cast<const SubsystemBlock *>(block)->getResetIdentifier();
    }
}

SIMULINK_EXPORT_FCN
slsvDiagnostic setResetIdentifierFromResetSubsystem( SLBlock *block, const fl::ustring name)
{
    slsvDiagnostic errorMsg = SLSV_NoDiagnostic;
    try {
        errorMsg = static_cast<SubsystemBlock *>(block)->setResetIdentifier(name);
    } catch (const fl::except::IException &e) {
        errorMsg = slsvCreateDiagnosticFromIException(e);
    }
    return errorMsg;
}

SIMULINK_EXPORT_FCN 
std::string getFunctionPrototypeFromSLFunction(const SLBlock* block)
{
    return SlFcnCallUtil::CreateSimulinkFunctionPrototype(block);
}

SIMULINK_EXPORT_FCN
slsvDiagnostic setFunctionBlockPrototypeString( SLBlock *block, const fl::ustring name)
{
    slsvDiagnostic errorMsg = SLSV_NoDiagnostic;
    errorMsg = SubsystemBlock::set_function_prototype_string( block, name, 0 );
    return errorMsg;
}

SIMULINK_EXPORT_FCN 
void syncArgumentBlocksWithPrototype(SLBlock *ssblock, GLEE::ErrorHolder &status)
{
    slsvDiagnostic errorMsg = SLSV_NoDiagnostic;
    errorMsg = SlFcnCallUtil::SyncArgumentBlocksWithPrototype(
        static_cast<SubsystemBlock *>(ssblock));

    if( errorMsg != SLSV_NoDiagnostic )
    {
        // Assuming that in case of an error, some argument's attributes could
        //    not be set   
        status = convertSLErrorToErrorHolder( errorMsg );
        return;
    }

}

SIMULINK_EXPORT_FCN
SlFcnCallArgSpecs* getArgumentSpecificationFromSubsys(SLBlock* block)
{
    return (static_cast<SubsystemBlock*>(block)->getArgumentSpecifications());
}

// BlockSimulationDataAccessorRegistry class

bool BlockSimulationDataAccessorRegistry::hasAccessor(const fl::ustring &blockType) const
{
    boost::unordered_map<fl::ustring, BlockSimulationDataAccessorRegistry::BLockSimulationDataHooks>::const_iterator it =  m_emitters.find(blockType);

    return (it != m_emitters.end());
}

BlockSimulationDataAccessorRegistry::BLockSimulationDataHooks &BlockSimulationDataAccessorRegistry::getBlockDataAccessor(const fl::ustring &blockType)
{
    return m_emitters[blockType];
}

void BlockSimulationDataAccessorRegistry::setBlockDataAccessor(const fl::ustring &blockType, BlockSimulationDataAccessorRegistry::BLockSimulationDataHooks &accessor)
{
    m_emitters[blockType] = accessor;
}

BlockSimulationDataAccessorRegistry *BlockSimulationDataAccessorRegistry::get()
{
    static BlockSimulationDataAccessorRegistry *registry = nullptr;

    if (registry == nullptr)
    {
        registry = new BlockSimulationDataAccessorRegistry();
    }

    return registry;
}

SIMULINK_EXPORT_FCN const slio::core::utils::SignalDescriptor *getSignalDescriptor(SLRootBD *bd, slPort *port)
{
    auto* const instance = slsim::getSimulationExecutionInstance(bd);
    if (instance)
    {
        auto catalogue = instance->simArtifacts().accessorCatalogue();
        if (catalogue) {
            return catalogue->getSignalDescriptor(port);
        }
    }

    return nullptr;
}

SIMULINK_EXPORT_FCN void addDataClient(slio::core::client::Client *client, SLRootBD *bd, slPort *port)
{
    auto portOwnerExec = bd->getExecBd();
    if (portOwnerExec)
    {
        auto* const instance = slsim::getSimulationExecutionInstance(bd);
        if (instance)
        {
            instance->addClient(port, slio::core::client::Client::UniquePtr{ client });
        }
    }
}

SIMULINK_EXPORT_FCN fl::ustring formatData(const void* valuePtr,
    int dataTypeId,
    SLValueLabelDisplayOptions::FloatFormat fltFmt,
    SLValueLabelDisplayOptions::FixedFormat fxpFmt,
    const SLBlock* block)
{
    if (block && block->getBPI() && block->getBPI()->getGrOwner())
    {
    const char *str = sletrace::disp::GetFormattedStringFromValue(valuePtr, dataTypeId, false, fltFmt, fxpFmt, block);
    slsv::uostringstream label;
    label << ConvertAscii8StringToUString(str);
    return label.str();
}

    return fl::ustring();
}

SIMULINK_EXPORT_FCN MG::Color getBlockRealForeGroundColor(const SLBlock *block)
{
    ColorPtr cptr = block->graphical.display.foregroundColor->getColorPtr();
    return MG::Color(cptr->r, cptr->g, cptr->b);
}

SIMULINK_EXPORT_FCN
GLEE::Color getSimulinkFunctionTriggerPortBlockColor(SLBlock* block)
{
    return getBlockForegroundColor(static_cast<SubsystemBlock*>(block)->getTriggerPortBlock());
}


const fl::ustring& getReferenceBlock(const SLBlock* block)
{
    return block->getRootBPI()->getReferenceBlock(block);
}

const fl::ustring getReferenceBlockErrMsgForDialog(const SLBlock* block)
{
    FL_DIAG_ASSERT(block->getBlockType() == SL_REFERENCE_BLOCK);
    return static_cast<ReferenceBlock*>(const_cast<SLBlock*>(block))->getDialogMessage();
}

SIMULINK_EXPORT_FCN bool getBlockHasReferenceBlock(const SLBlock* block)
{
    const fl::ustring& referenceBlock = block->getRootBPI()->getReferenceBlock(block);
    return !referenceBlock.empty();
}

const fl::ustring& getAncestorBlock(const SLBlock* block)
{
    return block->getRootBPI()->getGrAncestorBlock(block);
}

SIMULINK_EXPORT_FCN bool getBlockUserDataDouble(const SLBlock* block, double& userDataDouble)
{
    const mxArray* userData = block->getGrUserData();

    if (userData == nullptr || !mxIsScalar(userData))
    {
        return false;
    }

    userDataDouble = mxGetScalar(userData);
    return true;
}

SIMULINK_EXPORT_FCN void updateCommentOutStyling(SLBlock * block)
{
    FL_DIAG_ASSERT(block != nullptr);
    std::vector<double> segmentHandles;
    getSegmentHandles(block, &segmentHandles);
    diagram::style::Styler* commentedOutStyler = getOrCreateCommentedOutStyler();
    if (isCommented(block)) 
    {
        commentedOutStyler->applyClass(block->getHandle(), getCommentedOutElementTagStyleId());
        if (!isCommentedThrough(block))
        {
            for (double segHandle: segmentHandles)
            {
                const diagram::Object& obj = diagram::resolver::resolve(segHandle);
                if (gseg_owner(handle2segment(segHandle))->getLineType() == SL_CONNECTION)
                {
                    commentedOutStyler->applyClass(segHandle, getCommentedOutElementTagStyleId());
                }
                else
                {
                    commentedOutStyler->applyClass(obj.getParent(), getCommentedOutElementTagStyleId());
                }
                
            }
        }
    } 
    else 
    {
        commentedOutStyler->removeClass(block->getHandle(), getCommentedOutElementTagStyleId());
        for (double segHandle: segmentHandles)
        {
            slSegment* segment = handle2segment(segHandle);
            if (gseg_owner(segment)->getLineType() == SL_CONNECTION)
            {
                // get dst and src block, only remove class if both are not commented out
                bool removeStyle = true;

                slPort* srcPort = segment->getRootSourcePort();
                slPort* dstPort = segment->getDestinationPort();

                if (removeStyle && srcPort != nullptr )
                {
                    if(srcPort->getGrIsBlockOwner() && isCommented(srcPort->getGrOwnerBlock()))
                    {
                        removeStyle = false;
                    }
                }

                if (removeStyle && dstPort != nullptr )
                {
                    if(dstPort->getGrIsBlockOwner() && isCommented(dstPort->getGrOwnerBlock()))
                    {
                        removeStyle = false;
                    }
                }
                
                if (removeStyle)
                {
                    commentedOutStyler->removeClass(segHandle, getCommentedOutElementTagStyleId());
                }
            }
            else
            {
                const diagram::Object& obj = diagram::resolver::resolve(segHandle);
                commentedOutStyler->removeClass(obj.getParent(), getCommentedOutElementTagStyleId());
            }
        }
    }
}

static PortsDataForParamChangesCommand::PortsVecT getPortsVec(const slPortVector& v)
{
    PortsDataForParamChangesCommand::PortsVecT portsVec;
    for(size_t i = 0; i < v.getNumPorts(); i++) {
        portsVec.push_back(v.getPort(static_cast<int>(i)));
    }
    return portsVec;
}

SIMULINK_EXPORT_FCN
PortsDataForParamChangesCommand getPortsDataForUndoRedoOfParamChanges(double blockH)
{
    PortsDataForParamChangesCommand portsData;
    
    if (SLParamChangesCommandService::IsActive()) {
        SLBlock *block = (SLBlock::Handle2Block(blockH));
        
        FL_DIAG_ASSERT_MSG(block, "Invalid block handle in getting ports data for param changes undo/redo command");
        
        bool inParamChangesCtx = block && IsObjectInParamChangesCommandCtxt(blockH);
        
        FL_DIAG_ASSERT_MSG(inParamChangesCtx, "Block not in param changes context");
        
        if (inParamChangesCtx) {
            // 1. Cache ports with correct order as the order restored by M3I
            // after undo/redo may not be correct due to some clients moving ports
            // to the end of the lusts before being actually removed.
            // Refer: DeleteBlockInputPorts and DeleteBlockOutputPorts
            
            // inports
            for (slPort* port : block->getGrInputPorts()) {
                portsData.inports.push_back(port);
                    }
            
            // outports
            for (slPort* port : block->getGrOutputPorts()) {
                portsData.outports.push_back(port);
                }
            
            // 2. Cache 'graphical to order indices map vectors'
            
            // inports
            if (block->mGrInpPortIdxToInpPortOrderIdx) {
                portsData.inportsGrIdx2OrderIdxVec = *(block->mGrInpPortIdxToInpPortOrderIdx);
            }
            
            // outports
            if (block->mGrOutPortIdxToOutPortOrderIdx) {
                portsData.outportsGrIdx2OrderIdxVec = *(block->mGrOutPortIdxToOutPortOrderIdx);
            }
        }
    }
    
    return portsData;
}

SIMULINK_EXPORT_FCN
bool setPortsDataOnUndoRedoOfParamChanges(double blockH, const PortsDataForParamChangesCommand& portsData)
{
    bool result = true;
    if (SLParamChangesCommandService::IsActive()) {
        SLBlock *block = (SLBlock::Handle2Block(blockH));
        
        FL_DIAG_ASSERT_MSG(block, "Invalid block handle in setting ports data during param changes undo/redo");
        
        bool inUndoRedoCtx = block && IsObjectInParamChangesCommandUndoRedoCtxt(blockH);
        
        FL_DIAG_ASSERT_MSG(inUndoRedoCtx, "Block not in param changes undo/redo context");
        
        if (inUndoRedoCtx) {
            // 1. Check consistency of ports being restored
            
            // Lambda
            // to check consistency of the vector of ports being restored
            static auto checkConsistencyOfPorts =
                []
                (const PortsDataForParamChangesCommand::PortsVecT& portsNow, const PortsDataForParamChangesCommand::PortsVecT& portsSaved) ->
                bool
                {
                    bool isConsistent = true;
                    // 1. check that number must be correct
                    isConsistent = isConsistent && (portsNow.size() == portsSaved.size());
                    
                    // 2. check that the contents are same
                    {
                        PortsDataForParamChangesCommand::PortsVecT sortedPortsNow = portsNow;
                        std::sort(sortedPortsNow.begin(), sortedPortsNow.end());
                        
                        PortsDataForParamChangesCommand::PortsVecT sortedPortsSaved = portsSaved;
                        std::sort(sortedPortsSaved.begin(), sortedPortsSaved.end());
                        
                        isConsistent = isConsistent && (sortedPortsNow == sortedPortsSaved);
                    }
                    
                    return isConsistent;
                };
            
            // inports
            int numInports = block->getGrNumInputPorts();
            result = result && checkConsistencyOfPorts(getPortsVec(block->getGrInputPorts()),
                                                       portsData.inports);
            
            // outports
            int numOutports = block->getGrNumOutputPorts();
            result = result && checkConsistencyOfPorts(getPortsVec(block->getGrOutputPorts()),
                                                       portsData.outports);
            
            // In debug builds, we will assert but
            // in release builds, we will skip updating the ports vector and return false
            // to indicate failure. User will get an error message on completion of undo/redo.
            FL_DIAG_ASSERT_MSG(result, "Invalid list of inports/outports on param changes undo/redo");
            
            // 2. Restore ports with correct order as the order restored by M3I may not be correct
            // due to some clients move ports to the end of the vectors being actually removing
            // Refer: DeleteBlockInputPorts and DeleteBlockOutputPorts

            if (result) {
                auto restorePorts = [](PortsDataForParamChangesCommand::PortsVecT const& fromPorts,
                                       slPortVector& toPorts) {
                    auto fromPortsIt = fromPorts.begin();
                    for (slPort*& p : toPorts) {
                        p = const_cast<slPort*>(*fromPortsIt++);
                    }
                    toPorts.assignPortIndices();
                };

                restorePorts(portsData.inports, block->getGrInputPorts());
                restorePorts(portsData.outports, block->getGrOutputPorts());
            }

            // 3. Restore 'graphical to order indices map vectors'
            
            // Lambda
            // to update 'graphical to indices map vector' in blocks with the copy
            // held in 'port data'.
            // We don't do any consistency checks here as we know that these vectors
            // are not being handled by M3I
            
            static auto updateGr2OrderIndicesVector =
                []
                (std::vector<int> *& indicesNow, const std::vector<int>& indicesSaved)
                {
                    if (indicesNow) {
                        indicesNow->clear();
                        *(indicesNow) = indicesSaved;
                    } else if (indicesSaved.size() > 0) {
                        indicesNow = new std::vector<int>();
                        *(indicesNow) = indicesSaved;
                    }
                };
            
            // inports
            updateGr2OrderIndicesVector(block->mGrInpPortIdxToInpPortOrderIdx, portsData.inportsGrIdx2OrderIdxVec);
            
            // outports
            updateGr2OrderIndicesVector(block->mGrOutPortIdxToOutPortOrderIdx, portsData.outportsGrIdx2OrderIdxVec);
        }
    }
    
    return result;
}

namespace {

// Local helper function to determine if a dialog is slim or not
bool IsSlimDialog(UDInterface *dlgUdi) {

    UDErrorStatus err = UDErrorStatus();
    char *tag = static_cast<char*>(DAUtils::getUDDProperty(dlgUdi, "dialogTag", err));

    bool ret = utStrncmp(tag, "Simulink:Dialog:Parameters", 26) == 0;

    DAUtils::releaseUDDProperty(dlgUdi, "dialogTag", tag);

    return ret;
}

}

SIMULINK_EXPORT_FCN
std::vector<DialogRestoreInfo> closeAndGetOpenDialogsInfoBeforeUndoRedoOfParamChanges(double blockH)
{
    std::vector<DialogRestoreInfo> dlgRestoreInfos;
    
    using namespace SLParamChangesCommandService;
    if (HasFlagsSet(FeatureFlags::RefreshDDGDialogs)) {
        SLBlock *block = (SLBlock::Handle2Block(blockH));
        FL_DIAG_ASSERT_MSG(block, "Invalid block handle for refreshing dialogs");
        
        if (block) {
            UDInterface  *dlgUDI = nullptr;
            // 1. Intrinsic and Mask dialogs
            const DialogType all_DialogTypes[3] = {PROPERTY_DIALOG, INTRINSIC_DIALOG, MASK_DIALOG};
            for(DialogType dlgType : all_DialogTypes) {
                if ((dlgType == INTRINSIC_DIALOG) || (dlgType == MASK_DIALOG)) {
                    SLDialogData* dlgData = SLDialogData::getDialogData(block, dlgType);
                    if (dlgData) {
                        // This dialog may have invalid changes tried e.g. during auto rollback of
                        // parameter changes command.
                        // Closing such dialogs will call their 'close callback' and that can muck
                        // with the modeled changes.
                        // It should not be allowed to keep safe the remaining undo stack.
                        dlgData->setHasInvalidChange(false);
                        
                        // first deal with ME dialog or Slim dialog
                        dlgUDI = dlgData->getEmbeddedDialogUDI();
                        if (dlgUDI != nullptr) {
                            // Do not close Slim Dialog
                            if (!IsSlimDialog(dlgUDI)) {
                                // For ME dialog, only destroy. It will be restored automatically by Model Explorer later
                                dlgUDI->destroy(UDDatabaseClient::getInternalClient());
                            }
                        }
                        
                        dlgUDI = dlgData->getStandaloneDialogUDI();
                        if (dlgUDI) {
                            DialogRestoreInfo dlgRestoreInfo;
                            dlgRestoreInfo.dlgType = dlgType;
                            
                            MWrect pos;
                            slGetDialogSize(dlgUDI, &pos);
                            dlgRestoreInfo.left = pos.left;
                            dlgRestoreInfo.top = pos.top;
                            
                            dlgRestoreInfos.push_back(dlgRestoreInfo);
                            
                            dlgUDI->destroy(UDDatabaseClient::getInternalClient());
                        }
                    }
                } else {
                    // 2. Properties dialog even though refreshes correctly
                    //    needs to be closed for consistency
                    dlgUDI = BlockPropertiesHashTable::getGrIndexedDialogUdi(block,PROPERTY_DIALOG);
                    if (dlgUDI) {
                        DialogRestoreInfo dlgRestoreInfo;
                        dlgRestoreInfo.dlgType = PROPERTY_DIALOG;
                        if(DAUtils::callBoolMethod(dlgUDI, "isStandAlone")) {
                            MWrect pos;
                            slGetDialogSize(dlgUDI, &pos);
                            dlgRestoreInfo.left = pos.left;
                            dlgRestoreInfo.top = pos.top;
                            
                            dlgRestoreInfos.push_back(dlgRestoreInfo);
                        }
                        
                        dlgRestoreInfos.push_back(dlgRestoreInfo);
                        
                        DestroyBlkPropertiesDialog(block);
                    }
                }
            }
        }
    }
    
    return dlgRestoreInfos;
}

// Function to restore DDG dialogs on undo/redo of dialog parameter changes
SIMULINK_EXPORT_FCN
void restoreDialogsAfterUndoRedoOfParamChanges(double blockH, std::vector<DialogRestoreInfo> dlgRestoreInfos)
{
    using namespace SLParamChangesCommandService;
    if (HasFlagsSet(FeatureFlags::RefreshDDGDialogs)) {
        SLBlock *block = (SLBlock::Handle2Block(blockH));
        FL_DIAG_ASSERT_MSG(block, "Invalid block handle for refreshing dialogs");
        if (block) {
            // Need to restore all open dialogs as a given parameter may be visible
            // simultaneously on multiple dialogs
            // Note: This loop is for non-slim dialogs
            UDInterface  *dlgUDI = nullptr;
            for (const DialogRestoreInfo& dlgRestoreInfo : dlgRestoreInfos) {
                dlgUDI = nullptr;
                auto dlgType = dlgRestoreInfo.dlgType;
                
                // 1. Intrinsic and Mask dialogs
                if ((dlgType == INTRINSIC_DIALOG) || (dlgType == MASK_DIALOG)) {
                    dlgUDI = slCreateMEDialog(getBlockUDI(block), dlgType, true /* isStandAlone*/, fl::ustring(), std::make_pair(dlgRestoreInfo.left, dlgRestoreInfo.top), true /* ignoreOpenFcnCond */);
                } else {
                    // 2. Properties dialog
                    slsvDiagnostic err = BlockOpenPropertiesDialog(block, std::make_pair(dlgRestoreInfo.left, dlgRestoreInfo.top));
                    if (err != SLSV_NoDiagnostic) {
                        slsvDiscardDiagnostic(err);
                    } else {
                        dlgUDI = BlockPropertiesHashTable::getGrIndexedDialogUdi(block,PROPERTY_DIALOG);
                    }
                }
                
                if (dlgUDI) {
                    // We need to call the following methods for dialogs with "ExplicitShow" set to "true"
                    // Un-minimize
                    DAUtils::callVoidMethod(dlgUDI, "showNormal");
                    // Bring to front
                    DAUtils::callVoidMethod(dlgUDI, "show");
                    // Restore tab selection
                    DAUtils::callVoidMethod(dlgUDI, "restoreActiveTabs");
                }
            }

            // Take care of slim dialog
            if (dlgRestoreInfos.empty()){
                const bool hasMaskDialog = SLGlue::isMasked(block) && block->getBPI()->getGrMaskWithDialog(block);
                const slDialogInfo* dlgInfo = hasMaskDialog ?
                    const_cast<slDialogInfo*>(block->getBPI()->getGrMask()->getDialogInfo()) : (block->getDialogInfo());

                // Update the dialog data - this calls block dialog callback
                sluUpdateDialogParameters(block, dlgInfo);
                // Refresh dialog
                SLDialogData* dlgData = SLDialogData::getDialogData(block, dlgInfo->getDialogType());
                if (dlgData) {
                    dlgData->refreshAllOpenDialogs();
                }
            }
        }
    }
}

SIMULINK_EXPORT_FCN bool isBlockDialogOpen(double blockH) {
    // Check Intrinsic and Mask dialogs
    // Not using ggb_has_dialog as that ignores sleeping dialogs
    SLBlock* block = getBlockFromHandle(blockH);
    if (block == nullptr) return false;
    const DialogType all_DialogTypes[2] = { INTRINSIC_DIALOG, MASK_DIALOG };
    for (DialogType dlgType : all_DialogTypes) {
        SLDialogData* dlgData = SLDialogData::getDialogData(block, dlgType);
        if (dlgData != nullptr) {
            if (dlgData->getNumOpenDialogs() > 0) {
                return true;
            }
        }
    }
    return false;
}

SIMULINK_EXPORT_FCN const std::vector<fl::ustring>& getBusSelectorOutputSignals( double blockH )
{
    SLBlock* block = getBlockFromHandle( blockH );
    BusSelectorBlock *bsBlk = GLEE::assert_static_cast<BusSelectorBlock*>(block);
    return bsBlk->GetOutputSignalStringVector();
}

SIMULINK_EXPORT_FCN void setBusSelectorOutputSignals( double blockH, const fl::ustring& outputStr )
{
    SLBlock* block = getBlockFromHandle( blockH );
    BusSelectorBlock *bsBlk = GLEE::assert_static_cast<BusSelectorBlock*>(block);
    bsBlk->SetOutputSignalString( outputStr );
}

SIMULINK_EXPORT_FCN bool isBusSelectorOutputMuxed(double blockH)
{
    SLBlock* block = getBlockFromHandle( blockH );
    BusSelectorBlock *bsBlk = GLEE::assert_static_cast<BusSelectorBlock*>(block);
    return bsBlk->IsOutputMuxed();
}

SIMULINK_EXPORT_FCN bool isBusCreatorNonVirtual( double blockH )
{
    SLBlock* block = getBlockFromHandle( blockH );
    return BusCreatorNonVirtualBlock( block );
}

SIMULINK_EXPORT_FCN bool isInactiveVariant(const SLBlock *block)
{
    return BlockIsInactiveVariant(block,false);
}

const char* getParamValue(const slBlock* b, unsigned pn)
{
    return ::ggb_param_value(b, pn);
}

SLBlock* getNameToBlockIgnoreWhiteSpace(const char* name, const slGraph *graph)
{
    return name_to_block_ignore_white_space(name, graph);
}

} //EOF

// LocalWords:  mdlref sid dmarkman lcp sgb sg resizes gb subgraph UE gmi BPI
// LocalWords:  gg ut MTime livelinks slglue toplevel kweiss drillable tline
// LocalWords:  slapplication ip SLINSF MTimes USTR uchar TTR winrec NAME's
// LocalWords:  Proto Un Tnt blocksearch ustring conn Brancher SLG Lue endl
// LocalWords:  akaviman sflib nullptr
