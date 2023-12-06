// Basic settings
let showOriginal = false;          // Display a thumbnail of the original photo in the upper left (default: false)
let tileWidth = 40;               // Size of mosaic blocks (width in pixels, default: 40)
let num_subTiles = 1;              // Number of sub-tiles to analyze per mosaic tile (default: 1x1)

// Settings for using custom photos
let filename = 'target.jpg';      // Change the filename of your target image
let num_images = 4936;            // Number of source images in database
let filename_prefix = 'Photo - ';  // Change the name format of the photo collection (default: Photo - #)
let filename_ext = 'jpeg';        // Change the file extension of your photos (default: .jpeg);

// Settings for more complex photo analysis methods
let matchingMode = 'HSB';         // Color matching space (HSB: [default] hue-saturation-brightness, RGB: red-green-blue)
let quality_setting = 1;          // Mosaic quality optimization setting (1: [default] greedy search, 2: A* path optimization-can be very slow!)
let debug = false;                // Change this to true to see more detailed debugging info in the console

// Global variables
let tileHeight;
let targetImage, mosaic;
let sourceImages = [];
let colorValues = [];
let image_map = [];
let tile_map = [];
let used_images = [];

// For wait-to-click components
let waitToStart = 0;  // Now goes through multiple states: 0 > 1 > 2
let num_loaded_images = 0;
let click_highlight = [];


function setup() {
  createCanvas(windowWidth, windowHeight);
  background(0);
  textAlign(CENTER);
  textSize(24);
  stroke(0);
  fill(255);
  text('Loading source images...', width / 2, height / 2);
  loadSourceImages();
}

function draw() { // We're only going to draw once, so We're not going to worry about this
}


function mouseClicked() {
  switch (waitToStart) {
    case 0:
      waitToStart = 1;
      background(0);
      text('Loading source images...', width / 2, height / 2);
      console.log("waitToStart: " + waitToStart);
      console.log("Loading "+num_images+" source images...");
      loadSourceImages();
      break;
    case 1:
      waitToStart = 2;
      console.log("waitToStart: " + waitToStart);
      background(0);
      text('Finding best matching images for mosaic...', width / 2, height / 2);
      go();
      break;
  }
  
  if (click_highlight.length != 0) {
      highlightTile(mouseX, mouseY);    
  }
}


function highlightTile(click_x, click_y) {
  n = floor(click_x/tileWidth);
  m = floor(click_y/tileHeight);
  
  console.log("clicked tile: "+m+", "+n);
  console.log("click_highlight: "+click_highlight[m][n]);

  switch (click_highlight[m][n]) {
    case 1:
      click_highlight[m][n] = 2;
      this_tile = targetImage.get(n*tileWidth,m*tileHeight,tileWidth,tileHeight);
      image(this_tile, n*tileWidth,m*tileHeight,tileWidth,tileHeight);
      break;
    case 2:
      click_highlight[m][n] = 3;
      source_tile = targetImage.get(n*tileWidth,m*tileHeight,tileWidth,tileHeight);
//      c_tile = computeTileColors(source_tile);
      subTileColors = computeSubTileColors(source_tile);
      for (let i=0;i<subTileColors.length;i++) {
        for (let j=0; j<subTileColors[i].length; j++) {
          this_color = subTileColors[i][j];
          fill(this_color);
          strokeWeight(0.5);
          sub_x = round(tileWidth/num_subTiles);
          sub_y = round(tileHeight/num_subTiles);
          rect(n*tileWidth + j*sub_x,m*tileHeight + i*sub_y,sub_x,sub_y);
        }
      }
      break;
    case 3:
      click_highlight[m][n] = 1;
      this_tile = sourceImages[image_map[m][n]];
      image(this_tile, n*tileWidth,m*tileHeight,tileWidth,tileHeight);
      break;
  }  
}


