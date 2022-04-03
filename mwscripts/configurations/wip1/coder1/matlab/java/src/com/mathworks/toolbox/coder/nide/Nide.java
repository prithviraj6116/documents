// Copyright 2014-2019 The MathWorks, Inc.

package com.mathworks.toolbox.coder.nide;

import com.mathworks.matlab.api.datamodel.BackingStore;
import com.mathworks.matlab.api.editor.Editor;
import com.mathworks.matlab.api.explorer.FileLocation;
import com.mathworks.toolbox.coder.model.FunctionUtils;
import com.mathworks.toolbox.coder.model.Interval;
import com.mathworks.toolbox.coder.nide.editor.BoundEditorEventListener;
import com.mathworks.toolbox.coder.nide.editor.CoderEditorApplication;
import com.mathworks.toolbox.coder.nide.editor.CoderEditorLayerProvider;
import com.mathworks.toolbox.coder.nide.editor.CoderEditorUtils;
import com.mathworks.toolbox.coder.nide.impl.CodeInfoPopupLayer;
import com.mathworks.toolbox.coder.nide.impl.DefaultPopupController;
import com.mathworks.toolbox.coder.plugin.Utilities;
import com.mathworks.toolbox.coder.screener.MTreeUtils;
import com.mathworks.toolbox.coder.util.GenericTransaction;
import com.mathworks.toolbox.coder.util.LRUMap;
import com.mathworks.toolbox.coder.util.ProxyEventDispatcher;
import com.mathworks.util.Converter;
import com.mathworks.util.ParameterRunnable;
import com.mathworks.widgets.SyntaxTextPane;
import com.mathworks.widgets.datamodel.FileStorageLocation;
import com.mathworks.widgets.text.mcode.MTree;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.netbeans.editor.BaseDocument;
import org.netbeans.editor.Coloring;

import javax.swing.text.Document;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.Set;
import com.mathworks.toolbox.coder.mi.FevalCommand; 
import com.mathworks.mvm.exec.MatlabFevalRequest;
import com.mathworks.jmi.Matlab;

/**
 * View-agnostic model for an IDE-style UI.
 */
@SuppressWarnings("UnusedDeclaration")
public class Nide {
    private static final String POPUP_EDITOR_LAYER_NAME = "coder-popup-layer";

    private final ProxyEventDispatcher<NideObserver> fBaseObserver;
    private final Map<String, NideArtifactSet> fArtifactSets;
    private final Map<NideSourceArtifact, LocationResolver> fLocationResolvers;
    private final Map<NideArtifact, Editor> fIntegratedEditors;
    private final Set<SelectionClient> fSelectionClients;
    private final Set<SelectionKey> fActiveSelections;
    private final CoderEditorApplication fEditorApp;
    private final CodeInfoModel fInfoModel;
    private final HistoryModel fHistoryModel;
    private final NideClient fView;
    private final CodePopupLayerProvider fPopupLayerProvider;
    private final GeneralHighlightManager fHighlightManager;
    private PopupController fPopupController;
    private BindableNideSourceArtifact fDefaultArtifact;
    private BindableNideSourceArtifact fCurrentSourceArtifact;
    private boolean fSuspendFileMonitoringLoads;
    private boolean fActive;



    @SuppressWarnings("ThisEscapedInObjectConstruction")
    public Nide(NideEditorIntegrationContext integrationContext,
                CoderEditorApplicationFactory editorAppFactory,
                NideClient view) {
        fView = view;
        fBaseObserver = new ProxyEventDispatcher<>(NideObserver.class);
        fArtifactSets = new LinkedHashMap<>();
        fLocationResolvers = new HashMap<>();
        fInfoModel = new CodeInfoModel(this, createLocationResolverProvider());
        fHistoryModel = new HistoryModel();
        fIntegratedEditors = new HashMap<>();
        fSelectionClients = new HashSet<>();
        fActiveSelections = new HashSet<>();
        fPopupLayerProvider = new CodePopupLayerProvider();
        fHighlightManager = new GeneralHighlightManager();

        integrationContext.setIde(this);

        Collection<CoderEditorLayerProvider> allProviders = new LinkedList<>();
        allProviders.add(fPopupLayerProvider);
        allProviders.add(fHighlightManager);
        Collection<CoderEditorLayerProvider> hookedProviders = createEditorLayerProviders();
        if (hookedProviders != null) {
            allProviders.addAll(hookedProviders);
        }
        fEditorApp = editorAppFactory.createCoderEditorApplication(integrationContext, allProviders);

        fView.setNide(this);
        init();
    }

