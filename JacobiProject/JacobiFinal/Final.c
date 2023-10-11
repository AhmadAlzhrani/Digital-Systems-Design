#define _CRT_SECURE_NO_DEPRECATE
#include<stdio.h>
#include <stdlib.h>
#include<conio.h>
#include<math.h>
#include <stdbool.h>
#include <string.h>

#define SCALE (16)
#define HALF_SCALE (8)
#define FLOAT_TO_FIXED(f) (((int)((f)*(1<<SCALE))))
#define FIXED_TO_FLOAT(f) (((float)(f))/(1<<SCALE))
#define FIXED_DIVIDE(n, d)  (((long long)(n) << SCALE  )/(d) )
#define FIXED_MULT(a, b) ( ((a)>>HALF_SCALE) * ((b)>>HALF_SCALE) )
#define FileName "input1.txt"
#define FileName2 "output.txt"

bool diagonal(int matrix [], int size)
{
   int stop = size*size;
   for (int i=0; i<stop; i= i+size){

      int value = 0;
      int sum = 0;

      for(int j=0; j<size; j++){

         sum= sum + matrix[i+j];

      }
      if(matrix[value] < sum-matrix[value]){
         return false;
      }
      value = value + size + 1 ;
   }
   return true;
}

bool value1(int values [], int res [], int size, int TH)
{  
   int fin[200];
   for(int i=0; i<size ; i++){
      int sum=0;
      for(int j=0;j<size;j++){
         sum = sum + FIXED_MULT( values[j+size*i] , res[j] );
      }
      sum = sum - FIXED_MULT( values[size*i+i],res[i] );
      printf("sum= %f \n",FIXED_TO_FLOAT( sum ));
      
      printf("up= %f \n",FIXED_TO_FLOAT( values[size*size +i] - sum ));
      printf("div = %f \n ", FIXED_TO_FLOAT( values[size*i+i] ));
      int result = FIXED_DIVIDE( ( values[size*size +i] - sum ) , values[size*i+i] );
      printf("res= %f \n",FIXED_TO_FLOAT( result ));
      fin[i]=result;
   }
   for(int s=0;s<size;s++){
      if(abs( abs(fin[s]) - abs(res[s]) ) <= TH ){
         return false;
      }
   }
   for(int s=0;s<size;s++){
    res[s] = fin[s];
   }
   return true;
}

void main()
{

    // *READING THE FILE* 
    int count = 0;
    int iterations = 0;
    float thresh = 0;
    float NBmatrix[4200]; // This is matrix A and b,
    FILE* file = fopen(FileName, "r");
    if (file == NULL)
        printf("Error opening input file\n");
    else {

        //int count = 0; 
        fscanf(file, "%i", &count); // Debuggin 
        printf("Count is: %i\n", count); // Debugging 
        fscanf(file, "%i", &iterations); // Debugging 
        printf("iterations is: %i\n", iterations); // Debugging 
        fscanf(file, "%f", &thresh); // Debugging 
        printf("thresh is: %f\n", thresh); // Debugging 

        //float NBmatrix[4200]; // This is matrix A and b, 
        
        // the minimum size allowed for the 
        // user to enter is 2, and the maximum is 200. This will yield
        // 4000 element in total in addtion to 200 for matrix b, which will 
        // come after the the elements of a. Total size -> 4000 + 200 = 4200 
        
        // The following code will read matrix A inputs. 
        for (int j = 0; j < ((count*count)+count); j++) {
            {
                fscanf(file, "%f", &NBmatrix[j]);
            }
        }
        
        // The following code is just for testing and debugging
        for (int j = 0; j < (count * count); j++) {
            {
                printf("Element of A: %.5f\n", NBmatrix[j]); // Printing the elements of A
            }
        }
        // The following code is just for testing and debugging
        for (int j = (count*count); j < ((count * count)+count); j++) {
            {
                printf("Element of b: %.5f\n", NBmatrix[j]); // Printing the elements of b
            }
        }
        int fclose(FILE * file);


    
        // *STARTING THE ALGORITHM*
        int result[200];
        for(int i =0 ; i<count;i++){
            result[i]=0;
        }
        int threshFixed = FLOAT_TO_FIXED(thresh);
        int NBmatrixFixed[4200];
        for(int i = 0; i< (count*count +count); i++){
            NBmatrixFixed[i] = FLOAT_TO_FIXED(NBmatrix[i]);
        }

        if(!diagonal(NBmatrixFixed,count)){
            printf("The matrix is not diagonally dominant");
            count=0;
            goto output;
        }

        for(int i=0; i<iterations ; i++){

            bool hold = value1(NBmatrixFixed,result,count,threshFixed);
            printf("Results = ");
            for(int j=0;j<count;j++){
                printf(" %f , ",FIXED_TO_FLOAT(result[j]));
            }
            printf("\n");
            if(!hold){
                printf("threshold at itration %d \n",i);
                break;
            }
        }
        //getch();

        output:
        // *PREPARE THE VERILOG INPUT FILE*
        FILE* file = fopen(FileName2, "w");
        fprintf(file, "%i\n", SCALE);// In decimal 
        fprintf(file, "%X\n", count); // In Hexa
        fprintf(file, "%X\n", iterations); // In Hexa
        fprintf(file, "%X\n", threshFixed); // In Hexa  


        for (int j = 0; j < ((count*count)+count); j++) {
            fprintf(file, "%X\n", NBmatrixFixed[j]);
            // The above code will print the elements in A in Hexa form in the file
            // to be used as an input file by Verilog 
        }
        // to be used as an input file by Verilog 
        //}
        int fclose(FILE * file);
    }
}