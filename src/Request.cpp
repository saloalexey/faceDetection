#include "Request.hpp"

Request::Request(std::function<bool(const std::string&)> fnc, std::string paramsArg)
  : outFnc(std::move(fnc))
  , params(std::move(paramsArg))
{
}

void Request::process()
{
    outFnc(params);
}