    protected void init() {
        if (fPopupController == null) {
            setPopupController(new DefaultPopupController());
        }
    }

    @Nullable
    protected Collection<CoderEditorLayerProvider> createEditorLayerProviders() {
        return null;
    }

    public void activateNide() {
        fActive = true;
        fEditorApp.reloadAll(true);
        refreshFileMonitoringReloadProperty();
    }

    public void deactivateNide() {
        saveAll();
        fActive = false;
        refreshFileMonitoringReloadProperty();
    }

    public void dispose() {
        fPopupLayerProvider.closeAllPopups();

        for (NideArtifact artifact : new LinkedList<>(fIntegratedEditors.keySet())) {
            if (artifact.isSourceArtifact()) {
                asInternalArtifact(artifact).bind(null);
            }
        }

        fView.dispose();

        if (fActive) {
            fEditorApp.close();
        } else {
            fEditorApp.closeNoPrompt();
        }
    }

    public void installSelectionClient(final SelectionClient selectionClient) {
        fSelectionClients.add(selectionClient);
        selectionClient.init(new ParameterRunnable<SelectionContext>() {
            @Override
            public void run(SelectionContext selectionContext) {
                if (fSelectionClients.contains(selectionClient)) {
                    performSelect(selectionContext, selectionClient, true);
                }
            }
        });
    }

    public void uninstallSelectionClient(SelectionClient selectionClient) {
        fSelectionClients.remove(selectionClient);
    }

    private Converter<NideSourceArtifact, LocationResolver> createLocationResolverProvider() {
        return new Converter<NideSourceArtifact, LocationResolver>() {
            @Override
            public LocationResolver convert(NideSourceArtifact target) {
                return fLocationResolvers.get(target);
            }
        };
    }

    public PopupController getPopupController() {
        return fPopupController;
    }

    /**
     * Set the PopupController to be affiliated with the pre-installed CodeInfoPopupLayer.
     */
    public void setPopupController(PopupController popupController) {
        fPopupController = popupController;
        if (fPopupController != null) {
            getCodeInfoModel().installPopupViewFactories(fPopupController);
        }
        fPopupLayerProvider.updateExistingLayers();
    }

    public CodeInfoModel getCodeInfoModel() {
        return fInfoModel;
    }

    public void closePopups() {
        fPopupLayerProvider.closeAllPopups();
    }

    public void showFile(File file) {
        showFile(file, 1);
    }

    public void showFile(File file, int line) {
        NideArtifact artifact = getArtifactForFile(file);
        if (artifact != null) {
            showArtifact(artifact);
            if (artifact.isSourceArtifact()) {
                fCurrentSourceArtifact = asInternalArtifact(artifact);
            }
        } else {
            fView.showFileLoadFailure(file);
        }
    }

    public void showFile(File file, String functionName) {
        NideArtifact artifact = getArtifactForFile(file);
        if (artifact != null && !artifact.isSourceArtifact()) {
            throw new IllegalArgumentException(
                    String.format("Specified file '%s' does not map to a source artifact.",
                            file.getName()));
        }

        showFile(file);

        if (getActiveEditor() != null) {
            getActiveEditor().goToFunction(functionName, "");
        }
    }

    public void showArtifact(NideArtifact artifact) {
        showArtifact(artifact, 1);
    }

    public void showArtifact(NideArtifact artifact, int line) {
        showArtifact(artifact, line, true);
    }

