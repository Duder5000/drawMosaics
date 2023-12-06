PImage targetImage;
PImage[] photoImages;

PImage[] allImages;
int imgsToUse = 200;

int tileWidth = 20;
int tileHeight = 20;

int h, w;

void setup() {
  size(800, 600);
  
  File[] files = listFiles(sketchPath("data/photos"));
  allImages = new PImage[imgsToUse];
  
  for (int i = 0; i < allImages.length; i++) {
    String filename = files[i].toString();

    PImage img = loadImage(filename);
    allImages[i] = createImage(1, 1, RGB);
  }
  
  targetImage = loadImage("data/obama.jpg");
  photoImages = loadImages("data/photos");
  targetImage.resize(width, height);
  makeMosaic();
}

void draw() {
  image(targetImage, 0, 0);
}

PImage[] loadImages(String folderPath) {
  println("TEST1");
  String[] fileNames = listFileNames(folderPath);
  PImage[] images = new PImage[fileNames.length];

  for (int i = 0; i < fileNames.length; i++) {
    String filePath = folderPath + "/" + fileNames[i];

    // Check if the file exists before attempting to load it
    File file = new File(filePath);
    if (file.exists()) {
      images[i] = loadImage(filePath);
      images[i].resize(tileWidth, tileHeight);
    } else {
      // Handle the case where the file doesn't exist (print a message or skip)
      println("File not found: " + filePath);
    }
  }

  return images;
}

String[] listFileNames(String folderPath) {
  File[] files = listFiles(sketchPath(folderPath));
  println("TEST2");
  String[] fileNames = new String[files.length];
  for(int i = 0; i < files.length; i++){
    fileNames[i] = files[i].getName();
  }
  return fileNames;
}

void makeMosaic() {
  targetImage.loadPixels();

  for (int y = 0; y < height; y += tileHeight) {
    for (int x = 0; x < width; x += tileWidth) {
      int index = (y / tileHeight) * (width / tileWidth) + (x / tileWidth);
      index = constrain(index, 0, targetImage.pixels.length - 1); // Ensure index is within bounds
      PImage closestImage = findClosestImage(getRegionAverage(targetImage, x, y, tileWidth, tileHeight));

      image(closestImage, x, y);
    }
  }
}

PImage findClosestImage(float[] targetColors) {
  PImage closestImage = null;
  float minDist = Float.MAX_VALUE;

  for (PImage img : photoImages) {
    float[] imgColors = getAverageColors(img);
    float dist = calculateColorDistance(targetColors, imgColors);

    if (dist < minDist) {
      minDist = dist;
      closestImage = img;
    }
  }

  return closestImage;
}

float[] getRegionAverage(PImage img, int startX, int startY, int w, int h) {
  float[] averageColors = new float[3];
  int count = 0;

  for (int y = startY; y < startY + h; y++) {
    for (int x = startX; x < startX + w; x++) {
      int pixelColor = img.pixels[y * img.width + x];
      averageColors[0] += red(pixelColor);
      averageColors[1] += green(pixelColor);
      averageColors[2] += blue(pixelColor);
      count++;
    }
  }

  averageColors[0] /= count;
  averageColors[1] /= count;
  averageColors[2] /= count;

  return averageColors;
}

float[] getAverageColors(PImage img) {
  float[] averageColors = new float[3];
  int count = 0;

    w = img.width;
    h = img.height;

  //for (int i = 0; i < img.pixels.length; i++) {
  //  int pixelColor = img.pixels[i];
  //  averageColors[0] += red(pixelColor);
  //  averageColors[1] += green(pixelColor);
  //  averageColors[2] += blue(pixelColor);
  //  count++;
  //}
  
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      int index = x + y * w;
      int pixelColor = img.pixels[index];
      averageColors[0] += red(pixelColor);
      averageColors[1] += green(pixelColor);
      averageColors[2] += blue(pixelColor);  
      count++;
    }
  }
  
  averageColors[0] /= count;
  averageColors[1] /= count;
  averageColors[2] /= count;

  return averageColors;
}

float calculateColorDistance(float[] color1, float[] color2) {
  float sum = 0;

  for (int i = 0; i < color1.length; i++) {
    sum += pow(color1[i] - color2[i], 2);
  }

  return sqrt(sum);
}
