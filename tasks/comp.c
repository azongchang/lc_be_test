#include <stdio.h>

int main() {
	int a[1024] = {0};
	int i = 0;
	while (1) {
		i = 0;
		for (; i < 1024; i++) {
			a[i]++;
		}
	}
	return 0;
}
