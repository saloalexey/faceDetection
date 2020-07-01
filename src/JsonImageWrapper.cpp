#include "JsonImageWrapper.hpp"

#include <memory>

namespace pt = boost::property_tree;

JsonImageWrapepr::JsonImageWrapepr(execution_policy policy)
  : _policy(policy)
{
}

void JsonImageWrapepr::addImageObj(const std::string&            path,
                                   std::vector<fdlib::Rectangle> rectangles)
{
    pt::ptree imageJsonObj;
    imageJsonObj.put("filename", path);

    pt::ptree coordJsonArray;
    for (auto rect : rectangles)
    {
        pt::ptree coordJsonObj;
        coordJsonObj.put("x", rect.x);
        coordJsonObj.put("y", rect.y);
        coordJsonObj.put("width", rect.width);
        coordJsonObj.put("height", rect.height);
        coordJsonArray.push_back(std::make_pair("", coordJsonObj));
    }

    imageJsonObj.push_back(std::make_pair("coord", coordJsonArray));

    switch (_policy)
    {
        case execution_policy::parallel:
        {
            std::unique_lock<std::mutex> lock(_nodeMutex);
            _facesJsonArray.push_back(std::make_pair("", imageJsonObj));
        }
        break;
        case execution_policy::sequenced:
        {
            _facesJsonArray.push_back(std::make_pair("", imageJsonObj));
        }
        break;
    }
}

void JsonImageWrapepr::saveTo(const std::string path)
{
    _jsonObject.add_child("Data", _facesJsonArray);
    pt::write_json(path, _jsonObject);
}
