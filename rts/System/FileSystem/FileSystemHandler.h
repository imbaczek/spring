#ifndef FILESYSTEMHANDLER_H
#define FILESYSTEMHANDLER_H

#include <vector>
#include <string>

#include "DataDirLocater.h"

/**
 * @brief native file system handling abstraction
 */
class FileSystemHandler
{
public:
	static FileSystemHandler& GetInstance();
	static void Initialize(bool verbose);
	static void Cleanup();

	void Initialize();

	// almost direct wrappers to system calls
	bool mkdir(const std::string& dir) const;
	static bool DeleteFile(const std::string& file);
	static bool FileExists(const std::string& file);
	static bool DirExists(const std::string& dir);
	/// oddly, this is non-trivial on Windows
	static bool DirIsWritable(const std::string& dir);

	void Chdir(const std::string& dir);
	/**
	 * Returns true if path matches regex ...
	 * on windows:          ^[a-zA-Z]\:[\\/]?$
	 * on all other systems: ^/$
	 */
	static bool IsFSRoot(const std::string& path);

	// custom functions
	/**
	 * @brief find files
	 * @param dir path in which to start looking (tried relative to each data directory)
	 * @param pattern pattern to search for
	 * @param flags possible values: FileSystem::ONLY_DIRS, FileSystem::INCLUDE_DIRS, FileSystem::RECURSE
	 * @return absolute paths to the files
	 *
	 * Will search for a file given a particular pattern.
	 * Starts from dirpath, descending down if recurse is true.
	 */
	std::vector<std::string> FindFiles(const std::string& dir, const std::string& pattern, int flags) const;
	static bool IsReadableFile(const std::string& file);
	/**
	 * Returns an absolute path if the file was found in one of the data-dirs,
	 * or the argument (relative path) if it was not found.
	 *
	 * @return  an absolute path to file on success, or the argument
	 *          (relative path) on failure
	 */
	std::string LocateFile(const std::string& file) const;
	std::string GetWriteDir() const;
	std::vector<std::string> GetDataDirectories() const;

	static int GetNativePathSeparator() { return native_path_separator; }
	static bool IsAbsolutePath(const std::string& path);

private:
	~FileSystemHandler();
	FileSystemHandler();

	/**
	 * @brief internal find-files-in-a-single-datadir-function
	 * @param absolute paths to the dirs found will be added to this
	 * @param datadir root of the VFS data directory. This part of the path IS NOT included in returned matches.
	 * @param dir path in which to start looking. This part of path IS included in returned matches.
	 * @param pattern pattern to search for
	 * @param flags possible values: FileSystem::ONLY_DIRS, FileSystem::INCLUDE_DIRS, FileSystem::RECURSE
	 *
	 * Will search for dirs given a particular pattern.
	 * Starts from dir, descending down if FileSystem::ONLY_DIRS is set in flags.
	 */
	void FindFilesSingleDir(std::vector<std::string>& matches, const std::string& datadir, const std::string& dir, const std::string &pattern, int flags) const;

	DataDirLocater locater;
	static FileSystemHandler* instance;

	static const int native_path_separator;
};

#endif // !FILESYSTEMHANDLER_H
