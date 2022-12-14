float Sign(float v){
  if(v >= 0){
    return 1;
  }else{
    return -1;
  }
}

PVector Sign(PVector v){
  return new PVector(Sign(v.x), Sign(v.y), Sign(v.z));
}

void CopyTo(PVector dst, PVector src){
  dst.x = src.x;
  dst.y = src.y;
  dst.z = src.z;
}

String commas(int v){
  String ini = nf(v, 0);
  int inil = ini.length();
  if(inil <= 3){
    return ini;
  }
  
  String out = ini.substring(inil-3, inil);
  
  for(int i = inil-3; i >= inil%3 + 3; i-=3){
    out = ini.substring(i-3, i) + "," + out;
  }
  if(inil%3 == 0){
    return out;
  }else{
    return ini.substring(0, inil%3) + "," + out;
  }
}

String commas(long v){
  String ini = String.valueOf(v);
  int inil = ini.length();
  if(inil <= 3){
    return ini;
  }
  
  String out = ini.substring(inil-3, inil);
  
  for(int i = inil-3; i >= inil%3 + 3; i-=3){
    out = ini.substring(i-3, i) + "," + out;
  }
  if(inil%3 == 0){
    return out;
  }else{
    return ini.substring(0, inil%3) + "," + out;
  }
}

void transferCords(PVector a, PVector b){
  a.x = b.x;
  a.y = b.y;
  a.z = b.z;
}

PVector multEle(PVector a, PVector b){
  a.x *= b.x;
  a.y *= b.y;
  a.z *= b.z;
  return a;
}

void loadSettings(){
  preferences = loadTable("preferences.csv", "header");
  
  TableRow row = preferences.getRow(0);
  
  bloomStrength = row.getFloat("bloomStrength");
  bloomSize = row.getInt("bloomSize");
  exposure = row.getFloat("exposure");
  contrast = row.getFloat("contrast");
}

void writeSettings(){
  preferences = new Table();
  preferences.addColumn("bloomStrength");
  preferences.addColumn("bloomSize");
  preferences.addColumn("exposure");
  preferences.addColumn("contrast");
  
  TableRow newRow = preferences.addRow();
  newRow.setFloat("bloomStrength", bloomStrength);
  newRow.setInt("bloomSize", bloomSize);
  newRow.setFloat("exposure", exposure);
  newRow.setFloat("contrast", contrast);
  
  saveTable(preferences, "data/preferences.csv");
}

float rFloat(int x){
  x *= 100;
  x += ( x << 10 );
  x ^= ( x >>  6 );
  x += ( x <<  3 );
  x ^= ( x >> 11 );
  x += ( x << 15 );
  return (float)abs(x) / 2147483647;
}

PVector orthVector(PVector n){
  PVector v = PVector.random3D();
  while(v.dot(n) == 0){
    v = PVector.random3D();
  }
  return n.cross(v).normalize();
}

String breakText(String input, float boxWidth){ // adds new line characters to an input string, breaks only on spaces
  char[] chars = input.toCharArray();
  
  float currentWidth = 0;
  float wordWidth;
  float spaceWidth = textWidth(' ');
  
  String output = "";
  int wordStart = 0;
  int w;
  String word;
  while(wordStart < chars.length){
    w = wordStart;
    while(w < chars.length && chars[w] != ' ' && chars[w] != '\n'){w++;} // finds next space
    word = (String)input.subSequence(wordStart, w);
    wordWidth = textWidth(word);
    
    if(w < chars.length && chars[w] == '\n'){ // keep \n s in the word
      output += "\n" + word;
      currentWidth = wordWidth;
      wordStart = w+1;
      continue;
    }
    
    if(currentWidth + spaceWidth + wordWidth > boxWidth){ // if adding a word to this line makes it too long then insert a newline
      output += '\n';
      currentWidth = wordWidth;
    }else{ // no need to add a new line yet, just add a space to seperate chars
      if(wordStart > 0){output += ' ';}
      currentWidth += spaceWidth + wordWidth;
    }
    
    output += word;
    wordStart = w+1;
  }
  
  return output;
}

int numLines(String s){ // counts the number of lines that a string will have when printed (based on number of '\n')
  int out = 1;
  for(int i = 0; i < s.length(); i++){
    if(s.charAt(i) == '\n'){
      out++;
    }
  }
  return out;
}