    public void gotoFunction(File file, String functionName) {
        NideArtifact artifact = getArtifactForFile(file);
        if (artifact == null || !artifact.isSourceArtifact()) {
            return;
        }

        NideSourceArtifact sourceArtifact = artifact.getAsSourceArtifact();

        int lineNum = FunctionUtils.getFunctionLineNumber(sourceArtifact.getCurrentMTree(), functionName);
        if (lineNum == 0) {
            return;
        }

        showArtifact(sourceArtifact, lineNum);

        if (getActiveEditor() != null &&
                getActiveEditor().getTextComponent() instanceof SyntaxTextPane) {
            Interval interval = FunctionUtils.getFunctionSignatureInterval(
                    sourceArtifact.getCurrentMTree(), functionName,
                    sourceArtifact.getCurrentDocument());

            if (interval != null) {
                CoderEditorUtils.scrollTo((SyntaxTextPane) getActiveEditor().getTextComponent(),
                        interval.getStart(), true);
                highlightInterval(interval);
            }
        }
    }

    public void showInterval(@NotNull Interval interval) {
        CoderEditorUtils.scrollTo((SyntaxTextPane) getActiveEditor().getTextComponent(),
                interval.getStart(), true);
    }

    public void showInfoLocation(MappedInfoLocation<?> infoLocation) {
        performSelect(SelectionContext.infoLocationSelection(infoLocation), null, true);
    }

    private void showArtifact(NideArtifact artifact, int line, boolean userTriggered) {

        if (artifact != null) {
            File file = artifact.getFile();
            if (file.getName().endsWith(".sfx")) {
                //This opens sfx model when user clicks on the function name in the "Function List" window of coder gui.
                new Matlab().fevalConsoleOutput("edit",new Object[]{file.getName()});
                //early returning here keeps previous editor open and does not show "Filetype not viewable" 
                //return;
            }
        }
        if (artifact != null && Utilities.areValuesDifferent(getCurrentSourceArtifact(), artifact)) {
            performSelect(SelectionContext.artifactSelection(artifact, line), null,
                    userTriggered);
        } else if (artifact == null) {
             setActiveEditor(null, null);
        }
    }

    /** Actual implementation for select */
    private void performSelect(SelectionContext selectionContext,
                               @Nullable SelectionClient source,
                               boolean recordInHistory) {
        SelectionKey key = new SelectionKey(source, selectionContext);
        if (!fActiveSelections.add(key)) {
            // Circular selection detected, break
            return;
        }

        if (recordInHistory) {
            fHistoryModel.add(selectionContext);
        }

        setActiveEditor(selectionContext.getSourceArtifact() != null ?
                selectionContext.getSourceArtifact() : selectionContext.getArtifact());
        if (selectionContext.getInfoLocation() != null &&
                getActiveEditor().getTextComponent() instanceof SyntaxTextPane) {
            Interval interval = selectionContext.getInfoLocation().getCurrentInterval();
            if (interval != null) {
                CoderEditorUtils.scrollTo((SyntaxTextPane) getActiveEditor().getTextComponent(),
                        interval.getStart(), true);
                highlight(selectionContext.getInfoLocation());
            }
        }

        for (SelectionClient selectionClient : new LinkedList<>(fSelectionClients)) {
            selectionClient.handleSelection(selectionContext);
        }

        fActiveSelections.remove(key);
    }

    @NotNull
    private Editor createOrGetEditor(NideArtifact artifact) {
        Editor editor = fIntegratedEditors.get(artifact);
        if (editor == null && artifact != null) {
            editor = artifact.isSourceArtifact() ? fEditorApp.openEditor(artifact.getAsSourceArtifact(), false) :
                    fEditorApp.openEditor(artifact, false);
            fIntegratedEditors.put(artifact, editor);
        }
        //noinspection ConstantConditions
        return editor;
    }

    private void setActiveEditor(NideArtifact artifact) {
        setActiveEditor(fView.isSupportsEditor(artifact) ? createOrGetEditor(artifact) : null, artifact);
    }

