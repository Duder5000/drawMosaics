// Allow zoom in to see tiles
// Select own target image (upload own or have 3 to choose from via UI)
// Send email before Monday to setup presenation Zoom meeting (between 10 - 12)

//Stanford Dogs Image Dataset
//http://vision.stanford.edu/aditya86/ImageNetDogs/

//PImage myImgOrignal;
PImage myImg;
PImage testImg;
PImage smaller;
PImage[] allImages, allImages2;
float[] brightness;
PImage[] brightImages;

color[] colours;
PImage[] coloursImages;

int scl = 8; //8
int w, h;
int imgsToUse = 200;
float scaleFactor = 1.0;
boolean setupComplete = false;
boolean fileSelectedFlag = false;
boolean pauaseAll = false;
int scaler = 0;
int scalerSteps = 5;

int tileSize = 5;

void drawBrightness(){
  float offsetX = (width - w * scl * scaleFactor) / 2; 
  float offsetY = (height - h * scl * scaleFactor) / 2; 
    
  smaller.loadPixels();
  
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      int index = x + y * w;
      color c = smaller.pixels[index];
      int imageIndex = int(brightness(c));
      //int colourImageIndex = findClosestColorIndex(c, colours);
      
      float xPos = offsetX + x * scl * scaleFactor;
      float yPos = offsetY + y * scl * scaleFactor;
      
      //image(brightImages[imageIndex], xPos, yPos, scl * scaleFactor, scl * scaleFactor);
      //image(coloursImages[colourImageIndex], xPos, yPos, scl * scaleFactor, scl * scaleFactor);
    }
  }
}

int findClosestColorIndex(color target, color[] colors) {
  float minDist = Float.MAX_VALUE;
  //color closest = colors[0];
  int closestIndex = 0;

  for (int i = 0; i < colors.length; i++) {
    float dist = euclideanDistance(target, colors[i]);
    if (dist < minDist) {
      minDist = dist;
      //closest = colors[i];
      closestIndex = i;
    }
  }

  return closestIndex;
}

float euclideanDistance(color c1, color c2) {
  float dr = red(c1) - red(c2);
  float dg = green(c1) - green(c2);
  float db = blue(c1) - blue(c2);
  return sqrt(dr * dr + dg * dg + db * db);
}

void createMosaic(PImage targetImage) {
  for (int y = 0; y < height; y += tileSize) {
    for (int x = 0; x < width; x += tileSize) {
      //println("createMosaic: x" + x + ", y" + y);      
      
      color targetColor = targetImage.get(x, y);
      int imageIndex = int(brightness(targetColor));

      PImage p = brightImages[imageIndex];

      // Resize the photo to match the tile size
      p.resize(tileSize, tileSize);

      
      // Display the tinted photo at the current position
      image(p, x, y);
    }
  }
}

//PImage smallerImg (int cropPercent, PImage source){
//  //println("In smallerImg()");
//  PImage smallerImg = null; 
  
//  int cropAmount = (int)(source.width * cropPercent / 100.0);
//  smallerImg = source.get(cropAmount, cropAmount, source.width - 2 * cropAmount, source.height - 2 * cropAmount);
  
//  return smallerImg;
//}

//PImage stretchImage(PImage source, int targetWidth, int targetHeight) {
//  PImage stretched = createImage(targetWidth, targetHeight, RGB);
//  stretched.copy(source, 0, 0, source.width, source.height, 0, 0, targetWidth, targetHeight);
  
//  return stretched;
//}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window closed.");
  } else {
    //myImgOrignal = loadImage(selection.getAbsolutePath());
    //myImg = myImgOrignal;
    myImg = loadImage(selection.getAbsolutePath());
    fileSelectedFlag = true;
  }
}

void allowingMeToPauseSetupSortOf(){
  File[] files = listFiles(sketchPath("data/photos"));
  allImages = new PImage[imgsToUse];
  //allImages2 = new PImage[imgsToUse];
  
  brightness = new float[allImages.length];
  brightImages = new PImage[256];
  
  colours = new color[allImages.length];
  coloursImages = new PImage[256];

  for (int i = 0; i < allImages.length; i++) {
    String filename = files[i].toString();

    PImage img = loadImage(filename);

    allImages[i] = createImage(scl, scl, RGB);
    allImages[i].copy(img, 0, 0, img.width, img.height, 0, 0, scl, scl);
    allImages[i].loadPixels();
    //allImages[i] = img;

    float avg = 0;
    for (int j = 0; j < allImages[i].pixels.length; j++) {
      float b =  brightness(allImages[i].pixels[j]);
      avg += b;
    }
    
    avg /= allImages[i].pixels.length;
    brightness[i] = avg;
    
    color averageColor = calculateAverageColor(img);
    colours[i] = averageColor;
  }

  for (int i = 0; i < brightImages.length; i++) {
    float record = 256;
    for (int j = 0; j < brightness.length; j++) {
      float diff = abs(i - brightness[j]);
      if (diff < record) {
        record = diff;
        brightImages[i] = allImages[j];
        coloursImages[i] = allImages[j];
      }
    }
  }

  w = myImg.width/scl;
  h = myImg.height/scl;

  smaller = createImage(w, h, RGB);
  smaller.copy(myImg, 0, 0, myImg.width, myImg.height, 0, 0, w, h);
  
  setupComplete = true;
  pauaseAll = false;
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

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  scaleFactor -= delta * 0.1;
  scaleFactor = constrain(scaleFactor, 0.5, 5);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  size(600, 750);
  size(600, 800);
  //imageMode(CENTER);
  selectInput("Select an image file:", "fileSelected");
  
  testImg = loadImage("data/obama.jpg");
  //testImg = stretchImage(testImg, width, height);
}

void draw() {
  background(0);
  
  //float x = width / 2 - testImg.width / 2;
  //float y = height / 2 - testImg.height / 2;  
  //image(testImg, x, y);
  
  if(!pauaseAll){
    if(setupComplete){
      scale(scaleFactor);
      //drawBrightness();
      createMosaic(myImg);
    }else if(fileSelectedFlag){
      allowingMeToPauseSetupSortOf();
    }
  }
  //else if(pauaseAll && setupComplete && fileSelectedFlag){
  //  println("pauaseAll && setupComplete && fileSelectedFlag");
  //  myImg = smallerImg(scaler, myImgOrignal);
  //  myImg = stretchImage(myImg, width, height);
  //  allowingMeToPauseSetupSortOf();
  //}
}
