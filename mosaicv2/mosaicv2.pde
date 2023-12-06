import java.io.File;

PImage targetImage;
int tileSize = 25; // Adjust the size of each mosaic tile

void setup() {
  size(600, 750);
  targetImage = loadImage("data/obama.jpg");
  targetImage.resize(width, height); // Resize the target image to match the canvas size

  createMosaic();
  println("Done setup()");
}

void createMosaic() {
  File photosFolder = new File(dataPath("photos")); // Create a File object for the photos folder
  File[] photoFiles = photosFolder.listFiles(); // List all files in the photos folder

  for (int y = 0; y < height; y += tileSize) {
    for (int x = 0; x < width; x += tileSize) {
      // Extract the color of the current pixel in the target image
      color targetColor = targetImage.get(x, y);

      // Get a random photo from the "data/photos" folder
      PImage randomPhoto = getRandomPhoto(photoFiles);

      // Resize the photo to match the tile size
      randomPhoto.resize(tileSize, tileSize);

      // Calculate the average color of the photo
      color averageColor = calculateAverageColor(randomPhoto);

      // Tint the photo to match the target color
      tint(targetColor);
      
      // Display the tinted photo at the current position
      image(randomPhoto, x, y);
      
      // Reset tint to avoid affecting subsequent images
      noTint();
    }
  }
}

PImage getRandomPhoto(File[] photoFiles) {
  // Get a random file from the array
  File randomFile = photoFiles[int(random(photoFiles.length))];

  // Load the random photo
  PImage randomPhoto = loadImage(randomFile.getAbsolutePath());

  return randomPhoto;
}

color calculateAverageColor(PImage img) {
  img.loadPixels();
  float r = 0;
  float g = 0;
  float b = 0;
  int count = 0;

  for (int i = 0; i < img.pixels.length; i++) {
    color c = img.pixels[i];
    r += red(c);
    g += green(c);
    b += blue(c);
    count++;
  }

  img.updatePixels();

  // Calculate the average color
  r /= count;
  g /= count;
  b /= count;

  return color(r, g, b);
}

//void draw(){
//  image(targetImage,0,0);
//}
