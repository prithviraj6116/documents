// Copyright 2013-2019 The MathWorks, Inc.

package com.mathworks.toolbox.coder.model;

import com.mathworks.project.api.XmlApi;
import com.mathworks.project.api.XmlReader;
import com.mathworks.project.api.XmlWriter;
import com.mathworks.toolbox.coder.plugin.Utilities;
import com.mathworks.toolbox.coder.plugin.inputtypes.IDPFimath;
import com.mathworks.toolbox.coder.util.ExpressionTree;
import com.mathworks.toolbox.coder.util.LeakableObject;
import com.mathworks.toolbox.coder.wfa.build.CodeGenerationUtils;
import com.mathworks.util.Converter;
import com.mathworks.util.MulticastChangeListener;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.apache.commons.io.FilenameUtils;

import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.io.File;
import java.io.IOException;
import java.util.AbstractMap;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.regex.Pattern;

/**
 * Base model shared between Fixed Point, HDL, and Code Gen. Most properties for this base model do
 * not automatically fire property change events. Therefore, it allows derived models to define and
 * enforce the atomicity of changes to model properties.
 */
public class UnifiedModel extends LeakableObject {
    public static final String XML_USER_NODE = "UserEntities";
    public static final String XML_COMPUTED_NODE = "ComputedEntities";
    public static final String VARIABLE_NAMES_PROPERTY = "VariableNames";
    public static final String VARIABLE_KINDS_PROPERTY = "VariableKinds";
    public static final String FIELD_DEFINITIONS_PROPERTY = "FieldNatures";
    public static final String KEY_TREE_PROPERTY = "KeyTree";
    public static final String CALL_TREE_PROPERTY = "CallTree";
    public static final String EXPRESSION_PROPERTY = "ExpressionPosition";
    public static final String MATLAB_TYPES_PROPERTY = "MatlabTypes";
    public static final String ERRORS_PROPERTY = "BuildErrors";

    public static final Converter<Variable, Variable> FIELD_ACCESS_DISQUALIFIER =
            createDefaultFieldDisqualifier();
    private final MulticastChangeListener fChangeListeners;

    private final PropertyChangeSupport fPropertySupport;
    private final UnifiedSerializationStrategy fPersistenceStrategy;

    private MetadataTree<?> fKeyTree;
    private MetadataTree<VariableKind> fVariableNames;
    private MetadataTree<VariableKind> fVariableKinds;
    private MetadataTree<FieldNature> fFieldNatures;
    private MetadataTree<String> fClassDefinedIn;
    private Map<Function, ClassInfo> fClassInfos;
    private Map<String, List<String>> fLoggedSystemObjectPropertiesInfo;
    private Map<String, PropertyChangeEvent> fPropertyEvents;
    private MetadataTree<MatlabType> fMatlabTypes;
    private Map<String, Function> fLegacyFunctions;
    private Map<Function, ExpressionTree> fExpressions;
    private Map<Function, String> fUniqueFunctionNames;
    private Map<String, Function> fUniqueNameToFunctions;
    private Set<File> fFiles;
    private Collection<BuildError> fErrors;
    private Collection<PotentialDifference> fPotentialDifferences;
    private CallTree fCallTree;

    
    
    public UnifiedModel() {
        this(null);
    }

    public UnifiedModel(UnifiedSerializationStrategy persistenceStrategy) {
        fPersistenceStrategy = persistenceStrategy != null ?
                persistenceStrategy : new ConversionSerializer();
        fPropertySupport = new PropertyChangeSupport(this);
        fChangeListeners = new MulticastChangeListener();

        fVariableKinds = new MetadataTree<>();
        fMatlabTypes = new MetadataTree<>();
        fFieldNatures = new MetadataTree<>();
        fClassDefinedIn = new MetadataTree<>();
        fLoggedSystemObjectPropertiesInfo = new HashMap<>();
    }

    protected static String createPropertyName(String prefix, FunctionScopedKey key) {
        return prefix + key.getFunction() + ":" + key.toString();
    }

    public final void reset(boolean includeUserValues) {
        fKeyTree = fVariableKinds;
        resetExtensions(includeUserValues);
        fPropertyEvents = null;
    }

    /**
     * Hook method called by reset()
     */
    protected void resetExtensions(boolean includeUserValues) {

    }

    public void deserialize(UnifiedSerializationStrategy.XmlSourcePolicy sourcePolicy,
                            UnifiedSerializationStrategy.DeserializationExtender readExtender,
                            boolean includeComputedData) {
        fPersistenceStrategy.deserialize(sourcePolicy, readExtender != null ? readExtender :
                new UnifiedSerializationStrategy.DeserializationExtender() {
                    @Override
                    public void deserializeColumn(Function function, Variable variable,
                                                  XmlReader column,
                                                  boolean computed,
                                                  UnifiedSerializationStrategy strategy) {
                    }

                    @Override
                    public void deserializeColumn(Function function, XmlReader column,
                                                  boolean computed,
                                                  UnifiedSerializationStrategy strategy) {
                    }
                }, includeComputedData);
    }

