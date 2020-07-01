#include <gtest/gtest.h>
#include <faceDetection.hpp>

#include <algorithm>

TEST(Main, Face)
{

    fdlib::FaceCoordinates face_detect;

    {
        std::string img        = std::string(IMAGE_DIR) + "lena.bmp";
        auto        facesCoord = face_detect.getFacesCoordinates(img);

        std::vector<fdlib::Rectangle> realFacesCoord{{217, 201, 173, 173}};

        EXPECT_EQ(realFacesCoord.size(), facesCoord.size())
          << "[Explanation] Amount of found faces are different";
        EXPECT_EQ(realFacesCoord, facesCoord)
          << "[Explanation] Faces coordinates are different";
    }
}
