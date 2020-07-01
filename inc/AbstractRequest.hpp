#pragma once

class AbstractRequest
{
    //
  public:
    virtual void process()     = 0;
    virtual ~AbstractRequest() = default;
};