    public void serialize(UnifiedSerializationStrategy.XmlSourcePolicy sourcePolicy,
                          UnifiedSerializationStrategy.SerializationExtender writeExtender) {
        fPersistenceStrategy.serialize(sourcePolicy, writeExtender != null ? writeExtender :
                new UnifiedSerializationStrategy.SerializationExtender() {
                    @Override
                    public void serializeFunctionExtensions(Function function,
                                                            XmlWriter functionAnnotationRoot,
                                                            XmlWriter functionComputedRoot,
                                                            UnifiedSerializationStrategy strategy) {
                    }

                    @Override
                    public void serializeVariableExtensions(Variable variable,
                                                            XmlWriter variableAnnotationRoot,
                                                            XmlWriter variableComputedRoot,
                                                            UnifiedSerializationStrategy strategy) {
                    }

                    @Override
                    public void serializeAdditionalExtensions(
                            UnifiedSerializationStrategy strategy) {
                    }

                    @Override
                    public boolean shouldSerializeFunction(Function function) {
                        return true;
                    }

                    @Override
                    public boolean shouldSerializeVariable(Variable variable) {
                        return true;
                    }
                });
    }

    public final void addPropertyChangeListener(PropertyChangeListener listener) {
        fPropertySupport.addPropertyChangeListener(listener);
    }

    public final void removeChangeListener(PropertyChangeListener listener) {
        fPropertySupport.removePropertyChangeListener(listener);
    }

    /**
     * Fires a single property change event if no batched session is active or adds it
     * to the batched session if one is active.
     */
    protected final void firePropertyChange(String propertyName, Object oldValue, Object newValue) {
        if (fPropertyEvents == null) {
            fPropertySupport.firePropertyChange(propertyName, oldValue, newValue);
        } else {
            queuePropertyChangeEvent(propertyName, oldValue, newValue);
        }
    }

    protected final void firePropertyChange(PropertyChangeEvent event) {
        if (fPropertyEvents == null) {
            fPropertySupport.firePropertyChange(event);
        } else {
            queuePropertyChangeEvent(event);
        }
    }

    /**
     * Start a batched property change dispatch session. This provides atomicity on the dispatch
     * of property change events but not on the change of property values themselves.
     */
    protected final void startBatchingPropertyChangeEvents() {
        fPropertyEvents = new LinkedHashMap<>();
    }

    /**
     * Fires all existing batched property change events and ends the current batched session.
     */
    protected final void fireBatchedPropertyChangeEvents() {
        if (fPropertyEvents != null) {
            Collection<PropertyChangeEvent> events = new LinkedList<>(fPropertyEvents.values());
            fPropertyEvents = null;

            for (PropertyChangeEvent event : events) {
                fPropertySupport.firePropertyChange(event);
            }
        }
    }

    /**
     * Queue a property change event if there is an active batch session. Otherwise, the event is
     * immediately fired.
     */
    protected final void queuePropertyChangeEvent(String propertyName, Object oldValue, Object newValue) {
        if (fPropertyEvents != null) {
            if (fPropertyEvents.containsKey(propertyName)) {
                PropertyChangeEvent oldEvent = fPropertyEvents.get(propertyName);
                oldValue = fPropertyEvents.get(propertyName).getOldValue();
            }
            if (oldValue == null || newValue == null || !oldValue.equals(newValue)) {
                queuePropertyChangeEvent(
                        new PropertyChangeEvent(this, propertyName, oldValue, newValue));
            }
        } else {
            firePropertyChange(propertyName, oldValue, newValue);
        }
    }

    protected final void queuePropertyChangeEvent(PropertyChangeEvent event) {
        fPropertyEvents.put(event.getPropertyName(),
                new PropertyChangeEvent(this, event.getPropertyName(), event.getOldValue(),
                        event.getNewValue()));
    }

    public final CallTree getCallTree() {
        return fCallTree;
    }

    public final void setCallTree(CallTree callTree) {
        CallTree oldCallTree = fCallTree;
        fCallTree = callTree;
        firePropertyChange(CALL_TREE_PROPERTY, oldCallTree, callTree);
    }

    public final boolean hasFunction(Function function) {
        return getFunctions().contains(function);
    }

    public void addChangeListener(ChangeListener listener) {
        fChangeListeners.addChangeListener(listener);
    }

    protected void fireChange() {
        fChangeListeners.stateChanged(new ChangeEvent(this));
    }

    public void removeChangeListener(ChangeListener listener) {
        fChangeListeners.removeChangeListener(listener);
    }

    @NotNull
    protected FunctionFactory getFunctionFactory() {
        return Function.DEFAULT_FUNCTION_FACTORY;  
    }

