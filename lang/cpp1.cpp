#include <iostream>
bool is_sorted(int *a, int n) {
  for (int i = 0; i < n - 1; i++)
    if (a[i] > a[i + 1])
      return false;
  return true;
}
int main() {
    int a[4]={1,3,2,4};
    int b[4]={1,2,3,4};
    if (!is_sorted(a,4)) {
        printf("a no\n");
    }
    if (is_sorted(b,4)) {
        printf("b yes\n");
    }
    return 0;
}
#if 0
#include <iostream>
int f3(int v) {
  v = v + 1;
  std::cout << v << std::endl;
  return v;
}
int main() {
  f3(12);
  f3(13);
}
#include <ctime>
#include <iostream>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <xmmintrin.h>

static struct termios old, current;

/* Initialize new terminal i/o settings */
void initTermios(int echo) 
{
  tcgetattr(0, &old); /* grab old terminal i/o settings */
  current = old; /* make new settings same as old settings */
  current.c_lflag &= ~ICANON; /* disable buffered i/o */
  if (echo) {
      current.c_lflag |= ECHO; /* set echo mode */
  } else {
      current.c_lflag &= ~ECHO; /* set no echo mode */
  }
  tcsetattr(0, TCSANOW, &current); /* use these new terminal i/o settings now */
}

/* Restore old terminal i/o settings */
void resetTermios(void) 
{
  tcsetattr(0, TCSANOW, &old);
}

/* Read 1 character - echo defines echo mode */
char getch_(int echo) 
{
  char ch;
  initTermios(echo);
  ch = getchar();
  resetTermios();
  return ch;
}

/* Read 1 character without echo */
char getch(void) 
{
  return getch_(0);
}

/* Read 1 character with echo */
char getche(void) 
{
  return getch_(1);
}
using namespace std;

#define MAX_NUM 1000000
#define MAX_DIM 252

int main()
{
    int l = MAX_DIM, m = MAX_DIM, n = MAX_DIM;
    __attribute__ ((aligned(16)))  float a[MAX_DIM][MAX_DIM], b[MAX_DIM][MAX_DIM],c[MAX_DIM][MAX_DIM],d[MAX_DIM][MAX_DIM];

    srand((unsigned)time(0));

    for(int i = 0; i < l; ++i)
    {
        for(int j = 0; j < m; ++j)
        {
            a[i][j] = rand()%MAX_NUM;
        }
    }

    for(int i = 0; i < m; ++i)
    {
        for(int j = 0; j < n; ++j)
        {
            b[i][j] = rand()%MAX_NUM;
        }
    }

    clock_t Time1 = clock();

    for(int i = 0; i < m; ++i)
    {
        for(int j = 0; j < n; ++j)
        {
            d[i][j] = b[j][i];
        }
    }

    for(int i = 0; i < l; ++i)
    {
        for(int j = 0; j < n; ++j)
        {
            __m128 *m3 = (__m128*)a[i];
            __m128 *m4 = (__m128*)d[j];
            float* res;
            c[i][j] = 0;
            for(int k = 0; k < m; k += 4)
            {
                __m128 m5 = _mm_mul_ps(*m3,*m4);
                res = (float*)&m5;
                c[i][j] += res[0]+res[1]+res[2]+res[3];
                m3++;
                m4++;
            }
        }
        //cout<<endl;
    }

    clock_t Time2 = clock();
    double TotalTime = ((double)Time2 - (double)Time1)/CLOCKS_PER_SEC;
    cout<<"Time taken by SIMD implmentation is "<<TotalTime<<"s\n";

    Time1 = clock();

    for(int i = 0; i < l; ++i)
    {
        for(int j = 0; j < n; ++j)
        {
            c[i][j] = 0;
            for(int k = 0; k < m; k += 4)
            {
                c[i][j] += a[i][k] * b[k][j];
                c[i][j] += a[i][k+1] * b[k+1][j];
                c[i][j] += a[i][k+2] * b[k+2][j];
                c[i][j] += a[i][k+3] * b[k+3][j];

            }
        }
    }

    Time2 = clock();
    TotalTime = ((double)Time2 - (double)Time1)/CLOCKS_PER_SEC;
    cout<<"Time taken by normal implmentation is "<<TotalTime<<"s\n";

    getch();
    return 0;
}
#endif
#if 0
#include <iostream>


int main() {
    std::cout << "my hi" << std::endl;
}
#endif
#if 0
#include <algorithm>
#include <boost/algorithm/minmax.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <cassert>
#include <cstdlib>
#include <iostream>
#include <iterator>
#include <list>
void f1(){
    std::cout << "Hello" << std::endl;
}
int main() {

    using namespace std;
  boost::tuple<int const&, int const&> result1 = boost::minmax(1, 0);

  assert( result1.get<0>() == 0 );
  assert( result1.get<1>() == 1 );

  list<int> L;
  generate_n(front_inserter(L), 1000, rand);

  typedef list<int>::const_iterator iterator;
  pair< iterator, iterator > result2 = boost::minmax_element(L.begin(), L.end());
  cout << "The smallest element is " << *(result2.first) << endl;
  cout << "The largest element is  " << *(result2.second) << endl;

  assert( result2.first  == std::min_element(L.begin(), L.end()));
  assert( result2.second == std::max_element(L.begin(), L.end()));
    f1();
    return 0;
}
#endif
