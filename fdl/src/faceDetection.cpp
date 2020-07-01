#include "faceDetection.hpp"

#include <iostream>

#include <opencv4/opencv2/objdetect.hpp>
#include <opencv4/opencv2/imgcodecs.hpp>

namespace fdlib
{

FaceCoordinates::FaceCoordinates()
{
    // TODO: temporary solution
    std::string path = std::string(SYSROOT)
                       + "/share/opencv4/haarcascades/"
                         "haarcascade_frontalface_default.xml";
    _faceDetection.reset(new cv::CascadeClassifier);
    if (!_faceDetection->load(path))
    {
        std::cout << "\n[Error] Face detection CascadeClassifier file is not loaded "
                     "properly from "
                  << path;
        throw std::runtime_error("Can't load CascadeClassifier from " + path);
    }
}

FaceCoordinates::~FaceCoordinates() {}

bool Rectangle::operator==(const Rectangle& r) const
{
    return x == r.x && y == r.y && width == r.width && height == r.height;
}

std::vector<Rectangle> FaceCoordinates::getFacesCoordinates(const std::string& img_path)
{
    using namespace cv;

    Mat image;
    image = imread(img_path, IMREAD_UNCHANGED);

    if (!image.data)
    {
        std::cout << "[Warning] No image data \n";
        return {};
    }

    std::vector<Rect> faces;

    _faceDetection->detectMultiScale(image, faces);

    std::vector<Rectangle> ret_faces;
    ret_faces.reserve(faces.size());
    for (const auto& face : faces)
        ret_faces.push_back(Rectangle{face.x, face.y, face.width, face.height});

    std::cout << "Picture " << img_path << " has been handled\n";
    std::cout << "    Found " << faces.size() << " faces\n";
    return ret_faces;
}

}   // namespace fdlib