    public List<Function> getFunctions() {
        MetadataTree<?> keyTree = getKeyTree();
        return keyTree != null ? keyTree.getFunctions() : new LinkedList<Function>();
    }

    public final Map<File, List<Function>> getFunctionsByFile() {
        Map<File, List<Function>> result = new HashMap<>();
        List<Function> functions = getFunctions();

        if (functions != null) {
            for (Function function : getFunctions()) {
                List<Function> list = result.get(function.getFile());

                if (list == null) {
                    list = new LinkedList<>();
                    result.put(function.getFile(), list);
                }
                if (function.getFile().getName().endsWith(".sfx")) {
                    if (function.getName().equals(FilenameUtils.getBaseName(function.getFile().getName())) == false && function.getName().equals("step") == false) {
                        //hides sfx internal function (DONE)
                        //shows user visible functions (DONE): constructor,step
                        //show user visible functions (@TODO): ML functions, event functions, graphical functions
                        continue;
                    }
                }
                list.add(function);
            }
        }

        return result;
    }

    @Nullable
    public ClassInfo getClassInfo(Function function) {
        return fClassInfos != null ? fClassInfos.get(function) : null;
    }

    public void setClassInfos(Map<Function, ClassInfo> classInfos) {
        fClassInfos = classInfos;
    }

    @Nullable
    public Map<Function, ClassInfo> getClassInfos() {
        return fClassInfos;
    }

    @NotNull
    public List<Variable> getVariables(Function function) {
        return fVariableKinds.getKeys(function, Variable.class);
    }

    public final boolean hasVariable(Variable variable) {
        return fKeyTree.get(variable) != null;
    }

    public final boolean hasVariableNames() {
        return fVariableNames != null;
    }

    public boolean hasExpressions(Function function) {
        return fExpressions != null && fExpressions.containsKey(function);
    }

    public @Nullable ExpressionTree getExpressions(Function function) {
        return fExpressions.get(function);
    }

    public MetadataTree<VariableKind> getVariableKinds() {
        return fVariableKinds;
    }

    /**
     * This setter <i>does</i> automatically fire a property change event
     * unless the event batching mechanism is in use.
     */
    public final void setVariableKinds(MetadataTree<VariableKind> kinds) {
        MetadataTree<VariableKind> oldKinds = fVariableKinds;
        fVariableKinds = kinds;
        fPropertySupport.firePropertyChange(VARIABLE_KINDS_PROPERTY, oldKinds, kinds);
    }

    public final boolean hasVariableKinds() {
        return fVariableKinds != null;
    }

    public VariableKind getVariableKind(Variable variable) {
        VariableKind result = fVariableKinds.get(variable);

        if (result == null && variable.getName().contains(".")) {
            Variable structParent = new DefaultVariable(
                    variable.getFunction(),
                    variable.getName().substring(0, variable.getName().indexOf(".")));
            result = fVariableKinds.get(structParent);
        }

        return result;
    }

    public Collection<Function> getEntryPointFunctions() {
        Collection<Function> funcs = new LinkedList<>();

        for (Function func : getFunctions()) {
            if (func.isEntryPointFunction()) {
                funcs.add(func);
            }
        }

        return funcs;
    }

    public Function getEntryPointFunction(File file) {
        Collection<Function> functions = getFunctionsByFile().get(file);

        if (functions == null) {
            return null;
        }

        functions = new LinkedList<>(functions);

        for (Function func : functions) {
            if (func.isEntryPointFunction()) {
                return func;
            }
        }

        return null;
    }

    public Collection<Function> getSubFunctions(){
        Collection<Function> funcs = new LinkedList<>();

        for (Function func : getFunctions()) {
            if (!func.isEntryPointFunction()) {
                funcs.add(func);
            }
        }

        return funcs;
    }

    public void setUniqueFunctionNames(@Nullable Map<Function, String> uniqueFunctionNames) {
        //noinspection AssignmentToCollectionOrArrayFieldFromParameter
        fUniqueFunctionNames = uniqueFunctionNames;

        if (uniqueFunctionNames != null && !uniqueFunctionNames.isEmpty()) {
            fUniqueNameToFunctions = new HashMap<>((int) Math.ceil(uniqueFunctionNames.size() / 0.75));
            for (Map.Entry<Function, String> entry : uniqueFunctionNames.entrySet()) {
                fUniqueNameToFunctions.put(entry.getValue(), entry.getKey());
            }
        } else {
            fUniqueNameToFunctions = Collections.emptyMap();
        }
    }

    @Nullable
    public Function getFunctionByUniqueName(@NotNull String name) {
        return fUniqueNameToFunctions.get(name);
    }

    @NotNull
    public Map<Function, String> getUniqueFunctionNames() {
        if (fUniqueFunctionNames == null) {
            fUniqueFunctionNames = new HashMap<>();
        }
        //noinspection ReturnOfCollectionOrArrayField
        return fUniqueFunctionNames;
    }