    private static BindableNideSourceArtifact asInternalArtifact(NideArtifact artifact) {
        if (artifact.isSourceArtifact() && !(artifact.getAsSourceArtifact() instanceof BindableNideSourceArtifact)) {
            throw new IllegalArgumentException("Specified artifact is not of the expected type.");
        }
        return artifact.isSourceArtifact() ?
                (BindableNideSourceArtifact) artifact.getAsSourceArtifact() : null;
    }

    private void setActiveEditor(@Nullable Editor editor, @Nullable NideArtifact artifact) {
        fView.setSuppressCaretUpdates(true);
        fCurrentSourceArtifact = artifact != null ? asInternalArtifact(artifact) : null;
        fEditorApp.setActive(editor);

        fPopupLayerProvider.activateCurrent();

        fView.setIntegratedEditor(editor, artifact);
        fView.setSuppressCaretUpdates(false);

        fBaseObserver.getProxyDispatcher().integratedEditorChanged(editor, artifact);
    }

    private void removeEditor(NideArtifact artifact, boolean showPrevious, boolean showDefault) {
        if (!fIntegratedEditors.containsKey(artifact)) {
            return;
        }

        boolean wasActive = !Utilities.areValuesDifferent(fEditorApp.getActiveEditor(),
                fIntegratedEditors.get(artifact));
        Editor editor = fIntegratedEditors.remove(artifact);
        fHistoryModel.revalidate();

        if (artifact.isSourceArtifact()) {
            asInternalArtifact(artifact).bind(null);
        }

        if (wasActive) {
            if (showPrevious && fHistoryModel.hasPrevious()) {
                fHistoryModel.back();
            } else if (showDefault) {
                showArtifact(getDefaultArtifact());
            }
        }

        fEditorApp.closeEditor(editor);
    }

    @NotNull
    public CoderEditorApplication getEditorApplication() {
        return fEditorApp;
    }

    public Editor getActiveEditor() {
        return fEditorApp.getActiveEditor();
    }

    public File getActiveFile() {
        Editor editor = getActiveEditor();
        if (editor != null) {
            NideArtifact artifact = getArtifactFromEditor(editor);
            return artifact.getFile();
        }
        return null;
    }

    public NideArtifact getArtifactForBackingStore(BackingStore<Document> backingStore) {
        for (Map.Entry<NideArtifact, Editor> editorEntry : fIntegratedEditors.entrySet()) {
            if (backingStore.getStorageLocation()
                    .isTheSameAs(editorEntry.getValue().getStorageLocation())) {
                return editorEntry.getKey();
            }
        }
        return null;
    }

    @Nullable
    public NideArtifact getArtifactForFile(File file) {
        /*for (NideArtifact artifact : fIntegratedEditors.keySet()) {
            if (!Utilities.areValuesDifferent(artifact.getFile(), file)) {
                return artifact;
            }
        }*/

        for (NideArtifactSet artifactSet : fArtifactSets.values()) {
            NideArtifact artifact = artifactSet.getArtifactForFile(file);
            if (artifact != null) {
                return artifact;
            }
        }
        return null;
    }

    @Nullable
    public String getActiveFunctionName() {
        Editor editor = getActiveEditor();
        if (editor != null && editor.isOpen() && fCurrentSourceArtifact != null) {
            int position = editor.getTextComponent().getCaretPosition();
            if (position > 0) {
                MTree.Node node =
                        MTreeUtils.getNodeAtPosition(fCurrentSourceArtifact.getCurrentMTree(), position,
                                fCurrentSourceArtifact.getCurrentDocument(), true);
                if (node != null) {
                    MTree.Node fcnNode = FunctionUtils.getParentOfType(node, MTree.NodeType.FUNCTION);
                    if (fcnNode != null && fcnNode.getType() == MTree.NodeType.FUNCTION) {
                        return fcnNode.getFunctionName().getText();
                    }
                }
            }

            if (fCurrentSourceArtifact.isMCode() && fCurrentSourceArtifact.isFile()) {
                return new FileLocation(fCurrentSourceArtifact.getFile()).getNameBeforeDot();
            }
        }

        return null;
    }

