import processing.opengl.*;
import SimpleOpenNI.*;


// ''NaN arvoja tulee.. kun printtailee tietoja.. kaatuu, pitäisi siivota, toisaalta
// kinect_multiuser nyt työn alla... samaa ideaa, mutta parempi

SimpleOpenNI  kinect;

boolean tracking = false;
int userID;
int[] userMap;
// declare our background
PImage backgroundImage;
int closestX;
int closestY;
int currentX;
int currentY;
int Zvalue;
int millisp = 0;
ArrayList<Ball> balls;
int ballWidth = 25;

int ruutux = 0;
int ruutuy  = 0;

// This works with arrays of objects, too,
// but not when first making the array
PVector[] vectors = new PVector[640];
int track_i = 0;
PVector positionC;

int maxetaisyystyyppi = 8000;
float etaisyyskropast = 0;
void setup() {
  //size(640, 480, OPENGL);
  size(640, 780, OPENGL);  // info kuvan alle.. lukee ja updatee pisteet x ja sit y suunnassa.

  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  // enable color image from the Kinect
  // kinect.enableRGB();
  kinect.setMirror(true);
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_NONE);
  // turn on depth-color alignment
  kinect.alternativeViewPointDepthToImage();
  // load the background image
  // backgroundImage = loadImage("empire_state.jpg");
  textSize(20);

  // Create an empty ArrayList (will store Ball objects)
  balls = new ArrayList<Ball>();

  for (int i = 0; i < vectors.length; i++) {
    vectors[i] = new PVector();
  }

  textAlign(CENTER, CENTER);
  rectMode(CORNER);
}

