#include <stdio.h>
void __cyg_profile_func_enter (void *this_fn,
                                         void *call_site){};
          void __cyg_profile_func_exit  (void *this_fn,
                                         void *call_site){};
void foo(){}
int main(){//;//int argc){//, char* argv[], char* argE[],int v){
    printf("hii");
foo();
    return 0;
}