function loadSourceImages() {
  for (count = 0; count < num_images; count++) {
    this_img = loadImage(filename_prefix +(count+1) + '.' + filename_ext,

      // Callback function when image is loaded
      function(loaded_img) {
        sourceImages.push(loaded_img);
        num_loaded_images++;
        if (debug) { console.log("Loaded image number: " + num_loaded_images); }
        if (num_loaded_images == num_images) {
          background(0);
          text('Creating mosaic...', width / 2, height / 2);
          go();
        }                        
      } );
  }    
}

// CRITICAL FUNCTION: Compute a "distance" between two colors
function colorDistanceRGB(c1,c2) {
  r1 = red(c1);
  g1 = green(c1);
  b1 = blue(c1);
  
  r2 = red(c2);
  g2 = green(c2);
  b2 = blue(c2);

  // Compute the Euclidean distance between the color components (R,G,B)
  distance = sqrt( pow(r1-r2,2) + pow(g1-g2,2) + pow(b1-b2,2) );
  return distance;
}


// CRITICAL FUNCTION: Compute a "distance" between two colors
function colorDistanceHSB(c1,c2) {
  h1 = hue(c1);
  s1 = saturation(c1);
  b1 = brightness(c1);
  
  h2 = hue(c2);
  s2 = saturation(c2);
  b2 = brightness(c2);

  // Hue (h) is an angle, so find the smallest angular difference
  let h_diff = abs(h1-h2);
  if (h_diff > 180) { h_diff = 360 - h_diff; }

  // Compute a distance, more heavily weighting brightness
  distance = sqrt( pow(h_diff,2) + pow(s1-s2,2) + 3*pow(b1-b2,2) );
  return distance;
}


function findBestMatchForTile(subImage) {  

  let matches = [];
  // For now, we just take the center pixel in the sub-image
  // For the EXTRA CREDIT, you'll need to take more than a single pixel
//  c_target = subImage.get(floor(subImage.width/2),floor(subImage.height/2));
  c_target = computeTileColor(subImage);
  
  // What follows is the loop that searches for the best match for the given target color
  // You'll probably need to change this for the EXTRA CREDIT.
  
  // Initialize loop with maximum color distance value
  if (matchingMode == 'RGB') { current_min_distance = colorDistanceRGB(color(0,0,0), color(255,255,255)); } // RGB
  else if (matchingMode == 'HSB') { current_min_distance = colorDistanceHSB(color('hsb(1,0%,0%)'), color('hsb(360,100%,100%)')); } // HSB
    
  idx = 0;

  // Loop that searches for the best matching photo in the database
  subTile_m = 0;
  subTile_n = 0;
  for (let i = 0; i < sourceImages.length; i++) {
    color_distance = 0;
    for (let m=0; m < num_subTiles; m++) {
      for (let n=0; n < num_subTiles; n++) {
        if (matchingMode == 'RGB') { color_distance += colorDistanceRGB(c_target, colorValues[i][m][n]); }
        else if (matchingMode == 'HSB') { color_distance += colorDistanceHSB(c_target, colorValues[i][m][n]); }
      }
    }
    color_distance /= num_subTiles*num_subTiles; // Divide by number of subTiles to compute average across subTiles

    matches.push({index: i, distance: color_distance});
    
    if (distance < current_min_distance) {
      current_min_distance = distance;
      idx = i;
    }    
  }
  matches.sort(compareByDistance);

//  if (debug) { console.log("findBestMatchForSubImage: " + c_target + " > " + colorValues[idx]); }
//  return {index: idx, distance: current_min_distance, next_best: matches.slice(1,256)};
  return {index: idx, distance: current_min_distance, next_best: matches };

}


// Start processing the images
function go() {
  // Load target image and then load (and process) all the source image files for the mosaic
  targetImage = loadImage(filename, loadAllImages);
}


// Load and process all source image files for the mosaic
function loadAllImages() {

  let srcW = targetImage.width;
  let srcH = targetImage.height;

  createCanvas(srcW, srcH);
  background(0);

  textAlign(CENTER);
  textSize(24);
  stroke(0);
  fill(255);
  text('Creating mosaic...', width / 2, height / 2);

  setTimeout(startCreating, 1000);
}

