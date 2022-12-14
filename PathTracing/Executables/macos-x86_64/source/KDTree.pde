import java.util.Arrays;
import java.util.concurrent.atomic.AtomicInteger;

class KDTree { // this implementation is adapted from / inspired by the implementation in PBR-book
  PVector TL, BR;
  Primitive[] objs;
  int[] primSets;
  Node[] nodes;
  int threshold = 8;
  int maxDepth = -1;
  PVector[] Sdirs = {new PVector(1, 0, 0), new PVector(0, 1, 0), new PVector(0, 0, 1)};
  
  float traverseCost = 1;
  float intersectCost = 80;
  float emptyBonus = 0.2;
  AtomicInteger numThreads = new AtomicInteger();
    
  KDTree(ArrayList<Primitive> objs_){
    objs = objs_.toArray(new Primitive[objs_.size()]);
    Init();
  }
  
  KDTree(Primitive[] objs_){
    objs = objs_;
    Init();
    println("num Nodes: " + nodes.length + " ; primSetSize: " + primSets.length);
  }
  
  void Init(){
    if(objs.length == 0){return;}
    
    AABB[] BBoxes = new AABB[objs.length];
    BBoxes[0] = new AABB();
    objs[0].getBoundingBox(BBoxes[0].TL, BBoxes[0].BR);
    
    TL = BBoxes[0].TL.copy();
    BR = BBoxes[0].BR.copy();
    AABB t = new AABB(TL, BR);
    for(int i = 1; i < objs.length; i++){
      BBoxes[i] = new AABB();
      objs[i].getBoundingBox(BBoxes[i].TL, BBoxes[i].BR);
      t.grow(BBoxes[i]);
    }
    
    if(maxDepth <= 0){
      maxDepth = round(8 + 1.3 * log(objs.length) / log(2));
    }
    
    IntList pset = new IntList();
    ArrayList<Node> nodes = new ArrayList<Node>();
    IntList startList = new IntList(objs.length);
    for(int i = 0; i < objs.length; i++){startList.append(i);}
    
    Divide(pset, nodes, startList, t, BBoxes, maxDepth, new IntegerW());
    
    this.nodes = nodes.toArray(new Node[nodes.size()]);
    primSets = pset.toArray();
  }
  
