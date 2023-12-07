//Globals
PImage targetImg;

PImage[] allImages;
PImage[] tiles;
PImage[] tilesBrightness;

color[] colours;
float[] brightness;

int tileSize = 64;
float zoomMultiplier = 1.0;
boolean foundFile = false;
boolean startUpComplete = false;

int imgsToUse = 200;
String tilesPath = "data/photos";

int w, h;
PImage smaller;
int scl = 3;

//~~~~~~~~~~~~~~~~~~~~~~~~~

void startUp(){  
  File[] files = listFiles(sketchPath(tilesPath));
  allImages = new PImage[imgsToUse];
  brightness = new float[allImages.length];
  tilesBrightness = new PImage[256];
  
  for (int i = 0; i < allImages.length; i++) {
    String filename = files[i].toString();
    PImage img = loadImage(filename);
    

    allImages[i] = createImage(tileSize, tileSize, RGB);
    allImages[i].copy(img, 0, 0, img.width, img.height, 0, 0, tileSize, tileSize);
    allImages[i].loadPixels();
    
    float avg = 0;
    for (int j = 0; j < allImages[i].pixels.length; j++) {
      float b =  brightness(allImages[i].pixels[j]);
      avg += b;
    }
    
    avg /= allImages[i].pixels.length;
    brightness[i] = avg;
  }  
  
  for (int i = 0; i < tilesBrightness.length; i++) {
    float record = 256;
    for (int j = 0; j < brightness.length; j++) {
      float diff = abs(i - brightness[j]);
      if (diff < record) {
        record = diff;
        tilesBrightness[i] = allImages[j];
      }
    }
  }
  
  w = targetImg.width/scl;
  h = targetImg.height/scl;
  
  smaller = createImage(w, h, RGB);
  smaller.copy(targetImg, 0, 0, targetImg.width, targetImg.height, 0, 0, w, h);
  
  startUpComplete = true;
}

void keepDoing(){
  float offsetX = (width - w * scl) / 2; 
  float offsetY = (height - h * scl) / 2; 
  float scale = scl * zoomMultiplier;
    
  smaller.loadPixels();
  
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      int index = x + y * w;
      color c = smaller.pixels[index];
      int imageIndex = int(brightness(c));      
      float xPos = offsetX + x * scale;
      float yPos = offsetY + y * scale;      
      
      image(tilesBrightness[imageIndex], xPos, yPos, scale, scale);
    }
  }
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  zoomMultiplier -= delta * 0.1;
  //zoomMultiplier = constrain(zoomMultiplier, 0.5, 25);
  println("zoomMultiplier " + zoomMultiplier);
}

float euclideanDistance(color c1, color c2) {
  float dr = red(c1) - red(c2);
  float dg = green(c1) - green(c2);
  float db = blue(c1) - blue(c2);
  return sqrt(dr * dr + dg * dg + db * db);
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window closed");
  } else {
    targetImg = loadImage(selection.getAbsolutePath());
    foundFile = true;
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  size(600, 800);
  //selectInput("Select an image file:", "fileSelected");
  
  targetImg = loadImage("data/Snoopy01.jpg");
  foundFile = true;
}

void draw() {
  background(0);
  if(startUpComplete){
    keepDoing();
  }else if (foundFile && !startUpComplete){
    startUp(); 
  }
}