    @NotNull
    public String getUniqueFunctionName(Function function) {
        return fUniqueFunctionNames != null && fUniqueFunctionNames.containsKey(function) ?
                fUniqueFunctionNames.get(function) : function.getSpecializationName();
    }

    public MetadataTree<VariableKind> getVariableNames() {
        return fVariableNames;
    }

    /**
     * Setter for fVariableNames. Does not automatically fire property change.
     */
    public void setVariableNames(MetadataTree<VariableKind> variableNames) {
        Object oldValue = fVariableNames;
        fVariableNames = variableNames;
        queuePropertyChangeEvent(VARIABLE_KINDS_PROPERTY, oldValue, variableNames);
    }

    private void transformLegacyMetadata() {
        // Transforms the user annotations from a legacy HDL project to the new data structure
        // where the file name is part of the function key. This can only be done after a
        // function-name/file-name mapping is available.

        Map<String, Function> newFunctions = new HashMap<>();
        for (Function function : getFunctions()) {
            newFunctions.put(function.toString(), function);

            // Here we map the function name to the one specialization, if it only has one specialization
            if (!function.getName().equals(function.toString())) {
                if (newFunctions.get(function.getName()) != null) {
                    newFunctions.remove(function.getName());
                } else {
                    newFunctions.put(function.getName(), function);
                }
            }
        }

        for (Map.Entry<String, Function> entry : fLegacyFunctions.entrySet()) {
            Function newFunction = newFunctions.get(entry.getKey());
            Function legacyFunction = entry.getValue();

            if (newFunction == null) {
                // This may be due to a specialization ID mismatch. Try to find a match by stripping
                // off the specialization prefix on the legacy function name. This doesn't find it
                // if there are multiple specializations.

                int index = entry.getKey().indexOf("_");
                if (index > 0 && index < entry.getKey().length() - 1) {
                    String prefix = entry.getKey().substring(0, index);
                    if (Pattern.compile("f[\\d]*").matcher(prefix).matches()) {
                        newFunction = newFunctions.get(entry.getKey().substring(index + 1));
                    }
                }
            }

            if (newFunction != null) {
               transformLegacyFunction(legacyFunction, newFunction);
            }
        }

        fLegacyFunctions = null;
    }

    /**
     * Hook method called by transformLegacyMetadata
     */
    protected void transformLegacyFunction(Function legacyFunction, Function newFunction){

    }

    public MatlabType getMatlabType(FunctionScopedKey key) {
        if (fMatlabTypes == null) {
            return null;
        }

        return fMatlabTypes.get(key);
    }

    public final MetadataTree<?> getKeyTree() {
        return fKeyTree != null ? fKeyTree : getVariableKinds();
    }

    public Collection<BuildError> getErrors() {
        return fErrors != null ? Collections.unmodifiableCollection(fErrors) :
                Collections.<BuildError>emptyList();
    }

    public void setErrors(Collection<BuildError> errors) {
        Object oldVal = fErrors;
        fErrors = errors;
        firePropertyChange(ERRORS_PROPERTY, oldVal, errors);
    }

    public void setPotentialDifferences(Collection<PotentialDifference> messages) {
        Object oldMessages = fPotentialDifferences;
        fPotentialDifferences = messages;
        firePropertyChange("PotentialDifferences", oldMessages, messages);
    }

    @NotNull
    public Collection<PotentialDifference> getPotentialDifferences() {
        return fPotentialDifferences != null ? Collections.unmodifiableCollection(fPotentialDifferences)
                : Collections.<PotentialDifference>emptyList();
    }

    /**
     * This setter does not automatically fire a property change event but will queue one if there
     * is an active event batch session.
     */
    protected void setKeyTree(MetadataTree<?> keyTree) {
        Object oldValue = fKeyTree;
        fKeyTree = keyTree;

        if (keyTree != null) {
            fFiles = new HashSet<>();
            for (Function func : keyTree.getFunctions()) {
                fFiles.add(func.getFile());
            }
            fFiles = Collections.unmodifiableSet(fFiles);
        } else {
            fFiles = null;
        }

        queuePropertyChangeEvent(KEY_TREE_PROPERTY, oldValue, keyTree);
    }

    @NotNull
    public Set<File> getFiles() {
        //noinspection ReturnOfCollectionOrArrayField
        return fFiles != null ? fFiles : Collections.<File>emptySet();
    }

    @Nullable
    public UnifiedModel getDerivedModel() {
        return null;
    }

    public MetadataTree<MatlabType> getMatlabTypes() {
        return fMatlabTypes;
    }

    /**
     * This setter does not automatically fire a property change event but will queue one if there
     * is an active event batch session.
     */
    protected void setMatlabTypes(MetadataTree<MatlabType> matlabTypes) {
        Object oldValue = fMatlabTypes;
        fMatlabTypes = matlabTypes;
        queuePropertyChangeEvent(MATLAB_TYPES_PROPERTY, oldValue, matlabTypes);
    }

