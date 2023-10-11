#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define SCALE (16)
#define HALF_SCALE (8)
#define FLOAT_TO_FIXED(f) (((int)((f)*(1<<SCALE))))
#define FIXED_TO_FLOAT(f) (((float)(f))/(1<<SCALE))
#define FIXED_DIVIDE(n, d)  ((int)( (((long long)n)*(1<<SCALE)) / (d) ))
#define FIXED_MULT(a, b) ( ((a)>>HALF_SCALE) * ((b)>>HALF_SCALE) )

// input/output routines
int read_input(char*);
int write_verilog_input(char*);
int write_x_golden(char*);
int write_x_human_readable(char*);

// fixed-point conversion
void convert_system_to_fixed_point();

// jacobi related routines
float row_abs_sum(int);
int fx_row_abs_sum(int);
int is_diagonally_dominant();
int fx_is_diagonally_dominant();
float solve_for(int);
int fx_solve_for(int);
float jacobi_iteration();
int fx_jacobi_iteration();
void initialize_x();
void fx_initialize_x();

// degbugging routines
void print_system();
void fx_print_system();
void verify_solution();
void fx_verify_solution();
int create_ml_code(char*);

int N, k, fx_th;
float th;

int fx_A[200][200];
int fx_b[200];
int fx_x[200];

float A[200][200];
float b[200];
float x[200];

int main(int argc, char*argv[])
{
  // verilog, golden, human-readable file names
  char vfn[50], gfn[50], hrfn[50], mlfn[50];

  if (argc<2) {
    printf("Usage: jacobi filename\n");
    return 0;
  }
  else {
    strcpy(vfn, argv[1]);
    strcpy(gfn, argv[1]);
    strcpy(hrfn, argv[1]);
    strcpy(mlfn, argv[1]);
    strcat(vfn, "-verilog-input");
    strcat(gfn, "-x-golden");
    strcat(hrfn, "-x-human-readable");
    strcat(mlfn, "-ml-code");

    //printf("processing file %s\n", argv[1]);
    if (read_input(argv[1])==0) {
      printf("Error reading input file %s\n", argv[1]);
      return 0;
    }
    //print_system();
    convert_system_to_fixed_point();
    //fx_print_system();
    if (!write_verilog_input(vfn)) {
      printf("Error writing Verilog file %s\n", vfn);
      return 0;
    } else {
      printf("Verilog file %s generated\n", vfn);
    }

    // check for diagnoal dominance
    if (is_diagonally_dominant()) {
      printf("A is diagonally dominant\n");

      initialize_x();
      fx_initialize_x();
      int mm = (1<<30)-1;
      int i;
      for (i=0; (i<k && mm>fx_th); i++) {
        jacobi_iteration();
        mm=fx_jacobi_iteration();
      }
      printf("*** Simulation Ended After %d Iterations ***\n", i);
      printf("***Solution Verification***\n");
      //verify_solution();
      //fx_verify_solution();
    } else {
      printf("A is **NOT** diagonally dominant\n");
      N=0; // to avoid printing any X
    }

    if (!write_x_human_readable(hrfn)) {
      printf("Error writing human-readable solution file %s\n", hrfn);
      return 0;
    } else {
      printf("Human-readable solution file %s generated\n", hrfn);
    }

    if (!write_x_golden(gfn)) {
      printf("Error writing golden solution file %s\n", gfn);
      return 0;
    } else {
      printf("Golden solution file %s generated\n", gfn);
    }

    if (!create_ml_code(mlfn)) {
      printf("Error writing matlab code file %s\n", mlfn);
      return 0;
    } else {
      printf("Matlab code file %s generated\n", mlfn);
    }




    }



  return 0;
}

float solve_for(int i)
{
  float sum=0.0;
  for (int j=0; j<N; j++) {
    if (i!=j)
      sum += A[i][j]*x[j];
  }
  return (b[i]-sum)/A[i][i];
}

int fx_solve_for(int i)
{
  int sum=0;
  for (int j=0; j<N; j++) {
    if (i!=j)
      sum += FIXED_MULT(fx_A[i][j], fx_x[j]);
  }
  return FIXED_DIVIDE(fx_b[i]-sum, fx_A[i][i]);
}


float jacobi_iteration()
{
  float nx[N];
  float mm = 0.0; // max. move

  for (int i=0; i<N; i++) {
    nx[i] = solve_for(i);
    if (mm<fabs(nx[i]-x[i]))
      mm = fabs(nx[i]-x[i]);
  }

  for (int i=0; i<N; i++)
    x[i] = nx[i];
  return mm;
}

int fx_jacobi_iteration()
{
  int nx[N];
  int mm=0; // max. move
  for (int i=0; i<N; i++) {
    nx[i] = fx_solve_for(i);
    if (mm<abs(nx[i]-fx_x[i]))
      mm = abs(nx[i]-fx_x[i]);
  }

  for (int i=0; i<N; i++)
    fx_x[i] = nx[i];

  return mm;
}


void initialize_x()
{
  for (int i=0; i<N; i++)
    x[i] = 0.0;
}

void fx_initialize_x()
{
  for (int i=0; i<N; i++)
    fx_x[i] = 0;
}