void draw() {

  int closestValue = 8000;
  // background(0);
  fill(0);
  rect(0, 0, 640, 480);

  // display the background image
  // image(backgroundImage, 0, 0);
  kinect.update();



  PImage depthImage = kinect.depthImage();
  image(depthImage, 0, 0);


  // get the depth array from the kinect
  int[] depthValues = kinect.depthMap();


  if (tracking) {
    // get the Kinect color image
    // PImage rgbImage = kinect.rgbImage();
    // prepare the color pixels
    // rgbImage.loadPixels();

    // tää enne trackinkia, jos halutaan esim. huonekaluja värittää tai muokata...



    loadPixels();


    IntVector userList = new IntVector();  
    kinect.getUsers(userList);



    userMap = kinect.getUsersPixels(SimpleOpenNI.USERS_ALL);
    // for (int i =0; i < userMap.length; i++) {

    for (int y = 0; y < 480; y++) {
      // look at each pixel in the row
      for (int x = 0; x < 640; x++) {
        // pull out the corresponding value from the depth array
        int i = x + y * 640;



        // if the pixel is part of the user
        if (userMap[i] != 0) {
          // set the sketch pixel to the color pixel

          int currentDepthValue = depthValues[i];
          // println(pixels[i]);
          if (currentDepthValue < 610) {
            pixels[i] = color(20 + userMap[i]*40, 20, 20);
          }

          if (currentDepthValue >maxetaisyystyyppi) {
            pixels[i] = color(20, 20 + userMap[i]*40, 20);
          }

          //   if(currentDepthValue > 0 && currentDepthValue < closestValue){
          if (currentDepthValue > 610 && currentDepthValue < maxetaisyystyyppi && currentDepthValue < closestValue) {

            // save its value
            closestValue = currentDepthValue;
            // and save its position (both X and Y coordinates)
            currentX = x;
            currentY = y;
          }
        }
      }
    }


    // a running average with currentX and currentY
    closestX = currentX; //  (closestX + currentX) / 2;
    closestY = currentY; // (closestY + currentY) / 2;


    track_i = (track_i +1) % 640;
    if (track_i==1) {
      fill(200);
      rect(0, 480, 640, 300);
    }
    vectors[track_i] = new PVector(float(closestX), float(closestY), float(closestValue));




    updatePixels();






    int ero = millis() - millisp;
    textSize(25);
    text(track_i + "rate:" + ero, 50, 50);
    millisp = millis();
    stroke(0, 30, 0);
    if ((track_i)>0) {
      line(track_i-1, 480 + vectors[track_i-1].z/10, track_i, 480 + vectors[track_i].z/10);
    }
    stroke(20, 0, 0);
    if ((track_i)>1) {
      line(track_i-1, 480 + 150 + (vectors[track_i-2].z - vectors[track_i-1].z), track_i, 480 + 150 + (vectors[track_i-1].z - vectors[track_i-0].z));
    }
    stroke(0, 0, 0);

    for (int i=0; i<userList.size(); i++) { 
      int userId = userList.get(i);
      PVector position = new PVector();
      positionC = new PVector();
      kinect.getCoM(userId, position);
      kinect.convertRealWorldToProjective(position, positionC);
      // PVector convertedRightShoulder = new PVector();      kinect.convertRealWorldToProjective(rightShoulder,                                          convertedRightShoulder);

      rectMode(CENTER);
      fill(0, 155, 0);
      rect(positionC.x, positionC.y, 200, 50);
      rectMode(CORNER);
      fill(255, 0, i*50+50);    



      // ellipse(positionC.x, positionC.y, 25, 25); 
      fill(155, 255 - i*60, 0); 
      textSize(20);
      // text(userId + nf(positionC.x,4) + ", " + positionC.y + ", " +positionC.z + "\n" + position.x + ", " + position.y + ", " +position.z, positionC.x, positionC.y);
      text("u: "+userId+"_ " + nf(round(positionC.x), 4) + ", " +  nf(round(positionC.y), 4) + ", " +nf(round(positionC.z), 4), positionC.x, positionC.y);
    }
    etaisyyskropast = round(positionC.z - closestValue);
    int xyrajaus = 200; // pieni ni, potkussa pomppaa muualle...
    int etaisyyskropastrajaus = 400; // z suunnassa painopisteestä
    if ((track_i)>3) {
      //  if ((Zvalue - closestValue)>100) {

      // lyömtipysähtynyt
      // println(vectors[track_i-2].dist(vectors[track_i-1]));
      // z suunnassa vähintään 6 senttiä framessa..
      //  if (((vectors[track_i-3].z - vectors[track_i-2].z)>40) && (vectors[track_i-2].z - vectors[track_i-1].z)>40) &&  (vectors[track_i-2].dist(vectors[track_i-1])>50) && (vectors[track_i-1].dist(vectors[track_i-0])<30)) {

      // vika dist huono, jos nyrkki vedetään takas...
      // x ja y erikseen ei sivuliikettä, ja z saa mennä taakseki päin.. eli edellinen miinus nyt saa olla negatiivinen 
      if ( (etaisyyskropastrajaus< etaisyyskropast) &&      ((vectors[track_i-3].z - vectors[track_i-2].z)>40) && ((vectors[track_i-2].z - vectors[track_i-1].z)>40) &&  (vectors[track_i-2].dist(vectors[track_i-1])>50) && (abs(vectors[track_i-1].x - vectors[track_i-0].x)<xyrajaus)  && (abs(vectors[track_i-1].y - vectors[track_i-0].y)<xyrajaus)  && ((vectors[track_i-1].z - vectors[track_i-0].z)<50)) {

        fill(255, 0, 0);

        // A new ball object is added to the ArrayList (by default to the end)

        // arvioidaan tarkkuus: kohde - kohta
        // nopeus: viimeisin etäisyys
        // voima: esim. 3 vikaa pistettä etäisyys
        // pistävyys: esim. kuinka tarkkaan z-suunnassa jne.. 

        String iskuinfo = "teho:" + (Zvalue - closestValue);
        iskuinfo = iskuinfo + "\n" + (vectors[track_i-3].z - vectors[track_i-2].z) + ", " + (vectors[track_i-2].z - vectors[track_i-1].z) + ", " + (vectors[track_i-1].z - vectors[track_i-0].z) + ", ";
        iskuinfo = iskuinfo + "\n" + "Drift X:" + nfc((vectors[track_i-1].x - vectors[track_i-0].x), 0) + "Y:" + (vectors[track_i-1].y - vectors[track_i-0].y);


        balls.add(new Ball(closestX, closestY, ballWidth, iskuinfo));
      } 
      else {
        rectMode(CENTER);
        if ((etaisyyskropastrajaus< etaisyyskropast)) {
          fill(0, 155, 0);
        } 
        else {
          fill(155, 155, 0);
        }
        
        
        if (positionC.z>610) {
        ellipse(closestX, closestY, etaisyyskropast/10, etaisyyskropast/10);
        }
        fill(100, 100, 0);
        textSize(20);

        fill(255, 255, 255);
        rect( closestX, closestY, 100, 30);
        fill(100, 100, 0);
        text(nfc(etaisyyskropast, 0), closestX, closestY);

        rectMode(CORNER);
      }
    }

    Zvalue = closestValue;
  }


  // https://processing.org/examples/arraylistclass.html
  // With an array, we say balls.length, with an ArrayList, we say balls.size()
  // The length of an ArrayList is dynamic
  // Notice how we are looping through the ArrayList backwards
  // This is because we are deleting elements from the list  
  for (int i = balls.size()-1; i >= 0; i--) { 
    // An ArrayList doesn't know what it is storing so we have to cast the object coming out
    Ball ball = balls.get(i);
    ball.move();
    ball.display();
    if (ball.finished()) {
      // Items can be deleted with remove()
      balls.remove(i);
    }
  }
}