    public NideSourceArtifact getCurrentSourceArtifact() {
        return fCurrentSourceArtifact;
    }

    public NideArtifact getArtifactFromEditor(Editor editor) {
        for (Map.Entry<NideArtifact, Editor> entry : fIntegratedEditors.entrySet()) {
            if (entry.getValue().equals(editor)) {
                return entry.getKey();
            }
        }
        return null;
    }

    public LocationResolver getLocationResolver(NideSourceArtifact sourceArtifact) {
        return fLocationResolvers.get(sourceArtifact);
    }

    public NideSourceArtifact getDefaultArtifact() {
        return fDefaultArtifact;
    }

    public void setDefaultArtifact(NideSourceArtifact defaultArtifact) {
        validateArtifact(defaultArtifact);
        fDefaultArtifact = (BindableNideSourceArtifact) defaultArtifact;
    }

    public boolean isActive() {
        return fActive;
    }

    public boolean isDirty() {
        return fEditorApp.isDirty();
    }

    public void addBoundEditorEventListener(BoundEditorEventListener eventListener) {
        fEditorApp.addBoundEditorEventListener(eventListener);
    }

    public void removeBoundEditorEventListener(BoundEditorEventListener eventListener) {
        fEditorApp.removeBoundEditorEventListener(eventListener);
    }

    private BindableNideSourceArtifact validateArtifact(NideSourceArtifact artifact) {
        if (artifact instanceof BindableNideSourceArtifact) {
            for (NideArtifactSet artifactSet : fArtifactSets.values()) {
                if (artifactSet.contains(artifact)) {
                    return (BindableNideSourceArtifact) artifact;
                }
            }
        }
        throw new IllegalArgumentException("Specified artifact is not supported by this IDE");
    }

    public Editor getEditorForFile(File file) {
        for (Map.Entry<NideArtifact, Editor> entry : fIntegratedEditors.entrySet()) {
            if (entry.getKey().isFile() && entry.getKey().getFile().equals(file)) {
                return entry.getValue();
            }
        }
        return null;
    }

    Converter<BackingStore<Document>, MTree> createMTreeProvider() {
        return new Converter<BackingStore<Document>, MTree>() {
            @Override
            public MTree convert(BackingStore<Document> backingStore) {
                if (backingStore.getStorageLocation() instanceof FileStorageLocation) {
                    File file = ((FileStorageLocation) backingStore.getStorageLocation()).getFile();
                    for (NideArtifactSet artifactSet : fArtifactSets.values()) {
                        for (NideSourceArtifact artifact : artifactSet.getSourceArtifacts()) {
                            if (artifact.isFile() && artifact.getFile().equals(file)) {
                                return artifact.getCurrentMTree();
                            }
                        }
                    }
                }
                return null;
            }
        };
    }

    public void goBack() {
        fHistoryModel.back();
    }

    public void goForward() {
        fHistoryModel.forward();
    }

    public void highlightInterval(Interval interval) {
        highlight(new DummyMappedInfoLocation(interval, getCurrentSourceArtifact()));
    }

    public void highlightIntervals(@NotNull Collection<Interval> intervals) {
        final Collection<MappedInfoLocation<?>> dummyLocs = new ArrayList<>(intervals.size());
        final NideSourceArtifact sourceArtifact = getCurrentSourceArtifact();
        for (final Interval interval : intervals) {
            dummyLocs.add(new DummyMappedInfoLocation(interval, sourceArtifact));
        }
        highlight(dummyLocs);
    }

    public void highlight(Collection<MappedInfoLocation<?>> locations) {
        Set<File> cleared = new HashSet<>();
        for (MappedInfoLocation<?> location : locations) {
            if (cleared.add(location.getArtifact().getFile())) {
                fHighlightManager.clear(location.getArtifact().getFile());
            }

            CodeInfoSupport<?> infoSupport = getCodeInfoModel().getInstalled(location);
            Coloring coloring = infoSupport != null && infoSupport.getCodeInfoViewProvider() != null ?
                    infoSupport.getCodeInfoViewProvider().getHighlightColoring() : null;
            fHighlightManager.highlight(location.getArtifact().getFile(),
                    Arrays.<MappedInfoLocation<?>>asList(location), coloring);
        }
    }