    /**
     * This setter does not automatically fire a property change event but will queue one if there
     * is an active event batch session.
     */
    public final void setExpressions(Collection<Expression> expressions) {
        Object oldValue = fExpressions;
        Map<Function, Collection<Expression>> bucketedExprs = new HashMap<>();

        for (Expression expr : expressions) {
            Collection<Expression> bucket = bucketedExprs.get(expr.getFunction());
            if (bucket == null) {
                bucket = new LinkedList<>();
                bucketedExprs.put(expr.getFunction(), bucket);
            }
            bucket.add(expr);
        }

        fExpressions = new HashMap<>();
        for (Map.Entry<Function, Collection<Expression>> bucketEntry : bucketedExprs.entrySet()) {
            fExpressions.put(bucketEntry.getKey(), new ExpressionTree(bucketEntry.getValue()));
        }

        queuePropertyChangeEvent(EXPRESSION_PROPERTY, oldValue, fExpressions);
    }

    /**
     * This setter does fire an automatic property change unless a batch session is active.
     */
    /*public final void setVariableNames(MetadataTree<VariableKind> variables,
                                       MetadataTree<MatlabType> matlabTypes) {
        MetadataTree<VariableKind> oldVariables = fVariableNames;
        fVariableNames = variables;
        fMatlabTypes = matlabTypes;
        setKeyTree(variables);

        if (fLegacyFunctions != null && getKeyTree() != null && !getKeyTree().getFunctions().isEmpty()) {
            transformLegacyMetadata();
        }

        queuePropertyChangeEvent(VARIABLE_NAMES_PROPERTY, oldVariables, variables);
    }*/

    /**
     * This setter does not automatically fire a property change event but will queue one if there
     * is an active event batch session.
     */
    public final void setFieldNatures(MetadataTree<FieldNature> fieldNatures) {
        Object oldNatures = fFieldNatures;
        fFieldNatures = fieldNatures;
        queuePropertyChangeEvent(FIELD_DEFINITIONS_PROPERTY, oldNatures, fieldNatures);
    }

    public final MetadataTree<FieldNature> getFieldNatures() {
        return fFieldNatures;
    }

    public final boolean hasFieldNatures(){
        return fFieldNatures != null;
    }

    public final boolean hasFieldNature(Variable variable) {
        return fFieldNatures != null && fFieldNatures.get(variable) != null;
    }

    public final FieldNature getFieldNature(Variable variable) {
        return hasFieldNature(variable) ? fFieldNatures.get(variable) : null;
    }

    public final List<Variable> getLeafFields(Variable variable) {
        if (!hasFieldNature(variable)) {
            return null;
        }

        List<Variable> result = new LinkedList<>();

        for (Variable field : getFieldNature(variable).getFields()) {
            if (hasFieldNature(field)) {
                result.addAll(getLeafFields(field));
            } else {
                result.add(field);
            }
        }

        return result;
    }

    /**
     * Return the unqualified form of this field variable. Mainly for display purposes, as using
     * the returned value as a lookup key will fail. If the specified variable is not a field or
     * if no unqualified form can be returned, then the argument is returned instead.
     */
    public final Variable getUnqualifiedField(Variable fieldVariable) {
        Variable unqualifiedVar = FIELD_ACCESS_DISQUALIFIER.convert(fieldVariable);
        return unqualifiedVar != null ? unqualifiedVar : fieldVariable;
    }

    private static Converter<Variable, Variable> createDefaultFieldDisqualifier() {
        return new Converter<Variable, Variable>() {
            @Override
            public Variable convert(Variable variable) {
                String varName = Variable.cleanDisplayName(variable.getName());
                String[] parts = varName.split("\\.");
                return new DefaultVariable(variable.getFunction(), parts[parts.length-1]);
            }
        };
    }

    static String createStructAccessString(Variable structVar, String fieldName) {
        return structVar.getName() + '.' + fieldName;
    }

    public final MetadataTree<String> getClassProperties() {
        return fClassDefinedIn;
    }

    public final String getClassDefinedIn(Variable variable) {
        return fClassDefinedIn.get(variable);
    }

    public final Map<String, List<String>> getLoggedSystemObjectPropertiesInfo() {
        return fLoggedSystemObjectPropertiesInfo;
    }

    public final List<String> getLoggedSystemObjectProperties(String systemObjectClassName) {
        return fLoggedSystemObjectPropertiesInfo.get(systemObjectClassName);
    }

    protected void processTempVariables(Collection<Variable> tempVariables) {

    }

    public String generateSourceCodeChecksum() {
        Collection<File> files = new LinkedList<>();
        for (Function function : getFunctions()) {
            files.add(function.getFile());
        }

        return CodeGenerationUtils.generateFileChecksum(files, null);
    }

