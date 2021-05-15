#include <iostream>


int main() {
    std::cout << "my hi" << std::endl;
}
#if 0
#include <iostream>
#include <list>
#include <list>
#include <algorithm>
#include <cstdlib>
#include <cassert>
#include <iostream>
#include <iterator>
#include <boost/algorithm/minmax.hpp>
#include <boost/algorithm/minmax_element.hpp>
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
