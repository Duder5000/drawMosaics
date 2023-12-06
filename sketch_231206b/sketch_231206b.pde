// Create photomosaics from a source image and a directory of tile images.
// by Greg Borenstein, January 2013
// Read more here:

// see inline comments for more details
// -------------------------------------


// Import the java libraries we need.
// These are both utilites for sorting things.
// We use them to define a custom comparison operation.
// This lets us sort our PixelImages by their brightness,
// which makes it really easy to select the right one 
// for each portion of the source image
import java.util.Comparator;
import java.util.Collections;

// Our PixelImage class
// This class stores information about each of the images
// we'll use as tiles in making up our photomosaic.
// That infomation includes the path to where the image is stored
// as well as the image's "score", i.e. its brightness level.
// We use this latter to sort an ArrayList of these PixelImages
// so that they're stored in order from darkest to brightest.
// Then, when we need to find a PixelImage that matches one of the cells
// in our source image, we can do so simply by its position in this ArrayList.
//
// One other note: this class also "caches" the image that it represents.
// Loading images from disk takes time, especially when the image is large.
// Depending on how many images we have, we end up re-using the same PixelImage
// multiple times in our mosaic. Hence, we can speed things up, by saving the image
// the first time we see it. Then, next time this same PixelImage is called for
// we're able to display the image without having to reload it from disk
// and resize it. This makes things MUCH FASTER, making it less painful to create
// photomosaics with lots of cells.
class PixelImage {
  float score;
  String path;
  PImage cache;
  boolean cached = false;

  PixelImage(float s, String p) {
    score = s;
    path = p;
  }

  // This function implements the caching of the image.
  // Instead of having outside code access the PImage or the image path directly
  // they call this function, which loads, resizes and stores the image if it's never
  // seen it before or simply displays it if it has.
  
  // Note how we call the PImage resize() function with a 0
  // as the argument for either the width of the height depending on
  // if the image is wide or tall. This ensures proportional resizing: http://processing.org/reference/PImage_resize_.html
  PImage image() {
    if (!cached) {
      cache = loadImage(path);

      float proportion = 1;      
      if (cache.width > cache.height) {
        cache.resize(0, cellHeight*outputScale);
      }  
      else {
        cache.resize(cellWidth*outputScale, 0);
      }
      cached = true;
    }
    return cache;
  }
}

// This is our custom comparison operation.
// Java already knows how to compare its built-in types
// like integers: by looking at which number is bigger.
// However we want to be able to sort our own custom PixelImage
// type so we have to tell Java how to compare PixelImages.
// To do that we define this special class with one function, compare()
// that takes two PixelImages as arguments. compare() returns
// 1,0, or -1 depending on which of the arguments is greater (or 
// if they are equal). We want to sort our PixelImages based
// on their score variable, so all we do is subtract those from each other
// and return the result.
// We'll see how this function is used in setup()...
class PixelImageComparator implements Comparator<PixelImage> {
  public int compare(PixelImage i1, PixelImage i2) {
    return (int)(i1.score - i2.score);
  }
}

// These are our chief variables.
// We declare them here for one of two reasons:
// 1) They are global in score (i.e. used in multiple functions).
// 2) They represent 'settings' for our sketch that we might
//    want to manipulate without having to search through all the source code.
// Mostly they're the later. Each is describe inline.
PImage sourceImage; // image to be mosaic-ed
String sourceImageFilename = "data/snoopy01.jpg"; // filename for our sourceImage
int numCellsPerSide = 50; // increasing this, means more cells, and vice versa
int outputScale = 4; // size of photomosaic relative to original image.

int cellWidth, cellHeight; // size of each cell (calculated based on number of cells and image size)
ArrayList<PixelImage> pixelImages; // will store all the PixelImages as we load them in.

