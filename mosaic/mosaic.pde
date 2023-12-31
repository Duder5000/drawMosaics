//Paper presentation Monday before noon

//Globals
PImage targetImg;

PImage[] allImages;
PImage[] tilesColours;

color[] colours;

int tileSize = 64;
float zoomMultiplier = 1.0;

boolean foundFile = false;
boolean startUpComplete = false;
boolean mosaicSaved = false;
boolean paused = false;

int imgsToUse = 200;
String tilesPath = "data/photos";

int w, h;
PImage smaller;
int scl = 3;

//~~~~~~~~~~~~~~~~~~~~~~~~~

//Stuff that runs after a file is selected, moved out of setup because setup wouldn't wait for a file to be selected & would cause error
void startUp(){  
  File[] f = listFiles(sketchPath(tilesPath));
  allImages = new PImage[imgsToUse];
  int imagesCount = allImages.length;
  
  doColours(f, imagesCount);
  
  w = targetImg.width/scl;
  h = targetImg.height/scl;
  
  smaller = createImage(w, h, RGB);
  smaller.copy(targetImg, 0, 0, targetImg.width, targetImg.height, 0, 0, w, h);
    
  startUpComplete = true;
}

//Find the average colour of all the tile images & store the value in colours[] for later
void doColours(File[] files, int len){
  colours = new color[len];
  tilesColours = new PImage[len];
  
  for (int i = 0; i < len; i++) {
    String filename = files[i].toString();
    PImage img = loadImage(filename);
    
    allImages[i] = createImage(tileSize, tileSize, RGB);
    allImages[i].copy(img, 0, 0, img.width, img.height, 0, 0, tileSize, tileSize);
    allImages[i].loadPixels();
    
    colours[i] = calcAvgColour(allImages[i]); //Create a list of all the colours I have to work with
  } 
}

//My main draw loop broken out so that it can be easily paused
void keepDoing(float offsetX, float offsetY){      
  //offsetX = 0;
  //offsetY = 0;
  
  //println("mouseX: " + mouseX + ", mouseY: " + mouseY);
  //println("offsetX: " + offsetX + ", offsetY: " + offsetY);
  
  float scale = scl * zoomMultiplier; //Combaining tile scale & zoom
    
  smaller.loadPixels();
  
  //Drawing the tile images at their locations based on the closed average image colour from colours[]
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      int index = x + y * w;
      color c = smaller.pixels[index];  
      
      int colourIndex = findClosestColorIndex(c, colours);
      PImage tileFromColour = allImages[colourIndex];
      
      float xPos = offsetX + x * scale;
      float yPos = offsetY + y * scale;
             
      image(tileFromColour, xPos, yPos, scale, scale);
    }
  }
}

//Finds the average colours of an image, used for the tiles
color calcAvgColour(PImage img) {
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

  r /= count;
  g /= count;
  b /= count;

  return color(r, g, b);
}

//Uses euclideanDistance to find which tile has the best fit colour for the pixel(s)
int findClosestColorIndex(color target, color[] colors) {
  float minDist = Float.MAX_VALUE;
  int closestIndex = 0;

  for (int i = 0; i < colors.length; i++) {
    float dist = euclideanDistance(target, colors[i]);
    if (dist < minDist) {
      minDist = dist;
      closestIndex = i;
    }
  }
  return closestIndex;
}

//Math to figure out how far away a colour is from another
float euclideanDistance(color c1, color c2) {
  float dr = red(c1) - red(c2);
  float dg = green(c1) - green(c2);
  float db = blue(c1) - blue(c2);
  return sqrt(dr * dr + dg * dg + db * db);
}

//Grabs a file from the file browser
void fileSelected(File selection) {
  if (selection == null) {
    println("Window closed");
  } else {
    targetImg = loadImage(selection.getAbsolutePath());
    foundFile = true;
  }
}

//Even triggered when scrolling, used for zooming
void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  zoomMultiplier -= delta * 0.5;
  zoomMultiplier = constrain(zoomMultiplier, 1, 100);
  paused = false;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~

void setup() {
  size(600, 800);
  background(0);
  selectInput("Select an image file:", "fileSelected");
  
  //targetImg = loadImage("data/Snoopy01.jpg");
  //foundFile = true;
}

void draw() {
  if(!paused){
    background(0);
    if(startUpComplete){
      float offsetX = (width - w * scl * zoomMultiplier) / 2;
      float offsetY = (height - h * scl * zoomMultiplier) / 2;
      
      if(zoomMultiplier > 1 && !paused){
        //offsetX -= mouseX/2;
        //offsetY -= mouseY/2;
        paused = true;
      }
  
      keepDoing(offsetX, offsetY);
      if(!mosaicSaved){
        save("mosaic.png");
        mosaicSaved = true;
        paused = true;
      }
    }else if (foundFile && !startUpComplete){
      startUp(); 
    }
  }
}
