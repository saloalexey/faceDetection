#pragma once

#include "AbstractRequest.hpp"
#include <string>
#include <functional>


class Request : public AbstractRequest
{

    std::function<bool(const std::string&)> outFnc;
    std::string         params;

  public:
    Request( std::function<bool(const std::string&)> fnc, std::string paramsArg);
    void process() override;
};