    public void highlight(MappedInfoLocation<?> infoLocation) {
        highlight(Arrays.<MappedInfoLocation<?>>asList(infoLocation));
    }

    private static boolean checkIfLocatedInSameFile(Collection<MappedInfoLocation<?>> locations) {
        File file = null;
        for (MappedInfoLocation<?> location : locations) {
            if (file == null) {
                file = location.getArtifact().getFile();
            } else if(Utilities.areValuesDifferent(file, location.getArtifact().getFile())){
                return false;
            }
        }
        return true;
    }

    public void clearHighlights() {
        if (getActiveFile() != null) {
            fHighlightManager.clear(getActiveFile());
        }
    }

    public void save() {
        if (getActiveEditor() != null && getActiveEditor().isDirty()) {
            if (!fEditorApp.isForceSaves()) {
                getActiveEditor().negotiateSave();
            } else {
                try {
                    getActiveEditor().save();
                } catch (Exception e) {}
            }
            onSave();
        }
    }

    public void saveAll() {
        boolean saved = false;
        Set<Editor> relevantEditors = new HashSet<>(fIntegratedEditors.values());
        for (Editor editor : fEditorApp.getOpenEditors()) {
            if (editor.isDirty() && relevantEditors.contains(editor)) {
                if (!fEditorApp.isForceSaves()) {
                    editor.negotiateSave();
                } else {
                    try {
                        editor.save();
                    } catch (Exception e) {}
                }
                saved = true;
            }
        }

        if (saved) {
            onSave();
        }
    }

    protected void onSave() {

    }

    public void resetAllLocationMappings() {
        for(NideSourceArtifact artifact : fLocationResolvers.keySet()) {
            resetLocationMappings(artifact);
        }
    }

    public void resetLocationMappings(NideArtifact artifact) {
        if (artifact.isSourceArtifact()) {
            asInternalArtifact(artifact).updateBaseline();
            fLocationResolvers.get(artifact).reset();
        }
    }

    private void refreshFileMonitoringReloadProperty() {
        setFileMonitoringReloadsEnabled(!fSuspendFileMonitoringLoads);
    }

    public void setFileMonitoringReloadsEnabled(boolean enabled) {
        fSuspendFileMonitoringLoads = !enabled;
        fEditorApp.setFileMonitoringReloadsSuspended(fSuspendFileMonitoringLoads && isActive());
    }

    public void addBaseIDEObserver(NideObserver observer) {
        fBaseObserver.addObserver(observer);
    }

    public void removeBaseIDEObserver(NideObserver observer) {
        fBaseObserver.removeObserver(observer);
    }

    public NideArtifactSet  addArtifactSet(String key, String displayName) {
        assert !fArtifactSets.containsKey(key) : "ArtifactSet keys should be unique";
        NideArtifactSet artifactSet = new ArtifactSet(key, displayName);
        fArtifactSets.put(key, artifactSet);
        return artifactSet;
    }

    public void removeArtifactSet(String key, String displayName) {
        assert fArtifactSets.containsKey(key);
        fArtifactSets.remove(key);
    }

    void replaceActiveWithFailure() {
        if (getActiveFile() != null) {
            fView.showFileLoadFailure(getActiveFile());
        }
    }

    private boolean isContainedInArifactSets(NideArtifact artifact) {
        for (NideArtifactSet artifactSet : fArtifactSets.values()) {
            if (artifactSet.contains(artifact)) {
                return true;
            }
        }
        return false;
    }

    public void forceReloadAll() {
        fEditorApp.reloadAll(true);
    }

    private static Map<NideSourceArtifact, MTree> createParseTreeCache() {
        return new LRUMap<>(new LRUMap.LRUPredicate<NideSourceArtifact, MTree>() {
            @Override
            public boolean evictEldestEntry(Map.Entry<NideSourceArtifact, MTree> entry,
                                            Map<NideSourceArtifact, MTree> mapView) {
                return mapView.size() > 3;
            }
        });
    }

