#pragma once
#include <string>
#include <vector>
#include <memory>

namespace cv
{
class CascadeClassifier;
}

namespace fdlib
{

// Add structure Rectangle in order to not show internal library impl
struct Rectangle
{
    using value_type = int;
    Rectangle() {}
    Rectangle(value_type _x, value_type _y, value_type _width, value_type _height)
      : x(_x)
      , y(_y)
      , width(_width)
      , height(_height)
    {
    }

    bool operator==(const Rectangle&) const;

    value_type x{0};
    value_type y{0};
    value_type width{0};
    value_type height{0};
};

class FaceCoordinates
{
  public:
    FaceCoordinates();

    /**
     * Find faces on the given image and return coordinates
     *
     * @param imgPath     Path to image file
     * @return            Returns an array of faces coordinates
     */
    std::vector<Rectangle> getFacesCoordinates(const std::string& imgPath);
    ~FaceCoordinates();

  private:
    std::unique_ptr<cv::CascadeClassifier> _faceDetection;
};

}   // namespace fdlib