function startCreating() {
  console.log("Creating mosaic from " + sourceImages.length + " source images..." );

  mosaic = createImage(targetImage.width, targetImage.height);
  mosaic.copy(targetImage, 0, 0, targetImage.width, targetImage.height, 0, 0, targetImage.width, targetImage.height);

  pixelDensity(1);
  drawMosaic();
}

function drawMosaic() {
  
  if (colorValues.length == 0) {
    // Check if we've preloaded the image set color data. If not, recompute it for all photos.
    computeImageColors();
  }
  
  mosaic.loadPixels();
  numTiles = floor(mosaic.width/tileWidth);
  console.log("... finding best source image matches for "+numTiles+"x"+numTiles+" mosaic tiles.");
  tileHeight = floor(tileWidth*(targetImage.height/targetImage.width));
  
  let y = 0;
  image_map = [];
  tile_map = [];
  let t = 0;
  
  for (let m=0; m<numTiles; m++) {    
    let x = 0;
    image_map_row = [];
    for (let n=0; n<numTiles; n++) {
      subImage = mosaic.get(x, y, tileWidth, tileHeight);
      matchData = findBestMatchForTile(subImage);
      full_matchData = {index: matchData.index, distance: matchData.distance, next_best: matchData.next_best, row: m, column: n};
      tile_map.push(full_matchData);
      
      imageIndex = matchData.index;
//      image(sourceImages[imageIndex], x, y, tileWidth, tileHeight);
//      image_map_row[n] = imageIndex;
//      mosaic.copy(sourceImages[imageIndex],0,0,sourceImages[imageIndex].width,sourceImages[imageIndex].height,x,y,tileWidth,tileHeight);
      x += tileWidth;
    }
    image_map[m] = image_map_row;
    y += tileHeight;
  }
  
  // Sort tile_map by distance
  tile_map.sort(compareByDistance);
//  console.log(tile_map.slice(0,20));
  
  let trail = [];
  let h = 0;
  if (quality_setting == 1) {
    // Greedy search, starting with lowest distance
    removeDuplicateMatches();
    
    for (let t=0; t<tile_map.length; t++) {
      h += tile_map[t].distance;
      trail.push(tile_map[t].index);
    }
    console.log('Greedy search distance: ' + h);
  }
  else {
    // Sum to find the "best case" remaining path (lower bound on h[n])
    // Just summing the distance to best matches in the database
    for (let t=0; t<tile_map.length; t++) { h += tile_map[t].distance; }
    console.log('Greedy distance, includes duplicates: ' + h);

    trail = a_star();
    console.log('Trail: '+trail);
    console.log('Entries: '+trail.length);
  }
  
  for (let t=0; t<tile_map.length; t++) {
//    let imageIndex = tile_map[t].index;
    let imageIndex = trail[t];
    let m = tile_map[t].row;
    let n = tile_map[t].column;
    let x = n * tileWidth;
    let y = m * tileHeight;
//    console.log('Tile '+m+'x'+n+', matched to index: '+imageIndex);
    if ( imageIndex < num_images ) {
        image(sourceImages[imageIndex], x, y, tileWidth, tileHeight);
        mosaic.copy(sourceImages[imageIndex],0,0,sourceImages[imageIndex].width,sourceImages[imageIndex].height,x,y,tileWidth,tileHeight);    
    }
    image_map[m][n] = imageIndex;
  }
    
  click_highlight = new Array(numTiles);
  for (let m=0; m<numTiles; m++) {
    click_highlight[m] = new Array(numTiles).fill(1);
  }

  // Display the target image, for reference, in upper left corner
  if (showOriginal) { image(targetImage,0,0,400,300); }
  
  // Save and download the finished photomosaic
  mosaic.save('Photomosaic', 'png');
}


function compareByDistance(a, b) {
  // Compare distances in image info array
  let comparison = 0;
  if (a.distance > b.distance) {
    comparison = 1;
  } else if (a.distance < b.distance) {
    comparison = -1;
  }
  return comparison;
}

