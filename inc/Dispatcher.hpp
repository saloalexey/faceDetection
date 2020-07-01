#pragma once

#include "AbstractRequest.hpp"
#include "Worker.hpp"
#include <queue>
#include <mutex>
#include <thread>
#include <vector>
#include <memory>

class Dispatcher
{
    static std::queue<std::unique_ptr<AbstractRequest>> requests;
    static std::queue<Worker*>                          freeWorkers;
    static std::mutex                                   requestsMutex;
    static std::mutex                                   workersMutex;
    static std::vector<std::unique_ptr<Worker>>         allWorkers;
    static std::vector<std::unique_ptr<std::thread>>    threads;

  public:
    static bool init(std::size_t freeWorkers);
    static bool stop();
    static void addRequest(std::unique_ptr<AbstractRequest>&& request);
    static bool getTaskForWorker(Worker* worker);
};
