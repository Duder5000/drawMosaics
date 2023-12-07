//Globals
PImage targetImg;
PImage completeImg;

PImage[] allImages;

PImage[] tilesColours;
PImage[] tilesBrightness;

color[] colours;
float[] brightness;

int tileSize = 64;
float zoomMultiplier = 1.0;

boolean foundFile = false;
boolean startUpComplete = false;
boolean mosaicSaved = false;
boolean dragging = false;

int imgsToUse = 200;
String tilesPath = "data/photos";

int w, h;
PImage smaller;
int scl = 3;

//~~~~~~~~~~~~~~~~~~~~~~~~~

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

void keepDoing(){  
  float offsetX = (width - w * scl * zoomMultiplier) / 2;
  float offsetY = (height - h * scl * zoomMultiplier) / 2;
  
  if(zoomMultiplier > 1){
     
  }
  
  println("mouseX: " + mouseX + ", mouseY: " + mouseY);
  println("offsetX: " + offsetX + ", offsetY: " + offsetY);
    
  float scale = scl * zoomMultiplier;
    
  smaller.loadPixels();
  
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      int index = x + y * w;
      color c = smaller.pixels[index];  
      
      int colourIndex = findClosestColorIndex(c, colours);
      PImage tileFromColour = allImages[colourIndex];
      
      float xPos = offsetX + x * scale;
      float yPos = offsetY + y * scale;
      
      if(zoomMultiplier > 1){
     
      }
            
      image(tileFromColour, xPos, yPos, scale, scale);
    }
  }
}

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

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  zoomMultiplier -= delta * 0.5;
  zoomMultiplier = constrain(zoomMultiplier, 1, 100);
  //println(zoomMultiplier);
}

void mouseReleased() {

}

void mousePressed(){

}

void mouseDragged(){

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
    if(!mosaicSaved){
      save("canvas.png");
      completeImg = loadImage("data/canvas.png");
      mosaicSaved = true;
    }
  }else if (foundFile && !startUpComplete){
    startUp(); 
  }
}