function removeDuplicateMatches() {
  used_images = [];
  used_images[0] = tile_map[0].index;
  for (let t=1; t<tile_map.length; t++) {
    if (debug) {console.log('Examining tile #' + t); }
    findNextBestMatch(t);
  }
}


function a_star() {
  let h = 0;
  
  // Sum to find the "best case" remaining path (lower bound on h[n])
  // Just summing the distance to best matches in the database
  for (let t=0; t<tile_map.length; t++) { h += tile_map[t].distance; }
  console.log('Greedy min distance: ' + h);

  let f = [];
  let f_trail = [];
  let prev_f = [];
  prev_f[0] = 0;
  let prev_f_trail = [];
  prev_f_trail[0] = [];
  
  // Loop over tiles
  for (let t=0; t<tile_map.length; t++) {
    f[t] = [];
    f_trail[t] = [];
    let tempMinDistance = 1024.0*1024.0*1024.0; // A big number
    let l_range = 1;
    let h_range = 5;
    
    // Loop over valid nodes from prior tile
    for (let n=0; n<prev_f.length; n++) {    
      let nextVal = tile_map[t].distance + prev_f[n];
      if (0) {
//        console.log('nextVal: ' + nextVal); 
        console.log('tile_map[t].index: ' + tile_map[t].index);
        console.log('tile_map[t].distance: ' + tile_map[t].distance);
        console.log('prev_f[n]: ' + prev_f[n]);
        console.log('prev_f_trail[n] includes: ' + prev_f_trail[n].includes(tile_map[t].index) );
      }
      
      if ( !prev_f_trail[n].includes(tile_map[t].index) ) {
        if ( (nextVal + h) < tempMinDistance ) {
          if ( (t>l_range) && (t<h_range) ) {console.log('t=' + t + ', Adding node 0, index: '+tile_map[t].index); }
          tempMinDistance = nextVal + h;
          f[t].push(nextVal);
          f_trail[t][0] = prev_f_trail[n];
          f_trail[t][0].push( tile_map[t].index );
        }
      }
    
      // Loop over image distances for current tile
      for (let c=0; c<tile_map[t].next_best.length; c++) {
        let nextVal = tile_map[t].next_best[c].distance + prev_f[n];

        if (0) {
  //        console.log('nextVal: ' + nextVal); 
          console.log('tile_map[t].next_best[c].index: ' + tile_map[t].next_best[c].index);
          console.log('tile_map[t].next_best[c].distance: ' + tile_map[t].next_best[c].distance);
          //console.log('prev_f[n]: ' + prev_f[n]);
          console.log('prev_f_trail[n] includes: ' + prev_f_trail[n].includes(tile_map[t].next_best[c].index) );
        }

        if ( !prev_f_trail[n].includes(tile_map[t].next_best[c].index) ) {
          if ( (nextVal + h) < tempMinDistance ) {

            if ( (t>l_range) && (t<h_range) ) {
              console.log('t: '+t+', Adding node... next_best['+c+']'); 
              console.log('tile_map[t].next_best[c].index: ' + tile_map[t].next_best[c].index);
              console.log('tile_map[t].next_best[c].distance: ' + tile_map[t].next_best[c].distance);
              //console.log('prev_f[n]: ' + prev_f[n]);
              console.log('prev_f_trail[n] includes: ' + prev_f_trail[n].includes(tile_map[t].next_best[c].index) );
            }
    
            tempMinDistance = nextVal + h;
            f[t].push(nextVal);
            new_trail = prev_f_trail[n];
            new_trail.push(tile_map[t].next_best[c].index);
            f_trail[t].push( new_trail );
          }
        }
      } // End loop over image distances from current tile
    } // End loop over nodes from previous tile step
    
    h -= tile_map[t].distance; // Remove the minimum tile distance from h[n] sum
    prev_f = f[t];
    prev_f_trail = f_trail[t];

    if ( (t<h_range) && (t>l_range) ) {
//    console.log('h value: ' + h);
      console.log('f: ' + prev_f);
      console.log('f_trail: ' + prev_f_trail);
    }

  } // End loop over tiles
  
  console.log('Final f: ' + prev_f);
  console.log('Final f_trail: ' + prev_f_trail);
  
  return prev_f_trail[0];
} // End function