int read_input(char*fn)
{
  int buf_sz = 256;
  char buf[buf_sz];
  FILE* f = fopen(fn, "r");
  if (f==NULL) return 0;
  int state = 0, ri=0, ci=0;
  int exit_loop = 0;
  while (fgets(buf, buf_sz, f) && (exit_loop==0)) {
    if (buf[0]=='#')
      continue;
    else
      switch (state) {
        case 0:
          // reading N
          N=atoi(buf);
          if (N<2 || N>200) {
            printf("Invalid value of N (%d)\n", N);
            return 0;
          }
          state++;
          break;
        case 1:
          // reading k (number of iterations)
          k=atoi(buf);
          state++;
          break;
        case 2:
          // reading threshold
          th=atof(buf);
          state++;
          break;
        case 3:
          // reading matrix A
          A[ri][ci] = atof(buf);
          ci = (ci+1)%N;
          if (ci==0) {
            ri = (ri+1)%N;
            if (ri==0) state++;
          }
          break;
        case 4:
          // reading vector b
          b[ri] = atof(buf);
          ri = (ri+1)%N;
          if (ri==0) state++;
          break;
        default:
          exit_loop = 1;
      }
  }
  fclose(f);
  return 1;
}

int write_verilog_input(char* fn)
{
  FILE* f = fopen(fn, "w");
  if (f==NULL) return 0;
  fprintf(f, "%d\n", SCALE);
  fprintf(f, "%08x\n", N);
  fprintf(f, "%08x\n", k);
  fprintf(f, "%08x\n", fx_th);

  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      fprintf(f, "%08x\n", fx_A[i][j]);
    }
  }

  for (int i=0; i<N; i++) {
    fprintf(f, "%08x\n", fx_b[i]);
  }

  fclose(f);
  return 1;
}


void print_system()
{
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      printf("%f x%d", A[i][j], j);
      if (j<N-1)
        printf(" + ");
      else
        printf(" = %f\n", b[i]);
    }
  }
}

void fx_print_system()
{
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      printf("%08x x%d", fx_A[i][j], j);
      if (j<N-1)
        printf(" + ");
      else
        printf(" = %08x\n", fx_b[i]);
    }
  }
}

void convert_system_to_fixed_point()
{
  fx_th = FLOAT_TO_FIXED(th);
  for (int i=0; i<N; i++) {
    fx_b[i] = FLOAT_TO_FIXED(b[i]);
    for (int j=0; j<N; j++) {
      fx_A[i][j] = FLOAT_TO_FIXED(A[i][j]);
    }
  }
}

int write_x_golden(char* fn) {
  FILE* f = fopen(fn, "w");
  if (f==NULL) return 0;
  // fprintf(f, "%08x\n", N);
  fprintf(f, "%x\n", N);
  if (N>0) {
    for (int i=0; i<N; i++) {
      // fprintf(f, "%08x\n", fx_x[i]);
      fprintf(f, "%x\n", fx_x[i]);
    }
  }
  fclose(f);
  return 1;
}
int write_x_human_readable(char* fn) {
  FILE* f = fopen(fn, "w");
  if (f==NULL) return 0;
  fprintf(f, "%d\n", N);
  if (N>0) {
    for (int i=0; i<N; i++) {
      fprintf(f, "%f\n", FIXED_TO_FLOAT(fx_x[i]));
    }
  }
  fclose(f);
  return 1;
}

// row sum of abs values minus diagonal element
float row_abs_sum(int i)
{
  float sum = 0.0;
  for (int j=0; j<N; j++) {
    if (i!=j)
      sum += fabs(A[i][j]);
  }
  return sum;
}

int fx_row_abs_sum(int i)
{
  int sum = 0;
  for (int j=0; j<N; j++) {
    if (i!=j)
      sum += abs(fx_A[i][j]);
  }
  return sum;
}

int is_diagonally_dominant()
{
  for (int i=0; i<N; i++) {
    if (fabs(A[i][i])<row_abs_sum(i))
      return 0;
  }
  return 1;
}

int fx_is_diagonally_dominant()
{
  for (int i=0; i<N; i++) {
    if (abs(fx_A[i][i])<fx_row_abs_sum(i))
      return 0;
  }
  return 1;
}

void verify_solution()
{
  float dp[200];
  for (int i=0; i<N; i++) {
    dp[i]=0.0;
    for (int j=0; j<N; j++) {
      dp[i] += A[i][j]*x[j];
    }
  }
  printf("EQN#\tLHS\tRHS\tERR\n");
  for (int i=0; i<N; i++) {
    printf("%d\t%f\t%f\t%16f\n", i, dp[i], b[i], fabs(dp[i]-b[i]));
  }
}

void fx_verify_solution()
{
  int dp[200];
  for (int i=0; i<N; i++) {
    dp[i]=0;
    for (int j=0; j<N; j++) {
      dp[i] += FIXED_MULT(fx_A[i][j],fx_x[j]);
    }
  }
  printf("EQN#\tLHS\tRHS\tERR\n");
  for (int i=0; i<N; i++) {
    printf("%d\t%d\t%d\t%d (%20f)\n", i, dp[i], fx_b[i], abs(dp[i]-fx_b[i]), fabs(FIXED_TO_FLOAT(dp[i]-fx_b[i])));
  }
}

int create_ml_code(char* fn)
{
  FILE* f = fopen(fn, "w");
  if (f==NULL) return 0;

  fprintf(f, "A=[");
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      fprintf(f, "%f", A[i][j]);
      if (j==N-1) {
        if (i<N-1)
          fprintf(f, "; ");
      }
      else
        fprintf(f, ", ");
    }
  }
  fprintf(f, "];\nb=[");

  for (int i=0; i<N; i++) {
    fprintf(f, "%f", b[i]);
    if (i==N-1)
      fprintf(f, "];\n");
    else
      fprintf(f, "; ");
  }

  fprintf(f, "x_star=A\\b;\n");
  fprintf(f, "x=[");
  for (int i=0; i<N; i++) {
    fprintf(f, "%f", FIXED_TO_FLOAT(fx_x[i]));
    if (i==N-1)
      fprintf(f, "];\n");
    else
      fprintf(f, "; ");
  }

  fprintf(f, "abs(x-x_star)\n");

  fclose(f);
  return 1;

}
