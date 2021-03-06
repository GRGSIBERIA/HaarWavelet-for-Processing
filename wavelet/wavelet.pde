import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

class Wavelet {
  float weight, difference;
  
  Wavelet(Wavelet a, Wavelet b) {
    difference = a.weight - b.weight;
    weight = (a.weight + b.weight) * 0.5;
  }
  
  Wavelet(float initWeight) {
    weight = initWeight;
    difference = 0;
  }
}

class Scale {
  Wavelet[] wavelets;
  int scaleNumber;
  int size;
  
  Scale(Scale prevScale) {
    size = prevScale.size >> 1;
    scaleNumber = prevScale.scaleNumber + 1;
    wavelets = new Wavelet[size];
    
    for (int i = 0; i < size; i++) {
      Wavelet a = prevScale.wavelets[i*2];
      Wavelet b = prevScale.wavelets[i*2+1];
      wavelets[i] = new Wavelet(a, b);
    }
  }
  
  void InitZeroScale(int bufferSize) {
    size = bufferSize;
    scaleNumber = 0;
    wavelets = new Wavelet[size];
  }
  
  Scale(float[] soundBuffer, int powerOfTwo) {
    InitZeroScale(soundBuffer.length);
    
    if (powerOfTwo != 0) {
      for (int i = 0; i < size; i++) {
        soundBuffer[i] = abs(soundBuffer[i]);
      }
    }
    
    for (int i = 0; i < size; i++) {
      wavelets[i] = new Wavelet(soundBuffer[i]);
    }
  }
  
  float Average() {
    float sum = 0;
    for (int i = 0; i < size; i++) {
      sum += wavelets[i].weight;
    }
    return sum / size;
  }
}

class HaarWavelet {
  Scale[] scales;
  int numberOfScales;
  
  int log2Size(int size) {
    return (int)(log(size) / log(2));
  }
  
  int InitVariables(float[] soundBuffer) {
    int size = log2Size(soundBuffer.length); 
    scales = new Scale[size];
    numberOfScales = 0;
    return size;
  }
  
  void InitScales(int size) {
    for (int i = 1; i < size; i++) {
      scales[i] = new Scale(scales[i-1]);
      numberOfScales++;
      if (scales[i].size >> 1 <= 1) {
        break;
      }
    }
  }
  
  void InitHaarWavelet(float[] soundBuffer, int powerOfTwo) {
    int size = InitVariables(soundBuffer);
    scales[0] = new Scale(soundBuffer, powerOfTwo);
    InitScales(size);
  }
  
  HaarWavelet(float[] soundBuffer, int powerOfTwo) {
    InitHaarWavelet(soundBuffer, powerOfTwo);
  }
  
  HaarWavelet(float[] soundBuffer) {
    InitHaarWavelet(soundBuffer, 0);
  }
}

Minim minim;
AudioInput audioInput;

void setup() {
  size(512, 512);
  frameRate(120);
  
  minim = new Minim(this);
  audioInput = minim.getLineIn(Minim.STEREO, 32768);
}

void DrawScale(Scale scale, int numberOfScales) {
  float hdiff = (height / numberOfScales);
  float wdiff = width / scale.size;
  colorMode(HSB, 255);
  for (int i = 0; i < scale.size; i++) {
     float w1 = wdiff * i;
     float w2 = wdiff * (i + 1);
     float h2 = hdiff * scale.scaleNumber + scale.wavelets[i].weight * hdiff;
     float h1 = hdiff * scale.scaleNumber;
     stroke(scale.wavelets[i].weight * 255 * 2, 255, 255);
     line(w1, h1, w2, h2);
  }
}

int clapCount = 0;
int clap = 0;
void ClapHands(HaarWavelet haar) {
  float avg = haar.scales[4].Average();
  if (avg > 0.05) {
    if (clap == 0) {
      clap = 1;
      clapCount++;
      println(clapCount);
    }
  }
  else {
    clap = 0;
  }
}

void draw() {
  float[] audioBuffer = audioInput.mix.toArray();
  HaarWavelet haar = new HaarWavelet(audioBuffer, 1);
  
  background(0);
  for (int i = 0; i < haar.numberOfScales; i++) {
    DrawScale(haar.scales[i], haar.numberOfScales);
  }
  
  ClapHands(haar);
}

void stop() {
  audioInput.close();
  minim.stop();
  super.stop();
}