function findNextBestMatch(tile_idx) {
  image_idx = tile_map[tile_idx].index; 
  if (used_images.includes(image_idx)) {
//    console.log('... Tile #' + tile_idx + ' image ' + image_idx + ' in use.');
//    console.log('... ... choices remaining: ' + tile_map[tile_idx].next_best.length);
    next_choice = tile_map[tile_idx].next_best.shift();
    tile_map[tile_idx].index = next_choice.index;
    tile_map[tile_idx].distance = next_choice.distance;
//    console.log('... Tile #' + tile_idx + ' trying: ' + next_choice.index);
    tile_map.sort(compareByDistance);
    findNextBestMatch(tile_idx);
  }
  else {
    if (debug) {
      console.log('... Tile #' + tile_idx + ' matched to image: ' + image_idx);
      console.log('... ... choices remaining: ' + tile_map[tile_idx].next_best.length);
    }
    used_images.push(image_idx);
  }
}


// Process all source image files and download to JSON file: source-data.json
function computeImageColors() {
  console.log("... analyzing colors for "+sourceImages.length +" source images, using "+num_subTiles+"x"+num_subTiles+" sub tiles.");
  
  for (let i = 0; i < sourceImages.length; i++) {
    sourceImages[i].loadPixels();
    if (debug) { console.log("computeImageColors() for image "+(i+1)+"..."); }

    let subTileWidth = floor(sourceImages[i].width / num_subTiles);
    let subTileHeight = floor(sourceImages[i].height / num_subTiles);
    
    let y = 0; // reset y-coordinate for creating tiles from new image
    
    tileColors = [];
    
    for (let m=0; m < num_subTiles; m++) {
      tileRowColors = [];
      let x = 0; // reset x-coordinate for this row of tiles
      
      for (let n=0; n < num_subTiles; n++) {
//        if (debug) { console.log("computeImageColors() for image "+i+", subtile: "+m+","+n); }

        subImage = sourceImages[i].get(x, y, subTileWidth, subTileHeight);        
        tileRowColors[n] = computeTileColor(subImage);
  
        x += subTileWidth;
      }
      tileColors[m] = tileRowColors;
  
      y += subTileHeight;
    }

    colorValues[i] = tileColors;

    if (debug) { console.log("colorValues-" + i + ": " + colorValues[i]); }    
  }  
}


function computeSubTileColors(img) {
  
  let subTileWidth = floor(img.width / num_subTiles);
  let subTileHeight = floor(img.height / num_subTiles);

  let y = 0; // reset y-coordinate for creating tiles from new image

  tileColors = [];

  for (let m=0; m < num_subTiles; m++) {
    tileRowColors = [];
    let x = 0; // reset x-coordinate for this row of tiles

    for (let n=0; n < num_subTiles; n++) {
      subImage = img.get(x, y, subTileWidth, subTileHeight);        
      tileRowColors[n] = computeTileColor(subImage);

      x += subTileWidth;
    }
    tileColors[m] = tileRowColors;

    y += subTileHeight;
  }
  return tileColors;  
}



function computeTileColor(tileImage) {
  let r_avg = 0;
  let g_avg = 0;
  let b_avg = 0;
  
  tileImage.loadPixels();

  if (debug) { console.log("computeTileColors()..." ); }

  // Sum values of color components of every pixel in this tile
  for (let j = 0; j < tileImage.pixels.length; j+=4) {
    r_avg += tileImage.pixels[j];
    g_avg += tileImage.pixels[j+1];
    b_avg += tileImage.pixels[j+2];
  }

  // Divide by number of pixels in image
  r_avg /= (tileImage.pixels.length / 4);
  g_avg /= (tileImage.pixels.length / 4);
  b_avg /= (tileImage.pixels.length / 4);
  
  tileColor = color(floor(r_avg), floor(g_avg), floor(b_avg));
  return tileColor;
}
