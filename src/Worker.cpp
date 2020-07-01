#include "Worker.hpp"
#include "Dispatcher.hpp"
#include <chrono>
#include <iostream>
using namespace std;

Worker::Worker()
{
    running = true;
    ready   = false;
    ulock   = std::unique_lock<std::mutex>(mtx);
}

condition_variable& Worker::getCondition()
{
    return cv;
}

void Worker::run()
{
    while (running)
    {
        if (ready)
        {
            try
            {
                ready = false;
                request->process();
            }
            catch (const std::exception& e)
            {
                std::cout << "[Exception] What: " << e.what() << std::endl;
            }
        }
        if (Dispatcher::getTaskForWorker(this))
        {
            // Use the ready loop to deal with spurious wake-ups.
            while (!ready && running)
            {
                if (cv.wait_for(ulock, chrono::seconds(1)) == cv_status::timeout)
                {
                    // We timed out, but we keep waiting unless
                    // the worker is
                    // stopped by the dispatcher.
                }
            }
        }
    }
}

void Worker::stop()
{
    running = false;
}
void Worker::setRequest(std::unique_ptr<AbstractRequest> req)
{
    this->request = std::move(req);
    ready         = true;
}
