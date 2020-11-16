#include <stdio.h>
#include "../../../libs/checker.h"

int main() {
    int x;
    scanf("%d", &x);
    
    if(x >= 9 and x <= 23) printf("easy,");
    if(x < 9) printf("hard,");
    if(x < 0 or x > 23) printf("wrong,");

    is_eof();
}