    private class ConversionSerializer implements UnifiedSerializationStrategy {
        private final Map<Class<?>, Converter<Object, String>> fEnumConverters;

        private ConversionSerializer() {
            fEnumConverters = new HashMap<>();
        }

        @Override
        public <T extends Enum<T>> void setEnumConverter(final Class<T> enumType,
                                                         final Converter<T, String> converter) {
            fEnumConverters.put(enumType, new Converter<Object, String>() {
                @Override
                public String convert(Object object) {
                    return enumType.isInstance(object) ?
                            converter.convert(enumType.cast(object)) : null;
                }
            });
        }

        @Override
        public void serialize(XmlSourcePolicy sourcePolicy, SerializationExtender callback) {
            if (getKeyTree() == null) {
                return;
            }

            XmlWriter annotationRoot = XmlApi.getInstance().create(XML_USER_NODE);
            XmlWriter computedRoot = XmlApi.getInstance().create(XML_COMPUTED_NODE);

            for (Function function : getFunctions()) {
                if (!callback.shouldSerializeFunction(function)) {
                    continue;
                }

                XmlWriter functionAnnotationRoot = createFunctionRoot(sourcePolicy, annotationRoot, function);
                XmlWriter functionComputedRoot = createFunctionRoot(sourcePolicy, computedRoot, function);

                for (Variable variable : getVariables(function)) {
                    if (!callback.shouldSerializeVariable(variable)) {
                        continue;
                    }

                    XmlWriter variableAnnotationRoot = appendVariableRoot(functionAnnotationRoot,
                            variable);
                    XmlWriter variableComputedRoot = appendVariableRoot(functionComputedRoot,
                            variable);

                    if (getVariableKinds() != null) {
                        serializeProperty(variableComputedRoot, "Kind", "String", getVariableKind(variable));
                    }

                    callback.serializeVariableExtensions(variable,
                            variableAnnotationRoot, variableComputedRoot, this);
                }


                callback.serializeFunctionExtensions(function,
                        functionAnnotationRoot, functionComputedRoot, this);
            }

            try {
                sourcePolicy.setComputedXML(XmlApi.getInstance().read(computedRoot.getXML()));
                sourcePolicy.setAnnotatedXML(XmlApi.getInstance().read(annotationRoot.getXML()));
            } catch (IOException iox) {
                throw new IllegalStateException(iox);
            }

            callback.serializeAdditionalExtensions(this);
        }

        private XmlWriter appendVariableRoot(XmlWriter parent, Variable variable) {
            XmlWriter varRoot = parent.createElement("Variable");
            varRoot.writeAttribute("name", variable.getName());
            // Write this unconditionally as its presence will indicate the serialization version
            varRoot.writeAttribute("specid", variable.getVariableSpecializationId());

            if (variable.getParent() != null && variable.getParent().isSpecialized()) {
                // Serialize the parent's specialization in order to facilitate restoration of the child
                varRoot.writeAttribute("parentspec", variable.getParent().getVariableSpecializationId());
            }

            return varRoot;
        }

        private XmlWriter createFunctionRoot(XmlSourcePolicy sourcePolicy,
                                             XmlWriter parent,
                                             Function function) {

            XmlWriter functionRoot = parent.createElement("Function");
            functionRoot.writeAttribute("file", sourcePolicy.convertFileToReference(
                    function.getFile()));
            functionRoot.writeAttribute("name", function.getName());
            functionRoot.writeAttribute("uniqueId", getUniqueFunctionName(function));
            functionRoot.writeAttribute("specialization", function.getSpecializationName());
            functionRoot.writeAttribute("specializationId", function.getLegacySpecializationId());

            return functionRoot;
        }

        @Override
        public <T> void serializeAnnotatedProperty(XmlWriter computedRoot,
                                                    XmlWriter annotationRoot,
                                                    String propertyName,
                                                    String type,
                                                    AnnotatedMetadataTree<T> tree,
                                                    Variable variable) {

            if (tree.getComputedValues() != null) {
                serializeProperty(computedRoot,
                        propertyName,
                        type,
                        tree.getComputedValues().get(variable));
            }

            serializeProperty(annotationRoot,
                    propertyName,
                    type,
                    tree.getUserValues().get(variable));
        }

        @Override
        public void serializeProperty(XmlWriter variable, String propertyName, String type,
                                      Object value) {
            if (value != null && value instanceof Enum) {
                if (fEnumConverters.containsKey(value.getClass())) {
                    value = fEnumConverters.get(value.getClass()).convert(value);
                } else {
                    value = ((Enum) value).name().toLowerCase(Locale.ENGLISH);
                }
            }

            if (value != null) {
                XmlWriter column = variable.createElement("Column");
                column.writeAttribute("property", propertyName);
                column.writeAttribute("type", type);
                column.writeAttribute("value", value);
            }
        }

