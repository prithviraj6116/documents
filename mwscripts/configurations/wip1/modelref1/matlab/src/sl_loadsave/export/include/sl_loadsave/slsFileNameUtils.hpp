/* Copyright 2009-2016 The MathWorks, Inc. */

#pragma once

#include "sl_loadsave_spec.hpp"

#include "i18n/filesystem/upath.hpp"
#include "sl_services/slsvStringTable.hpp"
#include "sl_loadsave/sl_loadsave_fwd.hpp"

namespace slsFileNameUtils {
// Returns the extension, if there is one, from the supplied file
// name. This includes the leading dot.
SL_LOADSAVE_EXPORT_FCN slsvString GetExtension(const slsvString& f);

// Returns true if the specified file name ends with the specified
// extension.  Case-sensitive on platforms other than Windows.
SL_LOADSAVE_EXPORT_FCN bool HasExtension(const slsvString& fullFileName, const slsvString& ext);

// Returns true if the specified file name ends with any of the file
// extensions used by Simulink model files.
// Case-sensitive on platforms other than Windows.
SL_LOADSAVE_EXPORT_FCN bool HasSimulinkExtension(const slsvString& fullFileName,
                                                 bool allowProtected);


SL_LOADSAVE_EXPORT_FCN bool isSLX(const slsvString& fullFileName);
SL_LOADSAVE_EXPORT_FCN bool isSFX(const slsvString& fullFileName);
SL_LOADSAVE_EXPORT_FCN bool isSLXP(const slsvString& fullFileName);
SL_LOADSAVE_EXPORT_FCN bool isMDL(const slsvString& fullFileName);

// Returns true if the specified file name ends with any of the file
// extensions used by Simulink model files.
// Case-sensitive on platforms other than Windows.
SL_LOADSAVE_EXPORT_FCN bool HasSimulinkProtectedModelExtension(const slsvString& fullFileName);

inline bool HasSimulinkExtension(const slsvString& fullFileName) {
    return HasSimulinkExtension(fullFileName, false);
}

// Remove a simulink extension from the given file, if present
SL_LOADSAVE_EXPORT_FCN slsvString RemoveSimulinkExtensionIfPresent(const slsvString& fullFileName);

// Copies just the "block diagram" name part of the file name into
// the supplied string object.  Throws an exception if the supplied
// name is not a valid MDL file name.  If check_extension is true, this
// includes checking that the file extension is valid for a Simulink model.
// If allow_reserved is false, the names "simulink" and "sf" are treated as
// invalid, since a user must not create block diagrams with these names.
SL_LOADSAVE_EXPORT_FCN slsvString GetBlockDiagramName(const slsvString& fullname,
                                                      bool check_extension = true,
                                                      bool allow_reserved = true,
                                                      bool allow_protected = false);

// Throws an exception with a suitable identifier if the specified name is
// not valid for a block diagram.  This is the case if the name is longer
// that 63 characters, if it is a MATLAB keyword, or if it is not valid as
// a MATLAB variable name.  Also, optionally, the names "simulink" and "sf"
// are treated as invalid, since users must not create block diagrams with
// these names.
SL_LOADSAVE_EXPORT_FCN void CheckValidBlockDiagramName(const slsvString& bdname,
                                                       bool allow_simulink = true);

// Our code for reading MDL files on Windows cannot cope with very long
// file names.
SL_LOADSAVE_EXPORT_FCN void CheckMDLFileNameLength(const slsvString& filename);

enum ResolveNameType {
    // For loading a model, or specifically referencing an "unprotected"
    // model.  (SLX or MDL or SFX)
    RESOLVE_UNPROTECTED_MODEL,

    // For referencing a model (SLXP, SLX, MDL, or MDLP)
    RESOLVE_UNPROTECTED_OR_PROTECTED_MODEL,