void onNewUser(int uID) {
  userID = uID;
  tracking = true;
  // println("tracking");
}


void mousePressed() {
  int[] depthValues = kinect.depthMap();
  int clickPosition = mouseX + (mouseY * 640);
  int clickedDepth = depthValues[clickPosition];

  float metri = float(clickedDepth) / 1000;

  println("m: " + metri);
}






// Simple bouncing ball class

class Ball {

  float x;
  float y;
  float speed;
  float gravity;
  float w;
  float life = 255;
  String teksti = "";

  Ball(float tempX, float tempY, float tempW, String info) {
    x = tempX;
    y = tempY;
    w = tempW;
    speed = 0;
    gravity = 0;// 0.1;
    teksti = info;
  }

  void move() {
    // Add gravity to speed
    speed = speed + gravity;
    // Add speed to y location
    y = y + speed;
    // If square reaches the bottom
    // Reverse speed
    if (y > height) {
      // Dampening
      speed = speed * -0.8;
      y = height;
    }
  }

  boolean finished() {
    // Balls fade out
    life = life - 5; // life--;
    if (life < 0) {
      return true;
    } 
    else {
      return false;
    }
  }

  void display() {
    // Display the circle
    fill(255, 0, 255, life);
    //stroke(0,life);
    ellipse(x, y, w, w);
    fill(0, 0, 255);
    textSize(round(life/10)+10);
    text(teksti, x, y);
    
    
     fill(255, 255, 10, life);


    if (life>240) {

      text("TÄHTI", x, y);

      pushMatrix();
      translate(x, y);
      rotate(frameCount / -100.0);
      star(0, 0, 130, 170, 5); 
      popMatrix();
    }
    
  }
}  





// Simple bouncing ball class

class Isku {

  float x;
  float y;
  float speed;
  float gravity;
  float w;
  float life = 255;
  String teksti = "";

  Isku(float tempX, float tempY, float tempW, String info) {
    x = tempX;
    y = tempY;
    w = tempW;
    speed = 0;
    gravity = 0;// 0.1;
    teksti = info;
  }

  void move() {
    // Add gravity to speed
    speed = speed + gravity;
    // Add speed to y location
    y = y + speed;
    // If square reaches the bottom
    // Reverse speed
    if (y > height) {
      // Dampening
      speed = speed * -0.8;
      y = height;
    }
  }

  boolean finished() {
    // Balls fade out
    life--;
    if (life < 0) {
      return true;
    } 
    else {
      return false;
    }
  }

  void display() {



    // Display the circle
    fill(255, 0, 0, life);
    //stroke(0,life);
    ellipse(x, y, w, w);
    fill(0, 0, 255);
    text(teksti, x, y);


   
  }
}  


void star(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