        @Override
        public void serializeMatlabType(XmlWriter variable, MatlabType type) {
            XmlWriter typeRoot = variable.createElement("MATLABType");
            typeRoot.writeAttribute("class", type.getClassName());
            typeRoot.writeAttribute("complex", type.isComplex());
            for (int dimension : type.getSize()) {
                typeRoot.writeText("size", dimension);
            }

            for (boolean dynamic : type.getDynamicFlags()) {
                typeRoot.writeText("dynamic", dynamic);
            }

            if (type.getNumericType() != null) {
                XmlWriter numericTypeRoot = typeRoot.createElement("numericType");
                numericTypeRoot.writeText("signed", type.getNumericType().isSigned());
                numericTypeRoot.writeText("wordLength", type.getNumericType().getWordLength());
                numericTypeRoot.writeText("fractionLength", type.getNumericType().getFractionLength());
                numericTypeRoot.writeText("fimathIsLocal", type.isFimathLocal());
            }

            if (type.getFimath() != null) {
                XmlWriter fimathRoot = typeRoot.createElement("fimath");
                type.getFimath().getData(fimathRoot);
            }
        }

        @Override
        public MatlabType deserializeMatlabType(XmlReader variable) {
            XmlReader typeRoot = variable.getChild("MATLABType");
            if (typeRoot.isPresent()) {
                try {
                    String className = typeRoot.readAttribute("class");
                    boolean complex = Boolean.parseBoolean(typeRoot.readAttribute("complex"));
                    String[] sizeStrings = typeRoot.readTextList("size");
                    int[] sizes = new int[sizeStrings.length];
                    for (int i = 0; i < sizes.length; i++) {
                        sizes[i] = Integer.parseInt(sizeStrings[i]);
                    }

                    String[] dynamicFlags = typeRoot.readTextList("dynamic");
                    boolean[] dynamic = new boolean[dynamicFlags.length];
                    for (int i = 0; i < dynamic.length; i++) {
                        dynamic[i] = dynamicFlags[i].equals("true");
                    }

                    NumericType numericType = null;
                    IDPFimath fimath = null;
                    boolean fimathIsLocal = false;

                    XmlReader numericTypeRoot = typeRoot.getChild("numericType");
                    if (numericTypeRoot.isPresent()) {
                        String signed = numericTypeRoot.readText("signed");
                        String wordLength = numericTypeRoot.readText("wordLength");
                        String fractionLength = numericTypeRoot.readText("fractionLength");

                        if (signed != null && wordLength != null && fractionLength != null) {
                            fimathIsLocal = Boolean.parseBoolean(
                                    numericTypeRoot.readText("fimathIsLocal"));
                            numericType = new NumericType(Boolean.parseBoolean(signed), Integer.parseInt(wordLength), Integer.parseInt(fractionLength), false);
                        }
                    }

                    XmlReader fimathRoot = typeRoot.getChild("fimath");
                    if (fimathRoot.isPresent()) {
                        fimath = new IDPFimath();
                        Utilities.setPropertyValues(fimathRoot, fimath);
                    }

                    return new MatlabType(className, sizes, dynamic, complex, numericType, fimath, fimathIsLocal);
                } catch (RuntimeException x) {
                    return null;
                }
            }

            return null;
        }

        @Override
        public void deserialize(XmlSourcePolicy sourcePolicy,
                                DeserializationExtender callback,
                                boolean includeComputedData) {
            if (includeComputedData) {
                deserializeRoot(sourcePolicy, callback, sourcePolicy.getComputedXML(), true);
            }

            deserializeRoot(sourcePolicy, callback, sourcePolicy.getAnnotatedXML(), false);
        }

