#pragma once

#include <faceDetection.hpp>

#include "Types.hpp"

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <mutex>

class JsonImageWrapepr
{
  public:
    JsonImageWrapepr(execution_policy policy);

    void addImageObj(const std::string& path, std::vector<fdlib::Rectangle> rectangles);

    void saveTo(const std::string path);

  private:
    boost::property_tree::ptree _jsonObject;
    boost::property_tree::ptree _facesJsonArray;
    execution_policy            _policy;

    std::mutex _nodeMutex;
};