    // For specifically referencing a protected model (SLXP or MDLP)
    RESOLVE_PROTECTED_MODEL
};

SL_LOADSAVE_EXPORT_FCN slsvString ResolveName(const slsvString& name, ResolveNameType type);

SL_LOADSAVE_EXPORT_FCN slsvString ResolveName(const slsvString& name, const slsvString& extension);

SL_LOADSAVE_EXPORT_FCN slsvString ResolveFolder(const slsvString& name);

enum ResolveNameForSavingType { SAVE_MDL, SAVE_SLX, EXPORT_TO_XML };

// Converts a user-supplied name into a fully-qualified name of the
// requested type.  An error is thrown if the supplied name is not
// suitable for use as a model name.
SL_LOADSAVE_EXPORT_FCN slsvString ResolveNameForSaving(const slsvString& current_bdname,
                                                       const slsvString& supplied_name,
                                                       ResolveNameForSavingType type);

// Converts a user-supplied name into a fully-qualified name with the
// specified extension (if not empty).  If the supplied name already has
// a different extension, the new extension is appended.
SL_LOADSAVE_EXPORT_FCN slsvString ResolveNameForSaving(const slsvString& supplied_name,
                                                       const slsvString& extension);

// Copies the specified file to a new name with the specified
// suffix.  Returns the new name.
SL_LOADSAVE_EXPORT_FCN slsvString CopyWithSuffix(const slsvString& fullname,
                                                 const slsvString& suffix,
                                                 bool multipleAttempts = true);

// Renames the specified file to a new name with the specified
// suffix.  Optionally, the function will try further suffixes if using
// the supplied one fails.  Optionally, the path manager will be
// notified of the change. The new name is returned.
SL_LOADSAVE_EXPORT_FCN slsvString RenameWithSuffix(const slsvString& fullname,
                                                   const slsvString& suffix,
                                                   bool multipleAttempts = true);

// Returns the specified file name without the specified extension, if
// that extension was present.  If the specified extension is not
// present, the file name is returned unchanged.
SL_LOADSAVE_EXPORT_FCN slsvString RemoveExtensionIfPresent(const slsvString& filename,
                                                           const slsvString& extension);

// Moves the file to the specified location, optionally notifying
// the path manager of the change.  Any existing file of the same
// name will be overwritten if possible.  The extension must include
// the leading dot.
SL_LOADSAVE_EXPORT_FCN void RenameFile(const slsvString& fullname, const slsvString& newname);

// Deletes the specified file, optionally notifying
// the path manager of the change.
SL_LOADSAVE_EXPORT_FCN void RemoveFile(const slsvString& fullname);

/**
 * Returns true if the specified file exists.
 */
SL_LOADSAVE_EXPORT_FCN bool FileExists(const fl::filesystem::upath& fullname);
SL_LOADSAVE_EXPORT_FCN bool FileExists(const slsvString& fullname);

/**
 * Returns true if the specified file exists and is writable.
 *
 * @return Whether the file is writable.
 * @note Function does not throw.
 */
SL_LOADSAVE_EXPORT_FCN bool FileIsWritable(const slsvString& filename);

/**
 * Returns the result of attempting to make the specified file writable.
 *
 * @throw fl::filesystem::FsysExceptionBase See fl::filesystem.
 */
SL_LOADSAVE_EXPORT_FCN void MakeFileWritable(const slsvString& filename);

// Like FileIsWritable, but throws an exception if the file is not writable.
SL_LOADSAVE_EXPORT_FCN void CheckFileWritable(const slsvString& filename);

// Copies permissions from one file to another.
SL_LOADSAVE_EXPORT_FCN void CopyFilePermissions(const slsvString& from, const slsvString& to);

/**
 * Copies the contents of a file from one location to another.
 * Also copies the last modification time from the original to the new file.
 *
 * @throw Simulink::LoadSave::FileReadError
 * @throw Simulink::LoadSave::FileWriteError
 */
SL_LOADSAVE_EXPORT_FCN void slsCopyFile(const slsvString& from, const slsvString& toq);

SL_LOADSAVE_EXPORT_FCN bool IsSameFile(const slsvString& f1, const slsvString& f2);

// Converts C:\xyz to c:\xyz or vice versa for cases where we need
// to try both versions to find our function in the dispatcher's map.
SL_LOADSAVE_EXPORT_FCN slsvString ToggleDriveNameCase(const slsvString& fullname);

// Returns true if a folder exists with the specified name.
SL_LOADSAVE_EXPORT_FCN bool IsFolder(const slsvString& name);

// Returns true if the autosave file for the given model full file is present
SL_LOADSAVE_EXPORT_FCN bool IsAutosavePresent(const slsvString& fullfile);

// Returns true if the file is part of the MATLAB installation.
SL_LOADSAVE_EXPORT_FCN bool IsMathWorksFile(const slsvString& name);

// Returns true if the file is part of the "toolbox" folder inside the MATLAB installation.
SL_LOADSAVE_EXPORT_FCN bool IsMathWorksToolboxFile(const slsvString& name);

// Return the last modification time of a file as an slsFileMTimeType.
SL_LOADSAVE_EXPORT_FCN slsFileMTimeType GetLastModifiedTime(const slsvString& filename);

// Returns the resolved model name.  If the name is unresolved, returns empty.
// If the file name is invalid in some way it is returned unchanged.
SL_LOADSAVE_EXPORT_FCN slsvString GetFullModelName(const slsvString& name);

class SL_LOADSAVE_EXPORT_CLASS FileExt {
  public:
    static const fl::uchar* const UMDL;
    static const fl::uchar* const USLX;
    static const fl::uchar* const USFX;
    static const fl::uchar* const USLXP;
    static const fl::uchar* const UMDLP;
    static const fl::uchar* const UAUTOSAVE;
    static const char* const MDL;
    static const char* const SLX;
    static const char* const SFX;
    static const char* const SLXP;
    static const char* const MDLP;
    static const char* const AUTOSAVE;
    static const slsvString& getMDL();
    static const slsvString& getSLX();
    static const slsvString& getSFX();
    static const slsvString& getSLXP();
    static const slsvString& getMDLP();
    static const slsvString& getAUTOSAVE();
};

SL_LOADSAVE_EXPORT_FCN const slsvString& getPreferredFileExtension();
SL_LOADSAVE_EXPORT_FCN void setPreferredFileExtension(const slsvString& t);

// Looks at the contents of the specified file and returns a suitable
// suffix for using in the name of a back-up copy of the file.
SL_LOADSAVE_EXPORT_FCN slsvString getBackupExtensionFromFile(const slsvString& filename,
                                                             bool only_if_old_version);

enum ShadowType {
    // This file name does not conflict with any other name on the MATLAB
    // path or in the workspace.
    NOT_SHADOWED,
    // This file is shadowed by another file of the same name on the MATLAB
    // path.
    SHADOWED_BY_FILE,
    // This file is shadowed by a variable in the MATLAB workspace.
    SHADOWED_BY_VARIABLE,
    // This file is not on the MATLAB path, but is not shadowed.
    NOT_ON_PATH,
    // This SLX file shadows an MDL file which is more recent.
    SLX_FILE_SHADOWS_MORE_RECENT_MDL_FILE
};

// Looks for file of the same name on the MATLAB path and returns information
// about whether any are likely to conflict with the specified one.  If the
// file is shadowed by another file then the name of that file is returned
// in the second input argument.
SL_LOADSAVE_EXPORT_FCN ShadowType CheckShadowed(const slsvString& file, fl::ustring& shadower);

// Returns true if the specified file is shadowing another file of the same
// name on the MATLAB path.
SL_LOADSAVE_EXPORT_FCN bool CheckShadowing(const slsvString& file);

// Notify the path manager of a change to the specified file.
SL_LOADSAVE_EXPORT_FCN void NotifyPathManager(const slsvString& filename);

// Notify the path manager of a change to the specified files.
SL_LOADSAVE_EXPORT_FCN void NotifyPathManager(const std::vector<slsvString>&);

// Refresh the path manager so that any changes to files on the MATLAB path
// are detected.
SL_LOADSAVE_EXPORT_FCN void RefreshPathManager();

// While instances of this class exist, calls to ResolveName will not
// automatically refresh the path manager, meaning that changes to files
// on the MATLAB path since the last call may not be detected, but also
// saving a lot of time.
class SL_LOADSAVE_EXPORT_CLASS DisablePathRefreshing {
  public:
    DisablePathRefreshing();
    ~DisablePathRefreshing();
    void disable();
    void enable();

  private:
    bool fEnabled;
};

// A diagnostic about a missing SLX file.
SL_LOADSAVE_EXPORT_FCN slsvDiagnostic getSLXFileMissingDiagnostic(const slsvString& filename);

} // End namespace slsFileNameUtils

// LocalWords:  SLX SLXP MDLP Fsys xyz sls MTime