// Our setup() function.
// Since this sketch doesn't run interactively (it just runs once and produces a photomosaic)
// this is where most of the work is done. Comments inline to explain individual steps.
void setup() {
  // clear the screen to white.
  background(255);
  // load the source image
  sourceImage = loadImage(sourceImageFilename);
  // scale the canvas based on the proportions of
  // the source image, but somewhat bigger
  // (we want our final result to be nice and high res so we can see the individual tiles)
  
  //size(sourceImage.width*6, sourceImage.height*4);
  
  // calculate the size of each cell based on the size of the sourceImage
  // and the resolution of our grid.
  cellWidth = sourceImage.width/numCellsPerSide;
  cellHeight = sourceImage.height/numCellsPerSide;
  
  // Now we're going to process all of the tile images
  // and create PixelImage objects for each of them.
  
  // First we need to get a list of all of the names of the files
  // in our images directory.
  java.io.File folder = new java.io.File(dataPath("data/photos"));
  String[] tileImageFilenames = folder.list();

  // initialize our ArrayList of PixelImages
  // since we're about to populate it based on our images.
  // As in the declaration above, the angle-bracket indicator
  // tells Java the type of the object we'll be storing in the ArrayList
  // and avoids us having to cast it when accessing it later.
  pixelImages = new ArrayList<PixelImage>();
  
  // Since we'll be looping through and loading a lot of images
  // it's slightly more efficent to just declare a single PImage
  // object and then reuse that over and over. Hence we declare it outside
  // of the loop. This is a minor efficiency thing and not important.
  PImage img;
  // Loop through all of the filenames that we found in the directory
  for (int i = 0; i < tileImageFilenames.length; i++) {
    // print out a progress indicator
    println(i + "/" + tileImageFilenames.length);
    // we only want to process the actual images,
    // not the other files that might be in there like
    // text files and .DS_Store files and other junk.
    // So we wrap everything that's supposed to happen to images
    // inside of an if-statement based on the filename.
    // If you have images that are pngs or anything other than
    // jpgs, you'd need to change this.
    if (tileImageFilenames[i].endsWith("jpg")) {
      // Load the image based on its filename
      img = loadImage(dataPath("images/" + tileImageFilenames[i]));
      // Resize it down. This will make it
      // MUCH faster to find the average brightness of the image,
      // since that function has to loop through each pixel in the image.
      // With really large images, Processing will even choke if you try to load too
      // many of them, so this is very necessary.
      img.resize(200, 200);
      // Calculate the average brightness of the image.
      // See the implementation of the function below for details,
      // but the gist is that we loop through all the pixels, add up
      // their individual brightnesses, and divide by how many pixels there were.
      float imgBrightness = aveBrightness(img);
      // Now we create a new PixelImage object with the brightness score
      // and the path to the image. And add that object to our growing ArrayList
      PixelImage pixelImage = new PixelImage(imgBrightness, dataPath("images/" + tileImageFilenames[i]));
      pixelImages.add(pixelImage);
    } 
    else {
      println("skipping");
    }
  }

  // Now we use the custom comparison operator we created before
  // to sort our pxiel images based on their scores. This will
  // be in ascending order.
  Collections.sort(pixelImages, new PixelImageComparator());

  // We've now done all of our pre-processing and we're ready
  // to display our photomosaic.

  // First draw the original image, for reference.
  image(sourceImage, 0, 0);
  
  // Move over to the right so the photomosaic doesn't
  // overlap the source image.
  translate(sourceImage.width + 50, 0);
  // Draw the photomosaic.
  // This code is moved into its own function
  // solely to keep things organized. Look below
  // to see the details of how that's done.
  drawPhotomosaic();
  
  // Save the result as a png. The filename is based on
  // the filename of the source image and the number of cells
  // per side, which, in combination, should produce a unique result.
  saveFrame(sourceImageFilename+numCellsPerSide+".png");
  
  noLoop();
}