    private class ArtifactSet extends NideArtifactSet {
        ArtifactSet(String key, String displayName) {
            super(key, displayName);
        }

        @Override
        BindableNideSourceArtifact createSourceArtifact(BackingStore<Document> backingStore) throws
                NideException {
            return new BindableNideSourceArtifact(backingStore, true);
        }

        @Override
        void onGenericArtifactAdded(NideArtifact artifact) {

        }

        @Override
        void onSourceArtifactAdded(NideSourceArtifact infoTarget) {
            Editor editor = createOrGetEditor(infoTarget);
            assert editor.getDocument() instanceof BaseDocument &&
                    infoTarget instanceof BindableNideSourceArtifact;
            ((BindableNideSourceArtifact) infoTarget).bind(editor);
            fLocationResolvers.put(infoTarget, new DefaultLocationResolver(infoTarget));
            fInfoModel.transact(GenericTransaction.addTransaction(infoTarget));
        }

        @Override
        void onArtifactRemoved(NideArtifact artifact) {
            removeEditor(artifact, true, true);
        }

        @Override
        void onSourceArtifactRemoved(NideSourceArtifact infoTarget) {
            removeEditor(infoTarget, true, true);
            fInfoModel.transact(GenericTransaction.removeTransaction(infoTarget));
            fLocationResolvers.remove(infoTarget);
            onArtifactRemoved(infoTarget);
        }

        @Override
        void onArtifactsChanged(Set<NideArtifact> oldArtifacts, Set<NideSourceArtifact> oldInfoTargets,
                                Set<NideArtifact> newArtifacts, Set<NideSourceArtifact> newInfoTargets) {
            Set<NideSourceArtifact> removed = new HashSet<>(oldInfoTargets);
            removed.removeAll(newInfoTargets);
            Set<NideSourceArtifact> added = new HashSet<>(newInfoTargets);
            added.removeAll(oldInfoTargets);

            if (!removed.isEmpty() || !added.isEmpty()) {
                fInfoModel.transact(new GenericTransaction<>(added, removed, null));
            }

            for (NideArtifact artifact : removed) {
                onArtifactRemoved(artifact);
            }
        }
    }

    private class HistoryModel extends LinkedList<SelectionContext> {
        private final int fLimit;
        private int fMark;

        HistoryModel() {
            fLimit = 15;
        }

        void revalidate() {
            int index = 0;
            for (Iterator<SelectionContext> it = iterator(); it.hasNext(); ) {
                SelectionContext context = it.next();
                if (context.getArtifact() != null && !isContainedInArifactSets(context.getArtifact())) {
                    it.remove();
                    if (fMark > index || (fMark == index && index == size())) {
                        fMark--;
                    }
                }
                index++;
            }
        }

        boolean hasPrevious() {
            return fMark - 1 >= 0;
        }

        boolean back() {
            fMark--;
            boolean backable = fMark >= 0;
            fMark = Math.max(0, fMark);

            if (backable) {
                performSelect(get(fMark), null, false);
            }

            return backable;
        }

        boolean forward() {
            fMark++;
            boolean forwardable = fMark < size();
            fMark = Math.min(size() - 1, fMark);

            if (forwardable) {
                performSelect(get(fMark), null, false);
            }

            return forwardable;
        }

        @Override
        public boolean add(SelectionContext selectionContext) {
            subList(Math.max(0, fMark), size()).clear();

            super.add(selectionContext);
            while (size() > fLimit) {
                remove();
            }

            fMark = size() - 1;
            return true;
        }
    }

    private class CodePopupLayerProvider implements CoderEditorLayerProvider {
        private final Collection<CodeInfoPopupLayer> fLayers;
        private CodeInfoPopupLayer fActiveLayer;

        private CodePopupLayerProvider() {
            fLayers = new LinkedList<>();
        }

