#include "Dispatcher.hpp"
#include <iostream>
#include <memory>

using namespace std;

queue<std::unique_ptr<AbstractRequest>> Dispatcher::requests;
queue<Worker*>                          Dispatcher::freeWorkers;
mutex                                   Dispatcher::requestsMutex;
mutex                                   Dispatcher::workersMutex;
vector<std::unique_ptr<Worker>>         Dispatcher::allWorkers;
std::vector<std::unique_ptr<thread>>    Dispatcher::threads;

bool Dispatcher::init(std::size_t workers)
{
    for (auto i = 0u; i < workers; ++i)
    {
        allWorkers.push_back(std::unique_ptr<Worker>(new Worker));
        threads.push_back(
          std::unique_ptr<thread>(new thread(&Worker::run, allWorkers.back().get())));
    }
    return true;
}

bool Dispatcher::stop()
{
    requestsMutex.lock();
    while (!requests.empty())
    {
        requestsMutex.unlock();
        this_thread::sleep_for(chrono::seconds(1));
        requestsMutex.lock();
    }
    requestsMutex.unlock();

    for (auto& worker : allWorkers)
        worker->stop();

    cout << "Stopped workers.\n";

    for (auto& thread : threads)
        thread->join();

    cout << "Joined threads.\n";

    return true;
}

void Dispatcher::addRequest(std::unique_ptr<AbstractRequest>&& request)
{
    workersMutex.lock();
    if (!freeWorkers.empty())
    {
        Worker* worker = freeWorkers.front();
        worker->setRequest(std::move(request));
        auto& cv = worker->getCondition();
        cv.notify_one();
        freeWorkers.pop();
        workersMutex.unlock();
    }
    else
    {
        workersMutex.unlock();
        requestsMutex.lock();
        requests.push(std::move(request));
        requestsMutex.unlock();
    }
}

bool Dispatcher::getTaskForWorker(Worker* worker)
{
    bool wait = true;
    requestsMutex.lock();
    if (!requests.empty())
    {
        worker->setRequest(std::move(requests.front()));
        requests.pop();
        wait = false;
        requestsMutex.unlock();
    }
    else
    {
        requestsMutex.unlock();
        workersMutex.lock();
        freeWorkers.push(worker);
        workersMutex.unlock();
    }
    return wait;
}
