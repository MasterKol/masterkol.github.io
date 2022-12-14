Color getColor(Ray r, int depth, float power, boolean verbose, boolean isPreRes){
  //Color out = new Color(0, 0, 0);
  if(depth == 0){
    return new Color(0);
  }
  
  if(power < 0.0002){
    return new Color(0);
  }
  
  Hit h = new Hit();
  
  Color outputColor = null;
  
  raysThisFrame++;
  if(tracePath(r, h)){
    /*if(depth != -1){
      if(verbose){println(h.normal);}
      return new Color((h.normal.x + 1) / 2, (h.normal.y + 1) / 2, (h.normal.z + 1) / 2);
    }*/
    Material m = h.object.getMaterial();
    PVector hpos = PVector.mult(r.dir, h.dist).add(r.pos);
    
    if(m.getType() == 0){  // ====================================== Emissive ======================================
      Emissive e = (Emissive)m;
      outputColor = new Color(e.c).mult(e.strength);
    }else if(m.getType() == 1 || m.getType() == 5){  // ====================================== Diffuse ======================================
      Diffuse d = (Diffuse)m;
      
      if(power < 0.005/*0.1 / (float)samples*/){
        return new Color(0);//d.albedo.copy();
      }
      
      if(h.normal.dot(r.dir) > 0){
        h.normal.mult(-1);
        h.shadedNormal.mult(-1);
      }
      Color colAlbedo = d.getAlbedo(h.uv);
      if(isPreRes){ // && !verbose
        return colAlbedo.mult(min(max(h.shadedNormal.dot(preResLightDir), 0) * 0.5 + 0.5, 1));
      }
      
      if(depth <= 1){
        return new Color(0);//d.albedo.copy();
      }
      PVector Chpos = PVector.mult(h.normal, 0.0001).add(hpos);
      
      Color inderLight = new Color(0);
      PVector X = orthVector(h.shadedNormal).normalize();
      PVector Y = h.normal.cross(X);
      float theta, cp/* = random(0, 1)*/, sp;//, t = random(0, 1);
      
      int bounceSamples = constrain((int)(power * power * samples), 1, samples);
      
      float powerFactor = colAlbedo.maxValue() * 2 * power / (float)bounceSamples;
      float sx = random(0, 1), sy = random(0, 1);
      //int sig = floor(random(0, samples));
      /*float b = sx;
      for(int i = 0; i < samples; i++){
        if((sx + goldenConj * i) % 1 < b){
          sig = i;
          b = (sx + goldenConj * i) % 1;
        }
      }*/
      if(verbose){
        //return new Color(0);
        //println(samples);
        //println("X");
      }
      
      for(int i = 0; i < bounceSamples; i++){
        theta = TAU * ((sx + (float)i * plasticConj) % 1);//((sx + goldenConj * i) % 1) * TAU;
        cp = ((sy + 2 * (float)i * plasticConj * plasticConj) % 1);//(sy + goldenConj * sig) % 1;
        //theta = random(0, TAU);
        //cp = random(0, 1);
        sp = sqrt(1 - cp * cp);
        //println(theta + ", " + cp);
        
        PVector dir = PVector.mult(X, cos(theta) * sp).add(PVector.mult(Y, sin(theta) * sp)).add(PVector.mult(h.shadedNormal, cp));
        //println("dir", dir, dir.dot(h.normal));
        
        //if(verbose){println(dir.dot(h.normal), cp, sp, (cp * cp + sp * sp));}
        //if(!preRes){
        inderLight.add(getColor(new Ray(Chpos, dir), depth - 1, cp * powerFactor, false, isPreRes).mult(cp));
        //}
        /*if(sig <= fibB){
          sig += fibA;
          if(sig > samples){sig -= fibB;}
        }else{
          sig -= fibB;
        }*/
      }
      
      inderLight.div(bounceSamples);
      
      //if(verbose){println(d.albedo);}
      
      if(verbose){
        //println(inderLight);
        //println(inderLight.r, inderLight.g, inderLight.b);
        //println(d.albedo.r, d.albedo.g, d.albedo.b);
        //println(h.pos);
        //println(h.normal);
      }
      
      //inderLight.div(samples);
      outputColor = dot(inderLight, colAlbedo).mult(2);
    }else if(m.getType() == 2){ // ====================================== Glossy ======================================
      Glossy g = (Glossy)m;
      
      if(h.normal.dot(r.dir) > 0){
        h.normal.mult(-1);
      }
      
      PVector reflDir = PVector.mult(h.normal, -2 * h.normal.dot(r.dir) * -Sign(h.normal.dot(r.dir))).add(r.dir).normalize();
      PVector Chpos = PVector.mult(h.normal, 0.0001).add(hpos);
      
      if(isPreRes){
        Color ReflCol = getColor(new Ray(Chpos, reflDir), depth-1, power * g.albedo.maxValue(), false, isPreRes);
        return dot(ReflCol, g.albedo);
      }
      
      Color ReflCol = new Color(0);
      
      PVector dir;
      
      for(int i = 0; i < samples; i++){
        dir = PVector.random3D().mult(g.roughness).add(reflDir);
        if(h.normal.dot(dir) < 0){
          dir.sub(PVector.mult(h.normal, 2 * h.normal.dot(dir)));
        }
        
        dir.normalize();
        
        ReflCol.add(getColor(new Ray(Chpos, dir), depth-1, power * g.albedo.maxValue() / samples, false, isPreRes));
      }
      
      ReflCol.div(samples);
      
      outputColor = dot(ReflCol, g.albedo);
    }else if(m.getType() == 3){  // ====================================== Transparent ======================================
      Transparent t = (Transparent)m;
      //float nS = 2; // scale
      //float nA = 0.4; // amplitude
      //PVector nPos = PVector.div(h.pos, nS); // noisePosition
      //PVector nV = new PVector(noise(nPos.x + 100, nPos.y + 100) * nA * 2 - nA, noise(nPos.x + 10000, nPos.y + 100) * nA * 2 - nA, noise(nPos.x + 100, nPos.y + 10000) * nA * 2 - nA);
      //h.normal.add(nV).normalize();
      
      //float n1 = 1;
      //float n2 = t.ior;
      boolean inside = false;
      float iorR = 1 / t.ior;
      
      if(h.normal.dot(r.dir) > 0){ // object normals should always be facing outwards, this way internal collisions can be detected by this method
        //float n3 = n1;
        //n1 = n2;
        //n2 = n3;
        iorR = 1 / iorR;
        h.normal.mult(-1);
        inside = true;
      }
      
      PVector reflDir = PVector.mult(h.normal, -2 * h.normal.dot(r.dir) * -Sign(h.normal.dot(r.dir))).add(r.dir).normalize();
      //reflDir.add(PVector.random3D().mult(0.5)).normalize();
            
      PVector Chpos = PVector.mult(h.normal, -0.0001).add(hpos);
      
      //float iorR = n1 / n2;
      
      /*float ndi = -h.normal.dot(r.dir);
      float v = 1 - iorR * iorR * (1 - ndi * ndi);
      if(v < 0){ // total interal reflection
        return getColor(new Ray(Chpos, reflDir), depth-1, power, false, isPreRes);
      }
      v = sqrt(v);*/
      //PVector tv = PVector.mult(h.normal, -v + iorR * ndi).add(PVector.mult(r.dir, iorR)).normalize();
      
      float ndi = h.normal.dot(r.dir);
      PVector nxd = h.normal.cross(r.dir);
      float v = 1 - iorR * iorR * nxd.dot(nxd);
      if(v < 0){ // total internal reflection, only draw reflected ray
        //if(verbose){println(depth, r.pos, r.dir, h.normal, reflDir);}
        //if(verbose){println("totally interally reflected");}
        //return new Color(0);
        return getColor(new Ray(PVector.mult(h.normal, 0.0001).add(hpos), reflDir), depth-1, power, verbose, isPreRes);
        //return new Color(0, 1, 0);
      }
      //v = sqrt(v);
      PVector tv = h.normal.cross(nxd).mult(-iorR).sub(PVector.mult(h.normal, sqrt(v))).normalize();
      
      if(verbose){
        /*println("-------------");
        println(depth);
        println(h.pos);
        println(h.normal, r.dir);
        float ang = acos(-h.normal.dot(r.dir));
        println("a", ang * 180 / PI);
        println("b", acos(-h.normal.dot(tv)) * 180 / PI);
        println("c", asin(sin(ang) * iorR) * 180 / PI);
        println("stp", h.normal.cross(tv).dot(r.dir));
        println(iorR);
        println(v);
        println(ndi);
        println(tv);*/
      }
      
      float transmissionStrength = 1; // strength of transmission after some light is absorbed
      if(inside && t.absorbanceStrength > 0){
        transmissionStrength = 1 / pow(10, t.absorbanceStrength * h.dist);
      }
      
      if(verbose){
        /*println("===============");
        println(depth);
        println(inside);
        println(h.dist);
        println(transmissionStrength);*/
      }
      
      if(isPreRes){
        Color transColor = getColor(new Ray(Chpos, tv), depth-1, power * transmissionStrength, verbose, isPreRes);
        //return .dot(t.absorbance);
        if(inside && t.absorbanceStrength > 0){
          return dot(transColor, t.absorbance).mult(transmissionStrength);
        }else{
          return transColor;
        }
      }
      
      float ct = abs(ndi);
      float c = sqrt(1 - iorR * iorR * (1 - ndi * ndi));
      
      //float Rs = (n1 * ct - n2 * c) / (n1 * ct + n2 * c);
      float Rs = (iorR * ct - c) / (iorR * ct + c);
      Rs = min(Rs * Rs, 1);
      float Rp = (iorR * c - ct) / (iorR * c + ct);
      Rp = min(Rp * Rp, 1);
      
      float R = 0.5 * Rs + 0.5 * Rp; // percentage of light made up of reflected rays
      
      if(verbose){println(depth, r.pos, r.dir, hpos, h.normal, reflDir, tv, R);}
      
      if(verbose){
        //println("R", R);
      }
      
      Color TransCol, ReflCol;
      
      //ReflCol = getColor(new Ray(Chpos, reflDir), depth-1, false);
      //TransCol = getColor(new Ray(Chpos, tv), depth-1, verbose);
      //R = 0;
      /*if(R < 0.01){
        ReflCol = new Color(0);
        R = 0;
      }else{
        ReflCol = getColor(new Ray(Chpos, reflDir), depth, power * R, false, isPreRes);
      }
      
      if(R > 0.99){
        R = 1;
        TransCol = new Color(0);
      }else{
        TransCol = getColor(new Ray(Chpos, tv), depth-1, power*(1-R), verbose, isPreRes);
      }*/
      ReflCol = getColor(new Ray(PVector.mult(h.normal, 0.0001).add(hpos), reflDir), depth-1, power * R, false, isPreRes);
      
      if(inside && t.roughness != 0){
        TransCol = new Color(0);
        
        float tp = power * (1-R) * transmissionStrength / 20;
        PVector dir;
        for(int i = 0; i < samples; i++){
          //if(random(0, 1) < t.roughness){
          dir = PVector.random3D().mult(t.roughness).add(tv);
          if(dir.dot(h.normal) > 0){
            dir.add(h.normal.copy().mult(2 * dir.dot(h.normal)));
          }
          //}else{
            
          //}
          
          TransCol.add(getColor(new Ray(Chpos, dir), depth-1, tp, verbose, isPreRes));
        }
        TransCol.div(samples);
      }else{
        TransCol = getColor(new Ray(Chpos, tv), depth-1, power * (1-R) * transmissionStrength, verbose, isPreRes);
      }
      
      if(inside && t.absorbanceStrength > 0){
        TransCol = dot(TransCol, t.absorbance).mult(transmissionStrength);
        //TransCol.sub(dot(TransCol, t.absorbance).mult(1 - transmissionStrength));
      }
      
      outputColor = lerpColor(TransCol, ReflCol, R);
    }else if(m.getType() == 4){  // ====================================== Metal ======================================
      Metal me = (Metal)m;
      
      if(h.normal.dot(r.dir) > 0){
        h.normal.mult(-1);
      }
      
      PVector reflDir = PVector.mult(h.normal, 2 * h.normal.dot(r.dir) * Sign(h.normal.dot(r.dir))).add(r.dir).normalize();
      
      Color ReflCol = getColor(new Ray(PVector.mult(h.normal, 0.001).add(hpos), reflDir), depth-1, power * me.col.maxValue(), false, isPreRes);
      outputColor = dot(ReflCol, me.col);
    }
  }
  
  if(outputColor == null){
    outputColor = skyColor.copy().mult(skyBrightness);
    h.dist = MAX_FLOAT;
  }else{
    //outputColor = lerpColor(new Color(0.5), outputColor, exp(-h.dist / 30.0));
  }
  
  /*if(depth == maxBounces && !isPreRes){
    PVector selPos = PVector.mult(r.dir, random(0, max(h.dist, 30))).add(r.pos);
    PVector dir = PVector.random3D();
    Ray sr = new Ray(selPos, dir);
    
    float spower = 1 - exp(-h.dist / 50);
    
    Color scatterColor = getColor(sr, depth - 4, power * spower, false, isPreRes).mult(spower);
    
    outputColor.add(scatterColor);
  }*/
  
  return outputColor;
}
