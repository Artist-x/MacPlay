#include "macplay_scroll.h"
#include <cassert>
#include <cmath>
int main(){
 MPScrollGesture g;
 assert(!g.begin(-0.1,0.5)&&!g.active);
 assert(g.begin(0.5,0.5));g.move(0.1,-0.2);assert(std::abs(g.x-0.6)<1e-8&&std::abs(g.y-0.3)<1e-8);
 g.move(4,-4);assert(g.x==1&&g.y==0);g.end();assert(!g.active);
 g.move(-1,1);assert(g.x==1&&g.y==0);
 assert(g.begin(0.25,0.75));assert(g.x==0.25&&g.y==0.75);
 assert(g.begin(0.5,0.5));g.scroll(0,20,200,100);assert(std::abs(g.y-0.7)<1e-8);
 g.scroll(0,-30,200,100);assert(std::abs(g.y-0.4)<1e-8);
}
