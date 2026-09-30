#pragma once
#include <algorithm>
struct MPScrollGesture {
 double x=0.5,y=0.5;bool active=false;
 static double clamp(double v){return std::clamp(v,0.0,1.0);}
 bool begin(double px,double py){if(px<0||px>1||py<0||py>1)return false;x=px;y=py;active=true;return true;}
 void move(double dx,double dy){if(active){x=clamp(x+dx);y=clamp(y+dy);}}
 void scroll(double dx,double dy,double width,double height){if(width>0&&height>0)move(dx/width,dy/height);}
 void end(){active=false;}
};
