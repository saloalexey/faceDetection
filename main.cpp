
#include <faceDetection.hpp>
#include "Dispatcher.hpp"
#include "Request.hpp"
#include "CmdLineOptions.hpp"
#include "JsonImageWrapper.hpp"

#include <iostream>

#include <boost/filesystem.hpp>

#include <opencv4/opencv2/imgproc.hpp>
#include <opencv4/opencv2/imgcodecs.hpp>

namespace fs = boost::filesystem;

void for_each_file(execution_policy                               policy,
                   const std::string&                             dirpath,
                   const std::function<bool(const std::string&)>& func)
{
    fs::path p(dirpath);
    if (!fs::exists(p))
    {
        std::cout << p << " does not exist\n";
        return;
    }

    if (!fs::is_directory(p))
    {
        std::cout << p << " exists, but is not a directory\n";
        return;
    }

    for (fs::directory_entry& x : fs::directory_iterator(p))
    {
        if (fs::is_directory(x))
        {
            for_each_file(policy, x.path().c_str(), func);
        }
        else if (fs::is_regular(x))
        {
            switch (policy)
            {
                case execution_policy::sequenced:
                    func(x.path().c_str());
                    break;
                case execution_policy::parallel:
                    Dispatcher::addRequest(std::unique_ptr<AbstractRequest>(
                      new Request(func, x.path().c_str())));
                    break;
            }
        }
    }
}

int main(int argc, char** argv) try
{
    auto  confPair = initCmdLineOptions(argc, argv);
    auto& conf     = confPair.first;

    if (confPair.second == false)
        return 0;

    if (conf.policy == execution_policy::parallel)
        Dispatcher::init(std::thread::hardware_concurrency());

    fdlib::FaceCoordinates faceDetect;

    JsonImageWrapepr jsonObj(conf.policy);
    for_each_file(conf.policy,
                  conf.imagesSrcDir,
                  [&conf, &jsonObj, &faceDetect](const std::string& imgPath) -> bool {
                      std::cout << "****************************" << std::endl;
                      using namespace cv;
                      auto faces = faceDetect.getFacesCoordinates(imgPath);

                      if (faces.empty())
                          return false;

                      jsonObj.addImageObj(imgPath, faces);

                      Mat image;
                      image = imread(imgPath, IMREAD_UNCHANGED);

                      for (const auto& face : faces)
                      {
                          Point pt1(face.x, face.y);
                          Point pt2(face.x + face.height, face.y + face.width);
                          rectangle(image, pt1, pt2, Scalar(0, 0, 255), 2, 8, 0);

                          int kern_size = 40;
                          Mat roi(image, Rect(pt1, pt2));
                          blur(roi, roi, Size(kern_size, kern_size), Point(-1, -1));
                      }

                      cv::resize(image, image, cv::Size(), 0.5, 0.5);

                      std::string newImgPath = imgPath;
                      newImgPath.replace(0, conf.imagesSrcDir.size(), conf.imagesDstDir);
                      newImgPath = fs::path(newImgPath).replace_extension("jpg").c_str();

                      // TODO: need to sync with other threads
                      boost::system::error_code err;
                      fs::create_directory(fs::path(newImgPath).parent_path(), err);
                      if (err)
                      {
                          std::cout << "[Error] Can't create sub directory for image"
                                    << newImgPath << "\n";
                          return false;
                      }

                      auto res = imwrite(newImgPath, image);
                      if (!res)
                      {
                          std::cout << "\n [Error] Can't save the image\n";
                          return false;
                      }

                      return true;
                  });

    if (conf.policy == execution_policy::parallel)
        Dispatcher::stop();

    jsonObj.saveTo(conf.imagesSrcDir + "/result.json");

    return 0;
}
catch (const fs::filesystem_error& ex)
{
    std::cout << "[Exception] What : " << ex.what() << '\n';
    return 1;
}
catch (const std::exception& ex)
{
    std::cout << "[Exception] What : " << ex.what() << '\n';
    return 1;
}
catch (...)
{
    std::cout << "[Exception] Unknown \n";
    return 1;
}
