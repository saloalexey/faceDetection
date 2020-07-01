#include "CmdLineOptions.hpp"

#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

#include <iostream>

namespace po = boost::program_options;
namespace fs = boost::filesystem;

std::pair<CmdLineOptions, bool> initCmdLineOptions(int argc, char** argv)
{
    bool           ret{true};
    CmdLineOptions cmdLineOpts;

    po::options_description desc("Allowed options");
    desc.add_options()("help,h", "Print usage message")("version,v",
                                                        "Print application version")(
      "output,o", po::value(&cmdLineOpts.imagesDstDir), "Output data directory")(
      "input,i", po::value(&cmdLineOpts.imagesSrcDir), "Input data directory");

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help"))
    {
        std::cout << desc << "\n";
        return {cmdLineOpts, false};
    }

    if (vm.count("version"))
    {
        auto version = std::string("Version: ") + std::string(PROJECT_VERSION);
        std::cout << version << "\n";
        return {cmdLineOpts, false};
    }

    if (!vm.count("input"))
    {
        std::cout << "[Error] Obligatory param 'input' was not set.Terminate...\n ";
        std::cout << desc << "\n";
        return {cmdLineOpts, false};
    }

    if (!fs::exists(fs::path(cmdLineOpts.imagesSrcDir)))
    {
        std::cout << "[Error] Directory " << cmdLineOpts.imagesSrcDir
                  << " doesn't exist\n";
        return {cmdLineOpts, false};
    }

    if (cmdLineOpts.imagesDstDir.empty())
    {
        cmdLineOpts.imagesDstDir =
          std::string(fs::path(cmdLineOpts.imagesSrcDir).parent_path().c_str())
          + "-output/";

        boost::system::error_code err;
        fs::create_directory(cmdLineOpts.imagesDstDir, err);
        if (err)
        {
            std::cout << "[Error] Can't create ouput directory "
                      << cmdLineOpts.imagesDstDir << "\n";
            return {cmdLineOpts, false};
        }
    }

    auto stat = fs::status(cmdLineOpts.imagesDstDir);
    if (stat.permissions() == fs::owner_write || stat.permissions() == fs::group_write
        || stat.permissions() == fs::others_write)
    {
        std::cout << "[Error] Can't write to " << cmdLineOpts.imagesDstDir
                  << " directory\n";
        return {cmdLineOpts, false};
    }

    return {cmdLineOpts, ret};
}
