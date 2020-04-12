#include <stdio.h>
#include <stdlib.h>

int main() {
    int seed;
    scanf("%d", &seed);
    srand(seed);

    int x;
    do {
        x = rand()%24;
    } while(x < 9);
    printf("%d\n", x);
}
