#pragma once

#include "AbstractRequest.hpp"

#include <condition_variable>
#include <mutex>

class Worker
{
    std::condition_variable          cv;
    std::mutex                       mtx;
    std::unique_lock<std::mutex>     ulock;
    std::unique_ptr<AbstractRequest> request;
    bool                             running;
    bool                             ready;

  public:
    Worker();
    void                     run();
    void                     stop();
    void                     setRequest(std::unique_ptr<AbstractRequest> request);
    std::condition_variable& getCondition();
};