  void Divide(IntList pset, ArrayList<Node> nodes, IntList contained, AABB selfBounds, AABB[] BBoxes, int depth, IntegerW overlapable){
    //AABB selfBounds = getBounds(contained, BBoxes);
    if(0 == depth || contained.size() < threshold){ // can't make internal node so make leaf
      makeLeafNode(pset, nodes, contained, overlapable);
      return;
    }
    // try making an internal node
    
    int n = contained.size();
    //AABB selfBounds = getBounds(contained, BBoxes);
    int splitDir = getSplitDirection(selfBounds);
    PVector sdV = null;
    int chosenLocation = -1;
    int tries = 0;
    float splitPos = 0;
    Edge[] Es = new Edge[n * 2];
    
    PVector S = PVector.sub(selfBounds.BR, selfBounds.TL); // size of bounding box
    float totalSA = 2 * (S.x * S.y + S.x * S.z + S.y * S.z);
    //float InvTotalSA = 1 / totalSA;
    float oldCost = intersectCost * n * totalSA / intersectCost;
    float traC = traverseCost * totalSA / intersectCost / 2;
    
    do {
      sdV = getSplitVector(splitDir);
      
      for(int i = 0; i < n; i++){
        int p = contained.get(i);
        Es[i<<1] = new Edge(BBoxes[p].TL.dot(sdV), false, p);
        Es[1 + (i<<1)] = new Edge(BBoxes[p].BR.dot(sdV), true, p);
      }
      Arrays.sort(Es);
      int above = n;
      int split = 0;
      int below = 0;
      
      float min = sdV.dot(selfBounds.TL);
      float max = sdV.dot(selfBounds.BR);
      float bestC = MAX_FLOAT;

      float oA0Size = S.dot(Sdirs[(splitDir + 1) % 3]);
      float oA1Size = S.dot(Sdirs[(splitDir + 2) % 3]);
      float CapArea = oA0Size * oA1Size;
      float eB = emptyBonus;
      
      for(int i = 0; i < Es.length; i++){
        if(Es[i].end){
          above--;
          split--;
          eB = above == 0 ? emptyBonus : 0;
        }
        
        if(min < Es[i].pos && Es[i].pos < max && split < n){
          float belowP = CapArea + (Es[i].pos - min) * (oA0Size + oA1Size);
          float aboveP = CapArea + (max - Es[i].pos) * (oA0Size + oA1Size);
          //float eB = (above == 0 || below == 0) ? emptyBonus : 0;

          float cost = traC + (1 - eB) * (belowP * below + aboveP * above);
          if(cost < bestC && cost < oldCost){
            splitPos = Es[i].pos;
            bestC = cost;
            chosenLocation = i;
          }
        }
        
        if(!Es[i].end){
          below++;
          split++;
          eB = 0;
        }
      }

      if(0 <= chosenLocation){
        break;
      }
      splitDir = (++splitDir % 3);
    }while(++tries < 3);
    if(tries == 3){ // failed to make internal node, make leaf node instead
      makeLeafNode(pset, nodes, contained, overlapable);
      return;
    }
    
    IntList low = new IntList();
    for(int i = 0; i < chosenLocation; i++){
      if(!Es[i].end){
        low.append(Es[i].prim);
      }
    }
    IntList high = new IntList();
    for(int i = chosenLocation + 1; i < n * 2; i++){
      if(Es[i].end){
        high.append(Es[i].prim);
      }
    }
    Internal nd = new Internal(splitPos, splitDir);
    nodes.add(nd);
    
    AABB lowBox = selfBounds.copy();
    lowBox.BR.add(PVector.mult(sdV, splitPos - lowBox.BR.dot(sdV))); // sets br to splitpos in the direciton of the split
    AABB highBox = selfBounds.copy();
    highBox.TL.add(PVector.mult(sdV, splitPos - highBox.TL.dot(sdV))); // sets tl to splitpos in the direciton of the split
    
    // spawn thread if this split is fairly high in the tree, the sides are roughly balanced (so build time is roughly equivilent), and num threads < 8
    if(maxDepth / 2 <= depth && high.size() / (float)(low.size() + high.size()) > 0.4 && numThreads.get() < 8){
      numThreads.getAndIncrement();
      
      DivideThread dThread = new DivideThread(high, highBox, BBoxes, depth - 1);
      dThread.start();
      // divide low
      Divide(pset, nodes, low, lowBox, BBoxes, depth - 1, overlapable);
      nd.setHighChild(nodes.size()); // set to size and not size-1 because the NEXT node to be added will be the high child
      // divide high
      try{
        dThread.join();
      }catch (Exception e){
        e.printStackTrace();
      }
      
      dThread.Merge(pset, nodes);
    }else{
      // divide low
      Divide(pset, nodes, low, lowBox, BBoxes, depth - 1, overlapable);
      nd.setHighChild(nodes.size()); // set to size and not size-1 because the NEXT node to be added will be the high child
      // divide high
      Divide(pset, nodes, high, highBox, BBoxes, depth - 1, overlapable);
    }
    //516255 ; primSetSize: 988860
  }
  
  class DivideThread extends Thread {
    IntList subPset, contained;
    ArrayList<Node> subNodes;
    AABB selfBounds;
    AABB[] BBoxes;
    int depth;
    
    DivideThread(IntList contained, AABB selfBounds, AABB[] BBoxes, int depth){
      subPset = new IntList();
      subNodes = new ArrayList<Node>();
      this.contained = contained;
      this.selfBounds = selfBounds;
      this.BBoxes = BBoxes;
      this.depth = depth;
    }
    
    public void run(){
      Divide(subPset, subNodes, contained, selfBounds, BBoxes, depth, new IntegerW());
      numThreads.getAndDecrement();
    }
    
    void Merge(IntList pset, ArrayList<Node> nodes){
      int Noffset = nodes.size();
      int Poffset = pset.size();
      for(Node N : subNodes){
        if(N.isLeaf()){
          Leaf L = (Leaf)N;
          if(1 < L.getNumPrims()){
            L.offset += Poffset;
          }
        }else{
          ((Internal)N).setHighChild(((Internal)N).highChild() + Noffset);
        }
      }
      pset.append(subPset);
      nodes.addAll(subNodes);
    }
  }
  
