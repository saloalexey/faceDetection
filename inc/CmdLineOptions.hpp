#pragma once

#include <string>
#include "Types.hpp"

struct CmdLineOptions
{
    // TODO: Rename params
    std::string      imagesSrcDir;
    std::string      imagesDstDir;
    execution_policy policy{execution_policy::sequenced};
};

std::pair<CmdLineOptions, bool> initCmdLineOptions(int argc, char** argv);
