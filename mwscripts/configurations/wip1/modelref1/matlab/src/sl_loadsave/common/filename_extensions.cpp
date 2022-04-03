// Copyright 2013-2018 The MathWorks, Inc.
#include "version.h"

#include "sl_loadsave/slsFileNameUtils.hpp"

#include "filename_helpers.hpp"
#include "common.hpp"

#include "fl/diag/terminate.hpp"

namespace slsFileNameUtils {

const fl::uchar* const FileExt::UMDL = USTR(".mdl");
const fl::uchar* const FileExt::USLX = USTR(".slx");
const fl::uchar* const FileExt::USFX = USTR(".sfx");
const fl::uchar* const FileExt::USLXP = USTR(".slxp");
const fl::uchar* const FileExt::UMDLP = USTR(".mdlp");
const fl::uchar* const FileExt::UAUTOSAVE = USTR(".autosave");

const char* const FileExt::MDL = ".mdl";
const char* const FileExt::SLX = ".slx";
const char* const FileExt::SFX = ".sfx";
const char* const FileExt::SLXP = ".slxp";
const char* const FileExt::MDLP = ".mdlp";
const char* const FileExt::AUTOSAVE = ".autosave";

const slsvString& FileExt::getMDL() {
    // Construct on first use.
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::MDL));
    return ext;
}

const slsvString& FileExt::getSLX() {
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::SLX));
    return ext;
}

const slsvString& FileExt::getSFX() {
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::SFX));
    return ext;
}
const slsvString& FileExt::getSLXP() {
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::SLXP));
    return ext;
}

const slsvString& FileExt::getMDLP() {
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::MDLP));
    return ext;
}

const slsvString& FileExt::getAUTOSAVE() {
    static slsvString ext = slsvString::persistent(slsvToUString(FileExt::AUTOSAVE));
    return ext;
}

// Preferred file format.  Either MDL or SLX.
static bool gUseSLX = true;

const slsvString& getPreferredFileExtension() {
    if (gUseSLX) {
        return FileExt::getSLX();
    } else {
        return FileExt::getMDL();
    }
}

void setPreferredFileExtension(const slsvString& t) {
    if (t == FileExt::getSLX()) {
        gUseSLX = true;
    } else if (t == FileExt::getMDL()) {
        gUseSLX = false;
    } else {
        // This won't be the most coherent error message, but it's not
        // reachable by users under normal circumstances.
        slsThrow(Simulink::LoadSave::InvalidFileNameExtensionAll(t.c_str()));
    }
}

// Returns true if the specified file name ends with the specified
// extension, which must start with a dot.  Comparison is case-sensitive
// on platforms other than Windows.
bool HasExtension(const slsvString& fullname, const slsvString& ext) {
    FL_DIAG_ASSERT(!ext.empty());
    FL_DIAG_ASSERT(ext.c_str()[0] == '.');

#ifdef _WIN32
#define STRCMPFCN slsvStrcmpi
#else
#define STRCMPFCN slsvStrcmp
#endif

    size_t length = fullname.length();
    size_t extlen = ext.length();
    if ((length < extlen + 1) ||
        (STRCMPFCN(&fullname.c_str()[length - extlen], ext.c_str()) != 0)) {
        return false;
    }
    return true;
}

bool isSLX(const slsvString& fullFileName) {
    return HasExtension(fullFileName, FileExt::getSLX());
}

bool isSFX(const slsvString& fullFileName) {
    return HasExtension(fullFileName, FileExt::getSFX());
}
bool isSLXP(const slsvString& fullFileName) {
    return HasExtension(fullFileName, FileExt::getSLXP());
}

bool isMDL(const slsvString& fullFileName) {
    return HasExtension(fullFileName, FileExt::getMDL());
}


bool HasSimulinkProtectedModelExtension(const slsvString& fullFileName) {
    return (HasExtension(fullFileName, FileExt::getMDLP()) ||
            HasExtension(fullFileName, FileExt::getSLXP()));
}

bool HasSimulinkExtension(const slsvString& fullFileName, bool allowProtected) {
    return HasExtension(fullFileName, FileExt::getMDL()) ||
           HasExtension(fullFileName, FileExt::getSLX()) ||
           HasExtension(fullFileName, FileExt::getSFX()) ||
           (allowProtected && HasSimulinkProtectedModelExtension(fullFileName));
}

slsvString GetExtension(const fl::filesystem::upath& p) {
    fl::ustring ext = p.extension();
    if (!ext.empty()) {
        if (ext[0] != '.') {
            static const fl::ustring sDot(USTR("."));
            ext.insert(0U, sDot);
        }
    }
    return slsvString(ext);
}

slsvString GetExtension(const slsvString& f) {
    return GetExtension(fl::filesystem::upath(f.str()));
}

void CheckExtension(const fl::ustring& filename,
                    const slsvString& ext,
                    ResolveNameType resolvetype) {
    switch (resolvetype) {
    case RESOLVE_UNPROTECTED_MODEL:
        if (ext != FileExt::getSLX() && ext != FileExt::getMDL()) {
            slsThrow(Simulink::LoadSave::InvalidFileNameExtension(filename));
        }
        break;

    case RESOLVE_PROTECTED_MODEL:
        if (ext != FileExt::getSLXP() && ext != FileExt::getMDLP()) {
            slsThrow(Simulink::LoadSave::InvalidFileNameExtensionProtected(filename));
        }
        break;

    default:
        FL_DIAG_ASSERT(resolvetype == RESOLVE_UNPROTECTED_OR_PROTECTED_MODEL);
        if (ext != FileExt::getSLX() && ext != FileExt::getMDL() && ext != FileExt::getMDLP() &&
            ext != FileExt::getSLXP()) {
            slsThrow(Simulink::LoadSave::InvalidFileNameExtensionAll(filename));
        }
    }
}

slsvString RemoveExtensionIfPresent(const slsvString& filename, const slsvString& extension) {
    FL_DIAG_ASSERT(!extension.empty());
    FL_DIAG_ASSERT(extension[0] == '.');
    if (HasExtension(filename, extension)) {
        fl::ustring fn(filename);
        fn.erase(fn.length() - extension.length());
        return slsvString(fn);
    } else {
        return filename;
    }
}

slsvString RemoveSimulinkExtensionIfPresent(const slsvString& filename) {
    static const char* exts[] = {FileExt::MDL, FileExt::SLX, FileExt::MDLP, FileExt::SLXP, FileExt::SFX, NULL};

    for (size_t i = 0; exts[i] != NULL; ++i) {
        // Be careful here, want to convert "foo.mdlp.mdl" into "foo.mdlp",
        // not "foo", so return when the first extension is removed.
        const slsvString ext(slsvToUString(exts[i]));
        slsvString newFile = RemoveExtensionIfPresent(filename, ext);
        
        if (newFile != filename) {
            FL_DIAG_ASSERT(HasSimulinkExtension(filename, true));
            if (isSFX(filename)) {
                newFile.append(USTR("SFX"));
            }
            return (newFile);
        }
    }

    return (filename);
}

} // namespace slsFileNameUtils