  void makeLeafNode(IntList pset, ArrayList<Node> nodes, IntList contained, IntegerW overlapable){ // it is fine to change contained as it is specific to this node
    if(contained.size() == 0){
      nodes.add(new Leaf(0, 0));
    }else if(contained.size() == 1){
      nodes.add(new Leaf(contained.get(0), 1));
    }else{
      /*int cl = contained.size();
      int offset = 0;
      for(int i = pset.size() - 1; i >= 0; i--){
        if(contained.removeValue(pset.get(i)) == -1){
          break;
        }
        offset++;
      }*/
      IntList psE = pset.getSubset(pset.size() - overlapable.get());
      psE.sort();
      contained.sort();
      IntList overlap = new IntList();
      IntList left = new IntList();
      IntList right = new IntList();
      int I = 0;
      int J = 0;
      while(I != psE.size() && J != contained.size()){
        if(psE.get(I) == contained.get(J)){
          overlap.append(psE.get(I));
          I++;
          J++;
        }else if(psE.get(I) < contained.get(J)){
          left.append(psE.get(I++));
        }else{
          right.append(contained.get(J++));
        }
      }
      if(I != psE.size()){
        for(;I < psE.size(); I++){left.append(psE.get(I));}
      }else if(J != contained.size()){
        for(;J < contained.size(); J++){right.append(contained.get(J));}
      }
      
      int rpos = pset.size() - overlapable.get();
      for(int i = overlapable.get() - 1; i >= 0; i--){
        pset.remove(rpos);
      }
      pset.append(left);
      nodes.add(new Leaf(pset.size(), contained.size()));
      pset.append(overlap);
      pset.append(right);
      overlapable.set(right.size());
      //nodes.add(new Leaf(pset.size(), contained.size()));
      //pset.append(contained);
    }
  }
  
  int getSplitDirection(AABB aabb){
    PVector sz = PVector.sub(aabb.BR, aabb.TL);
    if(sz.x > sz.y && sz.x > sz.z){ // x is biggest
      return 0;
    }else if(sz.y > sz.z){ // y is biggest
      return 1;
    }
    return 2; // z is biggest
  }
  
  PVector getSplitVector(int sd){
    return Sdirs[sd].copy();
  }
  
  boolean Trace(Ray r, Hit h){
    PVector inv_dir = new PVector((r.dir.x == 0) ? MAX_FLOAT : 1 / r.dir.x, (r.dir.y == 0) ? MAX_FLOAT : 1 / r.dir.y, (r.dir.z == 0) ? MAX_FLOAT : 1 / r.dir.z);
    
    float near = MAX_FLOAT;
    float far = 0;
    PVector[] Bds = {multEle(PVector.sub(TL, r.pos), inv_dir), multEle(PVector.sub(BR, r.pos), inv_dir)};
    
    float t = 0;
    for(int i = 0; i < 2; i++){
      if(TL.y <= (t = Bds[i].x * r.dir.y + r.pos.y) && t <= BR.y &&
         TL.z <= (t = Bds[i].x * r.dir.z + r.pos.z) && t <= BR.z){near = min(near, Bds[i].x); far = max(far, Bds[i].x);}
      if(TL.x <= (t = Bds[i].y * r.dir.x + r.pos.x) && t <= BR.x &&
         TL.z <= (t = Bds[i].y * r.dir.z + r.pos.z) && t <= BR.z){near = min(near, Bds[i].y); far = max(far, Bds[i].y);}
      if(TL.x <= (t = Bds[i].z * r.dir.x + r.pos.x) && t <= BR.x &&
         TL.y <= (t = Bds[i].z * r.dir.y + r.pos.y) && t <= BR.y){near = min(near, Bds[i].z); far = max(far, Bds[i].z);}
    }
    
    if(near < 0 || (TL.x <= r.pos.x && r.pos.x <= BR.x && TL.y <= r.pos.y && r.pos.y <= BR.y && TL.z <= r.pos.z && r.pos.z <= BR.z)){ // point is inside tree
      near = 0;
    }
    far = min(h.dist, far);
    
    if(near == MAX_FLOAT){return false;}
    
    ToDo[] stack = new ToDo[maxDepth + 1];
    int stackPos = 1;
    stack[0] = new ToDo(near, far, 0);
    boolean out = false;
    while(stackPos > 0){
      ToDo cur = stack[--stackPos];
      
      if(far <= cur.tmin){continue;} // near side of node is further than current far clip plane, so cull node
      if(nodes[cur.node].isLeaf()){ // reached leaf node, check intersection will contents and then continue
        if( ((Leaf)nodes[cur.node]).Trace(r, h) ){
          out = true;
          far = min(far, h.dist); // adjust far plane if hit dist decreases
        }
        continue;
      }
      
      Internal N = (Internal)nodes[cur.node];
      PVector sdV = getSplitVector(N.getSplitDir());
      float rd = r.dir.dot(sdV);
      if(rd == 0){ // ray is parallel to split axis
        stack[stackPos++] = new ToDo(cur.tmin, cur.tmax, 
              N.splitPos < r.pos.dot(sdV) ? N.highChild() : (cur.node + 1)); // pick which node to add to stack
        continue;
      }
      
      float tsplit = (N.splitPos - r.pos.dot(sdV)) * inv_dir.dot(sdV);
      int closeN = 0 < rd ? (cur.node + 1) :  N.highChild();
      int farN   = 0 < rd ?  N.highChild() : (cur.node + 1);
      
      //println(cur.tmin, tsplit, cur.tmax);
      if(cur.tmin <= tsplit && tsplit <= cur.tmax){ // ray passes through both sections
        // recurse with close section taking tmin and far section taking tmax
        stack[stackPos++] = new ToDo(tsplit, cur.tmax, farN); // add far to the stack first so it gets processsed later
        stack[stackPos++] = new ToDo(cur.tmin, tsplit, closeN);
      }else if(cur.tmax < tsplit){ // ray only intersects the close section
        stack[stackPos++] = new ToDo(cur.tmin, cur.tmax, closeN);
      }else if(tsplit < cur.tmin){ // ray only intersects the far section
        stack[stackPos++] = new ToDo(cur.tmin, cur.tmax, farN);
      }
    }
    return out;
  }
  