        void activateCurrent() {
            if (fActiveLayer != null) {
                fActiveLayer.deactivate();
                fActiveLayer = null;
            }
            if (getCurrentSourceArtifact() != null) {
                for (CodeInfoPopupLayer layer : fLayers) {
                    if (layer.getArtifact() != null &&
                            layer.getArtifact().equals(getCurrentSourceArtifact())) {
                        fActiveLayer = layer;
                        break;
                    }
                }

            }
            if (fActiveLayer != null) {
                fActiveLayer.activate(getPopupController());
            }
        }

        void closeAllPopups() {
            for (CodeInfoPopupLayer layer : fLayers) {
                layer.closeAll();
            }
        }

        void updateExistingLayers() {
            if (fActiveLayer != null) {
                fActiveLayer.setPopupController(getPopupController());
            }
        }

        @Nullable
        @Override
        public CodeInfoPopupLayer createEditorLayer() {
            final CodeInfoPopupLayer layer = new CodeInfoPopupLayer(POPUP_EDITOR_LAYER_NAME);
            fLayers.add(layer);
            layer.setCleanupCallback(new Runnable() {
                @Override
                public void run() {
                    fLayers.remove(layer);
                }
            });

            return layer;
        }

        @Override
        public boolean requiresEditor() {
            return true;
        }
    }

    private static class SelectionKey {
        private final SelectionClient fSource;
        private final SelectionContext fContext;

        SelectionKey(SelectionClient source,
                             SelectionContext context) {
            fSource = source;
            fContext = context;
        }

        @SuppressWarnings("AccessingNonPublicFieldOfAnotherObject") // Auto-generated
        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;

            SelectionKey that = (SelectionKey) o;

            if (fContext != null ? !fContext.equals(that.fContext) : that.fContext != null)
                return false;
            return !(fSource != null ? !fSource.equals(that.fSource) : that.fSource != null);

        }

        @Override
        public int hashCode() {
            int result = fSource != null ? fSource.hashCode() : 0;
            result = 31 * result + (fContext != null ? fContext.hashCode() : 0);
            return result;
        }
    }

    private static class DummyInfoLocation implements CodeInfoLocation<DummyInfoLocation> {
        private final Interval fInterval;

        DummyInfoLocation(Interval interval) {
            fInterval = interval;
        }

        @NotNull
        @Override
        public Interval getInterval() {
            return fInterval;
        }

        @Nullable
        @Override
        public DummyInfoLocation getValue() {
            return this;
        }

        @Override
        public boolean equals(Object obj) {
            return obj instanceof DummyInfoLocation &&
                    getInterval().equals(((DummyInfoLocation) obj).getInterval());
        }

        @Override
        public int hashCode() {
            return fInterval.hashCode();
        }
    }

    private class DummyMappedInfoLocation implements MappedInfoLocation<DummyInfoLocation> {
        private final NideSourceArtifact fNideSourceArtifact;
        private final DummyInfoLocation fDummyInfoLocation;

        DummyMappedInfoLocation(Interval interval, NideSourceArtifact nideSourceArtifact) {
            fNideSourceArtifact = nideSourceArtifact;
            fDummyInfoLocation = new DummyInfoLocation(interval);
        }

        @Override
        public CodeInfoLocation<DummyInfoLocation> getCodeInfoLocation() {
            return fDummyInfoLocation;
        }

        @Override
        public NideSourceArtifact getArtifact() {
            return fNideSourceArtifact;
        }

        @Override
        public boolean isValid() {
            return getCurrentInterval() != null;
        }

        @Override
        public Interval getCurrentInterval() {
            return fLocationResolvers.containsKey(getArtifact()) ?
                    fLocationResolvers.get(getArtifact())
                            .getCurrentInterval(getCodeInfoLocation().getInterval()) : null;
        }

        @Override
        public void gotoLocation(boolean highlight) {
            showInfoLocation(this);
            if (highlight) {
                highlight();
            }
        }

        @Override
        public void highlight() {
            Nide.this.highlight(this);
        }

        @Override
        public void addIntervalChangeObserver(
                ParameterRunnable<MappedInfoLocation<?>> intervalChangeObserver) {

        }
    }
}

// LocalWords:  sfx