// This function loops over the grid and draws the actual photomosaic.
// The core of this is two steps:
// 1) Calculate the average brightness of that area of the source image.
// 2) Pick one of the PixelImages based on that brightness.
void drawPhotomosaic() {
  // To calcualte the average brightness of each portion of the source image
  // we'll copy the pixels from that area into its own image
  // and the run our aveBrightness() function on that image.
  // To make things somewhat more efficent, instead of creating a new image
  // each time, we'll re-use the same "working image" over and over.
  // Here we create that workingImage to be the appropriate dimensions and color space
  PImage workingImage = createImage(cellWidth, cellHeight, RGB);

  // These two variables are just used to give a kind of progress bar
  // since this part of the program can take a long time to run.
  // i captures how many cells we've processed so far and
  // total is the total number of cells needed.
  int i = 0; 
  int total = numCellsPerSide*numCellsPerSide;
  
  // A two dimensional loop. We know that our grid is made up of a series
  // of rows, each of which has numCellsPerSide images. And, likewise, we have
  // numCellsPerSide rows in total.
  // We need to loop through all of these cells in a way that allows us to
  // calculate the x and y coordinates of each cell. These coordinates
  // are determined by which row the cell is in and which column it represents
  // within that row.
  // So, to achieve this, we nest one loop inside of another. The outside
  // loop represnts all of the rows in the image, the inner one reprsents
  // each column of each row. For each row, we'll touch each column
  // exactly once. And between knowing which row and column we're on,
  // and knowing the width and height of our cells, we'll be able to calculate the 
  // x- and y-position of each cell, which is just what we need to copy 
  // the appropriate portion of the image into our workingImage, so that we
  // can find its average brightness.
  for (int row = 0; row < numCellsPerSide; row++) {
    for (int col = 0; col < numCellsPerSide; col++) {
      // pring progress bar and increment column counter
      println(i + "/" + total);
      i++;
      // Copy the pixels from the sourceImage into our working image.
      // The arguments to the copy() function represent the coordinates in the source image,
      // the dimensions of the area we want to copy from, the coordinates to paste into in the destination
      // image, and the dimensions we want the paste to be. For more detail: http://processing.org/reference/PImage_copy_.html  
      workingImage.copy(sourceImage, col*cellWidth, row*cellHeight, cellWidth, cellHeight, 0, 0, cellWidth, cellHeight);
      // Pass that working image into our aveBrightness() function to find the
      // average brightness of this area of our sourceImage
      float b = aveBrightness(workingImage);
      // Now this is the cool trick.
      // We need to translate from the brightness of this particular region of our source image
      // into which of our pixelImages we should select.
      // Since we've sorted our pixelImages ArrayList by the score, we know that darker images
      // will be at the front of the ArrayList and lighter ones will be at the back.
      // So the brightness of our sourceImage region varies from 0-255 and we want to translate
      // that into the corresponding index in the pixelImages ArrayList. For example, if the
      // brightness was 255, i.e. full white, we'd want to use the last entry in pixelImages.
      // If the brightness was 128, we'd want to use the entry exatly in the middle of pixelImages.
      // To acheive, this we use Processing's map() function. This takes a variable
      // that has a known input range and maps it to the corresponding value in a different outut
      // range.
      // map() is one of the most widely useful functions in Processing: http://processing.org/reference/map_.html
      // In our case, we use it to map from the range of potential brightnesses (i.e. 0 to 255) into the range
      // of indices into our pixelImages ArrayList, i.e. 0 to however many images we have.
      int imageIndex = (int)map(b, 0, 255, 0, pixelImages.size());
      // Once we have the imageIndex, we use it to get the corresponding image our of pixelImages 
      PImage cellImage = pixelImages.get(imageIndex).image();
      // Then we display that image at the right position,
      // calcuated based on our current row and column as well as the width and height
      // of our cells, and the output scale.
      image(cellImage, col*cellWidth*outputScale, row*cellHeight*outputScale);
    }
  }
}

// This helper function is used in a couple of different places in the sketch.
// It loops over the pixels in an image to calculate their average brightness.
// To do that it keeps a running variable where it adds up all the brightnesses
// and at the end it divides by the total number of images.
// It's key that the variable holding the total is declared as a float rather
// than an int, otherwise you'd get a weird result.
float aveBrightness(PImage img) {
  float result = 0;
  for (int i = 0; i < img.pixels.length; i++) {
    result += brightness(img.pixels[i]);
  }

  result /= img.pixels.length;
  return result;
}
