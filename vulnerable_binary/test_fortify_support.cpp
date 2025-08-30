#include <iostream>

int main() {
    #ifdef _FORTIFY_SOURCE
        std::cout << "_FORTIFY_SOURCE is defined as: " << _FORTIFY_SOURCE << std::endl;
    #else
        std::cout << "_FORTIFY_SOURCE is NOT defined" << std::endl;
    #endif
    
    #ifdef __USE_FORTIFY_LEVEL
        std::cout << "__USE_FORTIFY_LEVEL is: " << __USE_FORTIFY_LEVEL << std::endl;
    #endif
    
    return 0;
}