        private void deserializeRoot(XmlSourcePolicy sourcePolicy,
                                     DeserializationExtender callback,
                                     XmlReader root,
                                     boolean computed) {
            if (root == null) {
                return;
            }

            XmlReader function = root.getChild("Function");
            Collection<Variable> tempVariables = new LinkedList<>();
            RestorationVarLookup varLookup = new RestorationVarLookup();

            Map<Function, String> uniqueNames = new HashMap<>();

            while (function.isPresent()) {
                String fileName = function.readAttribute("file");
                String functionName = function.readAttribute("name");
                String specializationName = function.readAttribute("specialization");
                String uniqueId = function.readAttribute("uniqueId");
                String specializationId = function.readAttribute("specializationId");

                Integer specializationNum = null;
                Function functionObject;
                File file;

                if (fileName == null) {
                    // This means it's an old HDL project with less metadata than modern projects.
                    file = new File(functionName);
                    if (fLegacyFunctions == null) {
                        fLegacyFunctions = new HashMap<>();
                    }
                    functionObject = getFunctionFactory().createFunction(file, functionName,
                            specializationName);
                    fLegacyFunctions.put(functionName, functionObject);
                } else {
                    // Legacy project, copy fields
                    if (specializationName != null && uniqueId == null) {
                        uniqueId = specializationName;
                    }

                    if (specializationId != null && !specializationId.isEmpty()) {
                        try {
                            specializationNum = Integer.valueOf(specializationId);
                        } catch (NumberFormatException ignored) {

                        }
                    }

                    file = sourcePolicy.convertReferenceToFile(fileName);
                    functionObject = fileName != null && functionName != null && uniqueId != null && specializationNum != null?
                            getFunctionFactory().createFunction(file, functionName,
                                    specializationName, new FunctionSpecializationId(specializationNum)) :
                            getFunctionFactory().createFunction(file, functionName, specializationName);
                    if (uniqueId != null && !uniqueId.isEmpty()) {
                        uniqueNames.put(functionObject, uniqueId);
                    }
                }

                if (getUniqueFunctionNames() == null || getUniqueFunctionNames().isEmpty()) {
                    setUniqueFunctionNames(uniqueNames);
                }

                varLookup.reset();
                XmlReader variableReader = function.getChild("Variable");

                while (variableReader.isPresent()) {
                    String variableName = variableReader.readAttribute("name");
                    String specIdStr = variableReader.readAttribute("specid");
                    Variable variable = null;

                    if (specIdStr != null) {
                        try {
                            int specId = Integer.parseInt(specIdStr);
                            String parentSpecStr = variableReader.readAttribute("parentspec");
                            int parentSpec = parentSpecStr != null ? Integer.parseInt(parentSpecStr) :
                                    Function.NO_SPECIALIZATION_ID;
                            variable = new FineGrainedVariable(functionObject, variableName,
                                    varLookup.getParentVariable(variableName, parentSpec),
                                    specId, Collections.<Interval>emptyList());
                            varLookup.addVariable(variable);
                        } catch(NumberFormatException nfe) {
                            // OK
                        }
                    }
                    if(variable == null) {
                        // Legacy without specid attribute or invalid specid value
                        variable = new DefaultVariable(functionObject, variableName);
                    }

                    tempVariables.add(variable);

                    if (computed) {
                        if (getVariableNames() == null) {
                            setVariableNames(new MetadataTree<VariableKind>());
                            setVariableKinds(new MetadataTree<VariableKind>());
                            setMatlabTypes(new MetadataTree<MatlabType>());
                        }

                        getVariableNames().put(variable, VariableKind.LOCAL);
                        getMatlabTypes().put(variable, deserializeMatlabType(variableReader));
                    }

                    XmlReader column = variableReader.getChild("Column");
                    while (column.isPresent()) {
                        callback.deserializeColumn(functionObject, variable, column, computed, this);
                        column = column.next();
                    }
                    variableReader = variableReader.next();
                }

                if (computed && getVariableNames() != null) {
                    setKeyTree(getVariableNames());
                }

                callback.deserializeColumn(functionObject, function, computed, this);
                function = function.next();
            }

            processTempVariables(tempVariables);
        }

        @Override
        public AbstractMap.SimpleEntry<String, String> deserializeColumnProperty(XmlReader column) {
            String propertyName = column.readAttribute("property");
            String value = column.readAttribute("value");

            if (propertyName != null && value != null) {
                return new AbstractMap.SimpleEntry(propertyName, value);
            }

            return null;
        }
    }

    private static class RestorationVarLookup {
        private final Map<String, Variable> fUnspecialized;
        private final Map<String, Map<Integer, Variable>> fSpecialized;

        RestorationVarLookup() {
            fUnspecialized = new HashMap<>(25);
            fSpecialized = new HashMap<>(25);
        }

        void addVariable(@NotNull Variable variable) {
            if (variable.isSpecialized()) {
                Map<Integer, Variable> specs = fSpecialized.get(variable.getName());
                if (specs == null) {
                    specs = new TreeMap<>();
                    fSpecialized.put(variable.getName(), specs);
                }
                specs.put(variable.getVariableSpecializationId(), variable);
            } else {
                fUnspecialized.put(variable.getName(), variable);
            }
        }

        @Nullable
        Variable getVariable(String name, int specId) {
            return fSpecialized.containsKey(name) ? fSpecialized.get(name).get(specId) : fUnspecialized.get(name);
        }

        @Nullable
        Variable getParentVariable(String qualifiedName, int parentSpecId) {
            String[] splitClassDefinedIn = qualifiedName.split(",");
            String varName = splitClassDefinedIn[0];
            String[] tokens = varName.split("\\.");
            StringBuilder upstreamPath = new StringBuilder();
            for (int i = 0; i < tokens.length - 1; i++) {
                upstreamPath.append(tokens[i]);
                if (i + 1 < tokens.length - 1) {
                    upstreamPath.append('.');
                }
            }
            return tokens.length > 1 ? getVariable(upstreamPath.toString(), parentSpecId) : null;
        }

        void reset() {
            fUnspecialized.clear();
            fSpecialized.clear();
        }
    }
}

// LocalWords:  sfx
