 import SimpleOpenNI.*;
SimpleOpenNI kinect;
int[] userMap;
int totalusers = 0;
int maxkayttajia = 20;
boolean[] com_ok;
PVector[] com_loc;
float[] com_z = new float[maxkayttajia];
int apu;
//ArrayList<Tyyppi> tyypit;

Tyyppi[] tyypit = new Tyyppi[maxkayttajia];

boolean rgb_only = false; //true;
boolean depth_draw = false;



//int[] com_id;
void setup() {  
  size(640, 880);
  kinect = new SimpleOpenNI(this);  
  kinect.enableDepth(); 

  if (rgb_only) {
    kinect.enableRGB();
  }
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_NONE);
  kinect.setMirror(true);

  for (int i=0; i<maxkayttajia; i++) {
    tyypit[i] = new Tyyppi(i);
  }
}
void draw() {  
  kinect.update();  
  if (rgb_only) {
    image(kinect.rgbImage(), 0, 0);
  } else {
    if (depth_draw) {
      image(kinect.depthImage(), 0, 0);
    } else {
      rectMode(CORNER);
      fill(0);
      stroke(0);
      rect(0, 0, 640, 480);
    }
  }
  rectMode(CORNER);
  rect(0, 520, 640, 440);
  fill(20);
  rect(0, 480, 640, 40);

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

  int kayttajia = int(userList.size());
  com_ok = new boolean[kayttajia+4];
  com_loc = new PVector[kayttajia+4];
  
  for (int i=0; i<kayttajia+4; i++) { 
    tyypit[i].nollaaClosest();
  }

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
      com_loc[userId-1] = new PVector(0, 0, 0);
      com_z[userId-1+1] = 0;
    }
    // getUsersPixels(userId); // return int[]

    // tyypit.add(new Tyyppi(com_ok, position, i));

    fill(tyypit[i].vari);   
    tyypit[i].nollaaClosest();
    // ellipse(position.x, position.y, 25,25); 
    textSize(18); 
    text(userId, position.x, position.y);
    text(userId  +"(" + totalusers + ")" + ": " + position.x + ", " + position.y + ", " + position.z, 20, 60 + userId*25 + 480);

    stroke(tyypit[i].vari, 100);
    line( position.x, 0, position.x, 480);
    line( 0, position.y, 640, position.y);
  }



  // tutki tätä, voisiko ladata vain tietynkuvan pikselit. esim. image on jotain, ja sitten siitä...
  loadPixels();
  userMap = kinect.getUsersPixels(SimpleOpenNI.USERS_ALL); 
  //userMap = kinect.getUsersPixels(userId);  // loopin sisällä voisi hakea

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
          if (userMap[i-640] != 0) { 
            voimakkuus--;
          }
          if (userMap[i-1] != 0) { 
            voimakkuus--;
          }
        }

        float currentDepthValue = depthValues[i];
        //  println(userMap[i]);
        //   println(currentDepthValue);
        apu = userMap[i];
        //  println(apu);
        //PVector com_loc2 = com_loc[1]; 
        //println(com_ok[apu]);
        //  println(com_loc2.z);
        // Pvectorin arvoa ei saa täällä.. pitäisi olla get 160704
        float threshold_hit = 200;
        float threshold_exceed = ((com_loc[apu-1].z - currentDepthValue) - threshold_hit)/2;
        float threshold_exceed2 = threshold_exceed/255;
        if ((com_loc[apu-1].z - currentDepthValue)>threshold_hit) {
          //  if (threshold_exceed>0) {
          //  if ((com_z[apu] - currentDepthValue)>200) {
          // IHAN MAKEE: pixels[i] = color(min(255,threshold_exceed)) * tyypit[userMap[i]].vari /255; // tyypit[userMap[i]].vari;

          // Pelaajan väri + harmaa syvyys
          pixels[i] = color(red(tyypit[userMap[i]].vari)*threshold_exceed2, green(tyypit[userMap[i]].vari)*threshold_exceed2, blue(tyypit[userMap[i]].vari)*threshold_exceed2 ) ; // tyypit[userMap[i]].vari;

          // harmaa syvyys
          //pixels[i] = color(min(255,threshold_exceed));
          
          
             // save its value
            if (currentDepthValue<tyypit[userMap[i]].closestValue) { tyypit[userMap[i]].asetaClosest(currentDepthValue,x,y); };
         //   tyypit[userMap[i]].closestValue = currentDepthValue;
            // and save its position (both X and Y coordinates)
          //  tyypit[userMap[i]].currentX = x;
           // tyypit[userMap[i]].currentY = y;
          
        }
      }

      if ((voimakkuus>0) && (voimakkuus<10)) {
        pixels[i] = tyypit[userMap[i]].vari;
      }
    }
  }
  println(apu);


  updatePixels();

  for (int j=0; j<10; j++) { 
    fill(tyypit[j].vari);   
    // ellipse(position.x, position.y, 25,25); 
    textSize(18);
    text(j  + ": " + com_z[j], 470, 60 + j*25+480);
    
    
  }
  for (int j=1; j<10; j++) { 
     //if (com_ok[j-1]) {
        text(tyypit[j].closestValue, tyypit[j].closestX, tyypit[j].closestY);
    // } 
     text(tyypit[j].closestValue, 400, j*50+50);
  }

  // tyypit.clear();
}


// omat tiedot tässä, ja päivitetty lista tyypeistä
class Tyyppi {
  boolean on;
  PVector sijainti;
  int id;
  color vari;
  int iskuja;
  int iskuvoima;
  int iskuetaisyys;
  float closestValue;
  int closestX;
  int closestY;
  Tyyppi(int id_) {
    id = id_;
    vari = asetavari(id);
    iskuja = 0;
    iskuvoima = 0;
    iskuetaisyys = 0;
    closestValue = 8000;
    closestX = 0;
    closestY = 0;
  }
  Tyyppi(boolean on_, PVector sijainti_, int id_) {
    on = on_;
    sijainti = sijainti_;
    id = id_;
    vari = asetavari(id);
  }
  boolean finished() {

    if (sijainti.x > 0) {
      return false;
    } else {
      return true;
    }
  }
  void nollaaClosest() {
        closestValue = 8000;
    closestX = 0;
    closestY = 0;
  }
  void asetaClosest(float closestValue_, int currentX_, int currentY_) {
         closestValue = closestValue_;
    closestX = currentX_;
    closestY = currentY_;
  }
  
  void update(int userId) {
    PVector position = new PVector();    
    kinect.getCoM(userId, position);
    kinect.convertRealWorldToProjective(position, sijainti);
  }
  color asetavari(int id) {
    if (id == 0 ) {
      vari = color(100, 100, 100); // oikean puoleinen varjo kaikista hahmoista.. ei käyttäjää siinä.
    } else if (id == 1 ) {
      vari = color(200, 0, 0);
    } else if (id ==2 ) {
      vari = color(0, 200, 0);
    } else {
      vari = color(id*10, 0, 200-id*10);
    }
    return vari;
  }
}