void SaveImage(File location){
  if(location == null){return;}
  /*String name = "saves/SavedImage";
  boolean exists = false;
  int add = 1;
  
  File f = dataFile(name + ".png");
  exists = f.isFile();
  
  while(exists){
    exists = dataFile(name + str(++add) + ".png").isFile();
  }*/
  PImage local = imgToSave;
  imgToSave = null;
  
  /*if(!location.isFile()){
    println("Location is not a file");
    return;
  }*/
  
  String extention = location.getAbsolutePath();
  if(extention.contains(".")){
    //String t = "";
    for(int i = 0; i < extention.length(); i++){
      if(extention.charAt(i) == '.'){
        extention = extention.substring(i + 1,extention.length());
        break;
      }
    }
  }else{
    extention = "tiff";
    location = new File(location.getAbsolutePath() + "." + extention);
    
    println(location);
  }
  
  /*if(!location.exists()){
    try{
      location.createNewFile();
    }catch(IOException e){
      println("Unable to create file at this location");
      return;
    }
  }*/
  
  String dir = location.getPath();
  local.save(dir);
  
  /*if(!location.canWrite()){
    println("Cannot write to this location");
  }
  println(location.getAbsolutePath());
  try {
    imgToSave.save(location.getAbsolutePath());
  }catch(Exception e){
    println("failed to save");
  }*/
}

ObjParts ReadOBJ(String fileName){
  BufferedReader reader = createReader(fileName);
  
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  IntList faces = new IntList();
  
  ArrayList<PVector> vertexNormals = new ArrayList<PVector>();
  IntList vnIndices = new IntList();
  
  ArrayList<UV> vertUVs = new ArrayList<UV>();
  IntList uvInds = new IntList();
  
  try {
    String line = reader.readLine();
    while(line != null){
      String[] parts = line.split(" ");
      if(parts[0].equals("v")){ // vertex
        vertices.add(new PVector(Float.parseFloat(parts[1]), Float.parseFloat(parts[2]), Float.parseFloat(parts[3])));
      }else if(parts[0].equals("vn")){ // vertex normal
        vertexNormals.add(new PVector(Float.parseFloat(parts[1]), Float.parseFloat(parts[2]), Float.parseFloat(parts[3])));
      }else if(parts[0].equals("vt")){ // vertex uv
        vertUVs.add(new UV(Float.parseFloat(parts[1]), Float.parseFloat(parts[2])));
      }else if(parts[0].equals("f")){ // face
        //int[] f = new int[3];
        for(int i = 0; i < 3; i++){
          String[] inds = parts[i+1].split("/");
          faces.append(Integer.parseInt(inds[0]) - 1);
          
          if(inds.length > 1 && inds[1].length() > 0){
            try{
              uvInds.append(Integer.parseInt(inds[1]) - 1);
            } catch(NumberFormatException e){};
          }
          
          if(inds.length > 2 && inds[2].length() > 0){
            try{
              vnIndices.append(Integer.parseInt(inds[2]) - 1);
            } catch(NumberFormatException e){};
          }
        }
        //faces.add(f);
      }
      
      line = reader.readLine();
    }
  } catch(IOException e){
    e.printStackTrace();
  }
  
  UV[] uvArr = vertUVs.toArray(new UV[vertUVs.size()]);
  int[] uvIndArr = uvInds.toArray();
  
  if(uvArr.length == 0){
    uvArr = null;
    uvIndArr = null;
  }
  
  PVector[] vnArr = vertexNormals.toArray(new PVector[vertexNormals.size()]);
  int[] vnIndArr = vnIndices.toArray();
  
  if(vnArr.length == 0){
    vnArr = null;
    vnIndArr = null;
  }
  
  return new ObjParts(vertices.toArray(new PVector[0]), faces.toArray(),
                      vnArr, vnIndArr,
                      uvArr, uvIndArr);
}

class ObjParts {
  PVector[] verts;
  int[] faces;
  
  PVector[] vertNorms;
  int[] vnInds;
  
  UV[] vertUVs;
  int[] uvInds;
  ObjParts(PVector[] verts, int[] faces, PVector[] vertNorms, int[] vnInds, UV[] vertUVs, int[] uvInds){
    this.verts = verts;
    this.faces = faces;
    this.vertNorms = vertNorms;
    this.vnInds = vnInds;
    this.vertUVs = vertUVs;
    this.uvInds = uvInds;
  }
}

AtomicBoolean selectingObject = new AtomicBoolean(false);

void loadObjectGUI(File location){
  if(location == null || !location.exists() || !location.canRead() || !location.isFile()){
    return;
  }
  
  String name = location.getName();
  println(name.substring(name.length() - 3, name.length()));
  if(!name.substring(name.length() - 3, name.length()).equals("obj")){ // file extention is not obj
    return;
  }
  
  Mesh mesh = new Mesh(new PVector(0, 0, 0), location.getAbsolutePath(), true, true, new Diffuse(new Color(1, 1, 1)));
  
  if(mesh.verts.length == 0){ // mesh has no vertices, delete
    return;
  }
  
  Objs.add(mesh);
  
  selectedObject = Objs.get(Objs.size() - 1);
  objectSelected = true;
  preresUpdate = true;
  
  selectingObject.set(false);
}