  private class ToDo {
    float tmin, tmax;
    int node;
    ToDo(float tmin, float tmax, int node){
      this.tmin = tmin;
      this.tmax = tmax;
      this.node = node;
    }
  }
  
  private class IntegerW {
    int v;
    IntegerW(int v){this.v = v;}
    IntegerW(){v = 0;}
    void set(int v){this.v = v;}
    int get(){return v;}
  }
  
  private class Node {
    int dataFlags;
    boolean isLeaf(){
      return (dataFlags & 3) == 3;
    }
  }
  
  private class Internal extends Node{
    float splitPos;
    Internal(float splitPos, int splitDir){
      this.splitPos = splitPos;
      dataFlags = splitDir;
    }
    
    int getSplitDir(){
      return dataFlags & 3;
    }

    int highChild(){
      return dataFlags >> 2;
    }
    
    void setHighChild(int pos){
      dataFlags = (dataFlags & 3) | (pos << 2);
    }
  }
  
  private class Leaf extends Node{
    int offset;
    Leaf(int offset, int numPrims){
      this.offset = offset;
      dataFlags = (numPrims << 2) | 3;
    }
    
    int getNumPrims(){
      return dataFlags >> 2;
    }
    
    boolean Trace(Ray r, Hit h){
      int n = getNumPrims();
      if(n == 0){return false;}
      if(n == 1){
        return objs[offset].Trace(r, h);
      }
      
      boolean out = false;

      for(int i = offset + n - 1; i >= offset; i--){
        out |= objs[primSets[i]].Trace(r, h);
      }
      return out;
    }
  }
  
  private class Edge implements Comparable<Edge> {
    boolean end;
    float pos;
    int prim;
    public int compareTo(Edge that){
      float r = that.pos - pos;
      if(r < 0){ // that.pos < this.pos
        return 1;
      }else if(0 < r){ // this.pos < that.pos
        return -1;
      }else if(end != that.end){ // this.pos == that.pos
        return (end && !that.end) ? -1 : 1; // object that that is an end is ordered first
      }else if(prim != that.prim){
        return (prim < that.prim) ? -1 : 1; // return object with the smaller index
      }
      return 0;
    }
    
    Edge(float pos, boolean end, int prim){
      this.pos = pos;
      this.end = end;
      this.prim = prim;
    }
  }
  
  private class AABB {
    PVector TL, BR;
    AABB(PVector TL, PVector BR){
      this.TL = TL;
      this.BR = BR;
    }
    
    AABB(){
      TL = new PVector();
      BR = new PVector();
    }
    
    void grow(AABB aabb){
      TL.x = min(TL.x, aabb.TL.x); BR.x = max(BR.x, aabb.BR.x);
      TL.y = min(TL.y, aabb.TL.y); BR.y = max(BR.y, aabb.BR.y);
      TL.z = min(TL.z, aabb.TL.z); BR.z = max(BR.z, aabb.BR.z);
    }
    
    AABB copy(){
      return new AABB(TL.copy(), BR.copy());
    }
  }
}

interface Primitive {
  void getBoundingBox(PVector TL, PVector BR);
  boolean Trace(Ray r, Hit h);
}
