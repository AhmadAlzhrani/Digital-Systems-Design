#include <stdio.h>

int main() {
  int data[] = {100, 50, -10, 30, 70, 60};
  
  // find the array's length
  int size = sizeof(data) / sizeof(data[0]);

  for (int step = 0; step < size - 1; ++step) {
      
    // loop to compare array elements
    for (int i = 0; i < size - step - 1; ++i) {
      
      // compare two elements
      if (data[i] > data[i + 1]) {
        
        // swapping elements
        int temp = data[i];
        data[i] = data[i + 1];
        data[i + 1] = temp;
      }
    }
  }
  
  printf("Sorted Array in Ascending Order:\n");
  for (int i = 0; i < size; ++i) {
    printf("%d  ", data[i]);
  }
  printf("\n");
}