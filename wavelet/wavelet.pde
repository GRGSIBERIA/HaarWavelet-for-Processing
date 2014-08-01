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
  minim = new Minim(this);
  audioInput = minim.getLineIn(Minim.STEREO, 512);
  
  size(512, 512);
}

void DrawScale(Scale scale, int numberOfScales) {
  float hdiff = (height / numberOfScales);
  float wdiff = width / scale.size;
  stroke(255);
  for (int i = 0; i < scale.size; i++) {
     float w = wdiff * i;
     float h = hdiff * scale.scaleNumber + scale.wavelets[i].weight * hdiff;
     point(w, h);
  }
}

void draw() {
  float[] audioBuffer = audioInput.mix.toArray();
  HaarWavelet haar = new HaarWavelet(audioBuffer, 1);
  
  background(0);
  for (int i = 0; i < haar.numberOfScales; i++) {
    DrawScale(haar.scales[i], haar.numberOfScales);
  }
}

void stop() {
  audioInput.close();
  minim.stop();
  super.stop();
}
