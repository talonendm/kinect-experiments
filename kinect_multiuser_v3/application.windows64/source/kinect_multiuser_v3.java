import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import SimpleOpenNI.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class kinect_multiuser_v3 extends PApplet {


SimpleOpenNI kinect;
int[] userMap;
int totalusers = 0;

boolean[] com_ok;
PVector[] com_loc;
float[] com_z = new float[20];
int apu;
ArrayList<Tyyppi> tyypit;

boolean rgb_only = false; //true;




//int[] com_id;
public void setup() {  
  size(640, 480);
  kinect = new SimpleOpenNI(this);  
  kinect.enableDepth(); 
 
 if (rgb_only) {
  kinect.enableRGB();
 }
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_NONE);
   kinect.setMirror(true);
  tyypit = new ArrayList<Tyyppi>();
  
}
public void draw() {  
  kinect.update();  
  if (rgb_only) {
    image(kinect.rgbImage(),0,0);
  } else {
    image(kinect.depthImage(), 0, 0);
  }
  
  
  
  // get the depth array from the kinect
  int[] depthValues = kinect.depthMap();
  
  IntVector userList = new IntVector();  
  kinect.getUsers(userList);
  totalusers = 0;
  
   // https://processing.org/examples/arraylistclass.html
  // With an array, we say balls.length, with an ArrayList, we say balls.size()
  // The length of an ArrayList is dynamic
  // Notice how we are looping through the ArrayList backwards
  // This is because we are deleting elements from the list  

  
 // tyypit.add(new Tyyppi(closestX, closestY, ballWidth, iskuinfo));
  
  int kayttajia = PApplet.parseInt(userList.size());
  com_ok = new boolean[kayttajia+4];
  com_loc = new PVector[kayttajia+4];
  
  for (int i=0; i<kayttajia; i++) { 
    int userId = userList.get(i);
    PVector position = new PVector();    
    kinect.getCoM(userId, position);

    kinect.convertRealWorldToProjective(position, position);    

   

    if (position.x>0) {
      totalusers++;
      com_ok[userId-1] = true;
      com_loc[userId-1] = position;
      //println(com_loc[i]);
      //println(kayttajia);
      com_z[userId] = com_loc[userId-1].z;
    } else {
      com_ok[userId-1] = false;
      com_loc[userId-1] = new PVector(0,0,0);
      com_z[userId-1+1] = 0;
    }
    // getUsersPixels(userId); // return int[]

   // tyypit.add(new Tyyppi(com_ok, position, i));

    fill(255, 0, 0);   
    // ellipse(position.x, position.y, 25,25); 
    textSize(13); 
    text(userId, position.x, position.y);
    text(userId  +"(" + totalusers + ")" + ": " + position.x + ", " + position.y + ", " + position.z, 20, 20 + userId*30);
  }




  loadPixels();
  userMap = kinect.getUsersPixels(SimpleOpenNI.USERS_ALL); 
  //userMap = kinect.getUsersPixels(userId);  // loopin sis\u00e4ll\u00e4 voisi hakea
  
  int voimakkuus = 10;
  
  for (int y = 0; y < 480; y++) {
    // look at each pixel in the row
    for (int x = 0; x < 640; x++) {
      // pull out the corresponding value from the depth array
      int i = x + y * 640;

     

      // if the pixel is part of the user
      voimakkuus++;
      if (voimakkuus>10) {
        voimakkuus = 10;
      } 
      if (voimakkuus<0) {
        voimakkuus = 0;
      } 
      if (userMap[i] != 0) {
        
         if (i>642) {
           voimakkuus--;
           if (userMap[i-640] != 0) { voimakkuus--; }
           if (userMap[i-1] != 0) { voimakkuus--; }
         }
        
        int currentDepthValue = depthValues[i];
      //  println(userMap[i]);
     //   println(currentDepthValue);
        apu = userMap[i];
      //  println(apu);
        //PVector com_loc2 = com_loc[1]; 
        //println(com_ok[apu]);
      //  println(com_loc2.z);
        // Pvectorin arvoa ei saa t\u00e4\u00e4ll\u00e4.. pit\u00e4isi olla get 160704
        if ((com_loc[apu-1].z - currentDepthValue)>200) {
      //  if ((com_z[apu] - currentDepthValue)>200) {
          pixels[i] = color(120 + userMap[i]*40, 120, 20);
        } else if (voimakkuus>0){
          if (userMap[i] ==1 ) {
          pixels[i] = color(200,   0, 0);
          
          } else if (userMap[i] ==2 ) {
            pixels[i] = color(0,   200, 0);
          }else {
            pixels[i] = color(0,   0, 200);
          }
        }
      }
    }
  }
  println(apu);
 
  
  updatePixels();
  
    for (int j=0; j<10; j++) { 
      fill(255, 210, 0);   
    // ellipse(position.x, position.y, 25,25); 
    textSize(13);
    text(j  + ": " + com_z[j], 320, 20 + j*30);
   text("sfdfss", 120, 20 + j*30);
    
  }
  
  
  // tyypit.clear();
}


// omat tiedot t\u00e4ss\u00e4, ja p\u00e4ivitetty lista tyypeist\u00e4
class Tyyppi {
  boolean on;
  PVector sijainti;
  int id;
  Tyyppi(boolean on_, PVector sijainti_,  int id_) {
    on = on_;
    sijainti = sijainti_;
    id = id_;
  }
  public boolean finished() {
  
    if (sijainti.x > 0) {
      return false;
    } 
    else {
      return true;
    }
  }
  public void update(int userId) {
    PVector position = new PVector();    
    kinect.getCoM(userId, position);
    kinect.convertRealWorldToProjective(position, sijainti);   
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "kinect_multiuser_v3" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
